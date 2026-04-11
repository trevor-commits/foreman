#!/usr/bin/env bash

set -uo pipefail

BRANCH_PATTERN='^(agent|review)/[a-z0-9_-]+/[0-9]{4}-[0-9]{2}-[0-9]{2}/[a-z0-9-]+$'
PROTECTED_BRANCHES=("main" "master" "production" "prod")

current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
ledger_path="$repo_root/BRANCH_LEDGER.md"
review_path="$repo_root/.agent-runs/last-review.json"

all_pass=true

pass_check() {
  echo "✅ PASS  $1"
}

fail_check() {
  echo "❌ FAIL  $1"
  all_pass=false
}

extract_trailer() {
  local trailer="$1"
  local commit_body="$2"
  printf '%s\n' "$commit_body" | sed -n "s/^${trailer}:[[:space:]]*//p" | head -1
}

is_protected_branch() {
  local branch="$1"
  local protected
  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$branch" == "$protected" ]]; then
      return 0
    fi
  done
  return 1
}

resolve_base_ref() {
  if git show-ref --verify --quiet "refs/heads/main"; then
    printf '%s\n' "main"
    return 0
  fi

  if git show-ref --verify --quiet "refs/remotes/origin/main"; then
    printf '%s\n' "origin/main"
    return 0
  fi

  return 1
}

model_family() {
  local raw
  raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    *claude*)
      echo "claude"
      ;;
    *codex*)
      echo "codex"
      ;;
    gpt*|*gpt*|o1*|o3*|o4*|*openai*)
      echo "gpt"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

if [[ -n "$current_branch" && "$current_branch" =~ $BRANCH_PATTERN ]]; then
  pass_check "1. Branch name is compliant (${current_branch})"
else
  fail_check "1. Branch name is non-compliant (${current_branch:-not available})"
fi

if [[ -n "$current_branch" ]] && ! is_protected_branch "$current_branch"; then
  pass_check "2. Current branch is not protected"
else
  fail_check "2. Current branch is protected or unavailable (${current_branch:-not available})"
fi

base_ref="$(resolve_base_ref || true)"
missing_trailer_reason=""
if [[ -z "$base_ref" ]]; then
  missing_trailer_reason="could not resolve main or origin/main"
else
  mapfile -t branch_commits < <(git rev-list --reverse "${base_ref}"..HEAD 2>/dev/null)
  if [[ "${#branch_commits[@]}" -eq 0 ]]; then
    missing_trailer_reason="no commits found on this branch relative to ${base_ref}"
  else
    for commit_sha in "${branch_commits[@]}"; do
      commit_body="$(git log -1 --format=%B "$commit_sha" 2>/dev/null || true)"
      for trailer in Agent Thread Task Verified-By; do
        if ! printf '%s\n' "$commit_body" | grep -qiE "^${trailer}:[[:space:]]*.+"; then
          missing_trailer_reason="commit ${commit_sha:0:7} is missing ${trailer}"
          break 2
        fi
      done
    done
  fi
fi

if [[ -z "$missing_trailer_reason" ]]; then
  pass_check "3. All required commit trailers are present in every commit since ${base_ref}"
else
  fail_check "3. Required commit trailers are incomplete: ${missing_trailer_reason}"
fi

last_commit_body="$(git log -1 --format=%B 2>/dev/null || true)"
last_agent="$(extract_trailer "Agent" "$last_commit_body")"
last_reviewed_by="$(extract_trailer "Reviewed-By" "$last_commit_body")"

if [[ -n "$last_reviewed_by" && "$last_reviewed_by" != "none-yet" ]]; then
  pass_check "4. Reviewed-By is set on the most recent commit (${last_reviewed_by})"
else
  fail_check "4. Reviewed-By is missing or none-yet on the most recent commit"
fi

agent_family="$(model_family "$last_agent")"
reviewed_family="$(model_family "$last_reviewed_by")"
if [[ -n "$last_agent" && -n "$last_reviewed_by" && "$last_reviewed_by" != "none-yet" && "$agent_family" != "$reviewed_family" ]]; then
  pass_check "5. Reviewed-By differs from Agent by model family (${agent_family} vs ${reviewed_family})"
else
  fail_check "5. Reviewed-By matches Agent family or cannot be verified (${agent_family} vs ${reviewed_family})"
fi

review_verdict="not available"
if [[ -f "$review_path" ]]; then
  review_verdict="$(python3 - "$review_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    payload = json.loads(path.read_text(encoding="utf-8"))
    print(payload.get("verdict", "not available"))
except Exception:
    print("not available")
PY
)"
fi

if [[ "$review_verdict" == "APPROVE" ]]; then
  pass_check "6. Last reviewer verdict is APPROVE"
else
  fail_check "6. Last reviewer verdict is ${review_verdict}"
fi

ledger_row="$(grep -F "| \`$current_branch\` |" "$ledger_path" 2>/dev/null | head -1 || true)"
ledger_status=""
if [[ -n "$ledger_row" ]]; then
  ledger_status="$(printf '%s\n' "$ledger_row" | awk -F'|' '{gsub(/^[ \t`]+|[ \t`]+$/, "", $8); print $8}')"
fi
if [[ "$ledger_status" == "open" || "$ledger_status" == "ready" ]]; then
  pass_check "7. BRANCH_LEDGER.md has an active row for this branch"
else
  if [[ -n "$ledger_row" ]]; then
    fail_check "7. BRANCH_LEDGER.md row exists but status is ${ledger_status:-not available}"
  else
    fail_check "7. BRANCH_LEDGER.md has no row for this branch"
  fi
fi

echo ""
if [[ "$all_pass" == "true" ]]; then
  echo "✅  MERGE READY — all conditions met. Update BRANCH_LEDGER.md to 'ready' and open your PR."
  exit 0
fi

echo "❌  NOT READY — fix the issues above before opening a PR."
exit 1
