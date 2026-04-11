# AGENTS.project.md — Foreman Conventions

All AI agents (Codex, Claude Code, OpenClaw, Cursor, etc.) operating in any repo
using the foreman template MUST read this file before touching any file.

## 0. Communication Standard

**Be terse. Every token costs money.**

- One sentence beats a paragraph. A word beats a sentence.
- No preamble. No filler. No restating the task before doing it.
- No bullet lists unless structure genuinely helps comprehension.
- Commit messages: what changed and why, nothing else.
- Review verdicts: verdict, one-line summary, issues only if present.
- If a response feels long, cut it in half before sending.

When in doubt: say less.

---

## 1. Branch Naming

Every branch must follow this pattern:

```
agent/<tool>/<YYYY-MM-DD>/<slug>
```

Examples:
- `agent/codex/2026-04-09/add-stripe-webhooks`
- `agent/claude/2026-04-09/refactor-auth-service`
- `review/claude-of-codex/2026-04-09/add-stripe-webhooks`

Rules:
- `<tool>` is lowercase: `codex`, `claude`, `cursor`, `openclaw`, `human`
- `<slug>` is kebab-case, max 5 words, describes the task
- Review passes prefix with `review/<reviewer>-of-<coder>/`
- Never push directly to `main` or `master`

⚠️ **Phase 1 note:** As of Phase 2.1, the `pre-push` hook now warns on non-compliant
branch names. Set `FOREMAN_STRICT_BRANCH=1` to promote this to a hard gate.

---

## 2. Commit Trailer Schema

Every commit message MUST include these trailers after a blank line:

```
Agent: <tool and model, e.g. codex-5.3 or claude-sonnet-4-6>
Thread: <session/thread ID or URL — use "cowork" if from Cowork>
Task: <one-line description of the actual ask>
Verified-By: <comma-separated: pytest, ruff, mypy, build, manual, etc.>
Reviewed-By: <model that reviewed this diff, or "none-yet">
```

Full example:

```
Add Stripe webhook handler for payment events

Implements POST /webhooks/stripe, verifies signature,
dispatches to handlers by event type.

Agent: codex-5.3
Thread: https://platform.openai.com/codex/threads/t_abc123
Task: Add Stripe webhook handler with signature verification
Verified-By: pytest, ruff, mypy
Reviewed-By: claude-sonnet-4-6
```

Now that Phase 2 automated review runs from `hooks/pre-push`, `Reviewed-By:` is automatically
amended to the exact `reviewer_model` value by the pre-push hook when the reviewer runs
successfully. Manual population is still required for commits pushed with `--no-verify`.

**Phase 2 enforcement detail:**
- `commit-msg` hook **hard-rejects** commits missing `Agent`, `Thread`, `Task`, or `Verified-By`
- `Reviewed-By` is still **warning-only** at commit time — the hook warns but does not block
- `scripts/foreman-review.py` now returns the reviewer model name that should populate `Reviewed-By`
- Reviewer `BLOCKER` verdicts are a soft gate in Phase 2 and do not block pushes yet; Phase 2.1 may promote them after two weeks of validated use with no false `BLOCKER`s
- Set `FOREMAN_HARD_GATE=1` in your environment to enable hard blocking on `BLOCKER` verdicts. Default is soft gate (advisory only). Planned to become the default in Phase 2.1 after the two-week burn-in.
- Merge conditions (§ 3 below) still require a valid `Reviewed-By`; the gap is at commit time, not merge time

⚠️ **Cloud agent bypass:** The `commit-msg` hook only fires when git runs on the local machine.
Agents that commit from a remote cloud sandbox (confirmed: Codex Mac app) bypass it entirely.
Server-side enforcement via GitHub Actions is the implemented Phase 1.5 mitigation.

To bypass in a genuine emergency: `git commit --no-verify` (document why in DECISIONS.md).

---

## 3. Merge Conditions

A branch MAY be merged only when ALL of the following are true:

