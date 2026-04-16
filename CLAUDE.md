## Repo Principles

Load `CONTINUITY.md` and `COHERENCE.md` before any task. Their principles, plus `LINEAR.md` `## Linear-at-the-core`, govern planning, audit, state moves, and Codex handoff in this repository.

Before planning, audit, or a state move, verify:
- Continuity Check: the required Work Record exists and Self-audit is honest about what was and was not verified.
- Ripple Check: dependent docs were checked and any drift was updated in the same commit.
- Linear-coverage: actionable work is issue-backed or explicitly dispositioned, and live issues keep a repo-side ledger home in `todo.md`.

# Working Memory — foreman

_Claude's working memory. Read at the start of every session. Update as context changes._
_Last updated: 2026-04-11_

---

## Claude Operating Rules

These apply in every session, automatically, without being asked.

**Be terse.** One sentence beats a paragraph. No preamble, no filler, no restating the question.

**Don't implement code.** Claude is the auditor, planner, and reviewer. Codex is the implementer. When work needs to be done, generate a Codex prompt — don't write the code directly.

**Auto-generate Codex prompts.** When any implementation work is identified, produce a Codex prompt automatically. Don't wait to be asked.

**Read only what the task requires.** See AGENTS.md § 8 for the file-read routing table.

---

## Project Overview

Foreman is a convention and tooling template for AI-assisted coding. It gives AI agents
(Codex, Claude Code, Cursor, etc.) branch provenance, commit traceability, external
verification gates, and a foundation for cross-model review — without requiring a
full orchestration platform before it's needed.

It is Trevor's personal template. New projects clone or copy from it.

## Owner

Trevor Gillette — trevorgillette17@gmail.com

## Current Phase

**Phase 2.1** — Phase 2 governance is live, the reviewer still defaults to a soft gate,
the optional Haiku classifier is implemented, branch-name warnings now exist in `pre-push`,
and the remaining work is live validation plus deciding which soft gates should become defaults.

Phase 2.1 work still to finish:
- default hard-gate promotion decision after the burn-in window
- hosted GitHub Actions trailer-check validation from real PRs
- commit-time `Reviewed-By` promotion decision

Later phases:
- Phase 3: Dagger Container Use (isolation for parallel agents), unless the OpenHands evaluation replaces it
- Phase 4: OpenClaw orchestration (if still needed after Phase 3)

## Stack

This repo: shell scripts, Markdown. Language-agnostic — the conventions apply to any stack.

## Key Files

| File | What it is |
|------|-----------|
| `AGENTS.md` | Rules every AI agent must read before touching any repo |
| `BRANCH_LEDGER.md` | The canonical record of every open agent branch |
| `DECISIONS.md` | Architectural decisions and their reasoning |
| `memory/` | Durable knowledge: projects, people, context |
| `hooks/` | Git hooks for commit enforcement and pre-push gates |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template with agent metadata |

## Handoff Summary

Completed through 2026-04-11 and present on disk on `main`:
- Phase 1.5 landed in `foreman`, `Taxes`, and `bible-ai`
- `.github/workflows/foreman-trailer-check.yml` now enforces required trailers on pushes/PRs to `main`
- `.agent-runs/` is now documented as optional scratch space; commit trailers are the durable audit artifact
- `scripts/foreman-dispatch.sh` exists as the minimum shell dispatcher scaffold
- `PROJECT_INTENT.md` is now filled with the actual Phase 1 through Phase 2.1 purpose, scope, and constraints
- downstream governance-doc sync is intentionally manual for now; downstream copies stay repo-local until drift costs justify automation
- Phase 2 reviewer automation is now implemented via `scripts/foreman-review.py`
- `hooks/pre-push` now runs the reviewer after the existing gates and reports `APPROVE` / `REQUEST_CHANGES` / `BLOCKER` as a soft gate
- `scripts/foreman-dispatch.sh` now prints the exact post-run reviewer command for the author to run manually
- `scripts/foreman-classify.py` now provides an optional Haiku task classifier for `scripts/foreman-dispatch.sh`, with upward routing on low confidence and `--no-classify` for bypass/testing
- `FOREMAN_HARD_GATE=1` now promotes reviewer `BLOCKER` verdicts to a hard gate without editing the hook
- `FOREMAN_STRICT_BRANCH=1` now promotes non-compliant branch-name warnings to a hard gate without editing the hook
- `docs/mcp-tools.md` and `scripts/foreman-mcp-shim.py` now define a proof-of-concept MCP boundary for the existing governance operations
- `scripts/foreman-mcp-server.py` now exposes all 6 governance tools as a real FastMCP server compatible with Claude Code's MCP client. Connect via: `claude mcp add foreman python3 scripts/foreman-mcp-server.py`. Requires: `pip3 install mcp --break-system-packages`
- local Python 3.14 now has `anthropic` and `openai` installed, and the live classifier, Claude-fallback reviewer path, Anthropic Sonnet reviewer path, and OpenAI reviewer path have all been exercised successfully

