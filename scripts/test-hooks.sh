#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_REPO="/tmp/foreman-hook-test-$$"
TEST_REMOTE="/tmp/foreman-hook-remote-$$.git"
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
  rm -rf "$TEST_REMOTE"
}

trap cleanup EXIT

git -c init.defaultBranch=agent/codex/2026-04-11/hook-smoke init "$TEST_REPO" >/dev/null
git init --bare "$TEST_REMOTE" >/dev/null
git -C "$TEST_REPO" config user.name "Foreman Hook Test"
git -C "$TEST_REPO" config user.email "foreman-hook-test@example.com"
git -C "$TEST_REPO" config core.hooksPath .git/hooks
git -C "$TEST_REPO" remote add origin "$TEST_REMOTE"

cp "$ROOT_DIR/hooks/commit-msg" "$TEST_REPO/.git/hooks/commit-msg"
cp "$ROOT_DIR/hooks/pre-push" "$TEST_REPO/.git/hooks/pre-push"
mkdir -p "$TEST_REPO/scripts"
cp "$ROOT_DIR/scripts/foreman-review.py" "$TEST_REPO/scripts/foreman-review.py"
chmod +x "$TEST_REPO/.git/hooks/commit-msg" "$TEST_REPO/.git/hooks/pre-push"

VALID_MESSAGE=$'test: initialize hook smoke repo\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Initialize hook smoke repo\nVerified-By: manual\nReviewed-By: none-yet'
MISSING_AGENT_MESSAGE=$'test: missing agent trailer\n\nThread: codex-desktop-2026-04-11\nTask: Missing Agent trailer should fail\nVerified-By: manual\nReviewed-By: none-yet'
VALID_COMMIT_MESSAGE=$'test: valid trailer commit\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Valid hook smoke commit\nVerified-By: manual\nReviewed-By: none-yet'

LONG_MESSAGE_FILE="$TEST_REPO/long-valid-message.txt"
{
  printf 'test: long valid trailer message\n\nAgent: early body marker\n'
  head -c 131072 /dev/zero | tr '\0' x
  printf '\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Long valid hook smoke commit\nVerified-By: manual\nReviewed-By: none-yet\n'
} >"$LONG_MESSAGE_FILE"

if "$TEST_REPO/.git/hooks/commit-msg" "$LONG_MESSAGE_FILE" >/tmp/foreman-hook-long-message.log 2>&1; then
  pass "commit-msg accepts a long message with every required trailer under pipefail"
else
  cat /tmp/foreman-hook-long-message.log
  fail "commit-msg accepts a long message with every required trailer under pipefail"
fi

if git -C "$TEST_REPO" commit --allow-empty -m "$VALID_MESSAGE" >/tmp/foreman-hook-init.log 2>&1; then
  pass "initial commit with valid trailers is accepted"
else
  cat /tmp/foreman-hook-init.log
  fail "initial commit with valid trailers is accepted"
fi

if git -C "$TEST_REPO" branch -M main && git -C "$TEST_REPO" push --no-verify -u origin main >/tmp/foreman-hook-main-push.log 2>&1; then
  pass "bootstrap main push succeeds without verify"
else
  cat /tmp/foreman-hook-main-push.log
  fail "bootstrap main push succeeds without verify"
fi

INITIAL_MAIN_HASH="$(git -C "$TEST_REPO" rev-parse HEAD)"
git -C "$TEST_REPO" commit --allow-empty --no-verify -m "test: remote base without trailers"
REMOTE_BASE_HASH="$(git -C "$TEST_REPO" rev-parse --short=7 HEAD)"
git -C "$TEST_REPO" push --no-verify origin main

if git -C "$TEST_REPO" checkout -b agent/codex/2026-04-11/trailer-warning >/tmp/foreman-hook-branch.log 2>&1; then
  git -C "$TEST_REPO" branch -f main "$INITIAL_MAIN_HASH"
  pass "test branch for pre-push trailer scan is created"
else
  cat /tmp/foreman-hook-branch.log
  fail "test branch for pre-push trailer scan is created"
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

if git -C "$TEST_REPO" commit --allow-empty -F "$LONG_MESSAGE_FILE" >/tmp/foreman-hook-long-commit.log 2>&1; then
  LONG_COMMIT_HASH="$(git -C "$TEST_REPO" rev-parse --short=7 HEAD)"
  pass "long valid commit is available for pre-push trailer scanning"
else
  cat /tmp/foreman-hook-long-commit.log
  fail "long valid commit is available for pre-push trailer scanning"
fi

SECOND_VALID_COMMIT=$'test: second valid trailer commit\n\nAgent: codex-gpt-5\nThread: codex-desktop-2026-04-11\nTask: Second valid hook smoke commit\nVerified-By: manual\nReviewed-By: none-yet'
INVALID_NO_VERIFY_COMMIT=$'test: invalid trailer commit bypass\n\nThread: codex-desktop-2026-04-11\nTask: Bypassed invalid hook smoke commit\nVerified-By: manual\nReviewed-By: none-yet'

printf 'nonempty review diff\n' >"$TEST_REPO/review-fixture.txt"
git -C "$TEST_REPO" add review-fixture.txt
if git -C "$TEST_REPO" commit -m "$SECOND_VALID_COMMIT" >/tmp/foreman-hook-valid-second.log 2>&1; then
  pass "second valid commit for pre-push scan is accepted"
else
  cat /tmp/foreman-hook-valid-second.log
  fail "second valid commit for pre-push scan is accepted"
fi

if git -C "$TEST_REPO" commit --allow-empty --no-verify -m "$INVALID_NO_VERIFY_COMMIT" >/tmp/foreman-hook-invalid-no-verify.log 2>&1; then
  pass "invalid commit can be created with --no-verify for pre-push scan"
else
  cat /tmp/foreman-hook-invalid-no-verify.log
  fail "invalid commit can be created with --no-verify for pre-push scan"
fi

if (
  cd "$TEST_REPO"
  git push origin agent/codex/2026-04-11/trailer-warning >/tmp/foreman-hook-pre-push.log 2>&1
); then
  if grep -Fq "commit $LONG_COMMIT_HASH: missing" /tmp/foreman-hook-pre-push.log; then
    cat /tmp/foreman-hook-pre-push.log
    fail "pre-push trailer validation accepts the long valid commit under pipefail"
  else
    pass "pre-push trailer validation accepts the long valid commit under pipefail"
  fi

  if grep -Fq "commit $REMOTE_BASE_HASH: missing" /tmp/foreman-hook-pre-push.log; then
    cat /tmp/foreman-hook-pre-push.log
    fail "pre-push trailer validation uses current origin/main over stale local main"
  else
    pass "pre-push trailer validation uses current origin/main over stale local main"
  fi

  if grep -Fq "missing 'Agent:' trailer" /tmp/foreman-hook-pre-push.log; then
    pass "pre-push trailer validation warns when a branch commit is missing Agent"
  else
    cat /tmp/foreman-hook-pre-push.log
    fail "pre-push trailer validation warns when a branch commit is missing Agent"
  fi
else
  cat /tmp/foreman-hook-pre-push.log
  fail "pre-push trailer validation push warning run succeeds"
fi

if [[ "$FAILURES" -ne 0 ]]; then
  exit 1
fi
