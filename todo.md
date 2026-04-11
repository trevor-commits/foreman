# TODO

## Active Next Steps
Capture the current goal plus the concrete dependency-ordered steps that are still open.
- [Phase 2.1] Promote `BLOCKER` to hard gate in pre-push after two-week burn-in; defer until 2026-04-24.
- [Phase 2.1] Validate OpenAI reviewer path with live `OPENAI_API_KEY`.
- [Phase 2.1] Validate Claude-fallback (Haiku) path with live `ANTHROPIC_API_KEY`.
- [Phase 2.1] Validate trailer-check GitHub Actions workflow from a real hosted runner, not local syntax check only.
- [Phase 2.1] Add Haiku classifier to `scripts/foreman-dispatch.sh` after reviewer telemetry exists.
- [Phase 3 / deferred] Evaluate OpenHands as a combined Phase 3+4 replacement before building Dagger.

## Completed
Preserve a durable completion trail for verified work instead of deleting it from active planning.
- Completed 2026-04-09: Landed the Phase 1.5 governance rollout across `foreman`, `Taxes`, and `bible-ai`. Merged the stale downstream install branches to `main`, added `.github/workflows/foreman-trailer-check.yml` in all three repos, clarified that `.agent-runs/` is scratch space while commit trailers are the durable audit artifact, added `scripts/foreman-dispatch.sh`, refreshed `CLAUDE.md`, and pushed every reachable repo update | priority: P1 | owner: Trevor Gillette | target date: 2026-04-09
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

## Branch History
- branch: `agent/codex/2026-04-09/phase15-governance`
  source chat: 2026-04-09 "Work through Task 0-4 across foreman, Taxes, and bible-ai"
  last refreshed by chat: same chat
  purpose: land the Phase 1.5 trailer-check rollout, resolve the audit-trail decision, add the dispatcher prototype, and refresh downstream governance records
  outcome: merged to `main` on 2026-04-09 after all three repos were updated, committed, and pushed
  cleanup status: branch merged; local and remote cleanup still pending
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
| Hook or branch-policy changes | `bash hooks/pre-push origin` | Before every push from a feature branch | Exits `0`; no gate failures; reviewer may skip only for missing keys/dependencies or empty diff |
| Pre-push reviewer smoke coverage | `bash scripts/test-review.sh` | Every push | Must pass |
| Dispatcher script changes | `bash -n scripts/foreman-dispatch.sh` | Before commit and before push when `scripts/foreman-dispatch.sh` changes | Exits `0`; no shell syntax errors |
| Reviewer script changes | `python3 -c "import runpy; runpy.run_path('scripts/foreman-review.py', run_name='foreman_review')"` | Before commit and before push when `scripts/foreman-review.py` changes | Exits `0`; file loads without syntax or import-time failure |
| Trailer enforcement validation | `git push origin <branch>` | Every PR or push that is intended to validate `.github/workflows/foreman-trailer-check.yml` | Hosted `Foreman Trailer Check` workflow passes on GitHub Actions |

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