- [ ] All automated gates pass (tests, lint, type-check, build)
- [ ] `Reviewed-By:` is set to a different model than `Agent:`
- [ ] The reviewer verdict is APPROVE (not REQUEST_CHANGES, not BLOCKER)
- [ ] The task in the commit matches the ticket/issue that spawned the branch
- [ ] `BRANCH_LEDGER.md` row is updated to `ready` or `merged`

---

## 4. Task Brief

Before starting any non-trivial task, write a task brief to:
`.agent-runs/<YYYY-MM-DD>-<slug>/brief.md`

Template:

```markdown
## Task Brief

**Goal:** <one sentence>
**Context Files:** <list relevant files>
**Acceptance Criteria:**
- [ ] <testable criterion>
- [ ] <testable criterion>
**Out of Scope:** <what NOT to do>
**Constraints:** <style, perf, compat, security requirements>
**Model:** <which model will run this>
**Reasoning Level:** low | medium | high
**Estimated Cost Class:** cheap | medium | expensive
```

---

## 5. Model Routing Guide

Phase 2.1 routing policy:

| Task type | Model | Reasoning level |
|-----------|-------|-----------------|
| Standard feature work, refactors, test writing | Sonnet 4.6 | medium |
| Architecture, hard debugging, ambiguous requirements | Opus 4.6 | high |
| Reviewing another model's output | Different model than author | medium |

Notes:
- Phase 2.1 adds an optional Haiku classifier in `scripts/foreman-classify.py`, called by
  `scripts/foreman-dispatch.sh` unless `--no-classify` is used.
- The classifier returns `cheap`, `standard`, or `escalation`; confidence below `0.7`
  routes upward one tier, and any non-empty `escalation_triggers` forces escalation.
- The dispatcher only routes down to Haiku when the classifier says `cheap` and the brief
  already requests `low` reasoning. Otherwise the baseline remains Sonnet for normal work
  and Opus for escalations.
- Key rule: the reviewer must always be a different model than the one that wrote the code.

---

## 6. Branch Consolidation and Cleanup

When asked to merge, consolidate, close, or clean up branches, always use the repo-safe path:

1. Create a cleanup branch (`agent/<tool>/<date>/branch-cleanup` or similar)
2. Do all the work on that branch — land unmerged changes, update BRANCH_LEDGER.md, mark stale branches `abandoned`
3. Push the cleanup branch
4. Merge to main via PR or local merge

**Never use `--no-verify` to push consolidation work directly to main.** The hook blocking direct pushes to main is working correctly — it is not an obstacle to route around.

If branches are stale and have no unmerged work, mark them `abandoned` in BRANCH_LEDGER.md on the cleanup branch. You do not need to force-merge branches that contribute no net changes.

---

## 7. Autonomy Rules

The agent MAY:
- Create and edit files in its branch/worktree
- Run tests, lint, type-check, and build
- Commit to its own branch
- Ask clarifying questions by writing them to `.agent-runs/<slug>/questions.md`

The agent MUST NOT:
- Push to `main` or `master`
- Delete branches other than its own worktree
- Expose, log, or echo API keys or secrets
- Make changes affecting >10 files without first writing a plan and surfacing it

The agent MUST stop and surface a question if:
- Acceptance criteria are ambiguous
- Tests are failing and the fix is not obvious after 2 attempts
- A change would affect files outside the stated scope

---

## 7. Memory and Context

**Read only what the task requires. Every file you read costs context — don't read files you won't use.**

### Required for every session (no exceptions)
- `CLAUDE.md` — current state, open branches, gotchas, stack

### Read only for governance / audit / architectural work
- `DECISIONS.md` — only when making or reviewing architectural decisions
- `OPEN_QUESTIONS.md` — only when resolving or adding an open question
- `BRANCH_LEDGER.md` — only when opening, closing, or auditing branches

