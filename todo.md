# TODO

## Active Next Steps
Capture the current goal plus the concrete dependency-ordered steps that are still open.
- [Phase 2.1] Continue the reviewer `BLOCKER` burn-in and decide whether the default should flip to a hard gate after 2026-04-24.
- [Phase 2.1] Validate OpenAI reviewer path with live `OPENAI_API_KEY`.
- [Phase 2.1] Validate Claude-fallback (Haiku) reviewer path with live `ANTHROPIC_API_KEY`.
- [Phase 2.1] Validate the Haiku classifier path with live `ANTHROPIC_API_KEY` against real task briefs.
- [Phase 2.1] Validate trailer-check GitHub Actions workflow from a real hosted runner, not local syntax check only.
- [Phase 2.1] Decide whether commit-time `Reviewed-By` should remain warning-only or follow the Phase 2.1 hard-gate promotion path.
- [Governance] Add a dedicated temp-repo smoke test script for `hooks/commit-msg` and `hooks/pre-push` so future audits do not have to recreate hook behavior manually.
- [Phase 3 / deferred] Evaluate OpenHands as a combined Phase 3+4 replacement before building Dagger.

## Completed
Preserve a durable completion trail for verified work instead of deleting it from active planning.
- Completed 2026-04-11: Added the optional Phase 2.1 Haiku classifier via `scripts/foreman-classify.py` and wired it into `scripts/foreman-dispatch.sh` with conservative upward routing, `--no-classify`, and no-key fallback to `standard` | priority: P1 | owner: Trevor Gillette | target date: 2026-04-11
- Completed 2026-04-09: Landed the Phase 1.5 governance rollout across `foreman`, `Taxes`, and `bible-ai`. Merged the stale downstream install branches to `main`, added `.github/workflows/foreman-trailer-check.yml` in all three repos, clarified that `.agent-runs/` is scratch space while commit trailers are the durable audit artifact, added `scripts/foreman-dispatch.sh`, refreshed `CLAUDE.md`, and pushed every reachable repo update | priority: P1 | owner: Trevor Gillette | target date: 2026-04-09

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
- branch: `agent/codex/2026-04-10/phase2-reviewer`
  source chat: 2026-04-11 "Full audit of the foreman repository"
  last refreshed by chat: same chat
  purpose: audit and remediate hook/script/workflow/doc drift after the Phase 2 / 2.1 rollout
  merge expectation: current audit fixes land, required syntax checks pass, audit/test evidence is recorded, and the branch is pushed
  exit checklist: update hook/script/workflow/docs drift; refresh `BRANCH_LEDGER.md`; append audit + test evidence to `todo.md`; commit; push
  delete when: after this branch is merged to `main` and the active ledger entry is no longer needed

## Branch History
- branch: `agent/codex/2026-04-09/phase15-governance`
  source chat: 2026-04-09 "Work through Task 0-4 across foreman, Taxes, and bible-ai"
  last refreshed by chat: same chat
  purpose: land the Phase 1.5 trailer-check rollout, resolve the audit-trail decision, add the dispatcher prototype, and refresh downstream governance records
  outcome: merged to `main` on 2026-04-09 after all three repos were updated, committed, and pushed
  cleanup status: branch merged; local and remote cleanup still pending
