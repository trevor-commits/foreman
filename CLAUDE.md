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

**Phase 1** — Branch conventions, commit trailers, and gate hooks. See AGENTS.md.

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

## Open Threads

_None yet — add entries here as agent sessions open._

Format:
```
- Branch: agent/claude/2026-04-09/example-task
  Model: claude-sonnet-4-6
  Thread: <url or session id>
  Status: open
```

## Recent Decisions

See DECISIONS.md for full history.

- **2026-04-09** — Adopted Codex's phased approach to avoid overbuilding: branch ledger
  and hooks first, cross-model reviewer second, Container Use third, OpenClaw last.
- **2026-04-09** — Branch ledger (BRANCH_LEDGER.md) is the durable source of truth for
  open branches, not chat thread IDs. Chat links are metadata attached to the ledger.
- **2026-04-09** — Haiku 4.5 is the dispatcher model for cheap tasks; Sonnet 4.6 for
  standard work; Opus 4.6 for architecture and hard problems. Reviewer is always a
  different model than the one that wrote the code.

## Gotchas

- The pre-push hook blocks direct pushes to main/master. Use `git push --no-verify`
  only in genuine emergencies, and note why in the commit or DECISIONS.md.
- The commit-msg hook skips merge commits and fixup commits automatically.
- `.agent-runs/` is gitignored by default. Add specific run folders if you want
  to preserve an audit trail in the repo history.
