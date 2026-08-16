# foreman

A lightweight convention system for AI-assisted coding.

Gives your agents branch provenance, commit traceability, external verification
gates, and a foundation for cross-model review — without requiring a full
orchestration platform before it's needed.

Built on a core insight from the community and confirmed by GitHub's own tooling:
**one model should not grade its own homework.** Foreman makes the conventions that
enforce this portable, consistent, and repo-visible across all your projects.

---

## The Problem

When multiple AI agents (Codex, Claude Code, Cursor, etc.) are running across several
projects, three things go wrong fast:

- Branches pile up with no record of why they exist or when they can merge
- Commits carry no metadata linking them to the task or model that wrote them
- There's no external check — the model evaluates its own output

Foreman fixes all three with files and conventions, not new infrastructure.

---

## What's Here

| File / Dir | Purpose |
|-----------|---------|
| `AGENTS.md` | Entry contract every AI agent reads first; defines the required read order |
| `AGENTS.project.md` | Authoritative repo-local guidance — conventions, current state, open branches, gotchas |
| `CLAUDE.md` | Routing shim that sends Claude to `AGENTS.md`; carries no project state |
| `BRANCH_LEDGER.md` | Canonical record of every open agent branch (source of truth) |
| `DECISIONS.md` | Architectural decisions and their reasoning |
| `memory/` | Durable knowledge: projects index, people, context |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template with agent metadata and review fields |
| `hooks/commit-msg` | Rejects commits missing required trailers |
| `hooks/pre-push` | Runs tests/lint/build gate; blocks direct push to main |
| `hooks/install.sh` | Installs the two hooks into `.git/hooks/` |
| `.gitignore` | Ignores agent run logs, OS files, secrets |

---

## Quick Start

### Using foreman as a template for a new project

```bash
# Clone foreman into your new project folder
git clone git@github.com:trevor-commits/foreman.git my-new-project
cd my-new-project

# Point it at your new repo
git remote set-url origin git@github.com:yourusername/my-new-project.git

# Install the hooks
bash hooks/install.sh

# Personalize the files
# 1. AGENTS.project.md — add project overview, stack, current focus
# 2. BRANCH_LEDGER.md — clear the placeholder row
# 3. memory/projects.md — add this project's entry
# 4. DECISIONS.md  — keep or delete the foreman setup entries

# Push
git push -u origin main
```

### Adding foreman conventions to an existing project

```bash
# From your existing project root, grab just the files you need:
curl -sO https://raw.githubusercontent.com/trevor-commits/foreman/main/AGENTS.md
curl -sO https://raw.githubusercontent.com/trevor-commits/foreman/main/AGENTS.project.md
curl -sO https://raw.githubusercontent.com/trevor-commits/foreman/main/CLAUDE.md
curl -sO https://raw.githubusercontent.com/trevor-commits/foreman/main/BRANCH_LEDGER.md
curl -sO https://raw.githubusercontent.com/trevor-commits/foreman/main/DECISIONS.md

mkdir -p hooks memory .github
curl -so hooks/commit-msg https://raw.githubusercontent.com/trevor-commits/foreman/main/hooks/commit-msg
curl -so hooks/pre-push   https://raw.githubusercontent.com/trevor-commits/foreman/main/hooks/pre-push
curl -so hooks/install.sh https://raw.githubusercontent.com/trevor-commits/foreman/main/hooks/install.sh
curl -so .github/PULL_REQUEST_TEMPLATE.md \
  https://raw.githubusercontent.com/trevor-commits/foreman/main/.github/PULL_REQUEST_TEMPLATE.md

bash hooks/install.sh
```

---

## The Commit Trailer Schema

Every commit must include these trailers after a blank line:

```
Agent: claude-opus-5
Thread: https://...session-url...
Task: Add Stripe webhook handler with signature verification
Verified-By: pytest, ruff, mypy
Reviewed-By: codex-5.3
```

The `commit-msg` hook enforces `Agent`, `Thread`, `Task`, and `Verified-By`.
`Reviewed-By` is warning-only in Phase 2, and Phase 2.1 is the decision point for whether
that should become stricter later.

To bypass in a genuine emergency: `git commit --no-verify` (document why in DECISIONS.md).

---

## Branch Naming

```
agent/<tool>/<YYYY-MM-DD>/<slug>
```

| Example | Meaning |
|---------|---------|
| `agent/codex/2026-04-09/add-stripe-webhooks` | Codex working on Stripe integration |
| `agent/claude/2026-04-09/refactor-auth-service` | Claude Code refactoring auth |
| `review/claude-of-codex/2026-04-09/add-stripe-webhooks` | Claude reviewing Codex's stripe branch |

The `pre-push` hook blocks direct pushes to `main`, `master`, `production`, and `prod`.
It also warns on non-compliant branch names by default; `FOREMAN_STRICT_BRANCH=1` makes that blocking.

