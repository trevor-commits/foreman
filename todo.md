# TODO

## Active Next Steps
Capture the current goal plus the concrete dependency-ordered steps that are still open.
- [Governance] Tighten `scripts/foreman-drift-check.sh` repo discovery so non-project `CLAUDE.md` locations such as `~/.claude`, `~/Desktop`, and editor extensions are excluded by default.
- [MCP] Validate `scripts/foreman-mcp-server.py` from a real Claude Code or Claude desktop MCP client session and confirm stdio transport plus tool registration work end to end.
- [CI] Run the fixed `test-foreman-tooling.yml` on a real GitHub-hosted runner and confirm both jobs pass outside local YAML parsing and local shell checks.
- [Phase 2.1] Continue the reviewer `BLOCKER` burn-in and decide whether the default should flip to a hard gate after 2026-04-24.
- [Phase 2.1] Run `python3 scripts/foreman-calibration.py --days 14` on 2026-04-24 to evaluate `BLOCKER` accuracy before promoting `FOREMAN_HARD_GATE=1`.
- [Phase 2.1] `test-foreman-tooling.yml` now gives hosted CI coverage for the foreman test suite on every push and PR; the remaining hosted validation gap is the `foreman-trailer-check.yml` pass/fail PR pair.
- [Phase 2.1] Push a test PR with a correctly-tagged commit to confirm `foreman-trailer-check.yml` passes on GitHub's hosted runner, then push a PR with a missing-trailer commit and confirm it fails.
- [Phase 2.1] Decide whether commit-time `Reviewed-By` should remain warning-only or follow the Phase 2.1 hard-gate promotion path.
- [Governance] Run `scripts/foreman-drift-check.sh --fix` before any major phase release to ensure downstream repos are current.
- [Governance] Run `scripts/test-hooks.sh` manually after any hook change.
- [Governance] Add `foreman-close.sh` to the post-merge checklist in `.github/PULL_REQUEST_TEMPLATE.md` so reviewers run it after merging.
- [Phase 3 / deferred] Evaluate OpenHands as a combined Phase 3+4 replacement before building Dagger.

## Completed
Preserve a durable completion trail for verified work instead of deleting it from active planning.
- [x] 2026-04-16: backfilled the local durable trail for the `GIL-37` repo-principles rollout so this repo now records why the shared Continuity / Coherence / Linear-Core surfaces landed here instead of leaving that explanation only in the coordinating repo.

- Completed 2026-04-11: Audited all 10 Phase 2.1+ deliverables, fixed the invalid `test-foreman-tooling.yml` YAML, moved the real FastMCP server implementation into `scripts/foreman-mcp-server.py`, and simplified smoke checks to import the executable script directly | priority: P1 | owner: Trevor Gillette | target date: 2026-04-11
- Completed 2026-04-11: Added `scripts/foreman-pr-prep.sh`, which reads the current branch governance state and prints a PR description pre-filled from commit trailers, last-review data, the task brief, and `BRANCH_LEDGER.md` | priority: P1 | owner: Trevor Gillette | target date: 2026-04-11
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

### `agent/claude/2026-07-30/agents-first-consolidation`
- status: merged-pending-cleanup
- created: 2026-07-30
- base: `main` at `97b502c793ba361e0cbab2a33c24860bd4294c5c`
- worktree: none after the primary checkout switched to the cleanup branch
- source chat: Claude thread `e6ad7a4a-db41-46d9-bbbc-961c1d9458d0`
- last refreshed by chat: 2026-08-15 lossless branch cleanup (`01a00813-4314-76d0-8dea-2ca70f2126fb`)
- purpose: consolidate repository instructions under `AGENTS.md` / `AGENTS.project.md`, keep `CLAUDE.md` as a shim, and restore the MCP dependency bound
- linked issue: `self-contained:` inherited branch cleanup
- plugin mirror: none; live Linear team remains `TODO: verify`
- merge expectation: squash-merged to `main` through PR #3
- merge target: `main`
- review surface: PR #3; local tree comparison against `origin/main`
- exit checklist: archive tip, verify exact PR/head binding, delete local and remote refs through audited paths, then record Branch History
- delete when: exact tip `6cf1425f7530dafc9f4e004d4f1dc0e58ef961ef` is archived and PR #3 merge proof remains contained by `origin/main`
- retain reason: pending verified cleanup only
- cleanup command: audited branch-hygiene cleanup with expected-SHA remote lease
- linked PR/audit/completion record: PR #3; `origin/main` `13b592f3ccf60aa04001d291feab2a109e07a494`
- pre-existing dirt at task start: no tracked dirt; its former primary checkout retained five ignored paths
- usable invocation path: repository read order through `AGENTS.md` → `AGENTS.project.md`; Claude routing through `CLAUDE.md`
- owner lease: none; branch is not worktree-bound