### Read only when explicitly relevant to the task
- Files in `memory/` — only when the task involves a specific project or person listed there
- `hooks/pre-push`, `hooks/commit-msg` — only when modifying or debugging hooks
- `scripts/foreman-dispatch.sh`, `scripts/foreman-review.py` — only when modifying those scripts

### Task type quick reference

| Task type | Read these — nothing more |
|-----------|--------------------------|
| Coding / feature / bug fix | `CLAUDE.md` + files being changed |
| Governance / audit / phase planning | `CLAUDE.md` + `AGENTS.md` + `DECISIONS.md` + `OPEN_QUESTIONS.md` + `BRANCH_LEDGER.md` |
| Hook or script modification | `CLAUDE.md` + `AGENTS.md` + the specific file being changed |
| Quick cleanup / docs fix | `CLAUDE.md` only |
| New task on an unfamiliar repo | `CLAUDE.md` + `AGENTS.md` |

`CLAUDE.md` is maintained specifically so it is the single file an agent needs to orient itself. If `CLAUDE.md` doesn't have enough context for a task, the right fix is to improve `CLAUDE.md` — not to add more mandatory reads.

After any significant decision, append an entry to `DECISIONS.md`.
After starting a new task, add a row to `BRANCH_LEDGER.md`.

---

## 8. Run Logging

`.agent-runs/<YYYY-MM-DD>-<slug>/` is optional local scratch space for active
debugging, task briefs, reviewer notes, or temporary outcome notes.

When used, recommended contents are:
- `brief.md` — the task brief
- `review.md` — a second-model review note
- `outcome.md` — a local summary of what was done

This folder is **not** the primary audit trail. It may be gitignored and may not
survive a re-clone.

The durable audit artifact is the commit history plus tracked repo records:
- commit trailers (`Agent`, `Thread`, `Task`, `Verified-By`, `Reviewed-By`)
- `BRANCH_LEDGER.md`
- `DECISIONS.md`
- tracked audit/history entries in `todo.md` when present

If a result must survive beyond the current machine or active debug loop, record
it in a committed file or in the commit trailer schema instead of relying on
`.agent-runs/` alone.

---

## 9. Hooks

Run `hooks/install.sh` once after cloning this template into a new project.

- `commit-msg` — hard-rejects commits missing `Agent`, `Thread`, `Task`, `Verified-By`; warns on missing/none-yet `Reviewed-By`; skips merge commits, `fixup!`, `squash!`, `WIP`, and `wip` based on the commit subject
- `pre-push` — heuristic gate: warns on non-compliant branch names by default (`FOREMAN_STRICT_BRANCH=1` makes that blocking), autodetects Python (pytest, ruff, optional mypy), Node (npm test/lint/build), or Makefile; reports all results; blocks on any failure; blocks direct push to `main`, `master`, `production`, `prod`; then runs the Phase 2 reviewer as a soft gate (`FOREMAN_HARD_GATE=1` makes `BLOCKER` verdicts blocking) using `main...HEAD` with fallback to `origin/main...HEAD`

Note: both hooks are **local only**. They do not fire for agents that commit from a remote sandbox.