Skipped or caveated:
- `Reviewed-By` remains warning-only at commit time even though the reviewer now returns a concrete `reviewer_model`
- downstream governance-doc copies can still drift between sync passes because manual mirroring was kept by design
- hard-gating reviewer `BLOCKER`s is deferred to Phase 2.1 pending two weeks of use with no false `BLOCKER`s
- hosted GitHub Actions trailer-check validation is still pending from a real pass/fail PR pair

Planned for next session:
- validate whether reviewer `BLOCKER`s are accurate enough to promote to a hard gate after two weeks of use
- push a correctly tagged test PR and a missing-trailer test PR to confirm `foreman-trailer-check.yml` passes/fails on GitHub's hosted runner
- decide whether commit-time `Reviewed-By` should stay warning-only or follow the Phase 2.1 hard-gate path later

## Recent Decisions

See DECISIONS.md for full history.

- **2026-04-09** — Commit trailers plus tracked repo files are the durable audit trail;
  `.agent-runs/` is scratch space only.
- **2026-04-10** — Downstream governance docs remain manually mirrored at current scale;
  accept limited drift rather than adding sync machinery now.
- **2026-04-10** — Phase 2 review automation uses Python, runs as a soft gate first,
  and defers the Haiku classifier to Phase 2.1.
- **2026-04-11** — Phase 2.1 adds an optional Haiku classifier with upward routing on
  low confidence and a `--no-classify` bypass for dispatch testing or cost control.
- **2026-04-09** — Phase 1.5 server-side trailer enforcement is now active in `foreman`,
  `Taxes`, and `bible-ai`.
- **2026-04-09** — Adopted Codex's phased approach to avoid overbuilding: branch ledger
  and hooks first, cross-model reviewer second, Container Use third, OpenClaw last.
- **2026-04-09** — Branch ledger (BRANCH_LEDGER.md) is the durable source of truth for
  open branches, not chat thread IDs. Chat links are metadata attached to the ledger.
- **2026-04-09** — Haiku 4.5 is the dispatcher model for cheap tasks; Sonnet 4.6 for
  standard work; Opus 4.6 for architecture and hard problems. Reviewer is always a
  different model than the one that wrote the code.

## Gotchas

- The pre-push hook blocks direct pushes to `main`, `master`, `production`, and `prod`.
  Use `git push --no-verify` only in genuine emergencies, and note why in DECISIONS.md.
- The commit-msg hook skips merge commits, `fixup!`, `squash!`, `WIP`, and `wip` based on the commit subject line.
- The commit-msg hook hard-enforces `Agent`, `Thread`, `Task`, `Verified-By`. `Reviewed-By` is still warning-only at commit time in Phase 2.1, with the promotion decision still deferred.
- The pre-push gate is heuristic autodetection (pytest/ruff/mypy, npm, or make). It may run nothing if no test runner is found. It is not a guaranteed full-stack gate.
- The Phase 2 reviewer is advisory only for now. A `BLOCKER` verdict is reported loudly but does not stop the push yet.
- `FOREMAN_HARD_GATE=1` makes reviewer `BLOCKER` verdicts fail the push immediately, and `FOREMAN_STRICT_BRANCH=1` does the same for non-compliant branch names.
- The pre-push hook resolves its review diff base from local `main` first, then `origin/main`, and skips reviewer execution only if neither ref exists, `python3` is unavailable, or the review script is missing.
- The pre-push hook automatically amends the last commit's `Reviewed-By` trailer when the reviewer runs successfully, then stops that push so the next `git push` sends the amended SHA. If you push with `--no-verify`, `Reviewed-By` stays `none-yet`.
- `scripts/foreman-review.py` skips live review if the required API key or SDK package is missing and writes `.agent-runs/last-review.json` whenever it can persist a review payload locally.
- Live reviewer and classifier paths require `anthropic` and `openai` packages. Install via `pip3 install -r scripts/requirements.txt --break-system-packages`. Without them, the reviewer silently skips and the classifier defaults to `standard`.
- The FastMCP server (`scripts/foreman-mcp-server.py`) requires the `mcp` package. Install via `pip3 install -r scripts/requirements.txt --break-system-packages`. Without it, the server file compiles but cannot run.
- Local hooks still matter, but `.github/workflows/foreman-trailer-check.yml` now covers
  the server-side enforcement gap for pushes and pull requests to `main`.
- `.agent-runs/` is optional local scratch space only. Durable audit context lives in
  commit trailers plus tracked repo files such as `BRANCH_LEDGER.md`, `DECISIONS.md`,
  and `todo.md`.
