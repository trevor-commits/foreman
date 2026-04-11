#!/usr/bin/env python3
"""Foreman governance MCP server — exposes governance tools to MCP clients."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "scripts"
SHIM_SCRIPT = REPO_ROOT / "scripts" / "foreman-mcp-shim.py"
BRANCH_PATTERN = re.compile(r"^(agent|review)/[a-z0-9_-]+/[0-9]{4}-[0-9]{2}-[0-9]{2}/[a-z0-9-]+$")

mcp = FastMCP("foreman", instructions="Foreman governance tools for AI-assisted coding")


def _error_payload(code: str, message: str, *, details: dict[str, Any] | None = None) -> dict[str, Any]:
    error: dict[str, Any] = {"code": code, "message": message}
    if details is not None:
        error["details"] = details
    return {"error": error}


def _call_shim(tool_name: str, payload: dict[str, Any]) -> Any:
    command = [
        sys.executable,
        str(SHIM_SCRIPT),
        "--tool",
        tool_name,
        "--args",
        json.dumps(payload),
    ]

    try:
        result = subprocess.run(
            command,
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as exc:
        return _error_payload(
            "shim_exec_failed",
            f"Could not execute {SHIM_SCRIPT.name}.",
            details={"reason": str(exc), "command": command},
        )

    stdout = result.stdout.strip()
    if not stdout:
        return _error_payload(
            "shim_no_output",
            f"{SHIM_SCRIPT.name} returned no output.",
            details={"stderr": result.stderr.strip(), "exit_code": result.returncode},
        )

    try:
        parsed = json.loads(stdout)
    except json.JSONDecodeError:
        return _error_payload(
            "shim_invalid_json",
            f"{SHIM_SCRIPT.name} returned invalid JSON.",
            details={
                "stdout": stdout,
                "stderr": result.stderr.strip(),
                "exit_code": result.returncode,
            },
        )

    if result.returncode != 0 and not isinstance(parsed, dict):
        return _error_payload(
            "shim_failed",
            f"{SHIM_SCRIPT.name} exited non-zero.",
            details={
                "stdout": stdout,
                "stderr": result.stderr.strip(),
                "exit_code": result.returncode,
            },
        )

    return parsed


@mcp.tool()
def foreman_review(diff: str, author_model: str, branch: str) -> dict[str, Any]:
    """Run a cross-model code review on a diff. Returns APPROVE / REQUEST_CHANGES / BLOCKER verdict."""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".diff", delete=False, encoding="utf-8") as handle:
        handle.write(diff)
        diff_path = handle.name

    try:
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPTS / "foreman-review.py"),
                "--author-model",
                author_model,
                "--branch",
                branch,
                diff_path,
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        review_path = REPO_ROOT / ".agent-runs" / "last-review.json"
        if review_path.exists():
            try:
                return json.loads(review_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                return _error_payload(
                    "review_invalid_json",
                    "last-review.json could not be parsed.",
                    details={"reason": str(exc), "path": str(review_path)},
                )
        return _error_payload(
            "review_unavailable",
            "Review output was not written.",
            details={"stderr": result.stderr.strip(), "exit_code": result.returncode},
        )
    finally:
        os.unlink(diff_path)


@mcp.tool()
def foreman_classify(brief_path: str) -> dict[str, Any]:
    """Classify a task brief using the Haiku classifier. Returns route, confidence, and reason."""
    result = subprocess.run(
        [sys.executable, str(SCRIPTS / "foreman-classify.py"), brief_path],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            return _error_payload(
                "classifier_invalid_json",
                "foreman-classify.py returned invalid JSON.",
                details={"reason": str(exc), "stdout": result.stdout},
            )
    return _error_payload(
        "classifier_failed",
        "foreman-classify.py exited non-zero.",
        details={"stderr": result.stderr.strip(), "exit_code": result.returncode},
    )


@mcp.tool()
def foreman_dispatch(brief_path: str) -> dict[str, Any]:
    """Dispatch a task brief — resolves model tier, creates branch, verifies hooks."""
    result = subprocess.run(
        ["bash", str(SCRIPTS / "foreman-dispatch.sh"), brief_path],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return {"output": result.stdout, "exit_code": result.returncode, "stderr": result.stderr}


@mcp.tool()
def foreman_ledger_open(
    branch: str,
    agent: str,
    task: str,
    merge_condition: str,
    thread: str,
) -> dict[str, Any]:
    """Add a new open branch row to BRANCH_LEDGER.md."""
    result = _call_shim(
        "foreman_ledger_open",
        {
            "branch": branch,
            "agent": agent,
            "task": task,
            "merge_condition": merge_condition,
            "thread": thread,
        },
    )
    if result is None:
        return {"ok": True, "branch": branch, "status": "open"}
    return result if isinstance(result, dict) else {"result": result}


@mcp.tool()
def foreman_ledger_close(branch: str, outcome: str) -> dict[str, Any]:
    """Move a branch row from Active to Closed in BRANCH_LEDGER.md."""
    result = _call_shim("foreman_ledger_close", {"branch": branch, "outcome": outcome})
    if result is None:
        return {"ok": True, "branch": branch, "outcome": outcome}
    return result if isinstance(result, dict) else {"result": result}


@mcp.tool()
def foreman_status() -> dict[str, Any]:
    """Return the current branch's governance state as structured data."""
    branch = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip()

    last_commit = subprocess.run(
        ["git", "log", "-1", "--format=%B"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    ).stdout

    def extract_trailer(body: str, key: str) -> str | None:
        prefix = f"{key.lower()}:"
        for line in body.splitlines():
            if line.lower().startswith(prefix):
                return line.split(":", 1)[1].strip()
        return None

    review_path = REPO_ROOT / ".agent-runs" / "last-review.json"
    last_review = None
    if review_path.exists():
        try:
            last_review = json.loads(review_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            last_review = _error_payload(
                "review_invalid_json",
                "last-review.json could not be parsed.",
                details={"reason": str(exc), "path": str(review_path)},
            )

    return {
        "branch": branch,
        "branch_compliant": bool(BRANCH_PATTERN.match(branch)),
        "last_commit_trailers": {
            "Agent": extract_trailer(last_commit, "Agent"),
            "Thread": extract_trailer(last_commit, "Thread"),
            "Task": extract_trailer(last_commit, "Task"),
            "Verified-By": extract_trailer(last_commit, "Verified-By"),
            "Reviewed-By": extract_trailer(last_commit, "Reviewed-By"),
        },
        "last_review": last_review,
    }


# Compatibility alias for local smoke checks that inspect `mcp._tools` directly.
mcp._tools = mcp._tool_manager._tools  # type: ignore[attr-defined]


def main() -> int:
    mcp.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
