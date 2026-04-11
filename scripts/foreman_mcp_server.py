#!/usr/bin/env python3
"""Importable wrapper for the executable foreman FastMCP server."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SERVER_PATH = Path(__file__).with_name("foreman-mcp-server.py")
SPEC = importlib.util.spec_from_file_location("foreman_mcp_server_runtime", SERVER_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {SERVER_PATH}")

MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

mcp = MODULE.mcp
main = MODULE.main
foreman_review = MODULE.foreman_review
foreman_classify = MODULE.foreman_classify
foreman_dispatch = MODULE.foreman_dispatch
foreman_ledger_open = MODULE.foreman_ledger_open
foreman_ledger_close = MODULE.foreman_ledger_close
foreman_status = MODULE.foreman_status


__all__ = [
    "foreman_classify",
    "foreman_dispatch",
    "foreman_ledger_close",
    "foreman_ledger_open",
    "foreman_review",
    "foreman_status",
    "main",
    "mcp",
]
