#!/usr/bin/env bash
# Usage:
#   scripts/foreman-dispatch.sh .agent-runs/2026-04-09-example-task/brief.md
#   scripts/foreman-dispatch.sh --no-classify .agent-runs/2026-04-09-example-task/brief.md
#   scripts/foreman-dispatch.sh /absolute/path/to/.agent-runs/2026-04-09-example-task/brief.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 [--no-classify] <brief.md path>" >&2
}

CLASSIFY_ENABLED=1
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-classify)
      CLASSIFY_ENABLED=0
      shift
      ;;
    -*)
      usage
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "${#POSITIONAL_ARGS[@]}" -ne 1 ]]; then
  usage
  exit 1
fi

BRIEF_PATH="${POSITIONAL_ARGS[0]}"

if [[ ! -f "$BRIEF_PATH" ]]; then
  echo "Brief not found: $BRIEF_PATH" >&2
  exit 1
fi

extract_field() {
  local field="$1"
  sed -nE \
    -e "s/^[[:space:]]*\\*\\*${field}:\\*\\*[[:space:]]*//Ip" \
    -e "s/^[[:space:]]*${field}:[[:space:]]*//Ip" \
    "$BRIEF_PATH" | head -1
}

resolve_review_base_ref() {
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

MODEL_RAW="$(extract_field "Model" || true)"
REASONING_RAW="$(extract_field "Reasoning Level" || true)"

MODEL_RAW="${MODEL_RAW:-claude-opus-5}"
REASONING_RAW="${REASONING_RAW:-medium}"
TASK_GOAL="$(extract_field "Goal" || true)"

MODEL_NORMALIZED="$(printf '%s' "$MODEL_RAW" | tr '[:upper:]' '[:lower:]')"
REASONING_NORMALIZED="$(printf '%s' "$REASONING_RAW" | tr '[:upper:]' '[:lower:]')"

case "$MODEL_NORMALIZED" in
  claude|claude-opus-5|opus-5|opus5)
    MODEL_TIER="claude-opus-5"
    TOOL_NAME="claude"
    ;;
  *haiku*|*sonnet*|*opus*|*claude*)
    printf 'foreman-dispatch: only claude-opus-5 is allowed for Claude work (got %s)\n' "$MODEL_RAW" >&2
    exit 64
    ;;
  *codex*|*gpt*)
    MODEL_TIER="codex"
    TOOL_NAME="codex"
    ;;
  *cursor*)
    MODEL_TIER="cursor"
    TOOL_NAME="cursor"
    ;;
  *openclaw*)
    MODEL_TIER="openclaw"
    TOOL_NAME="openclaw"
    ;;
  *)
    MODEL_TIER="$MODEL_NORMALIZED"
    TOOL_NAME="human"
    ;;
esac

CLASSIFY_RESULT=""

if [[ "$CLASSIFY_ENABLED" -eq 0 ]]; then
  echo "Classifier: skipped (--no-classify)"
elif [[ -f "$BRIEF_PATH" ]] && command -v python3 >/dev/null 2>&1; then
  CLASSIFY_RESULT="$(
    python3 "$SCRIPT_DIR/foreman-classify.py" "$BRIEF_PATH" 2>/dev/null || \
      echo '{"route":"standard","confidence":0,"reason":"classifier failed","escalation_triggers":[]}'
  )"
else
  CLASSIFY_RESULT='{"route":"standard","confidence":0,"reason":"classifier unavailable - defaulting to standard","escalation_triggers":[]}'
fi

if [[ -n "$CLASSIFY_RESULT" ]] && command -v python3 >/dev/null 2>&1; then
  CLASSIFY_ROUTE="$(
    printf '%s' "$CLASSIFY_RESULT" | \
      python3 -c 'import json,sys; print(json.load(sys.stdin).get("route", "standard"))'
  )"
  CLASSIFY_REASON="$(
    printf '%s' "$CLASSIFY_RESULT" | \
      python3 -c 'import json,sys; print(json.load(sys.stdin).get("reason", ""))'
  )"
  echo "Classifier route: ${CLASSIFY_ROUTE} - ${CLASSIFY_REASON}"

  if [[ "$CLASSIFY_ROUTE" == "escalation" && "$MODEL_TIER" == "claude-opus-5" ]]; then
    REASONING_NORMALIZED="high"
    echo "Classifier raised Claude Opus 5 reasoning to high - review escalation_triggers before proceeding"
  fi
fi

BRIEF_DIR_BASENAME="$(basename "$(dirname "$BRIEF_PATH")")"
TODAY="$(date +%F)"
DATE_PART="$TODAY"
SLUG_PART="$BRIEF_DIR_BASENAME"

if [[ "$BRIEF_DIR_BASENAME" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)$ ]]; then
  DATE_PART="${BASH_REMATCH[1]}"
  SLUG_PART="${BASH_REMATCH[2]}"
fi

SLUG_PART="$(printf '%s' "$SLUG_PART" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
SLUG_PART="${SLUG_PART:-task}"
TASK_GOAL="${TASK_GOAL:-$SLUG_PART}"
THREAD_VALUE="${THREAD_ID:-unknown}"

BRANCH_NAME="agent/${TOOL_NAME}/${DATE_PART}/${SLUG_PART}"

