# TODO

## Active Next Steps
Capture the current goal plus the concrete dependency-ordered steps that are still open.
- Keep this section short, current, and ordered by impact/dependency.
- Put audit-created actionable execution items at the top of this section so audit follow-through is the next queue to execute.
- If the current chat creates or discovers more urgent execution-ready work than the existing queue reflects, persist and move that fresher work to the top of this section before handoff so the chat is not the only durable record.
- When a step is verified complete, move or summarize it in `## Completed` instead of deleting the history.
- Land the Phase 1.5 governance rollout across `foreman`, `Taxes`, and `bible-ai`: merge stale install branches, add GitHub trailer enforcement, resolve the audit-trail policy, ship the dispatcher prototype, refresh repo memory files, and push every reachable repo update | priority: P1 | owner: Trevor Gillette | target date: 2026-04-09

## Completed
Preserve a durable completion trail for verified work instead of deleting it from active planning.
- No completed entries recorded yet.

## Suggested Recommendation Log
Keep materially new suggestions here so they survive beyond the current chat.
- Do not delete old entries; mark them completed, declined, deferred, or superseded with date and chat context.
- Keep audit-created items here only when they are deferred, optional, or not yet execution-ready; otherwise promote them into `## Active Next Steps`.
- When a suggestion comes from an audit or feedback review, link back to the originating audit record or `Feedback Decision Log` entry and later note which chat implemented or declined it.

## Active Branch Ledger
Keep one entry per non-trivial active branch so any chat can see why it exists, which chat opened or resumed it, what work is active, what must happen before merge or closeout, and whether the branch should be deleted or intentionally retained.
Legacy branches opened before this workflow may still need manual backfill; use `TODO: verify` instead of guessing until those entries are added.
Each active branch entry should include:
- `source chat`
- `last refreshed by chat`
- `purpose`
- `merge expectation`
- `exit checklist`
- `delete when` or `retain after close`
- `retain reason` when not deleting
- branch: `agent/codex/2026-04-09/phase15-governance`
  source chat: 2026-04-09 "Work through Task 0-4 across foreman, Taxes, and bible-ai"
  last refreshed by chat: same chat
  purpose: land the Phase 1.5 trailer-check rollout, resolve the audit-trail decision, add the dispatcher prototype, and refresh downstream governance records
  merge expectation: merge to `main` after the three repos are updated, committed, and pushed
  exit checklist: merge stale downstream install branches; add trailer-check workflow in all three repos; resolve `OPEN_QUESTIONS.md` #5 and `DECISIONS.md`; add `scripts/foreman-dispatch.sh`; refresh `CLAUDE.md`; commit and push
  delete when: after merge to `main`, downstream repos are pushed, and the branch history entry is written

## Branch History
- No closed branch entries recorded yet.

## Audit Record Convention
- Record each audit, ship-check, or substantial verification-driven review in an easy-to-find project audit log entry.
- Each entry should capture:
  - `date`
  - `type` (for example `full audit`, `targeted audit`, `ship-check`, `governance review`)
  - `scope`
  - `repo fingerprint` (branch + commit when available)
  - `prior audit reference`
  - `source/work chat`
  - `audit chat`
  - `implementation chat` or `disposition chat`
  - `separate follow-up audit` (`yes` / `no` plus reason when `no`)
  - `commands / evidence`
  - `tested`
  - `not tested`
  - `findings opened or updated`
  - `fixes closed / verified`
  - `declined / deferred findings`
  - `better-path challenge`
  - `references` (issue, PR, commit, or log path)
- When a finding is later implemented, deferred, declined, or superseded, update the existing audit trail instead of deleting the history.

## Audit Record Log
- No audit entries recorded yet.

## Test Evidence Convention
- Testing is required delivery evidence. If a check is skipped, blocked, or only partially run, record the reason and the remaining risk.
- Record each verification run as:
  - `date` (YYYY-MM-DD)
  - `command(s)` executed
  - `result` (pass/fail + short note)
  - `log/PR reference` (commit SHA, CI URL, or local log path)
- When a verification run closes or updates an audit finding, cross-reference the matching audit record entry and the chat or commit that performed the work.

## Test Evidence Log
- No test evidence recorded yet.

## Testing Cadence Matrix
| Trigger | Command(s) | Cadence | Gate Criteria |
|---|---|---|---|
| TODO: verify | TODO: verify | TODO: verify | TODO: verify |

## Feedback Decision Log
Record outside feedback and the resulting reasoning once, then update the same entry as the decision evolves.
- Each entry should capture:
  - `date`
  - `feedback source`
  - `feedback summary`
  - `evaluation chat`
  - `reasoning response`
  - `decision status` (`accepted`, `partial`, `deferred`, `rejected`, or `superseded`)
  - `implementation/disposition chat`
  - `linked branch / audit / suggestion / test evidence`
- Reuse or update an existing entry when the same feedback thread comes back instead of opening duplicate records.
