#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_REPO="/tmp/foreman-hook-test-$$"
FAILURES=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

cleanup() {
  rm -rf "$TEST_REPO"
}

trap cleanup EXIT

git -c init.defaultBranch=agent/codex/2026-04-11/hook-smoke init "$TEST_REPO" >/dev/null
git -C "$TEST_REPO" config user.name "Foreman Hook Test"
git -C "$TEST_REPO" config user.email "foreman-hook-test@example.com"
git -C "$TEST_REPO" config core.hooksPath .git/hooks

cp "$ROOT_DIR/hooks/commit-msg" "$TEST_REPO/.git/hooks/commit-msg"
cp "$ROOT_DIR/hooks/pre-push" "$TEST_REPO/.git/hooks/pre-push"
chmod +x "$TEST_REPO/.git/hooks/commit-msg" "$TEST_REPO/.git/hooks/pre-push"

VALID_MESSAGE=$'test: initialize hook smoke repo\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Initialize hook smoke repo\nVerified-By: manual\nReviewed-By: none-yet'
MISSING_AGENT_MESSAGE=$'test: missing agent trailer\n\nThread: codex-desktop-2026-04-11\nTask: Missing Agent trailer should fail\nVerified-By: manual\nReviewed-By: none-yet'
VALID_COMMIT_MESSAGE=$'test: valid trailer commit\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Valid hook smoke commit\nVerified-By: manual\nReviewed-By: none-yet'

if git -C "$TEST_REPO" commit --allow-empty -m "$VALID_MESSAGE" >/tmp/foreman-hook-init.log 2>&1; then
  pass "initial commit with valid trailers is accepted"
else
  cat /tmp/foreman-hook-init.log
  fail "initial commit with valid trailers is accepted"
fi

if (
  cd "$TEST_REPO"
  git commit --allow-empty -m "$MISSING_AGENT_MESSAGE" >/tmp/foreman-hook-missing-agent.log 2>&1
); then
  cat /tmp/foreman-hook-missing-agent.log
  fail "commit without Agent trailer is rejected"
else
  pass "commit without Agent trailer is rejected"
fi

if git -C "$TEST_REPO" commit --allow-empty -m "$VALID_COMMIT_MESSAGE" >/tmp/foreman-hook-valid.log 2>&1; then
  pass "commit with all required trailers is accepted"
else
  cat /tmp/foreman-hook-valid.log
  fail "commit with all required trailers is accepted"
fi

if [[ "$FAILURES" -ne 0 ]]; then
  exit 1
fi
