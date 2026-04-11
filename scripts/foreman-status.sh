#!/usr/bin/env bash

set -uo pipefail

BRANCH_PATTERN='^(agent|review)/[a-z0-9_-]+/[0-9]{4}-[0-9]{2}-[0-9]{2}/[a-z0-9-]+$'
PROTECTED_BRANCHES=("main" "master" "production" "prod")

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not available")"

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

commit_body=""
if [[ -n "$repo_root" ]]; then
  commit_body="$(git -C "$repo_root" log -1 --format=%B 2>/dev/null || true)"
fi

agent_value="not available"
thread_value="not available"
task_value="not available"
verified_by_value="not available"
reviewed_by_value="not available"

if [[ -n "$commit_body" ]]; then
  agent_value="$(extract_trailer "Agent" "$commit_body")"
  thread_value="$(extract_trailer "Thread" "$commit_body")"
  task_value="$(extract_trailer "Task" "$commit_body")"
  verified_by_value="$(extract_trailer "Verified-By" "$commit_body")"
  reviewed_by_value="$(extract_trailer "Reviewed-By" "$commit_body")"

  agent_value="${agent_value:-not available}"
  thread_value="${thread_value:-not available}"
  task_value="${task_value:-not available}"
  verified_by_value="${verified_by_value:-not available}"
  reviewed_by_value="${reviewed_by_value:-not available}"
fi

review_verdict="not run yet"
review_model="not available"
review_summary="not available"
review_path_display="no review recorded"
if [[ -n "$repo_root" && -f "$repo_root/.agent-runs/last-review.json" ]]; then
  mapfile -t review_fields < <(
    python3 - "$repo_root/.agent-runs/last-review.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    payload = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    payload = {}

print(payload.get("verdict", "not available"))
print(payload.get("reviewer_model", "not available"))
print(payload.get("summary", "not available"))
PY
  )
  review_verdict="${review_fields[0]:-not available}"
  review_model="${review_fields[1]:-not available}"
  review_summary="${review_fields[2]:-not available}"
  review_path_display=".agent-runs/last-review.json"
fi

ledger_status="not found"
ledger_row_found="⚠️  no row found for this branch"
if [[ -n "$repo_root" && -f "$repo_root/BRANCH_LEDGER.md" && "$current_branch" != "not available" ]]; then
  ledger_row="$(grep -F "| \`$current_branch\` |" "$repo_root/BRANCH_LEDGER.md" | head -1 || true)"
  if [[ -n "$ledger_row" ]]; then
    ledger_row_found="yes"
    ledger_status="$(printf '%s\n' "$ledger_row" | awk -F'|' '{gsub(/^[ \t`]+|[ \t`]+$/, "", $8); print $8}')"
    if [[ -z "$ledger_status" ]]; then
      ledger_outcome="$(printf '%s\n' "$ledger_row" | awk -F'|' '{gsub(/^[ \t`]+|[ \t`]+$/, "", $6); print $6}')"
      case "${ledger_outcome,,}" in
        merged*)
          ledger_status="merged"
          ;;
        abandoned*)
          ledger_status="abandoned"
          ;;
        *)
          ledger_status="not available"
          ;;
      esac
    fi
  fi
fi

hard_gate_value="${FOREMAN_HARD_GATE:-not set}"
strict_branch_value="${FOREMAN_STRICT_BRANCH:-not set}"

echo "━━━ foreman status: ${current_branch} ━━━"
echo ""

if [[ "$current_branch" == "not available" ]]; then
  echo "Branch name:     not available"
else
  if [[ "$current_branch" =~ $BRANCH_PATTERN ]]; then
    echo "Branch name:     ✅ compliant"
  else
    echo "Branch name:     ⚠️  non-compliant: does not match ${BRANCH_PATTERN}"
  fi
fi

if is_protected_branch "$current_branch"; then
  echo "Protected branch: ❌ PROTECTED — do not push directly"
else
  echo "Protected branch: ✅ not a protected branch"
fi

echo ""
echo "Last commit:"
echo "  Agent:          ${agent_value}"
echo "  Thread:         ${thread_value}"
echo "  Task:           ${task_value}"
echo "  Verified-By:    ${verified_by_value}"
if [[ -z "$reviewed_by_value" || "$reviewed_by_value" == "not available" ]]; then
  echo "  Reviewed-By:    not available"
elif [[ "$reviewed_by_value" == "none-yet" ]]; then
  echo "  Reviewed-By:    ⚠️  none-yet"
else
  echo "  Reviewed-By:    ${reviewed_by_value}"
fi

echo ""
echo "Reviewer (last run):"
echo "  Verdict:        ${review_verdict}"
echo "  Reviewer model: ${review_model}"
echo "  Summary:        ${review_summary}"
echo "  Full review:    ${review_path_display}"

echo ""
echo "BRANCH_LEDGER.md:"
echo "  Status:         ${ledger_status}"
echo "  Row found:      ${ledger_row_found}"

echo ""
echo "Hard gate:        FOREMAN_HARD_GATE=${hard_gate_value}"
echo "Strict branch:    FOREMAN_STRICT_BRANCH=${strict_branch_value}"

echo ""
echo "━━━ merge readiness: see scripts/foreman-merge-check.sh ━━━"

exit 0
