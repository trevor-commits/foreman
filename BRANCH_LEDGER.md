# Branch Ledger

The canonical record of every open agent branch across projects using foreman.
This file is the durable source of truth — not the chat thread, not model memory.

Update this file when you open a branch (set status `open`) and when you close it
(set status `merged` or `abandoned`). Thread links are metadata; this file is the record.

---

## Active Branches

| Branch | Agent | Date | Task | Merge Condition | Thread | Status | Notes |
|--------|-------|------|------|-----------------|--------|--------|-------|
| `agent/codex/2026-04-10/phase2-reviewer` | codex-gpt-5 | 2026-04-11 | Full audit and remediation pass across hooks, scripts, workflow, and docs after the Phase 2 / 2.1 rollout | Hook/script/docs drift fixed, audit evidence recorded in `todo.md`, syntax checks pass, and branch is pushed | codex-desktop-2026-04-11 | open | Reusing the retained Phase 2 branch for the 2026-04-11 audit/remediation pass before the branch is finally merged or replaced |

---

## Closed Branches

| Branch | Agent | Date | Task | Outcome | Closed |
|--------|-------|------|------|---------|--------|
| `agent/codex/2026-04-10/phase2-reviewer` | codex-gpt-5 | 2026-04-10 | Build the Phase 2 automated cross-model review path across the reviewer script, hook wiring, dispatcher note, and docs | Phase 2 reviewer implemented — soft gate active, pending Phase 2.1 hard-gate promotion. | 2026-04-11 |
| `agent/codex/2026-04-10/cleanup-pass` | codex-gpt-5 | 2026-04-10 | Fix post-run cleanup findings, fill `PROJECT_INTENT.md`, and decide the downstream governance-doc sync strategy | Merged to `main` after documenting the bible-ai governance-only push bypass, filling `PROJECT_INTENT.md`, choosing manual downstream governance-doc mirroring, and refreshing both repos' handoff files | 2026-04-10 |
| `agent/codex/2026-04-09/phase15-governance` | codex-gpt-5 | 2026-04-09 | Land Phase 1.5 trailer enforcement, resolve audit-trail policy, add dispatcher prototype, and sync downstream repo governance updates | Merged to `main` after landing trailer-check workflows, audit-trail decision updates, dispatcher prototype, and CLAUDE handoff refreshes across all three repos | 2026-04-09 |

---

## Status Values

| Status | Meaning |
|--------|---------|
| `open` | Agent is actively working |
| `review` | Waiting for second-model review |
| `ready` | All gates pass + reviewed + approved; waiting for human merge |
| `merged` | Merged to main; branch can be deleted |
| `abandoned` | Closed without merging — see Notes for reason |

---

## How to Add a Row

When starting a new agent task, add a row to Active Branches **before doing anything else**:

1. **Branch** — use the naming convention: `agent/<tool>/<YYYY-MM-DD>/<slug>`
2. **Agent** — tool and model, e.g. `codex-5.3` or `claude-sonnet-4-6`
3. **Date** — YYYY-MM-DD when the branch was created
4. **Task** — one sentence: what this branch is trying to accomplish
5. **Merge Condition** — what must be true before this can merge (e.g. "tests pass, auth flow works end to end, reviewed by claude")
6. **Thread** — link or ID of the chat/session that spawned this (paste the URL)
7. **Status** — start with `open`
8. **Notes** — anything else worth knowing; update as the branch progresses

When the branch merges, move the row to Closed Branches and record the outcome.
When a branch is abandoned, move it to Closed and write why in Notes.
