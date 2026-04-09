#!/usr/bin/env bash
# =============================================================================
# PUSH.sh — run this once from your terminal to push foreman to GitHub
#
# Before running:
#   1. Download/open the foreman folder (click the link Claude gave you)
#   2. Open Terminal
#   3. cd into the foreman folder
#   4. bash PUSH.sh
#
# This script initializes git, sets the remote, commits everything,
# and pushes to git@github.com:trevor-commits/foreman.git
# =============================================================================

set -euo pipefail

REMOTE="git@github.com:trevor-commits/foreman.git"

echo ""
echo "🔧  foreman initial push"
echo ""

# Init git if not already a repo
if [ ! -d ".git" ]; then
  git init
  echo "  ✅  git init"
fi

# Set remote
if git remote get-url origin &>/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
  echo "  ✅  remote updated → $REMOTE"
else
  git remote add origin "$REMOTE"
  echo "  ✅  remote added → $REMOTE"
fi

# Stage everything
git add .
echo "  ✅  files staged"

# Configure git identity if not set
if ! git config user.name &>/dev/null; then
  git config user.name "Trevor Gillette"
  git config user.email "trevorgillette17@gmail.com"
fi

# Commit
git commit -m "Initialize foreman — Phase 1 branch conventions and gate hooks

Sets up the complete Phase 1 foreman convention system:

- AGENTS.md: branch naming, commit trailer schema, model routing guide,
  autonomy rules, merge conditions, task brief format, and run logging spec.
  Every AI agent operating in a foreman-template repo must read this first.

- CLAUDE.md: working memory file for Claude / Claude Code. Contains project
  overview, current phase, open threads, recent decisions, and gotchas.
  Read at the start of every session.

- BRANCH_LEDGER.md: the durable source of truth for every open agent branch.
  Tracks agent, date, task, merge condition, thread link, and status.
  Chosen over chat thread IDs because it survives tool changes and re-clones.

- DECISIONS.md: running log of architectural decisions with reasoning.
  Pre-populated with the three key foreman design decisions and their rationale.

- memory/: durable knowledge directory. Contains projects.md (project index
  template) and README.md explaining the memory structure and rules.

- .github/PULL_REQUEST_TEMPLATE.md: PR template with agent metadata fields,
  acceptance criteria, verification checklist, and second-model review section.

- hooks/commit-msg: enforces the trailer schema (Agent, Thread, Task,
  Verified-By) on every non-merge commit. Warns on missing Reviewed-By.
  Skips merge commits and fixup/squash commits automatically.

- hooks/pre-push: runs tests/lint/build gate before any push. Blocks direct
  pushes to main/master/production/prod. Auto-detects Python (pytest, ruff,
  mypy), Node (npm test/lint/build), and Makefile targets. Warns cleanly when
  no gates are found rather than failing.

- hooks/install.sh: one-command hook installer. Backs up any existing hooks
  before overwriting. Run once after cloning foreman into a new project.

- .gitignore: ignores .agent-runs/ (local debug logs), OS files, editor
  artifacts, hook backups, and secrets.

Design decisions:
  - Branch ledger is the source of truth, not chat threads (durable across tools)
  - Phase 1 only: no dispatcher, no cross-model script, no Container Use yet
    (follow phased plan — fix branch hygiene before building orchestration)
  - Reviewer must differ from author (enforced by convention, Phase 2 will
    enforce programmatically via cross-model reviewer script)

Agent: claude-sonnet-4-6
Thread: cowork
Task: Initialize foreman template repo with Phase 1 reliability conventions
Verified-By: manual review, structure verification
Reviewed-By: codex-5.3 (audited the design in prior session)"

echo "  ✅  committed"

# Push
git branch -M main
git push -u origin main
echo "  ✅  pushed to $REMOTE"

echo ""
echo "✅  foreman is live at: https://github.com/trevor-commits/foreman"
echo ""
echo "Next steps:"
echo "  1. Run:  bash hooks/install.sh   (installs hooks into .git/hooks/)"
echo "  2. Fill in CLAUDE.md with your project overview"
echo "  3. Start your next agent task by adding a row to BRANCH_LEDGER.md first"
echo "  4. Delete this PUSH.sh file — it's a one-time bootstrap script"
echo ""