---

## Model Routing (Phase 2.1 guide)

| Task type | Model | Reasoning level |
|-----------|-------|-----------------|
| Standard feature work, refactors, writing tests | Claude Opus 5 | medium |
| Architecture, hard debugging, ambiguous requirements | Claude Opus 5 | high |
| Reviewing another provider's output | Claude Opus 5 | medium/high |

Phase 2.1 uses exact `claude-opus-5` for every Claude request. The optional classifier changes
route labels and reasoning only; Claude-authored work requires an independent provider for cross-model review.

---

## Known Limitation: Cloud Agents Bypass Local Hooks

Phase 1 hooks run on your local machine. Any agent that operates in a remote cloud
sandbox — cloning your repo, committing, and pushing back without touching your
filesystem — will bypass them entirely.

**Confirmed affected:** Codex Mac app (proven by two trailer-less commits landing on
Taxes `main` in the first real-world Phase 1 audit, April 9 2026).

**Likely affected:** any GUI-based cloud AI coding tool that manages its own git sandbox.

**Not affected:** Codex CLI, Claude Code CLI, and any agent invoked locally.

**Phase 1.5 mitigation now active:** `.github/workflows/foreman-trailer-check.yml`
validates the required trailers server-side on pushes and pull requests to `main`.
This closes the known cloud-agent bypass gap for trailer enforcement even though the local
hooks are still the main authoring-time safety net. See `DECISIONS.md` for the Phase 1.5
resolution.

**Long-term:** Phase 3 remains container/sandbox isolation, but the exact backend is
deferred pending the OpenHands evaluation. Phase 4-style orchestration is likewise contingent
on what that evaluation proves unnecessary.

**Recommendation:** For foreman-governed work, still prefer CLI agents (Claude Code,
Codex CLI) over cloud-sandbox GUIs because the local hook path and reviewer flow remain
the most controllable authoring path even though trailer enforcement now also exists
server-side. See `DECISIONS.md` entry "Codex Mac App Is Not the Primary Agent Interface"
for full context.

---

## The Four Phases

Foreman is built in phases so you fix the most painful thing first without
overbuilding before you understand your actual failure modes.

**Phase 1 — Branch clarity and external gates** ✅ *this repo*
- Branch ledger (BRANCH_LEDGER.md) as the durable source of truth
- Branch naming convention
- Commit trailer schema
- pre-push gate (tests + lint + build)
- commit-msg hook
- ⚠️ Local hooks only — cloud-sandbox agents bypass them (see Known Limitation above)

**Phase 1.5 — Server-side enforcement** ✅ *implemented*
- GitHub Actions workflow validating the trailer schema on every push and pull request to `main`
- Branch protection can require that workflow where the downstream repo enables it
- Closes the cloud-agent bypass gap without requiring Phase 2 infrastructure

**Phase 2 — Cross-model reviewer script** ✅ *implemented as a soft gate*
- `scripts/foreman-review.py` reviews a diff against `main...HEAD`, with fallback to `origin/main...HEAD`, and requires a strict JSON verdict schema
- `hooks/pre-push` now prints the reviewer verdict on every non-empty diff after the normal test/lint/build gates run
- `BLOCKER` is advisory by default; `FOREMAN_HARD_GATE=1` promotes it to a hard gate while verdict quality is validated in real use

**Phase 2.1 — Routing + rollout controls** ✅ *partially implemented*
- `scripts/foreman-classify.py` adds an optional Opus 5 classifier for dispatch routing
- `hooks/pre-push` now warns on non-compliant branch names by default; `FOREMAN_STRICT_BRANCH=1` makes that blocking
- live API-path validation and any default promotion decisions remain open follow-up work

**Phase 3 — Dagger Container Use** *(after Phase 2 is stable)*
- Each agent gets its own isolated container + git worktree
- Local hooks fire inside the container → all agents covered
- Deny-by-default network policy
- Credential proxying so agents never see raw tokens
- Safe for unattended overnight runs

**Phase 4 — OpenClaw orchestration** *(if still needed after Phase 3)*
- Persistent multi-agent coordination across projects
- ACP harness: one orchestrator spawning Claude Code + Codex as sub-agents
- Adds when you want programmable, cross-device, cross-channel orchestration

---

## Why These Decisions Were Made

See `DECISIONS.md` for the full reasoning behind every convention in this repo.
The short version:

- Branch ledger over chat threads → chat threads are ephemeral and tool-specific;
  a committed Markdown file survives tool changes and re-clones
- Phase 1 before orchestration → building a control plane before fixing branch
  hygiene creates a new tooling project instead of reducing chaos
- Reviewer must differ from author → one model cannot reliably detect its own
  blind spots; validated by GitHub, Meta, and the developer community independently