### `codex/er930-opus5-only`
- status: active-owner-preservation
- created: 2026-08-11
- base: `main` at `97b502c793ba361e0cbab2a33c24860bd4294c5c`
- worktree: `/Users/gillettes/Coding Projects/foreman-worktrees/codex/er930-opus5-only`
- source chat: Codex task `019ff1e7-a4f1-7841-a6b7-99c783643ff5`
- last refreshed by chat: 2026-08-15 lossless branch cleanup (`01a00813-4314-76d0-8dea-2ca70f2126fb`)
- purpose: enforce exact Claude Opus 5 selectors and fail closed when independent review cannot run
- linked issue: `self-contained:` inherited ER-930 repository work
- plugin mirror: none; live Linear team remains `TODO: verify`
- merge expectation: preserve existing commits and integrate current net changes into `main`
- merge target: `main`
- review surface: focused reviewer tests plus independent integration review
- exit checklist: owner commits two dirty files, integration preserves both committed changes, verification passes, `origin/main` contains the result, owner releases lease, broker removes worktree and branch
- delete when: exact owner releases lease after `origin/main` containment and archive verification
- retain reason: active owner lease blocks cleanup until release
- cleanup command: owner release followed by `worktree-owner-lease.py cleanup-released`
- linked PR/audit/completion record: `TODO: verify`
- pre-existing dirt at task start: modified tracked files `scripts/foreman-review.py` and `scripts/test-review.py`; no listed untracked or ignored paths
- usable invocation path: `scripts/foreman-dispatch.sh`, `scripts/foreman-classify.py`, and `scripts/foreman-review.py`
- owner lease: task `019ff1e7-a4f1-7841-a6b7-99c783643ff5`; lease `392bea34-d735-424c-8f62-5150c56447cf`; state file `.git/codex-worktree-owners/8099c29fc332f55a648b287cefce5e43c8b38e812e5ccdcf9dc1009ad0e4a2d2.json`

### `agent/codex/2026-08-15/branch-cleanup`
- status: active
- created: 2026-08-15
- base: `origin/main` at `13b592f3ccf60aa04001d291feab2a109e07a494`
- worktree: `/Users/gillettes/Coding Projects/foreman`
- source chat: 2026-08-15 "merge/delete all branches/worktrees in this repo without losing any work" (`01a00813-4314-76d0-8dea-2ca70f2126fb`)
- last refreshed by chat: 2026-08-15 inventory and ownership verification
- purpose: preserve every branch and dirty-path contribution, merge the net work to `main`, then remove fully merged branches and owner-released linked worktrees
- linked issue: `self-contained:` direct repository cleanup request
- plugin mirror: none; live Linear team remains `TODO: verify`
- merge expectation: merge to `main`
- merge target: `main`
- review surface: local integration and repository verification; independent review status to be recorded before merge
- exit checklist:
  - [ ] Dirty work committed or preserved in a verified recovery artifact
  - [ ] Every non-default branch contribution merged or explicitly shown content-equivalent
  - [ ] Required verification complete
  - [ ] Branch records and Work Record updated
  - [ ] Cleanup branch pushed and merged to `main`
  - [ ] Owner-bound linked worktree released and removed through the cleanup broker
  - [ ] Fully merged non-default local and remote branches deleted through approved paths
