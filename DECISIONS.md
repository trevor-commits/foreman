# Architectural Decisions

## 2026-08-11 — Exact Opus 5 for Claude; independent provider for Claude-authored review

**Decision:** Every active Claude selector in Foreman uses exact `claude-opus-5`. A conflicting Claude selector fails before provider access. When Claude authored the work, Foreman uses OpenAI for independent review and does not fall back to another Claude tier.

**Why:** Trevor made Opus 5 the global Claude standard. Lower Claude tiers violate that rule, and another invocation of the same Claude model is not an independent model-family review.

**Alternatives Considered:** silently rewriting old selectors (rejected because configuration drift should be visible); using Opus 5 to review Opus 5 work (rejected as same-family review); skipping direct SDK guards and relying only on the public CLI wrapper (rejected because Foreman calls Anthropic directly).

**Agent:** Codex GPT-5.6
**Context:** Global ER-930, Codex thread `019ff1e7-a4f1-7841-a6b7-99c783643ff5`.

---

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

## 2026-04-11 — Foreman Uses FastMCP From The Official `mcp` Package

**Decision:** Use FastMCP from the official `mcp` package for foreman's real MCP server. The
server lives at `scripts/foreman-mcp-server.py` and exposes the same governance tool surface
already defined by `scripts/foreman-mcp-shim.py`.

**Why:** The `mcp` package is Anthropic-maintained, directly compatible with Claude Code's MCP
client, and keeps the server implementation small. The tool-decorator pattern maps cleanly to
the shim structure already in place, so the real server can stay transport-focused while the
existing shim remains the shared wrapper around foreman's governance scripts and ledger logic.

**Alternatives Considered:** Keep only the CLI shim with no real MCP server yet (rejected:
the framework decision is now resolved and the real integration path is needed). Use a lower-
level custom server or alternative SDK (rejected: more boilerplate and less direct alignment
with Claude Code and Claude desktop for no current benefit).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 FastMCP server implementation

---

## 2026-04-11 — Reviewer Hook Defers Provider Detection To `foreman-review.py`

**Decision:** The `pre-push` hook now resolves its diff base from explicit refs (`refs/heads/main`, then `refs/remotes/origin/main`) and always hands the diff to `scripts/foreman-review.py` when `python3` and the script itself are available. The shell hook no longer pre-checks for the `anthropic` package.

**Why:** The review script already owns provider routing and dependency/key fallback. Keeping a second provider-specific dependency check in shell created drift: valid OpenAI review paths and Anthropic-fallback paths could be skipped before the Python logic ever ran. Explicit local-vs-remote main resolution also fixes fresh-clone repos that only have `origin/main`, where ambiguous abbreviated ref resolution could say `main` existed even though `git diff main...HEAD` still failed.

**Alternatives Considered:** Keep the shell-level Anthropic pre-check (rejected: duplicates provider logic and skips valid review paths). Require a local `main` branch for review (rejected: breaks fresh clones and retained-branch workflows unnecessarily). Teach the hook both provider SDKs in shell (rejected: pushes application logic back into the least suitable layer).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 full audit and remediation pass

---

## 2026-04-11 — MCP Tool Surface Is Scaffolded As A Shim

**Decision:** Added `docs/mcp-tools.md` and `scripts/foreman-mcp-shim.py` to define and exercise the planned foreman MCP tool surface. Full MCP server implementation is deferred until OpenHands evaluation confirms the backend choice.

**Why:** The April 10 architecture decision identified MCP as the right boundary regardless of whether OpenHands, Codex CLI, Claude Code, or another backend ends up owning execution in Phase 3. A shim is the cheapest way to validate the interface contract now: it proves the tool inputs and outputs are coherent, wraps the existing review/dispatch/classify scripts, and keeps the ledger operations small and explicit without prematurely choosing a server framework.

**Alternatives Considered:** Building a full MCP server immediately with FastMCP or the Python MCP SDK (rejected: backend choice is still open, so locking into a framework now would be premature). Deferring all MCP work until after the OpenHands decision (rejected: the interface boundary itself is worth validating before the server framework choice is made).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 MCP-as-boundary scaffold

