#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEWER_SCRIPT="$ROOT_DIR/scripts/foreman-review.py"
FAILURES=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

run_test() {
  local name="$1"
  shift

  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

test_empty_diff() {
  local output

  if ! output="$(printf '' | python3 "$REVIEWER_SCRIPT" --author-model codex-5.3 --branch smoke-empty - 2>&1)"; then
    printf '%s\n' "$output"
    return 1
  fi

  [[ "$output" == *"Reviewer verdict: APPROVE"* ]] || {
    printf '%s\n' "$output"
    return 1
  }
  [[ "$output" == *"Summary: Empty diff"* ]] || {
    printf '%s\n' "$output"
    return 1
  }
}

test_codex_route() {
  python3 - <<'PY'
import importlib.util
from pathlib import Path

script_path = Path("scripts/foreman-review.py")
spec = importlib.util.spec_from_file_location("foreman_review", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

provider, model = module.resolve_reviewer("codex-5.3")
assert provider == "anthropic", (provider, model)
assert model == "claude-sonnet-4-6", (provider, model)
PY
}

test_claude_fallback_route() {
  python3 - <<'PY'
import importlib.util
import os
from pathlib import Path

os.environ.pop("OPENAI_API_KEY", None)

script_path = Path("scripts/foreman-review.py")
spec = importlib.util.spec_from_file_location("foreman_review", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

provider, model = module.resolve_reviewer("claude-sonnet-4-6")
assert provider == "anthropic", (provider, model)
assert model == "claude-haiku-4-5-20251001", (provider, model)
PY
}

test_malformed_json() {
  python3 - <<'PY'
import importlib.util
from pathlib import Path

script_path = Path("scripts/foreman-review.py")
spec = importlib.util.spec_from_file_location("foreman_review", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

try:
    module.extract_json_object('{"verdict": }')
except module.ReviewError:
    raise SystemExit(0)

raise SystemExit(1)
PY
}

cd "$ROOT_DIR" || exit 1

run_test "empty diff returns APPROVE" test_empty_diff
run_test "codex author routes to anthropic sonnet" test_codex_route
run_test "claude author without OPENAI_API_KEY routes to anthropic haiku" test_claude_fallback_route
run_test "malformed JSON raises ReviewError" test_malformed_json

if [[ "$FAILURES" -ne 0 ]]; then
  exit 1
fi