- delete when: after `main` contains the cleanup result and final recovery checks pass
- retain reason: n/a
- cleanup command: owner-bound broker for linked worktrees; audited remote-ref deletion path for remote branches
- linked PR/audit/completion record: `TODO: verify`
- pre-existing dirt at task start: primary checkout had no tracked dirt and five ignored paths (`.DS_Store`, one task brief, one review JSON, two Python bytecode files); linked `codex/er930-opus5-only` worktree had two modified tracked files and no listed ignored paths
- usable invocation path: n/a; this task changes repository state and records only
- owner lease: primary checkout has no lease; linked `codex/er930-opus5-only` worktree is owned by task `019ff1e7-a4f1-7841-a6b7-99c783643ff5`, lease `392bea34-d735-424c-8f62-5150c56447cf`, state file `.git/codex-worktree-owners/8099c29fc332f55a648b287cefce5e43c8b38e812e5ccdcf9dc1009ad0e4a2d2.json`; only that owner may release it

## Branch History
- branch: `agent/codex/2026-04-11/enrich-reviewer-prompt`
  source chat: 2026-04-11 "rewrite build_prompt() to inject the full foreman governance context"
  last refreshed by chat: 2026-04-11 "At this point merge/delete all branches and commit all uncommitted work in order to do so if there is any"
  purpose: align the reviewer governance prompt, add persistent review telemetry and calibration, close the `Reviewed-By` workflow gap, wire branch lifecycle automation into dispatch/close flows, add operator-facing status and merge-readiness commands, harden `hooks/pre-push` with branch-wide author detection plus local trailer validation, and add hosted CI coverage for the foreman tooling test suite
  outcome: merged to `main` on 2026-04-11 after landing the governance-prompt rewrite, telemetry and calibration tooling, the Reviewed-By auto-amend flow, dispatch and close lifecycle scripts, operator-facing status and merge-readiness commands, branch-wide pre-push author detection and trailer validation, and the hosted foreman tooling test workflow
  cleanup status: branch deleted locally and on `origin` after merge
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
  command(s): `bash scripts/foreman-drift-check.sh --repos '/Users/gillettes/Coding Projects/Taxes /Users/gillettes/Coding Projects/bible-ai'`; `python3 scripts/test-review.py`; `bash scripts/test-hooks.sh`; `bash -n hooks/pre-push`; `python3 -m py_compile scripts/foreman-mcp-server.py`; `python3 -m py_compile scripts/foreman-calibration.py`
  result: pass — downstream recheck reports 14 files in sync with 0 missing and 0 drifted across `Taxes` and `bible-ai`, and the full local verification block exits 0 after the MCP skip-guard change
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `pip3 install mcp --break-system-packages`; `python3 -c "import importlib.metadata; print(importlib.metadata.version('mcp'))"`; `python3 scripts/test-review.py`
  result: pass — `mcp` was already installed, `importlib.metadata` confirms version `1.27.0`, and the guarded MCP smoke test in `scripts/test-review.py` still passes after adding the skip-on-missing-package safety net
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `bash scripts/foreman-drift-check.sh --repos '/Users/gillettes/Coding Projects/Taxes /Users/gillettes/Coding Projects/bible-ai'`; `diff -u .github/workflows/foreman-trailer-check.yml '/Users/gillettes/Coding Projects/Taxes/.github/workflows/foreman-trailer-check.yml'`; `diff -u .github/workflows/foreman-trailer-check.yml '/Users/gillettes/Coding Projects/bible-ai/.github/workflows/foreman-trailer-check.yml'`; `bash scripts/foreman-drift-check.sh --fix --repos '/Users/gillettes/Coding Projects/Taxes /Users/gillettes/Coding Projects/bible-ai'`
  result: pass — reviewed the downstream trailer-workflow diffs, then synced 12 drifted files across `Taxes` and `bible-ai`: `scripts/foreman-review.py`, `scripts/foreman-dispatch.sh`, `scripts/foreman-mcp-shim.py`, `scripts/requirements.txt`, `docs/mcp-tools.md`, and `.github/workflows/foreman-trailer-check.yml` in each repo
  log/PR reference: local downstream sync run from `foreman/main`
