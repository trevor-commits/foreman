# AGENTS.md — Foreman Conventions

All AI agents (Codex, Claude Code, OpenClaw, Cursor, etc.) operating in any repo
using the foreman template MUST read this file before touching any file.

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

The `commit-msg` hook enforces this. To bypass in a genuine emergency: `git commit --no-verify`.

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

Use this until a dispatcher script is in place:

| Task type | Model | Reasoning level |
|-----------|-------|-----------------|
| Trivial edits, renames, small isolated fixes | Haiku 4.5 | low |
| Standard feature work, refactors, test writing | Sonnet 4.6 | medium |
| Architecture, hard debugging, ambiguous requirements | Opus 4.6 | high |
| Reviewing another model's output | Different model than author | medium |

Key rule: the reviewer must always be a different model than the one that wrote the code.

---

## 6. Autonomy Rules

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

Before every session, read:
1. `CLAUDE.md` (working memory — current state, open threads, gotchas)
2. Relevant files in `memory/` (projects, people, decisions)
3. `DECISIONS.md` (architectural decisions and their reasoning)
4. `BRANCH_LEDGER.md` (what's currently open and why)

After any significant decision, append an entry to `DECISIONS.md`.
After starting a new task, add a row to `BRANCH_LEDGER.md`.

---

## 8. Run Logging

Each agent run gets a folder: `.agent-runs/<YYYY-MM-DD>-<slug>/`

Minimum contents:
- `brief.md` — the task brief (written before starting)
- `review.md` — the second-model reviewer's verdict (written after)
- `outcome.md` — what was done, what passed, what was skipped, final status

This is how you reconstruct what happened when an overnight run goes sideways.

---

## 9. Hooks

Run `hooks/install.sh` once after cloning this template into a new project.

- `commit-msg` — rejects commits missing required trailers
- `pre-push` — runs tests/lint/build gate; blocks direct push to main/master
