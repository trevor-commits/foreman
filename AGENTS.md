# AGENTS.md (foreman)

This root file intentionally stays thin so repo-local policy does not drift from the global stack.

Paths below are repository-relative on purpose: foreman is copied into other
projects, so an absolute owner-specific path would not resolve in those clones.

## Required Read Order
1. The global agent baseline, when this machine has one (`~/.codex/AGENTS.md`). Skip it in clones that do not.
2. `AGENTS.project.md` — the authoritative repo-local overlay and the primary orientation document.
3. `PROJECT_INTENT.md` when present.
4. `todo.md` when present.
5. `CONTINUITY.md`, `COHERENCE.md`, and `LINEAR.md` when present, before planning, audit, or a state move.

## Local Authority
- `AGENTS.project.md` is the authoritative repo-local overlay for this repository.
- Do not treat this file as a second copy of the global AGENTS policy.
- Keep repo-specific edits in `AGENTS.project.md` so the root file remains a stable pointer.
- `CLAUDE.md` is a routing shim, not project state; it must not carry the repo contract.