echo "Resolved model tier: ${MODEL_TIER}"
echo "Resolved reasoning level: ${REASONING_NORMALIZED}"
echo "Proposed branch: ${BRANCH_NAME}"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  REVIEWER_SCRIPT="$REPO_ROOT/scripts/foreman-review.py"
  REVIEW_BASE_REF="$(resolve_review_base_ref || true)"
  BRANCH_READY=false
  if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    if git checkout "${BRANCH_NAME}" >/dev/null 2>&1; then
      echo "Checked out existing branch: ${BRANCH_NAME}"
      BRANCH_READY=true
    else
      echo "Could not switch branches automatically. Run: git checkout ${BRANCH_NAME}"
    fi
  else
    if git checkout -b "${BRANCH_NAME}" >/dev/null 2>&1; then
      echo "Created branch: ${BRANCH_NAME}"
      BRANCH_READY=true
    else
      echo "Could not create the branch automatically. Run: git checkout -b ${BRANCH_NAME}"
    fi
  fi

  if [[ "$BRANCH_READY" == "true" ]]; then
    LEDGER_PATH="$REPO_ROOT/BRANCH_LEDGER.md"
    if [[ -f "$LEDGER_PATH" ]] && command -v python3 >/dev/null 2>&1; then
      if LEDGER_STATUS="$(
        LEDGER_PATH="$LEDGER_PATH" \
        LEDGER_BRANCH_NAME="$BRANCH_NAME" \
        LEDGER_MODEL_TIER="$MODEL_TIER" \
        LEDGER_TODAY="$TODAY" \
        LEDGER_TASK_GOAL="$TASK_GOAL" \
        LEDGER_THREAD_VALUE="$THREAD_VALUE" \
        python3 <<'PY'
from pathlib import Path
import os
import sys

path = Path(os.environ["LEDGER_PATH"])
branch = os.environ["LEDGER_BRANCH_NAME"]
model_tier = os.environ["LEDGER_MODEL_TIER"]
today = os.environ["LEDGER_TODAY"]
task_goal = os.environ["LEDGER_TASK_GOAL"].replace("\n", " ").replace("|", "\\|").strip()
thread_value = os.environ["LEDGER_THREAD_VALUE"].replace("\n", " ").replace("|", "\\|").strip()

text = path.read_text(encoding="utf-8")
lines = text.splitlines(keepends=True)

header = "## Active Branches\n"
try:
    section_index = lines.index(header)
except ValueError:
    raise SystemExit(2)

table_header_index = None
for index in range(section_index + 1, len(lines)):
    if lines[index].startswith("| Branch |"):
        table_header_index = index
        break

if table_header_index is None or table_header_index + 1 >= len(lines):
    raise SystemExit(3)

branch_marker = f"| `{branch}` |"
if branch_marker in text:
    print("exists")
    raise SystemExit(0)

insert_index = table_header_index + 2
while insert_index < len(lines) and lines[insert_index].strip() != "":
    insert_index += 1

row = (
    f"| `{branch}` | {model_tier} | {today} | {task_goal} | "
    f"all gates pass + reviewed + APPROVE | {thread_value} | open | "
    "dispatched via foreman-dispatch.sh |\n"
)
lines.insert(insert_index, row)
path.write_text("".join(lines), encoding="utf-8")
print("added")
PY
      )"; then
        if [[ "$LEDGER_STATUS" == "added" ]]; then
          echo "📋 foreman: added row to BRANCH_LEDGER.md for ${BRANCH_NAME}"
        elif [[ "$LEDGER_STATUS" == "exists" ]]; then
          echo "ℹ️  foreman: BRANCH_LEDGER.md already contains a row for ${BRANCH_NAME}"
        fi
      else
        echo "WARNING: foreman could not update BRANCH_LEDGER.md for ${BRANCH_NAME}"
      fi
    else
      echo "WARNING: foreman could not update BRANCH_LEDGER.md for ${BRANCH_NAME}"
    fi
  fi

  HOOK_PATH="$(git rev-parse --git-path hooks/commit-msg)"
  if [[ -x "$HOOK_PATH" ]]; then
    echo "Hooks check: commit-msg hook is installed at ${HOOK_PATH}"
  else
    echo "WARNING: commit-msg hook is missing or not executable at ${HOOK_PATH}"
  fi
else
  REPO_ROOT="$DEFAULT_REPO_ROOT"
  REVIEWER_SCRIPT="$REPO_ROOT/scripts/foreman-review.py"
  REVIEW_BASE_REF=""
  echo "Not inside a git work tree. Run: git checkout -b ${BRANCH_NAME}"
  echo "WARNING: unable to verify .git/hooks/commit-msg outside a git work tree"
fi

echo ""
echo "Next step after completing your work:"
if [[ -n "$REVIEW_BASE_REF" ]]; then
  echo "  git diff ${REVIEW_BASE_REF}...HEAD | python3 \"$REVIEWER_SCRIPT\" --author-model ${MODEL_TIER} --branch ${BRANCH_NAME} -"
else
  echo "  if git show-ref --verify --quiet refs/heads/main; then BASE_REF=main; elif git show-ref --verify --quiet refs/remotes/origin/main; then BASE_REF=origin/main; else echo 'Missing main and origin/main'; exit 1; fi; git diff \"\${BASE_REF}\"...HEAD | python3 \"$REVIEWER_SCRIPT\" --author-model ${MODEL_TIER} --branch ${BRANCH_NAME} -"
fi
echo ""
echo "When done and merged, close the branch:"
echo "  scripts/foreman-close.sh ${BRANCH_NAME} merged"
