#!/usr/bin/env python3
"""Smoke tests for foreman downstream repo discovery."""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from foreman_drift_discovery import discover_downstream_repos, is_foreman_downstream  # noqa: E402


class DriftDiscoveryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_root = Path(tempfile.mkdtemp(prefix="foreman-drift-discovery."))
        self.foreman_root = self.temp_root / "foreman"
        self.home = self.temp_root / "home"
        self.foreman_root.mkdir(parents=True)
        self.home.mkdir(parents=True)
        (self.foreman_root / "CLAUDE.md").write_text("# foreman\n", encoding="utf-8")
        (self.foreman_root / ".git").mkdir()

    def tearDown(self) -> None:
        shutil.rmtree(self.temp_root, ignore_errors=True)

    def _make_downstream(self, relative: str) -> Path:
        repo = self.home / relative
        repo.mkdir(parents=True)
        (repo / ".git").mkdir()
        (repo / "CLAUDE.md").write_text("# project\n", encoding="utf-8")
        (repo / "scripts").mkdir()
        (repo / "scripts" / "foreman-review.py").write_text("# stub\n", encoding="utf-8")
        return repo

    def test_includes_governed_project_repo(self) -> None:
        project = self._make_downstream("Coding Projects/Taxes")
        found = discover_downstream_repos(self.home, self.foreman_root)
        self.assertEqual(found, [str(project.resolve())])

    def test_excludes_claude_config_dir(self) -> None:
        claude_cfg = self.home / ".claude" / "skills" / "demo"
        claude_cfg.mkdir(parents=True)
        (claude_cfg / "CLAUDE.md").write_text("# skill\n", encoding="utf-8")
        (claude_cfg / ".git").mkdir()
        (claude_cfg / "scripts").mkdir()
        (claude_cfg / "scripts" / "foreman-review.py").write_text("# stub\n", encoding="utf-8")
        found = discover_downstream_repos(self.home, self.foreman_root)
        self.assertEqual(found, [])

    def test_excludes_desktop_and_cursor_plugin_paths(self) -> None:
        desktop = self._make_downstream("Desktop/scratch-repo")
        plugins = self._make_downstream(".cursor/plugins/cache/demo/scratch-repo")
        found = discover_downstream_repos(self.home, self.foreman_root)
        self.assertNotIn(str(desktop.resolve()), found)
        self.assertNotIn(str(plugins.resolve()), found)

    def test_requires_git_and_foreman_marker(self) -> None:
        bare = self.home / "notes"
        bare.mkdir()
        (bare / "CLAUDE.md").write_text("# notes\n", encoding="utf-8")
        self.assertFalse(is_foreman_downstream(bare))
        found = discover_downstream_repos(self.home, self.foreman_root)
        self.assertEqual(found, [])


if __name__ == "__main__":
    unittest.main()