- date: 2026-04-11
  command(s): `ls scripts/foreman*mcp*`; `pip3 install mcp --break-system-packages 2>&1 | tail -5`; `python3 -c "import mcp; print(mcp.__version__)"`; `python3 -c "import importlib.metadata; print(importlib.metadata.version('mcp'))"`; `python3 -m py_compile scripts/foreman-mcp-server.py`; `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test-foreman-tooling.yml')); print('CI workflow: valid')"`; `python3 scripts/test-review.py`; `bash scripts/test-hooks.sh`; `bash -n hooks/pre-push`
  result: pass with one package-version caveat — the duplicate `scripts/foreman_mcp_server.py` wrapper was removed, only the hyphenated MCP server remains, `pip3` confirmed `mcp` is installed and `importlib.metadata` reports version `1.27.0`, the direct `mcp.__version__` probe still raises `AttributeError` because that package does not expose `__version__`, the MCP server compiles, the reviewer and hook smoke suites pass, and the tooling workflow YAML still validates
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `find ~ -maxdepth 5 -name 'CLAUDE.md'`; `find ~ -maxdepth 5 -name 'foreman-review.py'`; `ls ~/Coding\\ Projects/Taxes/scripts/foreman-review.py ~/Coding\\ Projects/Taxes/scripts/foreman-classify.py ~/Coding\\ Projects/Taxes/scripts/foreman-mcp-server.py ~/Coding\\ Projects/Taxes/docs/mcp-tools.md`; `ls ~/Coding\\ Projects/bible-ai/scripts/foreman-review.py ~/Coding\\ Projects/bible-ai/scripts/foreman-classify.py ~/Coding\\ Projects/bible-ai/scripts/foreman-mcp-server.py ~/Coding\\ Projects/bible-ai/docs/mcp-tools.md`; SHA-256 comparison against foreman canonical files
  result: partial sync complete — `Taxes` and `bible-ai` were visible, both were missing `scripts/foreman-mcp-server.py`, and the canonical MCP server file was copied into both repos; both repos remain in sync on `scripts/foreman-classify.py` and now on `scripts/foreman-mcp-server.py`, but still drift on `scripts/foreman-review.py` and `docs/mcp-tools.md`
  log/PR reference: local downstream sync check from `foreman/main`
- date: 2026-04-11
  command(s): `python3 scripts/test-review.py`; `bash scripts/test-hooks.sh`; `bash -n hooks/pre-push`; `bash -n hooks/commit-msg`; `bash -n hooks/install.sh`; `bash -n scripts/foreman-dispatch.sh`; `bash -n scripts/foreman-close.sh`; `bash -n scripts/foreman-status.sh`; `bash -n scripts/foreman-merge-check.sh`; `bash -n scripts/foreman-drift-check.sh`; `bash -n scripts/foreman-pr-prep.sh`; `bash -n scripts/test-review.sh`; `bash -n scripts/test-hooks.sh`; `python3 -m py_compile scripts/foreman-review.py`; `python3 -m py_compile scripts/foreman-classify.py`; `python3 -m py_compile scripts/foreman-mcp-shim.py`; `python3 -m py_compile scripts/foreman-mcp-server.py`; `python3 -m py_compile scripts/foreman-calibration.py`; `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test-foreman-tooling.yml')); print('CI workflow: valid')"`
  result: pass — the full Phase 2.1+ verification suite passed after the audit/fix pass; the tooling workflow now parses as valid YAML, the FastMCP server compiles from the executable script directly, and all shell entrypoints remain syntax-valid
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `bash -n scripts/foreman-pr-prep.sh`
  result: pass — the new PR-prep helper script is syntax-valid and ready to generate pre-filled GitHub PR descriptions from current branch governance state
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `pip3 install mcp --break-system-packages 2>&1 | tail -3`; `python3 -m py_compile scripts/foreman-mcp-server.py`; direct importlib smoke check against `scripts/foreman-mcp-server.py`
  result: pass — installed the official `mcp` package with FastMCP support, the executable MCP server entrypoint compiles cleanly, and the import smoke check lists the registered tools from the hyphenated server file directly
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `bash scripts/foreman-drift-check.sh --repos $'/Users/gillettes/Coding Projects/Taxes\n/Users/gillettes/Coding Projects/bible-ai'`
  result: pass — report mode ran cleanly and found 8 drifted files total across `Taxes` and `bible-ai`: `scripts/foreman-review.py`, `scripts/foreman-dispatch.sh`, `scripts/requirements.txt`, and `.github/workflows/foreman-trailer-check.yml` in each repo; the trailer workflow warnings correctly called out repo-specific customization risk
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `bash -n scripts/foreman-drift-check.sh`
  result: pass — the new downstream drift detector shell script is syntax-valid
  log/PR reference: local verification run in `main`
