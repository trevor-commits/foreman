# Working Memory — foreman

_Claude's working memory. Read at the start of every session. Update as context changes._
_Last updated: 2026-04-09_

---

## Project Overview

Foreman is a convention and tooling template for AI-assisted coding. It gives AI agents
(Codex, Claude Code, Cursor, etc.) branch provenance, commit traceability, external
verification gates, and a foundation for cross-model review — without requiring a
full orchestration platform before it's needed.

It is Trevor's personal template. New projects clone or copy from it.

## Owner

Trevor Gillette — trevorgillette17@gmail.com

## Current Phase

**Phase 1.5** — Branch conventions, commit trailers, local hooks, and GitHub Actions
trailer enforcement are active. A shell dispatcher prototype now exists; cross-model
review automation is still pending.

Phases still to build:
- Phase 2: cross-model reviewer script (a different model reviews every diff)
- Phase 3: Dagger Container Use (isolation for parallel agents)
- Phase 4: OpenClaw orchestration (if still needed after Phase 3)

## Stack

This repo: shell scripts, Markdown. Language-agnostic — the conventions apply to any stack.

## Key Files

| File | What it is |
|------|-----------|
| `AGENTS.md` | Rules every AI agent must read before touching any repo |
| `BRANCH_LEDGER.md` | The canonical record of every open agent branch |
| `DECISIONS.md` | Architectural decisions and their reasoning |
| `memory/` | Durable knowledge: projects, people, context |
| `hooks/` | Git hooks for commit enforcement and pre-push gates |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template with agent metadata |

## Handoff Summary

Completed on 2026-04-09:
- Phase 1.5 landed in `foreman`, `Taxes`, and `bible-ai`
- `.github/workflows/foreman-trailer-check.yml` now enforces required trailers on pushes/PRs to `main`
- `.agent-runs/` is now documented as optional scratch space; commit trailers are the durable audit artifact
- `scripts/foreman-dispatch.sh` exists as the minimum shell dispatcher scaffold

Skipped or caveated:
- No second-model review automation yet; `Reviewed-By` remains warning-only
- `PROJECT_INTENT.md` is still mostly `TODO: verify`

Next session should:
- decide whether to promote the shell dispatcher into a real CLI-invoking Phase 2 dispatcher
- fill in `PROJECT_INTENT.md`
- add the reviewer wiring / merge gate that Phase 2 still promises

## Recent Decisions

See DECISIONS.md for full history.

- **2026-04-09** — Commit trailers plus tracked repo files are the durable audit trail;
  `.agent-runs/` is scratch space only.
- **2026-04-09** — Phase 1.5 server-side trailer enforcement is now active in `foreman`,
  `Taxes`, and `bible-ai`.
- **2026-04-09** — Adopted Codex's phased approach to avoid overbuilding: branch ledger
  and hooks first, cross-model reviewer second, Container Use third, OpenClaw last.
- **2026-04-09** — Branch ledger (BRANCH_LEDGER.md) is the durable source of truth for
  open branches, not chat thread IDs. Chat links are metadata attached to the ledger.
- **2026-04-09** — Haiku 4.5 is the dispatcher model for cheap tasks; Sonnet 4.6 for
  standard work; Opus 4.6 for architecture and hard problems. Reviewer is always a
  different model than the one that wrote the code.

## Gotchas

- The pre-push hook blocks direct pushes to `main`, `master`, `production`, and `prod`.
  Use `git push --no-verify` only in genuine emergencies, and note why in DECISIONS.md.
- The commit-msg hook skips merge commits, fixup commits, squash! commits, and WIP/wip prefixes.
- The commit-msg hook hard-enforces `Agent`, `Thread`, `Task`, `Verified-By`. `Reviewed-By` is warning-only in Phase 1.
- The pre-push gate is heuristic autodetection (pytest/ruff/mypy, npm, or make). It may run nothing if no test runner is found. It is not a guaranteed full-stack gate.
- Local hooks still matter, but `.github/workflows/foreman-trailer-check.yml` now covers
  the server-side enforcement gap for pushes and pull requests to `main`.
- `.agent-runs/` is optional local scratch space only. Durable audit context lives in
  commit trailers plus tracked repo files such as `BRANCH_LEDGER.md`, `DECISIONS.md`,
  and `todo.md`.
