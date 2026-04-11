#!/usr/bin/env python3
"""Executable entrypoint for the foreman FastMCP server."""

from __future__ import annotations

import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.foreman_mcp_server import main, mcp


if __name__ == "__main__":
    raise SystemExit(main())