---

## 2026-04-11 — Branch Naming Validation Starts As A Warning In Pre-Push

**Decision:** Added branch-name validation to the `pre-push` hook using the foreman branch pattern. Non-compliant names warn by default, and `FOREMAN_STRICT_BRANCH=1` promotes the warning to a hard gate.

**Why:** This closes the gap between documented branch naming rules and actual local enforcement without surprising existing workflows with a sudden hard block. The env flag mirrors `FOREMAN_HARD_GATE` and makes it easy to test or opt into stricter hygiene per machine before deciding whether hard enforcement should become the default.

**Alternatives Considered:** Hard-block all non-compliant branch names immediately (rejected: too abrupt for a rule that was previously discipline-only). Leave naming entirely advisory in docs (rejected: the repo had already outgrown pure convention here).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 Phase 2.1 branch validation rollout

---

## 2026-04-11 — Phase 2.1 Adds An Optional Haiku Task Classifier

**Decision:** Added `scripts/foreman-classify.py` and wired it into `scripts/foreman-dispatch.sh` as an optional classifier step. The classifier uses Haiku to return `cheap`, `standard`, or `escalation`, routes upward when confidence is below `0.7`, and forces `escalation` whenever `escalation_triggers` is non-empty. `--no-classify` skips the classifier.

**Why:** This adds cheap routing signal without making it the default source of truth. The upward-only confidence policy is conservative by design: uncertain tasks get promoted rather than under-routed, and specific escalation triggers always win. That preserves Sonnet as the safe default while allowing clearly cheap, low-reasoning tasks to drop to Haiku when the brief already says that is appropriate.

**Alternatives Considered:** Leaving routing fully manual until more telemetry exists (rejected: the classifier is now bounded, optional, and conservative enough to test safely). Allowing low-confidence results to keep their original route (rejected: too likely to under-route ambiguous work). Making the classifier mandatory with no skip flag (rejected: harder to test, debug, or bypass when cost or determinism matters).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 Phase 2.1 classifier rollout

---

## 2026-04-11 — FOREMAN_HARD_GATE Enables Phase 2.1 Hard-Gate Rollout

**Decision:** Added the `FOREMAN_HARD_GATE` environment flag to the `pre-push` hook so a reviewer `BLOCKER` verdict can be promoted to a hard gate without editing hook code.

**Why:** This allows gradual per-machine rollout and easy testing without committing to a hard gate system-wide before the two-week burn-in is confirmed.

**Alternatives Considered:** Hard-coding the hook to block every `BLOCKER` immediately (rejected: too aggressive before the burn-in is complete). Leaving the hook permanently advisory until a later code edit (rejected: makes rollout and testing slower than necessary).

**Agent:** codex-gpt-5
**Context:** 2026-04-11 Phase 2.1 hook rollout

---

## 2026-04-10 — OpenHands and MCP as Candidate Replacements for Phases 3–4

**Decision:** Defer a final architecture decision on Phases 3 (Dagger container isolation) and 4 (OpenClaw orchestration), pending evaluation of OpenHands as a combined replacement for both. MCP tool wrapping is identified as the preferred long-term interface boundary regardless of which execution backend wins.

**Why:** Bible AI's post-launch architecture session (2026-04-10, captured in `bible-brain-vision.md`) identified OpenHands (formerly OpenDevin) as a sandboxed autonomous coding agent that already provides what Phases 3 and 4 are intended to provide separately: isolated execution environments, iterative code runs, and MCP tool support. Rather than building Dagger container isolation and then an OpenClaw orchestration layer on top of it, OpenHands may satisfy both requirements in one framework. Evaluating it before committing to the Phase 3/4 build avoids over-engineering.

The MCP-as-boundary pattern applies directly to foreman: repo governance operations (branch ledger queries, trailer validation, review dispatch) should eventually be exposed as MCP tools so any agent backend — OpenHands, Codex CLI, Claude Code — interacts through a uniform interface rather than foreman-specific shell scripts.

