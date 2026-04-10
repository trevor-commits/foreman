#!/usr/bin/env bash
# Usage:
#   scripts/foreman-dispatch.sh .agent-runs/2026-04-09-example-task/brief.md
#   scripts/foreman-dispatch.sh /absolute/path/to/.agent-runs/2026-04-09-example-task/brief.md

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <brief.md path>" >&2
  exit 1
fi

BRIEF_PATH="$1"

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
