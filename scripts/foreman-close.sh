#!/usr/bin/env bash
# Usage:
#   scripts/foreman-close.sh <branch> <outcome: merged|abandoned> [reason]

set -euo pipefail

usage() {
  echo "Usage: $0 <branch> <outcome: merged|abandoned> [reason]" >&2
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

BRANCH_NAME="$1"
OUTCOME="$2"
shift 2
REASON="${*:-}"

if [[ -z "$BRANCH_NAME" ]]; then
  usage
  exit 1
fi

if [[ "$OUTCOME" != "merged" && "$OUTCOME" != "abandoned" ]]; then
  echo "Outcome must be 'merged' or 'abandoned'." >&2
  usage
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to update BRANCH_LEDGER.md." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
LEDGER_PATH="$REPO_ROOT/BRANCH_LEDGER.md"
TODAY="$(date +%F)"
OUTCOME_TEXT="$OUTCOME"
if [[ -n "$REASON" ]]; then
  OUTCOME_TEXT="${OUTCOME} - ${REASON}"
fi

UPDATE_RESULT="$(
  LEDGER_PATH="$LEDGER_PATH" \
  CLOSE_BRANCH_NAME="$BRANCH_NAME" \
  CLOSE_OUTCOME_TEXT="$OUTCOME_TEXT" \
  CLOSE_TODAY="$TODAY" \
  python3 <<'PY'
from pathlib import Path
import json
import os
import sys

ACTIVE_SECTION = "## Active Branches"
CLOSED_SECTION = "## Closed Branches"
STATUS_SECTION = "## Status Values"


def parse_markdown_row(row: str) -> list[str]:
    return [cell.strip() for cell in row.split("|")[1:-1]]


def normalize_branch(cell: str) -> str:
    return cell.strip().strip("`")


def find_table_body(lines: list[str], section_header: str, next_header: str) -> tuple[int, int, list[str]]:
    try:
        section_index = lines.index(section_header)
    except ValueError:
        raise RuntimeError(f"Could not locate {section_header!r} in BRANCH_LEDGER.md.")

    header_index = None
    for index in range(section_index + 1, len(lines)):
        if lines[index].startswith("|"):
            header_index = index
            break
        if lines[index] == next_header:
            break

    if header_index is None or header_index + 1 >= len(lines) or not lines[header_index + 1].startswith("|"):
        raise RuntimeError(f"Could not parse the table header for {section_header!r}.")

    try:
        next_index = lines.index(next_header, header_index + 2)
    except ValueError:
        raise RuntimeError(f"Could not locate section boundary before {next_header!r}.")

    body_start = header_index + 2
    body_end = next_index

    while body_end > body_start and lines[body_end - 1] == "":
        body_end -= 1
    if body_end > body_start and lines[body_end - 1] == "---":
        body_end -= 1
        while body_end > body_start and lines[body_end - 1] == "":
            body_end -= 1

    rows = [line for line in lines[body_start:body_end] if line.strip()]
    return body_start, body_end, rows


path = Path(os.environ["LEDGER_PATH"])
branch = os.environ["CLOSE_BRANCH_NAME"]
outcome_text = os.environ["CLOSE_OUTCOME_TEXT"].replace("\n", " ").replace("|", "\\|").strip()
today = os.environ["CLOSE_TODAY"]
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
ends_with_newline = text.endswith("\n")

active_start, active_end, active_rows = find_table_body(lines, ACTIVE_SECTION, CLOSED_SECTION)

found_cells = None
remaining_rows = []
for row in active_rows:
    cells = parse_markdown_row(row)
    if cells and normalize_branch(cells[0]) == branch:
        found_cells = cells
        continue
    remaining_rows.append(row)

if found_cells is None:
    print(f"Branch '{branch}' not found in Active Branches.", file=sys.stderr)
    raise SystemExit(1)

lines[active_start:active_end] = remaining_rows

closed_start, closed_end, closed_rows = find_table_body(lines, CLOSED_SECTION, STATUS_SECTION)
closed_rows.append(
    "| `{branch}` | {agent} | {date} | {task} | {outcome} | {closed} |".format(
        branch=branch.replace("|", "\\|"),
        agent=found_cells[1].replace("|", "\\|"),
        date=found_cells[2].replace("|", "\\|"),
        task=found_cells[3].replace("|", "\\|"),
        outcome=outcome_text,
        closed=today,
    )
)

lines[closed_start:closed_end] = closed_rows
updated_text = "\n".join(lines)
if ends_with_newline:
    updated_text += "\n"
path.write_text(updated_text, encoding="utf-8")

print(
    json.dumps(
        {
            "branch": branch,
            "agent": found_cells[1],
            "date": found_cells[2],
            "task": found_cells[3],
            "outcome": outcome_text,
            "closed": today,
        }
    )
)
PY
)"

echo "Closed branch in BRANCH_LEDGER.md:"
echo "  $UPDATE_RESULT"

if [[ "$OUTCOME" == "merged" ]]; then
  if git branch -d "$BRANCH_NAME" >/dev/null 2>&1; then
    echo "Deleted local branch: $BRANCH_NAME"
  else
    echo "Local branch deletion skipped (not found or not merged)"
  fi

  if git push origin --delete "$BRANCH_NAME" >/dev/null 2>&1; then
    echo "Deleted remote branch: $BRANCH_NAME"
  else
    echo "Remote branch deletion skipped"
  fi
fi

echo "Summary:"
echo "  Branch: $BRANCH_NAME"
echo "  Outcome: $OUTCOME_TEXT"
echo "  Closed: $TODAY"