**Alternatives Considered:** Proceeding with Dagger (Phase 3) as planned (deferred: evaluate OpenHands first since it may make Dagger unnecessary). Adopting OpenHands immediately (rejected: need to validate it fits the foreman governance model before committing). Skipping both phases entirely (rejected: sandboxed execution is still the right long-term goal; the question is how to get there).

**Agent:** claude-sonnet-4-6
**Context:** 2026-04-10 cross-project architecture review

---

## 2026-04-10 — Phase 2 Reviewer Uses Python, Not Shell

**Decision:** The Phase 2 automated reviewer is implemented as `scripts/foreman-review.py`
in Python instead of extending the shell dispatcher or shell hook logic to make API calls
directly.

**Why:** The reviewer must call external APIs, parse strict JSON reliably, handle large
multi-line diffs without shell quoting bugs, and grow into structured output and fallback
logic. Python is the safer implementation language for that job, while shell remains
appropriate for small orchestration tasks such as branch setup and hook entrypoints.

**Alternatives Considered:** Extending the shell prototype into a shell reviewer (rejected:
fragile JSON parsing, weak multiline handling, and harder future API/schema support). Moving
the whole dispatcher into Python immediately (rejected for now: the shell dispatcher already
handles the current scaffolding use case and does not need the same complexity yet).

**Agent:** codex-gpt-5
**Context:** 2026-04-10 Phase 2 reviewer implementation

---

## 2026-04-10 — Phase 2 Reviewer Starts As A Soft Gate

**Decision:** The Phase 2 reviewer verdict is advisory in the `pre-push` hook. The hook
prints `APPROVE`, `REQUEST_CHANGES`, or `BLOCKER`, but a reviewer `BLOCKER` does not stop
the push yet. Promotion to a hard gate is deferred to Phase 2.1 after two weeks of real use
with no false `BLOCKER`s.

**Why:** Cross-model review is the core value of foreman, but the system has not yet earned
the right to block pushes automatically. A soft gate preserves the new signal immediately
while collecting enough real-world data to determine whether the reviewer is trustworthy.
A false `BLOCKER` means the reviewer claims a correct change is broken, unsafe, or
non-compliant when it is actually valid.

**Alternatives Considered:** Hard gate from day one (rejected: too risky before reviewer
quality is calibrated). Reviewer output as a local-only manual step outside the hook
(rejected: too easy to skip and not visible enough to shape behavior).

**Agent:** codex-gpt-5
**Context:** 2026-04-10 Phase 2 reviewer implementation

---

## 2026-04-10 — Phase 2 Model Routing Skips The Haiku Classifier

**Decision:** Resolved OPEN_QUESTIONS.md #1. Phase 2 does not add a Haiku classifier yet.
All real implementation work defaults to Sonnet-level routing, and the classifier is deferred
to Phase 2.1 after the reviewer is stable.

**Why:** The current task volume is too small to calibrate a classifier well, and a cheap
router would add complexity before there is enough data to tune confidence thresholds or
measure misroutes. The immediate value is the cross-model reviewer, not another decision
layer ahead of it.

**Alternatives Considered:** Adding the Haiku classifier in Phase 2 (rejected: extra moving
parts before enough task volume exists to justify them). Sending trivial implementation work
to Haiku immediately (rejected: not enough evidence yet that the savings outweigh the review
and routing complexity). Deferring all routing guidance (rejected: Phase 2 still needs a
clear default).

**Agent:** codex-gpt-5
**Context:** 2026-04-10 Phase 2 reviewer implementation

---

## 2026-04-10 — Downstream Governance Docs Stay Manually Mirrored

**Decision:** Chose Option A. Downstream repos keep their own `OPEN_QUESTIONS.md` and
`DECISIONS.md` copies. Cross-cutting foreman governance decisions are propagated manually
during agent sessions when they materially affect a downstream repo.

