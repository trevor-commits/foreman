# Architectural Decisions

A running log of non-trivial decisions and the reasoning behind them.
Add new entries at the top. One entry per decision. Be concise but complete —
future agents and humans need to understand the "why," not just the "what."

Entry format:
```
## YYYY-MM-DD — <Decision Title>
**Decision:** <what was decided>
**Why:** <reasoning>
**Alternatives Considered:** <what was rejected and why>
**Agent:** <which model proposed or made this decision>
**Context:** <branch or thread this came from>
```

---

## 2026-04-09 — Branch Ledger is the Durable Source of Truth

**Decision:** `BRANCH_LEDGER.md` is the canonical record for open agent branches.
Chat thread IDs and session URLs are metadata attached to ledger rows, not the
primary record.

**Why:** Chat threads are tool-specific and ephemeral. If Trevor stops using Codex,
or switches from Claude Code to OpenClaw, thread URLs become unreachable. A committed
Markdown file in the repo survives tool changes, account changes, and re-clones.

**Alternatives Considered:** Using Codex thread IDs as the source of truth (rejected:
not durable, not repo-visible, breaks when switching tools). Using GitHub issues as
the source of truth (rejected: overkill for personal projects, adds friction for
small tasks).

**Agent:** claude-sonnet-4-6 / audited by codex-5.3
**Context:** Foreman initial setup session, April 9 2026

---

## 2026-04-09 — Phased Rollout: Branch Conventions Before Orchestration

**Decision:** Build in four phases. Phase 1 is branch naming, commit trailers, and
gate hooks. Phases 2–4 add cross-model review, container isolation, and orchestration
— only after Phase 1 is stable and the real pain points are understood.

**Why:** Building the full system at once (dispatcher + hooks + multi-agent harness +
observability + dashboards) creates a new tooling project instead of reducing chaos.
The most immediate pain is "I don't know what this branch is or why it exists."
That is solved entirely by Phase 1 without any infrastructure.

**Alternatives Considered:** Full orchestration from day one via OpenClaw (rejected:
too heavy, requires learning a new system before the fundamentals are solid). Single
monolithic script that does dispatch + review + logging (rejected: hard to debug,
hard to evolve, couples too many concerns).

**Agent:** claude-sonnet-4-6 / audited by codex-5.3
**Context:** Foreman initial setup session, April 9 2026

---

## 2026-04-09 — Reviewer Must Always Be a Different Model Than Author

**Decision:** The `Reviewed-By:` trailer must name a different model from `Agent:`.
The pre-push hook does not enforce this mechanically in Phase 1, but the principle
is treated as mandatory. Phase 2 will enforce it programmatically.

**Why:** One model reviewing its own output produces overconfident verdicts. The most
reliable pattern from the community is cross-model review: Codex codes, Claude reviews
(or vice versa). This was validated independently by GitHub (Copilot CLI second-opinion
feature, April 6 2026) and Meta (semi-formal verifier work, March 2026).

**Alternatives Considered:** Single-model self-review with chain-of-thought critique
(rejected: model still has the same blind spots). No formal review step (rejected:
defeats the purpose of a multi-agent setup).

**Agent:** claude-sonnet-4-6 / audited by codex-5.3
**Context:** Foreman initial setup session, April 9 2026

---

## 2026-04-09 — Adopted Foreman Template

**Decision:** Use a shared convention repo ("foreman") as the base for all AI-assisted
projects. New projects clone or copy from it. Conventions are defined once and drift
is visible via git diff against the template.

**Why:** Multiple personal projects were each developing ad-hoc conventions. Branches
were untraceable, commits had no metadata, there was no external verification gate,
and there was no audit trail for overnight agent runs. A single template repo makes
the conventions portable and improvable.

**Alternatives Considered:** Per-project ad-hoc conventions (rejected: they diverge,
drift, and require reinventing every decision). Full platform like Linear or Jira
(rejected: overkill for personal projects, too much overhead for solo work).

**Agent:** claude-sonnet-4-6
**Context:** Foreman initial setup session, April 9 2026
