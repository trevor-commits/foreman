#!/usr/bin/env bash
# =============================================================================
# foreman — local verification (mirrors .github/workflows/test-foreman-tooling.yml)
#
# Usage (from repo root):
#   bash scripts/verify.sh
#
# First-time / CI-parity deps (needs network once):
#   FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh
#
# macOS with Homebrew Python: use a venv instead of a global install:
#   python3 -m venv .venv && source .venv/bin/activate
#   pip install -r scripts/requirements.txt
#   bash scripts/verify.sh
#
# No API keys required — reviewer/classifier tests use fixtures and mocks.
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Prefer an in-repo venv when present (common on macOS / PEP 668 systems).
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  export PATH="$ROOT_DIR/.venv/bin:$PATH"
fi

require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "verify: python3 is required" >&2
    exit 1
  fi
}

deps_satisfied() {
  python3 -c "import yaml" >/dev/null 2>&1 && python3 -c "import mcp" >/dev/null 2>&1
}

ensure_deps() {
  if deps_satisfied; then
    return 0
  fi
  if [[ "${FOREMAN_VERIFY_INSTALL:-}" == "1" ]]; then
    echo "verify: installing Python deps from scripts/requirements.txt ..."
    python3 -m pip install -r scripts/requirements.txt
    if deps_satisfied; then
      return 0
    fi
    echo "verify: pip install completed but imports still missing (wrong python3 on PATH?)" >&2
    exit 1
  fi
  cat >&2 <<'EOF'
verify: missing Python packages from scripts/requirements.txt (need PyYAML and mcp).

  python3 -m pip install -r scripts/requirements.txt

Or one-shot:

  FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh

On macOS with an externally managed system Python, use a virtualenv (see header in this script).
EOF
  exit 1
}

echo ""
echo "foreman verify — local CI parity"
echo "    root: $ROOT_DIR"
echo ""

require_python
ensure_deps

echo "▸ bash syntax — hooks and shell scripts"
bash -n hooks/pre-push
bash -n hooks/commit-msg
bash -n hooks/install.sh
bash -n scripts/foreman-dispatch.sh
bash -n scripts/foreman-close.sh
bash -n scripts/foreman-status.sh
bash -n scripts/foreman-merge-check.sh
bash -n scripts/foreman-drift-check.sh
bash -n scripts/foreman-pr-prep.sh
bash -n scripts/verify.sh

echo "▸ python compile — governance scripts"
python3 -m py_compile scripts/foreman-review.py
python3 -m py_compile scripts/foreman-classify.py
python3 -m py_compile scripts/foreman-mcp-shim.py
python3 -m py_compile scripts/foreman-mcp-server.py
python3 -m py_compile scripts/foreman-calibration.py

echo "▸ reviewer smoke tests"
python3 scripts/test-review.py

echo "▸ classifier smoke tests"
python3 scripts/test-classify.py

echo "▸ hook smoke tests"
bash scripts/test-hooks.sh

echo "▸ dispatcher routing tests"
bash scripts/test-dispatch.sh

echo "▸ MCP shim help check"
if python3 scripts/foreman-mcp-shim.py --help 2>&1 | grep -q "tool"; then
  :
else
  python3 scripts/foreman-mcp-shim.py --tool foreman_review \
    --args '{"diff":"","author_model":"codex","branch":"test"}' | \
    python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('verdict')=='APPROVE'"
fi

echo "▸ MCP server import smoke check"
python3 <<'PY'
import importlib.util

spec = importlib.util.spec_from_file_location("srv", "scripts/foreman-mcp-server.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
tools = list(mod.mcp._tools.keys())
assert tools, "expected at least one MCP tool"
print(f"    tools: {tools}")
PY

echo "▸ GitHub Actions workflow YAML"
python3 <<'PY'
import yaml
from pathlib import Path


def workflow_triggers(doc: dict) -> dict:
    # YAML 1.1 treats bare `on` as boolean True in some parsers.
    return doc.get(True) if True in doc else doc.get("on") or {}


for path in (
    ".github/workflows/foreman-trailer-check.yml",
    ".github/workflows/test-foreman-tooling.yml",
):
    with open(path, encoding="utf-8") as f:
        doc = yaml.safe_load(f)
    triggers = workflow_triggers(doc)
    assert triggers, f"{path}: missing on: triggers"
    print(f"    {path}: valid YAML (triggers: {list(triggers.keys())})")

with open(".github/workflows/test-foreman-tooling.yml", encoding="utf-8") as f:
    tooling = yaml.safe_load(f)

job = tooling.get("jobs", {}).get("test-scripts", {})
steps = job.get("steps") or []
run_steps = [s for s in steps if isinstance(s, dict) and "run" in s]
assert len(run_steps) == 1, (
    "test-foreman-tooling.yml: expected exactly one run: step (delegate to verify.sh)"
)
run_body = run_steps[0]["run"]
assert "scripts/verify.sh" in run_body, (
    "test-foreman-tooling.yml: run step must invoke scripts/verify.sh"
)
env = run_steps[0].get("env") or {}
assert env.get("FOREMAN_VERIFY_INSTALL") == "1", (
    "test-foreman-tooling.yml: FOREMAN_VERIFY_INSTALL=1 required for hosted parity"
)
print("    test-foreman-tooling.yml: CI parity contract OK")
PY

echo ""
echo "✅  foreman verify passed"
echo ""