- date: 2026-04-11
  command(s): `python3 -m pip install --break-system-packages -r scripts/requirements.txt`; `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test-foreman-tooling.yml'))"`
  result: pass — installed the YAML parser dependency required by the new workflow sanity check, and the new `test-foreman-tooling.yml` workflow parses cleanly as YAML
  log/PR reference: local verification run on `agent/codex/2026-04-11/enrich-reviewer-prompt`
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
| Hosted CI tooling suite | `.github/workflows/test-foreman-tooling.yml` | Every push and PR to `main` | Both GitHub Actions jobs pass |
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

## Linear Issue Ledger
If it's not here, it isn't remembered.
Mirror every live Linear issue here with the repo-side home that explains why it exists.
- Each entry should capture:
  - `issue`
  - `status`
  - `todo home`
  - `why this exists`
  - `origin source`
  - `last synced`
- If this repo is intentionally `repo-only` or no live Linear surface exists yet, keep an explicit note here instead of leaving the section absent.
- `GIL-37` | status: `Building` | todo home: `Work Record Log` 2026-04-16 (local durable-record backfill for the portfolio repo-principles rollout) | why this exists: preserve a repo-local pointer explaining why the shared Continuity / Coherence / Linear-Core surfaces landed here instead of leaving that reasoning only in the coordinating repo | origin source: Trevor portfolio-baseline rollout request on 2026-04-16, tracked centrally in `/Users/gillettes/Coding Projects/Autonomous Coding Agent` under `GIL-37` | last synced: `2026-04-16`

## Work Record Log
If it's not here, it isn't remembered.
Use one entry per bounded task, fix, audit, or review that would otherwise lose reasoning between chats.

```md
### YYYY-MM-DD — short title
- Problem:
- Reasoning:
- Diagnosis inputs:
- Implementation inputs:
- Fix:
- Self-audit:
  - method:
  - outcome:
  - did not verify:
- by:
- triggered by:
- led to:
- linear:
```

### 2026-04-16 — local GIL-37 rollout record
- Problem: This repo had the shared Continuity / Coherence / Linear-Core baseline on disk, but its local durable record was still blank: `todo.md` had the new `Work Record Log` and `Linear Issue Ledger` sections with no repo-local pointer explaining why those surfaces landed here.
- Reasoning: The coordinating repo keeps the portfolio-wide reasoning, but this repo still needs a local durable pointer so future readers can understand why the principle docs, Claude entrypoint, Linear contract, and AGENTS overlay changed here without hunting through another repo or relying on chat history.
- Diagnosis inputs: direct read of this repo's `todo.md` showing empty rollout-tracking sections; direct read of local `AGENTS.project.md`, `CONTINUITY.md`, `COHERENCE.md`, `CLAUDE.md`, and `LINEAR.md`; coordinating audit trail in `/Users/gillettes/Coding Projects/Autonomous Coding Agent` `todo.md` for `GIL-37`.
- Implementation inputs: this repo's `todo.md` only.
- Fix: Added a local `Linear Issue Ledger` pointer for `GIL-37`, appended this Work Record, and added a `Completed` summary so the repo-principles rollout now has a durable local home in this repo instead of living only in the coordinating repo.
- Self-audit:
  - method: reread `todo.md` sections `Linear Issue Ledger`, `Completed`, and `Work Record Log` after edit.
  - outcome: pass — the coordinating rollout issue, the durable narrative, and the local landing summary now all exist in this repo.
  - method: `git diff --check`
  - outcome: pending at repo closeout.
  - did not verify: repo-specific runtime behavior because this repair only backfills governance records for already-landed principle surfaces.
- by: Codex
- triggered by: 2026-04-16 portfolio rollout full-audit in `/Users/gillettes/Coding Projects/Autonomous Coding Agent`
- led to: local durable-record backfill for the already-landed repo-principles rollout; coordinating issue `GIL-37`
- linear: GIL-37