**Why:** At current solo-operator scale, manual mirroring is the safer and lower-risk choice.
It avoids adding cross-repo symlink/reference coupling or a sync script that itself would
need maintenance, trust, and failure handling. The current downstream set is small enough
that occasional manual propagation is cheaper than adding more machinery now.

**Alternatives Considered:** Option B — canonical foreman-only docs with downstream repos
referencing the foreman copy (rejected: creates cross-repo coupling and makes downstream
context less self-contained). Option C — add a sync script (rejected: more moving parts than
the current scale justifies, and another tool agents would need to remember to run).

**Agent:** codex-gpt-5
**Context:** 2026-04-10 cleanup pass

---

## 2026-04-09 — Commit Trailers Are The Durable Audit Trail

**Decision:** `.agent-runs/` is optional local scratch space only. The durable audit trail
for foreman-governed work is the commit trailer schema plus tracked repo-visible records
such as `BRANCH_LEDGER.md`, `DECISIONS.md`, and `todo.md` audit/history entries.

**Why:** `.agent-runs/` is gitignored by default, so it does not survive a re-clone and
cannot serve as the system of record. The commit trailer schema already captures the key
who/what/how-verified fields in a durable, tool-agnostic place, and tracked repo files are
better suited for long-lived branch, audit, and decision context.

**Alternatives Considered:** Committing run folders selectively (rejected: adds noise and
still leaves partial-history questions). Writing to a separate audit store (rejected:
too much overhead for solo-operator scale). Treating `.agent-runs/` as the primary audit
trail (rejected: not durable enough).

**Agent:** codex-gpt-5
**Context:** 2026-04-09 Phase 1.5 governance rollout

---

## 2026-04-09 — Phase 1.5 Trailer Enforcement Is Now Implemented

**Decision:** GitHub Actions trailer enforcement is now active in `foreman`, `Taxes`, and
`bible-ai` via `.github/workflows/foreman-trailer-check.yml`.

**Why:** This closes the known gap where cloud or sandboxed agents can bypass local git
hooks. The server-side workflow mirrors the local `commit-msg` hook semantics: it enforces
`Agent`, `Thread`, `Task`, and `Verified-By`, skips merge/fixup/squash/WIP commits, and
keeps `Reviewed-By` warning-only in Phase 1.

**Alternatives Considered:** Deferring server-side enforcement until Phase 2 (rejected:
the gap was already proven in real use and did not need to wait on the larger reviewer
design).

**Agent:** codex-gpt-5
**Context:** 2026-04-09 Phase 1.5 governance rollout

---

## 2026-04-09 — Codex Phase 1 Audit: Accepted Findings and Resolutions

**Decision:** Accepted Codex's Phase 1 audit findings in full. Applied fixes to AGENTS.md,
README.md, and CLAUDE.md. Updated two prior decisions. Opened two new OPEN_QUESTIONS entries.

**Confirmed findings acted on:**
- AGENTS.md overstated `Reviewed-By` as hard-enforced. Fixed: clarified it is warning-only in Phase 1, with the enforcement gap explicitly documented.
- AGENTS.md and README.md implied branch naming was mechanically enforced. Fixed: added Phase 1 caveat noting it is convention-only; no hook validates the pattern.
- README.md described GitHub Actions trailer enforcement as a mitigation that exists "today." Fixed: rewritten as a planned Phase 1.5 mitigation.
- CLAUDE.md omitted `production`/`prod` from the pre-push block list, and omitted `squash!`/`WIP` from commit-msg skips. Fixed.
- AGENTS.md § 9 (Hooks) was vague about what each hook actually does. Fixed: rewritten to match the actual hook behavior.
- The gate described as "tests/lint/build" is a heuristic autodetector that may run nothing. Fixed: documented explicitly in AGENTS.md and CLAUDE.md.

**Decision updates from Codex's disagreements:**
- "Codex Mac App Is Not the Primary Agent Interface" — softened from "not viable" to "not safe as primary write path." Advisory/read-only use remains valid. See that entry.
- "Phased Rollout" — Phase 3 and Phase 4 reframed as contingent options, not committed phases. Phase 1.5 added. See that entry.

