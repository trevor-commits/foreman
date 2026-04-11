# TODO

## Active Next Steps
Capture the current goal plus the concrete dependency-ordered steps that are still open.
- [Phase 2.1] Continue the reviewer `BLOCKER` burn-in and decide whether the default should flip to a hard gate after 2026-04-24.
- [Phase 2.1] Run `python3 scripts/foreman-calibration.py --days 14` on 2026-04-24 to evaluate `BLOCKER` accuracy before promoting `FOREMAN_HARD_GATE=1`.
- [Phase 2.1] Validate trailer-check GitHub Actions workflow from a real hosted runner, not local syntax check only.
- [Phase 2.1] Push a test PR with a correctly-tagged commit to confirm `foreman-trailer-check.yml` passes on GitHub's hosted runner, then push a PR with a missing-trailer commit and confirm it fails.
- [Phase 2.1] Decide whether commit-time `Reviewed-By` should remain warning-only or follow the Phase 2.1 hard-gate promotion path.
- [Governance] Run `scripts/test-hooks.sh` manually after any hook change.
- [Governance] Add `foreman-close.sh` to the post-merge checklist in `.github/PULL_REQUEST_TEMPLATE.md` so reviewers run it after merging.
- [Phase 3 / deferred] Evaluate OpenHands as a combined Phase 3+4 replacement before building Dagger.

