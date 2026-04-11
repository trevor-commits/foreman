# Foreman Scripts

Install Python reviewer dependencies with:

```bash
python3 -m pip install -r scripts/requirements.txt
```

If your system Python is externally managed (for example Homebrew Python on macOS),
install these packages in a virtual environment instead of forcing a global install.

Environment variables:
- `ANTHROPIC_API_KEY` for the default reviewer path and the Claude fallback path
- `OPENAI_API_KEY` for reviewing Claude-authored diffs with `o4-mini`

If `OPENAI_API_KEY` is missing when the author model is Claude, `foreman-review.py`
falls back to a second Claude model instead of failing immediately.

## Live Validation Setup

The reviewer and classifier require Anthropic and OpenAI SDKs. Install once per environment:

```bash
pip3 install -r scripts/requirements.txt --break-system-packages
```

Or in a virtualenv:

```bash
python3 -m venv .venv && source .venv/bin/activate && pip install -r scripts/requirements.txt
```

Required env vars:
- `ANTHROPIC_API_KEY` — for reviewer (Claude-authored diffs) and Haiku classifier
- `OPENAI_API_KEY` — for reviewer (Codex/GPT-authored diffs); optional if Anthropic-only setup

## Operational Commands

- `scripts/foreman-dispatch.sh [--no-classify] <brief.md>` creates or checks out the branch proposed from the task brief and adds an active row to `BRANCH_LEDGER.md`
- `scripts/foreman-status.sh` prints the current branch's governance state, last commit trailers, last review verdict, ledger row status, and active gate env vars
- `scripts/foreman-merge-check.sh` evaluates the merge conditions and exits `0` only when the branch is governance-ready for PR
- `scripts/foreman-close.sh <branch> <merged|abandoned> [reason]` moves a branch from Active Branches to Closed Branches and, for merged branches, attempts local and remote branch deletion
- `scripts/foreman-drift-check.sh [--fix] [--repos "..."]` detects drift between foreman canonical governance files and downstream repos, and can auto-sync missing or drifted files without committing them
- `scripts/foreman-pr-prep.sh` generates a pre-filled GitHub PR description from the current branch state
- `scripts/foreman-mcp-server.py` starts the FastMCP server that exposes foreman's governance tools to MCP clients such as Claude Code and Claude desktop

## MCP Server

The real MCP server now lives at `scripts/foreman-mcp-server.py`, backed by the official
Anthropic-maintained `mcp` package.

To connect foreman to Claude Code: add foreman to your `~/.claude/mcp.json` or run:

```bash
claude mcp add foreman python3 "$(pwd)/scripts/foreman-mcp-server.py"
```

## Telemetry And Calibration

- `scripts/foreman-review.py` writes the latest review to `.agent-runs/last-review.json` and appends telemetry to `.agent-runs/review-log.jsonl`
- `scripts/foreman-calibration.py` summarizes reviewer telemetry and prints the hard-gate readiness decision
- Burn-in checkpoint command: `python3 scripts/foreman-calibration.py --days 14`
