#!/usr/bin/env bash
# Detect or sync foreman-owned governance files across downstream repos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FOREMAN_ROOT="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$REPO_ROOT")"
FIX_MODE=false
REPOS_OVERRIDE=""

CANONICAL_FILES=(
  "scripts/foreman-review.py"
  "scripts/foreman-classify.py"
  "scripts/foreman-dispatch.sh"
  "scripts/foreman-mcp-shim.py"
  "scripts/requirements.txt"
  "docs/mcp-tools.md"
  ".github/workflows/foreman-trailer-check.yml"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/foreman-drift-check.sh
  scripts/foreman-drift-check.sh --fix
  scripts/foreman-drift-check.sh --repos "path1 path2"

Options:
  --fix         Copy missing or drifted canonical files into downstream repos.
  --repos       Override auto-discovered repos. Supports newline-separated paths or
                a single quoted string of existing repo paths.
  -h, --help    Show this help text.
EOF
}

resolve_path() {
  python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$1"
}

sha256_file() {
  python3 - "$1" <<'PY'
from pathlib import Path
import hashlib
import sys

path = Path(sys.argv[1])
digest = hashlib.sha256(path.read_bytes()).hexdigest()
print(digest)
PY
}

parse_override_repos() {
  python3 - "$1" <<'PY'
from __future__ import annotations

import os
import sys
from pathlib import Path

raw = sys.argv[1]

lines = [line.strip() for line in raw.splitlines() if line.strip()]
if len(lines) > 1:
    for item in lines:
        path = Path(os.path.expanduser(item)).resolve()
        if not path.is_dir():
            print(f"Invalid repo path in --repos override: {item}", file=sys.stderr)
            raise SystemExit(1)
        print(path)
    raise SystemExit(0)

tokens = raw.split()
if not tokens:
    raise SystemExit(0)

pending: list[str] = []
resolved: list[str] = []
for token in tokens:
    pending.append(token)
    candidate = Path(os.path.expanduser(" ".join(pending))).resolve()
    if candidate.is_dir():
      resolved.append(str(candidate))
      pending = []

if pending:
    candidate = Path(os.path.expanduser(" ".join(pending))).resolve()
    if candidate.is_dir():
        resolved.append(str(candidate))
        pending = []

if pending:
    print(
        "Could not resolve one or more repo paths from --repos override: "
        + " ".join(pending),
        file=sys.stderr,
    )
    raise SystemExit(1)

for path in resolved:
    print(path)
PY
}

discover_repos() {
  if [[ -n "$REPOS_OVERRIDE" ]]; then
    parse_override_repos "$REPOS_OVERRIDE"
    return 0
  fi

  find "$HOME" \
    -maxdepth 5 \
    -type f \
    -name "CLAUDE.md" \
    ! -path "*/Library/*" \
    ! -path "*/.git/*" \
    -print0 2>/dev/null | \
  while IFS= read -r -d '' claude_file; do
    repo_dir="$(dirname "$claude_file")"
    repo_real="$(resolve_path "$repo_dir")"
    if [[ "$repo_real" == "$FOREMAN_ROOT" ]]; then
      continue
    fi
    printf '%s\n' "$repo_real"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)
      FIX_MODE=true
      shift
      ;;
    --repos)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --repos requires a value." >&2
        usage >&2
        exit 1
      fi
      REPOS_OVERRIDE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for canonical_file in "${CANONICAL_FILES[@]}"; do
  if [[ ! -f "$REPO_ROOT/$canonical_file" ]]; then
    echo "ERROR: canonical file missing in foreman: $canonical_file" >&2
    exit 1
  fi
done

REPOS=()
while IFS= read -r repo_path; do
  [[ -n "$repo_path" ]] || continue
  duplicate=false
  for existing_repo in "${REPOS[@]:-}"; do
    if [[ "$existing_repo" == "$repo_path" ]]; then
      duplicate=true
      break
    fi
  done
  if [[ "$duplicate" == false ]]; then
    REPOS+=("$repo_path")
  fi
done < <(discover_repos)

if [[ -n "$REPOS_OVERRIDE" ]]; then
  echo "Using overridden downstream repos:"
else
  echo "Discovered downstream repos:"
fi

if [[ "${#REPOS[@]}" -eq 0 ]]; then
  echo "  (none)"
else
  for repo_path in "${REPOS[@]}"; do
    echo "  - $repo_path"
  done
fi

echo ""

IN_SYNC_COUNT=0
MISSING_COUNT=0
DRIFTED_COUNT=0
SYNCED_COUNT=0

for repo_path in "${REPOS[@]}"; do
  repo_name="$(basename "$repo_path")"
  for relative_file in "${CANONICAL_FILES[@]}"; do
    canonical_path="$REPO_ROOT/$relative_file"
    downstream_path="$repo_path/$relative_file"

    if [[ ! -f "$downstream_path" ]]; then
      echo "❌ MISSING   ${repo_name}/${relative_file}"
      MISSING_COUNT=$((MISSING_COUNT + 1))
      if [[ "$FIX_MODE" == true ]]; then
        mkdir -p "$(dirname "$downstream_path")"
        cp "$canonical_path" "$downstream_path"
        echo "🔄 SYNCED    ${repo_name}/${relative_file}"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
      fi
      continue
    fi

    canonical_sha="$(sha256_file "$canonical_path")"
    downstream_sha="$(sha256_file "$downstream_path")"

    if [[ "$canonical_sha" == "$downstream_sha" ]]; then
      echo "✅ IN SYNC  ${repo_name}/${relative_file}"
      IN_SYNC_COUNT=$((IN_SYNC_COUNT + 1))
      continue
    fi

    echo "⚠️  DRIFTED   ${repo_name}/${relative_file}  (foreman: ${canonical_sha:0:8}, downstream: ${downstream_sha:0:8})"
    DRIFTED_COUNT=$((DRIFTED_COUNT + 1))
    if [[ "$relative_file" == ".github/workflows/foreman-trailer-check.yml" ]]; then
      echo "⚠️  NOTE: foreman-trailer-check.yml in ${repo_name} differs from foreman canonical."
      echo "   The downstream workflow may have repo-specific customizations (branch filters, etc.)."
      echo "   Review the diff before syncing: diff \"$canonical_path\" \"$downstream_path\""
    fi
    if [[ "$FIX_MODE" == true ]]; then
      mkdir -p "$(dirname "$downstream_path")"
      cp "$canonical_path" "$downstream_path"
      echo "🔄 SYNCED    ${repo_name}/${relative_file}"
      SYNCED_COUNT=$((SYNCED_COUNT + 1))
    fi
  done
done

echo ""
echo "Summary: ${IN_SYNC_COUNT} files in sync, ${MISSING_COUNT} missing, ${DRIFTED_COUNT} drifted."

if [[ "$FIX_MODE" == true ]]; then
  echo "Synced ${SYNCED_COUNT} files. Review changes in each repo and commit with proper foreman trailers."
  echo "Sync complete. No downstream commits made — review and commit manually."
else
  echo "Run with --fix to auto-sync missing and drifted files."
fi
