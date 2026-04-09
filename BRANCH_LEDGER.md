# Branch Ledger

The canonical record of every open agent branch across projects using foreman.
This file is the durable source of truth — not the chat thread, not model memory.

Update this file when you open a branch (set status `open`) and when you close it
(set status `merged` or `abandoned`). Thread links are metadata; this file is the record.

---

## Active Branches

| Branch | Agent | Date | Task | Merge Condition | Thread | Status | Notes |
|--------|-------|------|------|-----------------|--------|--------|-------|
| _(none yet)_ | | | | | | | |

---

## Closed Branches

| Branch | Agent | Date | Task | Outcome | Closed |
|--------|-------|------|------|---------|--------|
| _(none yet)_ | | | | | |

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
