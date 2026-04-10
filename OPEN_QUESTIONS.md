# Open Questions

Unresolved architectural questions that any agent auditing this repo should weigh in on.
These are not blockers for current work, but they shape what Phase 2+ should look like.
Add new entries at the top. Close an entry by moving it to `DECISIONS.md` with a resolution.

Entry format:
```
## #N — <Question>
**Status:** open | investigating | resolved (→ DECISIONS.md)
**Background:** <why this is a question>
**Options on the table:** <what we're considering>
**Wanted:** <what a useful audit response looks like>
**Opened:** <date>
```

---

## #3 — Is there a programmatic (CLI/OAuth/API) interface into Codex that foreman can control?

**Status:** open

**Background:** Trevor has ruled out the Codex Mac app as a long-term interface (see
DECISIONS.md: "Codex Mac App Is Not the Primary Agent Interface"). The concern is scriptability:
the Mac app can't be invoked by a dispatcher, can't have its model tier set programmatically,
and its cloud sandbox bypasses local git hooks entirely. The question is whether Codex CLI or
an OpenAI OAuth flow changes this picture enough to make Codex viable inside a foreman-governed
workflow.

**Options on the table:**
1. **Codex CLI** (`codex` command) — appears to be scriptable; unknown whether it fires local
   git hooks or runs in its own sandbox like the Mac app. Needs testing.
2. **OpenAI API direct** — call `o3` or `o4-mini` as a raw API model from a foreman dispatcher
   script, passing context and getting a diff back. Full control but loses the "agentic loop"
   (no autonomous tool use without custom scaffolding).
3. **Claude Code only** — drop Codex entirely and use Claude Code CLI for all agentic work.
   Simpler dispatch, same hook compliance, one less interface to maintain.
4. **OpenClaw/ACP harness** — spawns Claude Code and Codex as sub-agents with full hook
   compliance and container isolation. This is Phase 4 in the roadmap; may be premature.

**Wanted:** An agent auditing this should: (a) confirm whether Codex CLI fires local git hooks
on the host machine or runs in a sandbox, (b) assess whether Codex CLI is wirable into a simple
dispatcher script, (c) recommend whether Option 2 or 3 is more practical at Phase 2 scale
(a few personal projects, solo operator, no team).

**Opened:** 2026-04-09

---

## #2 — Should server-side trailer enforcement (GitHub branch protection) be Phase 1.5 or Phase 2?

**Status:** open

**Background:** Phase 1 enforcement uses local git hooks. These fire for local commits and pushes
but are completely bypassed by cloud agents (Codex Mac app proven; likely any cloud-hosted agent
that clones and pushes remotely). GitHub branch protection rules + a required status check
(GitHub Actions CI that validates the trailer schema) would catch non-compliant commits from any
source including cloud agents. This is a meaningful gap in Phase 1 that was discovered during
the first real-world audit.

**Options on the table:**
1. **Phase 1.5 (do it now, separately from Phase 2):** Set up branch protection on Taxes and
   bible-ai repos. Add a small GitHub Actions workflow that checks for required trailers on every
   push. Low complexity, high impact.
2. **Fold into Phase 2:** The Phase 2 cross-model reviewer script will also need CI integration.
   Combining them reduces the number of times we touch GitHub Actions config.
3. **Skip it:** If we move away from cloud agents (see question #3), the gap closes itself.
   Only revisit if a new cloud agent creates the same bypass problem.

**Wanted:** A recommendation on whether the gap is urgent enough to warrant a dedicated
Phase 1.5 step, or whether waiting for Phase 2 CI integration is acceptable given the current
scale (personal projects, solo operator, mostly CLI-based going forward).

**Opened:** 2026-04-09

---

## #1 — What is the right model routing policy for Phase 2+?

**Status:** open

**Background:** The current policy (see AGENTS.md § Model Routing) is:
- Haiku 4.5 → trivial/cheap tasks (dispatcher, summarization, classification)
- Sonnet 4.6 → standard implementation work
- Opus 4.6 → architecture decisions, hard problems, final review on critical paths
- Reviewer is always a different model from the author

This policy was set in the initial foreman session and hasn't been validated against real task
distributions. It's possible that Haiku 4.5 is underused (almost everything goes to Sonnet),
or that the Opus 4.6 threshold is too high/low.

**Options on the table:**
1. **Keep current policy, revisit after 30 days of actual use** — let real task data inform
   the policy rather than hypothesizing.
2. **Add a middle tier:** Haiku for classification/routing only, Sonnet 4.6 for all
   implementation including "easy" tasks, Opus only for architecture. This simplifies
   the decision boundary.
3. **Use task metadata to route:** The branch name slug and the task brief both contain
   enough signal for a Haiku-based classifier to decide tier. Phase 2 dispatcher script
   could do this automatically.

**Wanted:** An assessment of whether Option 3 is practical at Phase 2 (a simple Python script
that reads the task brief and outputs a recommended tier). What prompts work well for this kind
of routing classification?

**Opened:** 2026-04-09
