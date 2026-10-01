#!/usr/bin/env python3
"""Discover foreman downstream repos for drift-check (excludes non-project CLAUDE.md paths)."""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Directory names that never host a governed downstream clone.
EXCLUDED_DIR_NAMES: frozenset[str] = frozenset(
    {
        ".claude",
        ".codex",
        ".cursor",
        ".git",
        ".npm",
        ".nvm",
        ".pyenv",
        ".venv",
        "Library",
        "node_modules",
        "venv",
    }
)

# Path fragments (after realpath) that indicate editor/runtime bundles, not project repos.
EXCLUDED_PATH_MARKERS: tuple[str, ...] = (
    "/.cursor/plugins/",
    "/.vscode/extensions/",
    "/Application Support/",
    "/Caches/",
    "/Desktop/",
    "/Downloads/",
)

MAX_DEPTH = 5
CLAUDE_FILENAME = "CLAUDE.md"


def _path_excluded(repo_dir: Path) -> bool:
    resolved = str(repo_dir.resolve())
    for marker in EXCLUDED_PATH_MARKERS:
        if marker in resolved:
            return True
    for part in repo_dir.resolve().parts:
        if part in EXCLUDED_DIR_NAMES:
            return True
    return False


def is_foreman_downstream(repo_dir: Path) -> bool:
    """True when the directory looks like a repo that adopted foreman governance files."""
    if not (repo_dir / ".git").exists():
        return False
    markers = (
        repo_dir / "scripts" / "foreman-review.py",
        repo_dir / ".github" / "workflows" / "foreman-trailer-check.yml",
    )
    return any(path.is_file() for path in markers)


def discover_downstream_repos(home: Path, foreman_root: Path) -> list[str]:
    """Return sorted unique realpaths of downstream repos under home (max depth 5)."""
    home = home.resolve()
    foreman_real = foreman_root.resolve()
    found: dict[str, None] = {}

    if not home.is_dir():
        return []

    home_parts = len(home.parts)

    for root, dirnames, filenames in os.walk(home, topdown=True, followlinks=False):
        root_path = Path(root)
        depth = len(root_path.parts) - home_parts
        if depth > MAX_DEPTH:
            dirnames.clear()
            continue

        dirnames[:] = [
            name
            for name in dirnames
            if name not in EXCLUDED_DIR_NAMES and not name.startswith(".Trash")
        ]

        if CLAUDE_FILENAME not in filenames:
            continue

        repo_dir = root_path
        repo_real = repo_dir.resolve()
        if repo_real == foreman_real:
            continue
        if _path_excluded(repo_dir):
            continue
        if not is_foreman_downstream(repo_dir):
            continue

        found[str(repo_real)] = None

    return sorted(found.keys())


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: foreman_drift_discovery.py <home_dir> <foreman_root>",
            file=sys.stderr,
        )
        return 2
    home = Path(sys.argv[1]).expanduser()
    foreman_root = Path(sys.argv[2]).expanduser()
    for line in discover_downstream_repos(home, foreman_root):
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
