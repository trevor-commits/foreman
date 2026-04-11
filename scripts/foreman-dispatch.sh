#!/usr/bin/env bash
# Usage:
#   scripts/foreman-dispatch.sh .agent-runs/2026-04-09-example-task/brief.md
#   scripts/foreman-dispatch.sh --no-classify .agent-runs/2026-04-09-example-task/brief.md
#   scripts/foreman-dispatch.sh /absolute/path/to/.agent-runs/2026-04-09-example-task/brief.md

set -euo pipefail

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
    -e "s/^\\*\\*${field}:\\*\\*[[:space:]]*//Ip" \
    -e "s/^${field}:[[:space:]]*//Ip" \
    "$BRIEF_PATH" | head -1
}

MODEL_RAW="$(extract_field "Model" || true)"
REASONING_RAW="$(extract_field "Reasoning Level" || true)"

MODEL_RAW="${MODEL_RAW:-sonnet}"
REASONING_RAW="${REASONING_RAW:-medium}"

MODEL_NORMALIZED="$(printf '%s' "$MODEL_RAW" | tr '[:upper:]' '[:lower:]')"
REASONING_NORMALIZED="$(printf '%s' "$REASONING_RAW" | tr '[:upper:]' '[:lower:]')"

case "$MODEL_NORMALIZED" in
  *haiku*)
    MODEL_TIER="haiku"
    TOOL_NAME="claude"
    ;;
  *sonnet*)
    MODEL_TIER="sonnet"
    TOOL_NAME="claude"
    ;;
  *opus*)
    MODEL_TIER="opus"
    TOOL_NAME="claude"
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
  if python3 -c "import anthropic" >/dev/null 2>&1; then
    CLASSIFY_RESULT="$(
      python3 scripts/foreman-classify.py "$BRIEF_PATH" 2>/dev/null || \
        echo '{"route":"standard","confidence":0,"reason":"classifier failed","escalation_triggers":[]}'
    )"
  else
    CLASSIFY_RESULT='{"route":"standard","confidence":0,"reason":"classifier unavailable - defaulting to standard","escalation_triggers":[]}'
  fi
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

  if [[ "$CLASSIFY_ROUTE" == "escalation" && "$MODEL_TIER" != "opus" ]]; then
    MODEL_TIER="opus"
    echo "WARNING: Haiku classifier escalated task to Opus - review escalation_triggers before proceeding"
  elif [[ "$CLASSIFY_ROUTE" == "cheap" && "$REASONING_NORMALIZED" == "low" ]]; then
    MODEL_TIER="haiku"
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

BRANCH_NAME="agent/${TOOL_NAME}/${DATE_PART}/${SLUG_PART}"

echo "Resolved model tier: ${MODEL_TIER}"
echo "Resolved reasoning level: ${REASONING_NORMALIZED}"
echo "Proposed branch: ${BRANCH_NAME}"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    if git checkout "${BRANCH_NAME}" >/dev/null 2>&1; then
      echo "Checked out existing branch: ${BRANCH_NAME}"
    else
      echo "Could not switch branches automatically. Run: git checkout ${BRANCH_NAME}"
    fi
  else
    if git checkout -b "${BRANCH_NAME}" >/dev/null 2>&1; then
      echo "Created branch: ${BRANCH_NAME}"
    else
      echo "Could not create the branch automatically. Run: git checkout -b ${BRANCH_NAME}"
    fi
  fi

  HOOK_PATH="$(git rev-parse --git-path hooks/commit-msg)"
  if [[ -x "$HOOK_PATH" ]]; then
    echo "Hooks check: commit-msg hook is installed at ${HOOK_PATH}"
  else
    echo "WARNING: commit-msg hook is missing or not executable at ${HOOK_PATH}"
  fi
else
  echo "Not inside a git work tree. Run: git checkout -b ${BRANCH_NAME}"
  echo "WARNING: unable to verify .git/hooks/commit-msg outside a git work tree"
fi

echo ""
echo "Next step after completing your work:"
echo "  git diff main...HEAD | python3 scripts/foreman-review.py --author-model ${MODEL_TIER} --branch ${BRANCH_NAME} -"
