# PROJECT_INTENT

## Purpose
Foreman is Trevor Gillette's lightweight convention template for AI-assisted coding across his repositories.

## Problem Statement
When multiple AI agents work across several repos, branch purpose disappears, commits lose task/model provenance, and local-only hooks are not enough to enforce consistent review and verification rules. Foreman solves that with repo-visible conventions, tracked records, and lightweight automation instead of a full orchestration platform.

## Target Users and Top Jobs
- Primary users: Trevor Gillette and AI agents operating in his repos
- Top jobs:
  - start work on a branch with clear provenance, merge expectations, and durable handoff context
  - make every commit traceable to the tool, task, and verification that produced it
  - enforce minimum review and verification rules across repos without building a large control plane too early

## In-Scope Outcomes
- Phase 1: branch naming, commit trailers, `BRANCH_LEDGER.md`, local `commit-msg` and `pre-push` hooks, and PR metadata
- Phase 1.5: GitHub Actions trailer enforcement on pushes and pull requests to `main`
- Phase 2: `scripts/foreman-review.py`, reviewer wiring in `hooks/pre-push`, and reviewer-backed `Reviewed-By` guidance
- Phase 2.1: optional classifier routing in `scripts/foreman-classify.py`, branch-name warning enforcement, and opt-in hard-gate rollout via `FOREMAN_HARD_GATE`
- durable governance records in `AGENTS.md`, `CLAUDE.md`, `DECISIONS.md`, and repo-visible branch history
- a shell dispatcher scaffold (`scripts/foreman-dispatch.sh`) that reads a brief, resolves model defaults, proposes a compliant branch name, and checks for installed hooks

## Explicit Non-Goals
- full orchestration, dashboards, or supervisor infrastructure before the conventions prove their value
- treating cloud-sandbox GUI agents as a primary governed write path
- replacing project-local implementation docs or project-specific release logic
- making reviewer hard-blocking by default before the Phase 2.1 burn-in is validated, or shipping Phase 3 / Phase 4 orchestration before they are justified

## Success Metrics and Guardrails
- Leading metrics: open branches are explainable from repo files; commits carry the required trailers; non-compliant pushes are caught locally or server-side
- Lagging metrics: less branch drift, clearer task provenance, and easier cross-repo handoff/audit recovery
- Guardrails: keep the system lightweight, repo-visible, and portable; prefer files and small scripts over new infrastructure; require a different reviewer model than the author at merge time

## Technical Strategy and Stack Rationale
- Current project type: `generic`
- Stack: Markdown plus shell scripts so the conventions stay language-agnostic and easy to copy into other repos
- Strategy: solve the highest-value coordination problems first with conventions and small tools, then add automation only where real usage proves it is needed

## Constraints, Assumptions, Risks, and Invalidation Triggers
- Constraints: solo-operator scale, mixed downstream stacks, and the need to support multiple AI tools without assuming one vendor or runtime
- Assumptions: CLI-based agents are the safe primary governed write path; lightweight repo-native records are easier to maintain than a separate control system
- Risks: cloud agents can bypass local hooks, downstream copies of governance docs can drift, and Phase 2+ automation can be overbuilt
- Invalidation triggers: if the lightweight model fails to control branch/review hygiene, if manual propagation becomes too error-prone, or if real usage shows orchestration is needed sooner

## Open Questions and Decision Records
- Open questions: `Reviewed-By` hard enforcement and the eventual MCP server implementation remain in `OPEN_QUESTIONS.md`
- Key decisions: branch ledger as source of truth, commit trailers as the durable audit trail, and Phase 1.5 server-side trailer enforcement in `DECISIONS.md`
