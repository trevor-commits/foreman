#!/usr/bin/env python3
"""Proof-of-concept CLI shim for the planned foreman MCP tool surface."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parents[1]
REVIEW_SCRIPT = REPO_ROOT / "scripts" / "foreman-review.py"
DISPATCH_SCRIPT = REPO_ROOT / "scripts" / "foreman-dispatch.sh"
CLASSIFY_SCRIPT = REPO_ROOT / "scripts" / "foreman-classify.py"
LEDGER_PATH = Path(os.getenv("FOREMAN_LEDGER_PATH", str(REPO_ROOT / "BRANCH_LEDGER.md")))
LAST_REVIEW_PATH = REPO_ROOT / ".agent-runs" / "last-review.json"

ACTIVE_SECTION = "## Active Branches"
CLOSED_SECTION = "## Closed Branches"
STATUS_SECTION = "## Status Values"
BRANCH_PATTERN = re.compile(r"^(agent|review)/[a-z0-9_-]+/[0-9]{4}-[0-9]{2}-[0-9]{2}/[a-z0-9-]+$")
PROTECTED_BRANCHES = {"main", "master", "production", "prod"}


class ShimError(Exception):
    """Structured error for shim failures."""

    def __init__(self, code: str, message: str, details: Any | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details

    def as_json(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "error": {
                "code": self.code,
                "message": self.message,
            }
        }
        if self.details is not None:
            payload["error"]["details"] = self.details
        return payload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CLI shim for the planned foreman MCP tools.")
    parser.add_argument("--tool", required=True, help="Tool name to invoke.")
    parser.add_argument("--args", required=True, help="JSON object containing tool arguments.")
    return parser.parse_args()


def require_string(payload: dict[str, Any], key: str, *, allow_empty: bool = False) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or (not allow_empty and not value):
        requirement = "a string" if allow_empty else "a non-empty string"
        raise ShimError("invalid_args", f"{key!r} must be {requirement}.")
    return value


def run_command(command: list[str], *, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            cwd=REPO_ROOT,
            input=input_text,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError as exc:
        raise ShimError(
            "script_failed",
            f"Could not execute command: {' '.join(command)}",
            {"reason": str(exc)},
        ) from exc


def parse_json_output(raw_text: str, *, error_code: str) -> dict[str, Any]:
    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise ShimError(error_code, "Tool output was not valid JSON.", {"raw_output": raw_text}) from exc

    if not isinstance(parsed, dict):
        raise ShimError(error_code, "Tool output must be a JSON object.", {"raw_output": raw_text})

    return parsed


def find_review_json_path(stdout_text: str) -> Path | None:
    match = re.search(r"^Review JSON:\s*(.+)$", stdout_text, flags=re.MULTILINE)
    if not match:
        return None
    return Path(match.group(1).strip())


def sanitize_cell(value: str) -> str:
    return value.replace("\n", " ").replace("|", "\\|").strip()


def parse_markdown_row(row: str) -> list[str]:
    cells = [cell.strip() for cell in row.split("|")[1:-1]]
    return cells


def normalize_branch_cell(cell: str) -> str:
    return cell.strip().strip("`")


def extract_trailer(body: str, key: str) -> str | None:
    prefix = f"{key.lower()}:"
    for line in body.splitlines():
        if line.lower().startswith(prefix):
            return line.split(":", 1)[1].strip()
    return None


def read_last_review() -> dict[str, Any] | None:
    if not LAST_REVIEW_PATH.exists():
        return None

    try:
        review = json.loads(LAST_REVIEW_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {
            "error": {
                "code": "invalid_json",
                "message": f"Could not parse {LAST_REVIEW_PATH}.",
                "details": {"reason": str(exc)},
            }
        }

    if not isinstance(review, dict):
        return {
            "error": {
                "code": "invalid_json",
                "message": f"{LAST_REVIEW_PATH} did not contain a JSON object.",
            }
        }

    return review


def load_ledger() -> str:
    try:
        return LEDGER_PATH.read_text(encoding="utf-8")
    except OSError as exc:
        raise ShimError("write_failed", f"Could not read {LEDGER_PATH}.", {"reason": str(exc)}) from exc


def save_ledger(text: str) -> None:
    try:
        LEDGER_PATH.write_text(text, encoding="utf-8")
    except OSError as exc:
        raise ShimError("write_failed", f"Could not write {LEDGER_PATH}.", {"reason": str(exc)}) from exc


def find_table_body(
    lines: list[str],
    section_header: str,
    next_header: str,
) -> tuple[int, int, list[str]]:
    try:
        section_index = lines.index(section_header)
    except ValueError as exc:
        raise ShimError(
            "ledger_format_error",
            f"Could not locate the {section_header!r} table in {LEDGER_PATH.name}.",
        ) from exc

    header_index = None
    for index in range(section_index + 1, len(lines)):
        if lines[index].startswith("|"):
            header_index = index
            break
        if lines[index] == next_header:
            break

    if header_index is None or header_index + 1 >= len(lines) or not lines[header_index + 1].startswith("|"):
        raise ShimError(
            "ledger_format_error",
            f"Could not parse the header rows for {section_header!r}.",
        )

    try:
        next_index = lines.index(next_header, header_index + 2)
    except ValueError as exc:
        raise ShimError(
            "ledger_format_error",
            f"Could not locate the section boundary before {next_header!r}.",
        ) from exc

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


def tool_foreman_review(payload: dict[str, Any]) -> dict[str, Any]:
    diff = require_string(payload, "diff", allow_empty=True)
    author_model = require_string(payload, "author_model")
    branch = require_string(payload, "branch")

    review_path = REPO_ROOT / ".agent-runs" / "last-review.json"
    previous_mtime = review_path.stat().st_mtime if review_path.exists() else None

    result = run_command(
        [
            "python3",
            str(REVIEW_SCRIPT),
            "--author-model",
            author_model,
            "--branch",
            branch,
            "-",
        ],
        input_text=diff,
    )

    if result.returncode not in {0, 1}:
        raise ShimError(
            "script_failed",
            "foreman-review.py exited unexpectedly.",
            {
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            },
        )

    output_path = find_review_json_path(result.stdout)
    if output_path is None and review_path.exists():
        new_mtime = review_path.stat().st_mtime
        if previous_mtime is None or new_mtime > previous_mtime:
            output_path = review_path

    if output_path is None or not output_path.exists():
        message = result.stderr.strip() or result.stdout.strip() or "Review did not produce JSON output."
        raise ShimError(
            "review_unavailable",
            message,
            {
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            },
        )

    try:
        review = json.loads(output_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ShimError("invalid_json", f"Could not load review JSON from {output_path}.") from exc

    if not isinstance(review, dict):
        raise ShimError("invalid_json", "Review JSON must be an object.", {"path": str(output_path)})

    return review


def tool_foreman_dispatch(payload: dict[str, Any]) -> dict[str, Any]:
    brief_path = require_string(payload, "brief_path")
    result = run_command(["bash", str(DISPATCH_SCRIPT), brief_path])
    if result.returncode != 0:
        raise ShimError(
            "script_failed",
            "foreman-dispatch.sh exited non-zero.",
            {
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            },
        )

    model_match = re.search(r"^Resolved model tier:\s*(.+)$", result.stdout, flags=re.MULTILINE)
    branch_match = re.search(r"^Proposed branch:\s*(.+)$", result.stdout, flags=re.MULTILINE)

    hook_status: dict[str, Any] | None = None
    installed_match = re.search(
        r"^Hooks check: commit-msg hook is installed at (.+)$",
        result.stdout,
        flags=re.MULTILINE,
    )
    missing_match = re.search(
        r"^WARNING: commit-msg hook is missing or not executable at (.+)$",
        result.stdout,
        flags=re.MULTILINE,
    )
    unverifiable_match = re.search(
        r"^WARNING: unable to verify \.git/hooks/commit-msg outside a git work tree$",
        result.stdout,
        flags=re.MULTILINE,
    )

    if installed_match:
        hook_status = {
            "state": "installed",
            "path": installed_match.group(1).strip(),
            "message": "commit-msg hook is installed",
        }
    elif missing_match:
        hook_status = {
            "state": "missing",
            "path": missing_match.group(1).strip(),
            "message": "commit-msg hook is missing or not executable",
        }
    elif unverifiable_match:
        hook_status = {
            "state": "unverifiable",
            "path": None,
            "message": "unable to verify hook status outside a git work tree",
        }

    if not model_match or not branch_match or hook_status is None:
        raise ShimError(
            "parse_failed",
            "Could not parse dispatcher output into DispatchResult.",
            {"stdout": result.stdout, "stderr": result.stderr},
        )

    return {
        "model_tier": model_match.group(1).strip(),
        "branch_name": branch_match.group(1).strip(),
        "hook_status": hook_status,
    }


def tool_foreman_classify(payload: dict[str, Any]) -> dict[str, Any]:
    brief_path = require_string(payload, "brief_path")
    result = run_command(["python3", str(CLASSIFY_SCRIPT), brief_path])
    if result.returncode != 0:
        raise ShimError(
            "script_failed",
            "foreman-classify.py exited non-zero.",
            {
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            },
        )

    return parse_json_output(result.stdout.strip(), error_code="invalid_json")


def tool_foreman_ledger_open(payload: dict[str, Any]) -> None:
    branch = require_string(payload, "branch")
    agent = require_string(payload, "agent")
    task = require_string(payload, "task")
    merge_condition = require_string(payload, "merge_condition")
    thread = require_string(payload, "thread")

    text = load_ledger()
    lines = text.splitlines()
    ends_with_newline = text.endswith("\n")

    active_start, active_end, active_rows = find_table_body(lines, ACTIVE_SECTION, CLOSED_SECTION)
    _, _, closed_rows = find_table_body(lines, CLOSED_SECTION, STATUS_SECTION)

    for row in active_rows + closed_rows:
        cells = parse_markdown_row(row)
        if cells and normalize_branch_cell(cells[0]) == branch:
            raise ShimError("ledger_conflict", f"Branch {branch!r} is already recorded in BRANCH_LEDGER.md.")

    active_rows.append(
        "| `{branch}` | {agent} | {date} | {task} | {merge_condition} | {thread} | open |  |".format(
            branch=sanitize_cell(branch),
            agent=sanitize_cell(agent),
            date=date.today().isoformat(),
            task=sanitize_cell(task),
            merge_condition=sanitize_cell(merge_condition),
            thread=sanitize_cell(thread),
        )
    )

    lines[active_start:active_end] = active_rows
    updated_text = "\n".join(lines)
    if ends_with_newline:
        updated_text += "\n"
    save_ledger(updated_text)
    return None


def tool_foreman_ledger_close(payload: dict[str, Any]) -> None:
    branch = require_string(payload, "branch")
    outcome = require_string(payload, "outcome")

    text = load_ledger()
    lines = text.splitlines()
    ends_with_newline = text.endswith("\n")

    active_start, active_end, active_rows = find_table_body(lines, ACTIVE_SECTION, CLOSED_SECTION)

    found_row: list[str] | None = None
    remaining_active: list[str] = []
    for row in active_rows:
        cells = parse_markdown_row(row)
        if cells and normalize_branch_cell(cells[0]) == branch:
            found_row = cells
            continue
        remaining_active.append(row)

    if found_row is None:
        raise ShimError("ledger_not_found", f"Branch {branch!r} is not present in the active ledger.")
    if len(found_row) < 4:
        raise ShimError("ledger_format_error", "Active ledger row does not have the expected columns.")

    lines[active_start:active_end] = remaining_active

    closed_start, closed_end, closed_rows = find_table_body(lines, CLOSED_SECTION, STATUS_SECTION)
    closed_rows.insert(
        0,
        "| `{branch}` | {agent} | {date} | {task} | {outcome} | {closed} |".format(
            branch=sanitize_cell(branch),
            agent=sanitize_cell(found_row[1]),
            date=sanitize_cell(found_row[2]),
            task=sanitize_cell(found_row[3]),
            outcome=sanitize_cell(outcome),
            closed=date.today().isoformat(),
        ),
    )

    lines[closed_start:closed_end] = closed_rows
    updated_text = "\n".join(lines)
    if ends_with_newline:
        updated_text += "\n"
    save_ledger(updated_text)
    return None


def tool_foreman_status(payload: dict[str, Any]) -> dict[str, Any]:
    _ = payload
    branch_result = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if branch_result.returncode != 0:
        raise ShimError(
            "git_failed",
            "Could not determine the current branch.",
            {"stderr": branch_result.stderr, "stdout": branch_result.stdout},
        )

    branch = branch_result.stdout.strip()
    commit_result = run_command(["git", "log", "-1", "--format=%B"])
    if commit_result.returncode != 0:
        raise ShimError(
            "git_failed",
            "Could not load the most recent commit message.",
            {"stderr": commit_result.stderr, "stdout": commit_result.stdout},
        )

    ledger_status = "not found"
    row_found = False
    try:
        text = load_ledger()
        lines = text.splitlines()
        _, _, active_rows = find_table_body(lines, ACTIVE_SECTION, CLOSED_SECTION)
        _, _, closed_rows = find_table_body(lines, CLOSED_SECTION, STATUS_SECTION)
        for row in active_rows:
            cells = parse_markdown_row(row)
            if cells and normalize_branch_cell(cells[0]) == branch:
                row_found = True
                ledger_status = cells[6] if len(cells) > 6 else "open"
                break
        if not row_found:
            for row in closed_rows:
                cells = parse_markdown_row(row)
                if cells and normalize_branch_cell(cells[0]) == branch:
                    row_found = True
                    ledger_status = "closed"
                    break
    except ShimError:
        ledger_status = "not available"

    commit_body = commit_result.stdout
    return {
        "branch": branch,
        "branch_compliant": bool(BRANCH_PATTERN.match(branch)),
        "protected_branch": branch in PROTECTED_BRANCHES,
        "last_commit_trailers": {
            "Agent": extract_trailer(commit_body, "Agent"),
            "Thread": extract_trailer(commit_body, "Thread"),
            "Task": extract_trailer(commit_body, "Task"),
            "Verified-By": extract_trailer(commit_body, "Verified-By"),
            "Reviewed-By": extract_trailer(commit_body, "Reviewed-By"),
        },
        "last_review": read_last_review(),
        "ledger": {
            "row_found": row_found,
            "status": ledger_status,
        },
    }


TOOLS: dict[str, Callable[[dict[str, Any]], Any]] = {
    "foreman_review": tool_foreman_review,
    "foreman_dispatch": tool_foreman_dispatch,
    "foreman_classify": tool_foreman_classify,
    "foreman_ledger_open": tool_foreman_ledger_open,
    "foreman_ledger_close": tool_foreman_ledger_close,
    "foreman_status": tool_foreman_status,
}


def main() -> int:
    cli_args = parse_args()

    if cli_args.tool not in TOOLS:
        print(
            json.dumps(
                {
                    "error": {
                        "code": "unknown_tool",
                        "message": f"Unsupported tool {cli_args.tool!r}.",
                        "details": {"supported_tools": sorted(TOOLS)},
                    }
                },
                indent=2,
            )
        )
        return 1

    try:
        payload = json.loads(cli_args.args)
    except json.JSONDecodeError as exc:
        print(
            json.dumps(
                {
                    "error": {
                        "code": "invalid_args_json",
                        "message": "The value passed to --args must be valid JSON.",
                        "details": {"reason": str(exc)},
                    }
                },
                indent=2,
            )
        )
        return 1

    if not isinstance(payload, dict):
        print(
            json.dumps(
                {
                    "error": {
                        "code": "invalid_args_json",
                        "message": "The value passed to --args must decode to a JSON object.",
                    }
                },
                indent=2,
            )
        )
        return 1

    try:
        result = TOOLS[cli_args.tool](payload)
        print(json.dumps(result, indent=2))
        return 0
    except ShimError as exc:
        print(json.dumps(exc.as_json(), indent=2))
        return 1
    except Exception as exc:  # pragma: no cover - last-resort guard for CLI use
        print(
            json.dumps(
                {
                    "error": {
                        "code": "unexpected_error",
                        "message": str(exc),
                    }
                },
                indent=2,
            )
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