**Inferred finding (not experimentally proven in audit):**
- Codex CLI on the local machine should fire local git hooks because it commits to the host checkout rather than a remote sandbox. This is inferred from the CLI's local-first interface, not tested end-to-end. See OPEN_QUESTIONS.md #3 (now resolved with caveats).

**Agent:** codex (auditor) + claude-sonnet-4-6 (applied fixes)
**Context:** Phase 1 audit, April 9 2026

---

## 2026-04-09 — Codex Mac App Is Not the Primary Agent Interface

**Decision:** The Codex Mac app is not safe as a primary write path for foreman-governed repos
until server-side enforcement exists. It is deprioritized for commit-and-push workflows.
It may still be used as a read-only or advisory interface (e.g., for code review commentary,
planning, or exploration that does not produce commits). Preferred write-path interfaces
are: Codex CLI, Claude Code CLI, or any agent invoked locally where hooks fire normally.

*Codex's audit (April 9 2026) correctly challenged an earlier formulation that banned the Mac
app "entirely." The narrower policy — ban as write path, not ban from the system — is the
right call. Updated accordingly.*

**Why:** Phase 1 audited two Codex Mac app commits on Taxes `main` (`2f80ddf feat(web)` and
`12b0d2d fix(web)`) and confirmed neither carried any foreman trailers (Agent, Thread, Task,
Verified-By, Reviewed-By). Root cause: the Codex Mac app runs in OpenAI's cloud sandbox —
it clones the repo remotely, makes commits, and pushes back directly. Local `.git/hooks/`
never fire in that environment. This makes Phase 1 enforcement structurally impossible against
the Mac app without server-side controls.

Beyond the hook problem: the Mac app doesn't expose a programmatic interface. You can't script
which model it uses, inject context at session start, enforce a branch naming convention before
the agent begins, or wire it into a dispatcher that routes tasks by cost tier. It is a
GUI-first tool and fundamentally difficult to control from outside the GUI. CLI-based agents
(Codex CLI, Claude Code) are scriptable, composable, and can be invoked by a foreman dispatcher
in Phase 3+.

**Alternatives Considered:**
- GitHub branch protection rules to block non-compliant pushes server-side (valid partial fix:
  catches trailerless commits even from cloud agents; does NOT solve the scriptability problem;
  planned for Phase 1.5).
- GitHub Actions CI hook to validate trailer schema on every push (same: catches some
  compliance failures but doesn't make the Mac app controllable).
- Continue using Mac app for large context tasks only, CLI for everything governed by foreman
  (rejected: two-tier policy creates confusion; better to standardize on one interface).

**Implication for the roadmap:**
- Phase 2 cross-model reviewer script targets CLI invocations — Codex CLI and Claude Code CLI
  are both scriptable and can be piped into a reviewer subprocess.
- Phase 3 Dagger Container Use gives each CLI agent an isolated worktree; Mac app cannot
  participate in container-isolated workflows.
- Any foreman work done via the Mac app in the interim should be treated as "best-effort" and
  manually audited before merge.

**Open question:** Is there an OAuth/API path into Codex that would give foreman-level control?
See `OPEN_QUESTIONS.md` entry #3.

**Agent:** claude-sonnet-4-6
**Context:** Phase 1 audit, Cowork session April 9 2026

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

**Decision:** Build in phases. Phase 1 (done) is branch naming, commit trailers, and gate
hooks. Phase 1.5 (next) is server-side enforcement via GitHub Actions + branch protection.
Phase 2 (likely) is the cross-model reviewer script. Phases 3 and 4 are contingent options,
not commitments — they trigger only if measured pain justifies the complexity.

*Codex's audit (April 9 2026) correctly flagged the original "four phases" framing as
treating Phase 3 (Dagger) and Phase 4 (OpenClaw) as planned work. For a solo operator
across a few personal projects, those phases may never pay for their complexity. Phase 1.5
was added as an explicit step after the first real-world audit revealed the cloud-bypass gap.*

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