## Completed
Preserve a durable completion trail for verified work instead of deleting it from active planning.
- Completed 2026-04-11: Installed `anthropic` and `openai` into the local Python 3.14 environment and completed live classifier, Claude-fallback reviewer, Anthropic Sonnet reviewer, and OpenAI reviewer validation against trivial README diffs | priority: P1 | owner: Trevor Gillette | target date: 2026-04-11
- Completed 2026-04-11: Added `scripts/test-hooks.sh`, a temp-repo smoke harness that validates the local `commit-msg` hook rejects missing trailers and accepts a fully tagged commit | priority: P1 | owner: Trevor Gillette | target date: 2026-04-11
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
- branch: `agent/codex/2026-04-11/enrich-reviewer-prompt`
  source chat: 2026-04-11 "rewrite build_prompt() to inject the full foreman governance context"
  last refreshed by chat: 2026-04-11 "fix multi-commit author detection and add trailer validation scan to pre-push"
  purpose: align the reviewer governance prompt, add persistent review telemetry and calibration, close the `Reviewed-By` workflow gap, wire branch lifecycle automation into dispatch/close flows, add operator-facing status and merge-readiness commands, and harden `hooks/pre-push` with branch-wide author detection plus local trailer validation
  merge expectation: merge after `bash -n hooks/pre-push`, `bash scripts/test-hooks.sh`, `bash -n scripts/foreman-dispatch.sh`, `bash -n scripts/foreman-close.sh`, `bash -n scripts/foreman-status.sh`, `bash -n scripts/foreman-merge-check.sh`, the empty-diff manual hook check, `python3 -m py_compile scripts/foreman-calibration.py`, and `python3 scripts/test-review.py` pass and the branch receives a second-model review with a compliant `Reviewed-By` trailer
  exit checklist: keep `hooks/pre-push`, `AGENTS.project.md`, `CLAUDE.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `scripts/foreman-review.py`, `scripts/foreman-calibration.py`, `scripts/foreman-dispatch.sh`, `scripts/foreman-close.sh`, `scripts/foreman-status.sh`, `scripts/foreman-merge-check.sh`, `scripts/README.md`, `scripts/test-review.py`, and `scripts/test-hooks.sh` aligned, keep the branch ledger row open until review is complete, then mark the branch ready/merged
  delete when: after merge to `main`

## Branch History
- branch: `agent/codex/2026-04-09/phase15-governance`
  source chat: 2026-04-09 "Work through Task 0-4 across foreman, Taxes, and bible-ai"
  last refreshed by chat: same chat
  purpose: land the Phase 1.5 trailer-check rollout, resolve the audit-trail decision, add the dispatcher prototype, and refresh downstream governance records
  outcome: merged to `main` on 2026-04-09 after all three repos were updated, committed, and pushed
  cleanup status: branch merged; local and remote cleanup still pending
- branch: `agent/codex/2026-04-10/phase2-reviewer`
  source chat: 2026-04-10 "Build the Phase 2 automated cross-model review path"
  last refreshed by chat: 2026-04-11 "commit all uncommitted work, merge/delete all branches"
  purpose: originally land the Phase 2 reviewer, later reused for Phase 2.1 follow-up and audit remediation before merge
  outcome: merged to `main` on 2026-04-11 after the audit/remediation pass closed hook, script, workflow, and documentation drift and recorded the verification evidence in this file
  cleanup status: branch deleted locally and on `origin` after merge
- branch: `agent/codex/2026-04-11/branch-cleanup`
  source chat: 2026-04-11 "commit all uncommitted work, merge/delete all branches"
  last refreshed by chat: same chat
  purpose: close the retained Phase 2 branch cleanly, land it to `main`, and remove merged branches
  outcome: merged to `main` on 2026-04-11 after the branch ledger and history were closed out for the retained reviewer branch
  cleanup status: branch deleted locally and on `origin` after merge
- branch: `agent/codex/2026-04-11/phase21-validation-pass`
  source chat: 2026-04-11 "Phase 2.1 validation pass — live API tests, hooks smoke test, downstream sync, hard-gate comment"
  last refreshed by chat: 2026-04-11 "commit any uncommitted work. merge delete any branches"
  purpose: run the Phase 2.1 validation pass, add the reusable hook smoke test, sync missing governance artifacts to downstream repos, and record exactly what live validation is blocked locally
  outcome: merged to `main` on 2026-04-11 after landing the hook smoke harness, the explicit hard-gate rollout note, and the deferred live-SDK validation evidence in `todo.md`
  cleanup status: branch deleted locally and on `origin` after merge

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
  commands / evidence: `bash -n hooks/pre-push`; `bash -n hooks/commit-msg`; `bash -n hooks/install.sh`; `python3 -m py_compile scripts/foreman-review.py`; `bash -n scripts/foreman-dispatch.sh`; `python3 scripts/test-review.py`; `bash hooks/commit-msg <temp message with Reviewed-By: none-yet>`; temp-clone `bash hooks/pre-push origin` with only `origin/main`
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
  command(s): `bash -n hooks/pre-push`; `bash scripts/test-hooks.sh`; temp-repo push proof with a stub `scripts/foreman-review.py` plus branch commits authored by `codex-gpt-5`, `codex-gpt-5`, and `claude-sonnet-4-6`
  result: pass — `hooks/pre-push` is syntax-valid, `scripts/test-hooks.sh` confirms the pre-push trailer scan warns when a non-tip branch commit is missing `Agent:`, and the mixed-author temp-repo push prints `detected author model 'codex-gpt-5' from 3 commits on branch`, proving the hook no longer routes review from the last commit alone
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `bash -n scripts/foreman-status.sh`; `bash -n scripts/foreman-merge-check.sh`
  result: pass — both scripts are syntax-valid; `foreman-status.sh` renders the current branch governance state without failing, and `foreman-merge-check.sh` exits `1` with the expected not-ready reasons on this branch because the newest commit still has `Reviewed-By: none-yet`
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `bash -n scripts/foreman-dispatch.sh`; `bash -n scripts/foreman-close.sh`
  result: pass — both scripts are syntax-valid, and a temp-repo lifecycle proof confirmed that `foreman-dispatch.sh --no-classify` creates the branch and adds an active ledger row while `foreman-close.sh ... merged` moves that row to Closed Branches and deletes the merged branch locally and on `origin`
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `bash -n hooks/pre-push`; `HEAD_BEFORE=$(git rev-parse HEAD); FOREMAN_REVIEW_BASE_REF=HEAD bash hooks/pre-push origin; HEAD_AFTER=$(git rev-parse HEAD)`; temp-repo push proof with a stub `scripts/foreman-review.py` to verify first push amends+stops and second push sends the amended SHA
  result: pass — shell syntax is valid, the empty-diff manual hook run skipped review and left `HEAD` unchanged, and the temp-repo proof confirmed the safe flow: first push amends `Reviewed-By` and aborts, second push sends the amended commit
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `python3 -m py_compile scripts/foreman-calibration.py`; `python3 scripts/test-review.py`
  result: pass — the new calibration script compiles, the reviewer smoke suite now covers telemetry JSONL writes, and `python3 scripts/foreman-calibration.py --days 14` correctly prints the no-telemetry bootstrap message before any real reviews are logged
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `python3 scripts/test-review.py`
  result: pass — reviewer smoke tests still pass after the governance-prompt rewrite and the added validation coverage for valid `reviewer_model` handling plus missing-`note` rejection
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
- date: 2026-04-11
  command(s): `sed -n '1,220p' /Users/gillettes/Coding Projects/bible-ai/.github/workflows/foreman-trailer-check.yml`; `test -f /Users/gillettes/Coding Projects/bible-ai/scripts/ci/verify-foreman-trailers.sh`
  result: pass — `bible-ai` trailer workflow delegates to `./scripts/ci/verify-foreman-trailers.sh`, and that script exists; no workflow hotfix was needed
  log/PR reference: local downstream workflow audit from `foreman/main`
- date: 2026-04-11
  command(s): `pip3 install anthropic openai --break-system-packages`; `python3 -c "import anthropic; print('anthropic', anthropic.__version__)"`; `python3 -c "import openai; print('openai', openai.__version__)"`
  result: pass — installed `anthropic 0.94.0` and `openai 2.31.0` into Python 3.14.4; live reviewer/classifier calls are now executable in this shell
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `python3 scripts/test-review.py`; `python3 -m py_compile scripts/foreman-classify.py`; `python3 -m py_compile scripts/foreman-mcp-shim.py`
  result: pass — smoke tests still pass after SDK install, and both classifier / MCP shim compile cleanly
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `python3 scripts/foreman-classify.py .agent-runs/2026-04-11-live-validate/brief.md`
  result: pass — classifier returned `route=cheap`, `confidence=0.95`, `classifier_model=claude-haiku-4-5-20251001`, `escalation_triggers=[]`
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `OPENAI_API_KEY='' printf 'diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# foreman\n+# foreman template\n' | OPENAI_API_KEY='' python3 scripts/foreman-review.py --author-model claude-sonnet-4-6 --branch test/live-validate -`
  result: pass — forced Claude fallback path returned `verdict=APPROVE`, `reviewer_model=claude-haiku-4-5-20251001`, `summary=Minor documentation update to README title.`
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `printf 'diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# foreman\n+# foreman template\n' | python3 scripts/foreman-review.py --author-model codex-5.3 --branch test/live-validate -`
  result: pass — Anthropic reviewer path for a codex-authored diff returned `verdict=APPROVE`, `reviewer_model=claude-sonnet-4-6`, `summary=Trivial README title update with no functional changes.`
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `printf 'diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# foreman\n+# foreman template\n' | python3 scripts/foreman-review.py --author-model claude-sonnet-4-6 --branch test/live-validate -`
  result: pass — actual OpenAI reviewer path returned `verdict=APPROVE`, `reviewer_model=o4-mini-2025-04-16`, `summary=Updated README header to clarify template usage`
  log/PR reference: local live-validation run on `agent/codex/2026-04-11/live-validation-sync`
- date: 2026-04-11
  command(s): `bash scripts/test-hooks.sh`
  result: pass — temp-repo smoke harness confirmed the local `commit-msg` hook rejects a commit missing `Agent:` and accepts a commit with the full trailer set
  log/PR reference: local validation run on `agent/codex/2026-04-11/phase21-validation-pass`
- date: 2026-04-11
  command(s): `echo $ANTHROPIC_API_KEY | head -c 8`; `echo $OPENAI_API_KEY | head -c 8`; `python3 -c "import anthropic; print('anthropic ok')" 2>&1`; `python3 -c "import openai; print('openai ok')" 2>&1`
  result: partial — both API keys are present in the shell (`sk-ant-a`, `sk-proj-`), but the current `python3` cannot import `anthropic` or `openai`, so live reviewer/classifier calls are deferred until those SDKs are installed into a usable interpreter or virtualenv
  log/PR reference: local validation intake on `agent/codex/2026-04-11/phase21-validation-pass`
- date: 2026-04-11
  command(s): `python3 scripts/test-review.py`; `python3 -m py_compile scripts/foreman-review.py`; `python3 -m py_compile scripts/foreman-classify.py`; `bash -n hooks/pre-push && bash -n hooks/commit-msg`
  result: pass — baseline local reviewer/classifier smoke and hook syntax checks all succeeded before live validation attempts
  log/PR reference: local validation run on `agent/codex/2026-04-11/phase21-validation-pass`
- date: 2026-04-11
  command(s): `python3 scripts/foreman-classify.py .agent-runs/2026-04-11-classifier-test/brief.md`; `echo "diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# foreman\n+# foreman template" | python3 scripts/foreman-review.py --author-model codex-5.3 --branch test/validation -`; `echo "diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# foreman\n+# foreman template" | python3 scripts/foreman-review.py --author-model claude-sonnet-4-6 --branch test/validation -`
  result: deferred — live Anthropic and OpenAI validation was not run because the current `python3` interpreter is missing both SDK packages; unblock by installing `anthropic` and `openai` into the interpreter or a project venv, then rerun these exact commands with the existing API keys
  log/PR reference: local validation intake on `agent/codex/2026-04-11/phase21-validation-pass`
- date: 2026-04-11
  command(s): `python3 -m py_compile scripts/foreman-review.py`; `python3 scripts/test-review.py`; `bash -n hooks/pre-push`; `python3 -m py_compile scripts/foreman-classify.py`; `bash -n scripts/test-review.sh`; `bash -n scripts/foreman-dispatch.sh`
  result: pass — targeted fix pass replaced the bash smoke harness with a Python one, kept the compatibility wrapper syntax-valid, and revalidated the reviewer / classifier / hook syntax paths
  log/PR reference: local targeted fix run in `main`
- date: 2026-04-11
  command(s): `bash -n hooks/pre-push`; `bash -n hooks/commit-msg`; `bash -n hooks/install.sh`; `python3 -m py_compile scripts/foreman-review.py`; `bash -n scripts/foreman-dispatch.sh`
  result: pass — all required syntax / compile checks succeeded
  log/PR reference: local audit run in `agent/codex/2026-04-10/phase2-reviewer`
- date: 2026-04-11
  command(s): `python3 scripts/test-review.py`
  result: pass — empty diff, reviewer routing, JSON extraction, and invalid-shape smoke cases all passed
  log/PR reference: local audit run in `main`
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
| Pre-push gate | `bash -n hooks/pre-push && bash -n hooks/commit-msg` | Every push | Must pass (syntax valid) |
| Reviewer script compile | `python3 -m py_compile scripts/foreman-review.py` | Every push | Must pass |
| Reviewer smoke tests | `python3 scripts/test-review.py` | Every push | All tests PASS |
| Hook smoke tests | `bash scripts/test-hooks.sh` | Every push after hook changes | All tests PASS |
| Dispatcher syntax | `bash -n scripts/foreman-dispatch.sh` | Every push | Must pass |
| Classifier compile | `python3 -m py_compile scripts/foreman-classify.py` | Every push | Must pass |
| Hard-gate calibration | `python3 scripts/foreman-calibration.py --days 14` | Once on 2026-04-24 (burn-in checkpoint) | READY verdict from the script |

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