## Global Mandatory Markers
- [MANDATORY_STACK_RUNTIME] stack/runtime profile, risk areas, release gates, boundaries, rollback/ops checks
- [MANDATORY_OPERATING_PRINCIPLES] operating principles aligned to `OPERATING_PRINCIPLES.md`
- [MANDATORY_PROJECT_INTENT] canonical project intent documentation + behavior aligned to `PROJECT_INTENT_ALIGNMENT.md`
- [MANDATORY_TODO_ADD] add follow-up work to project `todo.md`
- [MANDATORY_TODO_SUGGESTIONS] maintain a persistent `Suggested Recommendation Log` in `todo.md`; record every materially new suggested action there, avoid duplicate entries by reusing matching items, keep history instead of deleting entries, and check items off when completed
- [MANDATORY_TODO_CHECKOFF] auto-check completed verified `todo.md` items
- [MANDATORY_PLAN_TRACKING] capture durable chat-created plans in `todo.md` by recording the overall goal plus concrete steps, then mark them complete in the same file/log when verified
- [MANDATORY_FEEDBACK_DECISIONS] maintain a durable `Feedback Decision Log` in root `todo.md`; record outside feedback, the reasoning response, final decision, and any linked implementation/audit/test evidence there; update existing entries instead of duplicating the same feedback thread
- [MANDATORY_TESTING_GOVERNANCE] testing is required delivery evidence; keep `Test Evidence Convention`, `Test Evidence Log`, and `Testing Cadence Matrix` in root `todo.md`, and document what ran or what remains untested
- [MANDATORY_BRANCH_LIFECYCLE] maintain `Active Branch Ledger` and `Branch History` in root `todo.md`; every non-trivial branch must record purpose, responsible/source chat, last refreshed by chat, merge expectation, exit checklist, delete-vs-retain outcome, retain reason when applicable, and delete/cleanup trigger
- [MANDATORY_WORKTREE] one-worktree-per-chat rule for concurrent chats in same repo
- [MANDATORY_PRAGMATIC] pragmatic improvement mindset
- [MANDATORY_FULL_AUDIT] full-audit behavior aligned to `FULL_AUDIT.md`
- [MANDATORY_NEXT_STEPS] next-steps behavior aligned to `NEXT_STEPS_ORCHESTRATION.md`, including `todo.md`-grounded and independently inferred recommendations with a reasoning level for every suggested item; when an audit or the current chat creates or discovers more urgent execution-ready work, persist and move those items to the top of `Active Next Steps` and reserve `Suggested Recommendation Log` for deferred, optional, or not-yet-execution-ready items; if none remain, explicitly state `No further steps required.`
- [MANDATORY_CLARIFY] ask focused clarifying question(s), explain the conflict/misalignment, and pause risky changes until clarified
- [MANDATORY_CREDIT_IMPACT] prioritize correctness/reliability and flag significant low-upside credit waste with efficient reliable alternatives
- [MANDATORY_NO_COMMIT_BLOCK] verification commands provide evidence and do not block commits/pushes unless the user explicitly requests strict gates
- [MANDATORY_NO_APPROVAL_PROMPTS] execute requested actions end-to-end without repeated approval prompts; ask only when blocked by platform constraints or missing requirements
- [MANDATORY_IGNORE_UNRELATED_CHANGES] treat unrelated tracked edits as valid concurrent work; do not block execution/cleanup, and never revert them unless explicitly requested
- [MANDATORY_COMMIT_OWN_CHANGES] commit every file edited in the current task before completion unless the user explicitly says not to; never let unrelated dirty state prevent committing task files
- [MANDATORY_AUTO_PUSH] after edits in a git repository, automatically commit and push every task-touched file that remains changed unless the user explicitly says not to push; if push fails, stop and report the exact failing command/output
- [MANDATORY_TASK_CLASSIFICATION] classify task tier per `TASK_CLASSIFICATION.md`; match verification depth and playbook loading to tier
- [MANDATORY_TRUST_GATE] evaluate Trust Gate triggers at session intake per `session-intake-closeout` skill; when `on`, require `Evidence Checked`, `Decision Status` labels (`Confirmed` / `Inferred` / `Needs More Evidence` / `Do Not Do Yet`), `Challenge Findings`, and `Unresolved` sections at closeout; no polished final recommendation for uncertain items
- [MANDATORY_ANTI_THRASH] after 2 grounded attempts at the same problem, narrow scope, request the smallest missing artifact, or escalate; do not retry unchanged approach

## Communication Defaults
- Default to terse execution. Assume the user wants the shortest useful response unless they ask for depth.
- Keep routine implementation closeouts compact: outcome + verification + blocker/risk only.
- Do not restate obvious plans, commands, or touched files unless they materially help the user.
- Trust-gated or other high-stakes answers should still include required sections, but keep them compact and decision-focused.