- branch: `agent/codex/2026-04-10/phase2-reviewer`
  source chat: 2026-04-10 "Build the Phase 2 automated cross-model review path"
  last refreshed by chat: 2026-04-11 full audit chat
  purpose: originally land the Phase 2 reviewer, later reused for Phase 2.1 follow-up and audit remediation before merge
  outcome: Phase 2 reviewer shipped as a soft gate on 2026-04-11; branch remains active for follow-up audit/remediation work
  cleanup status: retained until the current audit/remediation pass is merged or replaced by a fresh follow-up branch

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
- date: 2026-04-11
  type: full audit
  scope: hooks + scripts + workflow + docs
  repo fingerprint: `agent/codex/2026-04-10/phase2-reviewer @ 2ef634f` (pre-fix base for this audit pass)
  prior audit reference: 2026-04-09 Phase 1 audit acceptance in `DECISIONS.md`
  source/work chat: 2026-04-11 "Full audit of the foreman repository"
  audit chat: codex-desktop-2026-04-11
  implementation chat: same chat
  separate follow-up audit: no — fixes landed in the same session
  commands / evidence: `bash -n hooks/pre-push`; `bash -n hooks/commit-msg`; `bash -n hooks/install.sh`; `python3 -m py_compile scripts/foreman-review.py`; `bash -n scripts/foreman-dispatch.sh`; `bash scripts/test-review.sh`; `bash hooks/commit-msg <temp message with Reviewed-By: none-yet>`; temp-clone `bash hooks/pre-push origin` with only `origin/main`
  tested: syntax for hooks + dispatcher; reviewer script compile path; reviewer smoke script; `commit-msg` warning-only path; `pre-push` fresh-clone fallback to `origin/main`
  not tested: live OpenAI reviewer path; live Anthropic reviewer/classifier paths; hosted GitHub Actions runner behavior
  findings opened or updated: refreshed the Phase 2.1 live-validation queue; added a follow-up item for dedicated hook smoke automation; reopened the current retained branch in the ledger so branch state is accurate again
  fixes closed / verified: tightened `commit-msg` skip logic to use the subject line only; made Python gate selection interpreter-safe; made the reviewer diff base fall back from local `main` to `origin/main`; removed the shell-level Anthropic pre-check so `foreman-review.py` owns provider/dependency skipping; made reviewer JSON extraction and write-path handling more robust; pinned `actions/checkout`; aligned README / CLAUDE / AGENTS / PROJECT_INTENT / OPEN_QUESTIONS with the current Phase 2.1 behavior
  declined / deferred findings: live API-path validation and hosted-workflow validation remain deferred until credentials / hosted runs are available
  better-path challenge: prefer a provider-agnostic shell hook that defers dependency decisions to `scripts/foreman-review.py`, and prefer explicit `refs/heads/main` vs `refs/remotes/origin/main` checks over ambiguous abbreviated ref resolution
  references: current branch `agent/codex/2026-04-10/phase2-reviewer`

## Test Evidence Convention
- Testing is required delivery evidence. If a check is skipped, blocked, or only partially run, record the reason and the remaining risk.
- Record each verification run as:
  - `date` (YYYY-MM-DD)
  - `command(s)` executed
  - `result` (pass/fail + short note)
  - `log/PR reference` (commit SHA, CI URL, or local log path)
- When a verification run closes or updates an audit finding, cross-reference the matching audit record entry and the chat or commit that performed the work.

## Test Evidence Log
- date: 2026-04-11
  command(s): `bash -n hooks/pre-push`; `bash -n hooks/commit-msg`; `bash -n hooks/install.sh`; `python3 -m py_compile scripts/foreman-review.py`; `bash -n scripts/foreman-dispatch.sh`
  result: pass — all required syntax / compile checks succeeded
  log/PR reference: local audit run in `agent/codex/2026-04-10/phase2-reviewer`
- date: 2026-04-11
  command(s): `bash scripts/test-review.sh`
  result: pass — empty diff, reviewer routing, and malformed JSON smoke cases all passed
  log/PR reference: local audit run in `agent/codex/2026-04-10/phase2-reviewer`
- date: 2026-04-11
  command(s): `bash hooks/commit-msg <temp message with valid required trailers + Reviewed-By: none-yet>`
  result: pass — warning-only behavior confirmed; commit not blocked
  log/PR reference: local audit run in `agent/codex/2026-04-10/phase2-reviewer`
- date: 2026-04-11
  command(s): temp clone of `agent/codex/2026-04-10/phase2-reviewer` with only `origin/main`, then `bash hooks/pre-push origin`
  result: pass — reviewer base fallback resolved correctly; reviewer script emitted a dependency warning instead of failing the push
  log/PR reference: local audit run in `agent/codex/2026-04-10/phase2-reviewer`

## Testing Cadence Matrix
| Trigger | Command(s) | Cadence | Gate Criteria |
|---|---|---|---|
| Hook changes | `bash -n hooks/pre-push && bash -n hooks/commit-msg` | Before commit and before push when hook logic changes | Both commands exit `0` |
| Hook installation changes | `bash -n hooks/install.sh` | Before commit and before push when `hooks/install.sh` changes | Exits `0`; no shell syntax errors |
| Pre-push reviewer smoke coverage | `bash scripts/test-review.sh` | Every push | Must pass |
| Dispatcher script changes | `bash -n scripts/foreman-dispatch.sh` | Before commit and before push when `scripts/foreman-dispatch.sh` changes | Exits `0`; no shell syntax errors |
| Classifier script changes | `python3 scripts/foreman-classify.py <brief.md>` | Before commit and before push when `scripts/foreman-classify.py` changes | Exits `0` and prints valid JSON; without credentials it must fall back to `standard` |
| Reviewer script changes | `python3 -m py_compile scripts/foreman-review.py && bash scripts/test-review.sh` | Before commit and before push when `scripts/foreman-review.py` changes | Both commands exit `0` |
| Local pre-push smoke | `bash hooks/pre-push origin` | Before every push from a feature branch | Exits `0`; no gate failures; reviewer may skip only for missing keys/dependencies, missing diff base, or empty diff |
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
