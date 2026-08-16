#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

cp "$ROOT_DIR/scripts/foreman-dispatch.sh" "$TEST_DIR/foreman-dispatch.sh"
printf '%s\n' \
  '#!/usr/bin/env python3' \
  "print('{\"route\":\"cheap\",\"confidence\":1,\"reason\":\"fixture\",\"escalation_triggers\":[]}')" \
  >"$TEST_DIR/foreman-classify.py"
chmod +x "$TEST_DIR/foreman-dispatch.sh" "$TEST_DIR/foreman-classify.py"

run_case() {
  local name="$1"
  local model="$2"
  local expected_tool="$3"
  local expected_author="$4"
  local brief_dir="$TEST_DIR/2026-08-15-$name"
  local brief_path="$brief_dir/brief.md"
  local output

  mkdir -p "$brief_dir"
  printf '%s\n' \
    '## Task Brief' \
    '' \
    '**Goal:** Verify cheap-route model preservation' \
    "**Model:** $model" \
    '**Reasoning Level:** low' \
    >"$brief_path"

  output="$(cd "$TEST_DIR" && ./foreman-dispatch.sh "$brief_path")"
  grep -Fq 'Classifier route: cheap - fixture' <<<"$output"
  grep -Fq "agent/$expected_tool/2026-08-15/$name" <<<"$output"
  grep -Fq -- "--author-model $expected_author" <<<"$output"
}

run_case "dispatch-codex" "codex" "codex" "codex"
printf 'PASS: cheap route preserves Codex author provenance\n'

run_case "dispatch-claude" "claude-opus-5" "claude" "claude-opus-5"
printf 'PASS: cheap route preserves Claude Opus 5 author provenance\n'
