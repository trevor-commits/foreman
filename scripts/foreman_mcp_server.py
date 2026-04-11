#!/usr/bin/env python3
"""Foreman governance MCP server — exposes governance tools to MCP clients."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP


REPO_ROOT = Path(__file__).resolve().parents[1]
SHIM_SCRIPT = REPO_ROOT / "scripts" / "foreman-mcp-shim.py"

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
    result = _call_shim(
        "foreman_review",
        {"diff": diff, "author_model": author_model, "branch": branch},
    )
    return result if isinstance(result, dict) else {"result": result}


@mcp.tool()
def foreman_classify(brief_path: str) -> dict[str, Any]:
    """Classify a task brief using the Haiku classifier. Returns route, confidence, and reason."""
    result = _call_shim("foreman_classify", {"brief_path": brief_path})
    return result if isinstance(result, dict) else {"result": result}


@mcp.tool()
def foreman_dispatch(brief_path: str) -> dict[str, Any]:
    """Dispatch a task brief — resolves model tier, creates branch, verifies hooks."""
    result = _call_shim("foreman_dispatch", {"brief_path": brief_path})
    return result if isinstance(result, dict) else {"result": result}


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
    result = _call_shim("foreman_status", {})
    return result if isinstance(result, dict) else {"result": result}


# Compatibility alias for local smoke checks that inspect `mcp._tools` directly.
mcp._tools = mcp._tool_manager._tools  # type: ignore[attr-defined]


def main() -> int:
    mcp.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
