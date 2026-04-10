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

## #5 — Audit trail is gitignored: how do we make run evidence durable?

**Status:** open

**Background:** AGENTS.md (§ 8 Run Logging) says each agent run gets a folder under
`.agent-runs/<YYYY-MM-DD>-<slug>/` containing `brief.md`, `review.md`, and `outcome.md`.
This is described as "how you reconstruct what happened when an overnight run goes sideways."
But `.gitignore` excludes `.agent-runs/` by default (confirmed in `.gitignore`). That means
the audit trail the system claims to provide does not actually survive a re-clone, does not
appear in `git log`, and is invisible to any agent or human starting a new session.

This is a direct contradiction at the core of the system's auditability promise.

**Options on the table:**
1. **Commit run folders selectively:** Add `.agent-runs/` to `.gitignore` with an exception
   pattern (e.g., `!.agent-runs/**/outcome.md`) so outcomes are committed but intermediate
   working files are not.
2. **Commit a single summary artifact per task:** After each run, the agent writes a one-file
   summary to `runs/<branch-slug>.md` (not `.agent-runs/`) and commits it. Lean and durable.
3. **Accept ephemeral local audit trail:** The current behavior is intentional — `.agent-runs/`
   is scratch space; the commit trailer itself (`Agent`, `Thread`, `Task`, `Verified-By`,
   `Reviewed-By`) is the durable artifact. The trailer schema already captures enough to
   reconstruct what happened. Run folders are optional detail for active debugging only.
4. **Separate audit store:** Write run outcomes to a separate repo or external store
   (e.g., a private `foreman-runs` repo, an S3 bucket, a simple append-only JSON log).

**Wanted:** A concrete recommendation on which option best fits solo-operator scale with
minimal friction. Option 3 may be the right answer — but if so, AGENTS.md § 8 needs to be
rewritten so it doesn't promise an audit trail that doesn't exist.

**Opened:** 2026-04-09

---

## #4 — What does the Phase 2 dispatcher script actually look like?

**Status:** open

**Background:** The roadmap describes Phase 2 as "a script that pipes any diff to a different
model with a strict output schema, returns APPROVE / REQUEST_CHANGES / BLOCKER with reasons,
wired into the pre-push hook." AGENTS.md describes a task brief format and model routing
guide. But there is no executable contract for how a dispatcher would actually work — no
defined CLI interface, no defined input/output schema, no decision about where it lives.

Codex's audit (April 9 2026) flagged this as the second most important missing piece:
"The repo has prose about model routing, task briefs, branch ledgers, and review, but it
does not yet define the actual command surface that makes those things happen in a
repeatable way. For your scale, a 100-line dispatcher script matters more than more
roadmap prose."

**Options on the table:**
1. **Shell dispatcher:** `scripts/foreman-dispatch.sh` reads `brief.md`, classifies via
   Haiku API call, creates the branch, ensures hooks are installed, shells out to
   `codex exec` or `claude code`, then invokes the reviewer. Simple, no dependencies.
2. **Python dispatcher:** Same logic in Python — easier to test, easier to parse structured
   JSON from the classifier, easier to integrate with the Anthropic SDK for Phase 2.
3. **Defer entirely:** Build Phase 1.5 (server-side enforcement) first, then design the
   dispatcher based on what Phase 1.5 surfaces as the next pain point.

**Wanted:** A prototype dispatcher in Option 1 or 2 form that handles the minimum viable
case: (a) classify task tier, (b) create a foreman-compliant branch, (c) invoke the agent
CLI, (d) write a brief.md. Review wiring can be Phase 2.1.

**Opened:** 2026-04-09

---

## #3 — Is there a programmatic (CLI/OAuth/API) interface into Codex that foreman can control?

**Status:** resolved — see DECISIONS.md "Codex Mac App Is Not the Primary Agent Interface"

**Resolution (from Codex's own audit, April 9 2026):**
Codex CLI (codex-cli 0.118.0 as of April 9 2026) is a local-first CLI, not a copy of the
Mac app's remote sandbox. It exposes local exec, explicit local sandbox modes, and separate
experimental cloud commands with local apply. If Codex CLI runs `git commit` in the host
checkout, local git hooks should fire — this is inferred from the CLI's local-first interface,
not experimentally proven in a live end-to-end test.

Codex's recommended dispatcher wiring: a shell or Python script reads the task brief,
classifies the task, creates the branch, ensures hooks are installed, then shells out to
`codex exec -C <repo> -m <model> -s workspace-write <prompt>`. After that, the dispatcher
invokes a second-model reviewer, updates the branch ledger, and the normal local commit/push
path enforces hooks.

The updated policy: ban Codex Mac app as a write path; Codex CLI and Claude Code CLI are
both viable for foreman-governed CLI dispatch. See OPEN_QUESTIONS.md #4 for the dispatcher
design question.

**Opened:** 2026-04-09 | **Resolved:** 2026-04-09

---

## #2 — Should server-side trailer enforcement (GitHub branch protection) be Phase 1.5 or Phase 2?

**Status:** resolved — implemented in Phase 1.5

**Resolution (from Codex's audit, April 9 2026):**
Codex's verdict: "This should be Phase 1.5 now, not Phase 2 later. The reason is simple:
it closes the only proven enforcement gap you have already hit in real use, and it is
orthogonal to the cross-model reviewer work. A tiny GitHub Actions check for required
trailers plus branch protection is small, cheap, and immediately useful. Waiting for Phase
2 couples a solved problem to a larger unsolved design."

Agreed. Phase 1.5 is now an explicit step in the roadmap (see README.md and the Phased
Rollout decision in DECISIONS.md). As of 2026-04-09, the implementation is now present in
`foreman`, `Taxes`, and `bible-ai` via `.github/workflows/foreman-trailer-check.yml`.
The workflow checks every non-merge commit on pushes and pull requests to `main`, enforces
`Agent`, `Thread`, `Task`, and `Verified-By`, and preserves the local hook's warning-only
behavior for missing or `none-yet` `Reviewed-By`.

**Opened:** 2026-04-09 | **Resolved:** 2026-04-09

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

**Codex's audit input (April 9 2026):**
Auto-classification via a cheap dispatcher is practical at Phase 2 scale, but only with
coarse buckets. The classifier should answer: "classification-only, normal implementation,
or escalation-worthy?" — not fine-grained distinctions within a tier. Use a hybrid of Option
2 and 3: Haiku for classification only, Sonnet for all real implementation including "easy"
tasks, Opus only for architecture. The classifier prompt should read the task brief (not just
the branch slug), acceptance criteria, changed-file set if available, and return structured
JSON: `{ route, confidence, reason, escalation_triggers }`. Useful heuristics: file-count
expectation, whether the task changes behavior or architecture, whether it touches risk areas
(auth/data/migrations), whether acceptance criteria are crisp, whether failure is cheap to
detect. If confidence is low, route upward automatically.

**Wanted:** Validation against 30 days of real task distribution before locking the policy.
Design the classifier prompt once Phase 1.5 is done and real task volume gives something to
calibrate against.

**Opened:** 2026-04-09
