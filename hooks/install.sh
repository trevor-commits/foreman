#!/usr/bin/env bash
# =============================================================================
# foreman — hooks/install.sh
# Installs foreman git hooks into the current repo's .git/hooks/ directory.
# Run this once after cloning a repo that uses the foreman template.
#
# Usage (from anywhere inside your repo):
#   bash hooks/install.sh
#
# What it does:
#   - Copies hooks/commit-msg  → .git/hooks/commit-msg  (chmod +x)
#   - Copies hooks/pre-push    → .git/hooks/pre-push    (chmod +x)
#   - Backs up any existing hooks before overwriting
# =============================================================================

set -euo pipefail

# Resolve paths
REPO_ROOT=$(git rev-parse --show-toplevel)
GIT_HOOKS_DIR=$(git rev-parse --git-dir)/hooks
FOREMAN_HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "🔧  foreman: installing git hooks"
echo "    Repo:   $REPO_ROOT"
echo "    Hooks:  $GIT_HOOKS_DIR"
echo ""

# Ensure hooks directory exists
mkdir -p "$GIT_HOOKS_DIR"

install_hook() {
  local name="$1"
  local src="$FOREMAN_HOOKS_DIR/$name"
  local dst="$GIT_HOOKS_DIR/$name"

  if [ ! -f "$src" ]; then
    echo "  ⚠️   Source not found: $src — skipping"
    return
  fi

  # Back up existing hook if it isn't already a foreman hook
  if [ -f "$dst" ]; then
    if ! grep -q "foreman" "$dst" 2>/dev/null; then
      echo "  📦  Backing up existing $name → $dst.bak"
      cp "$dst" "$dst.bak"
    fi
  fi

  cp "$src" "$dst"
  chmod +x "$dst"
  echo "  ✅  $name"
}

install_hook "commit-msg"
install_hook "pre-push"

echo ""
echo "✅  foreman hooks installed."
echo ""
echo "    commit-msg  Enforces the trailer schema on every commit"
echo "                (Agent, Thread, Task, Verified-By)"
echo ""
echo "    pre-push    Runs tests/lint/build before any push, warns on"
echo "                non-compliant branch names, and runs the reviewer"
echo "                soft gate. Blocks direct pushes to main/master/"
echo "                production/prod."
echo ""
echo "    Both hooks can be bypassed with --no-verify in genuine emergencies."
echo "    See AGENTS.md for the full conventions."
echo ""
