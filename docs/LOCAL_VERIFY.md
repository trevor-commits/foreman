# Local verification (CI parity)

Foreman’s **template repo** has no application `pytest` suite. The supported offline gate is
`scripts/verify.sh`, which mirrors the hosted job in `.github/workflows/test-foreman-tooling.yml`.

No API keys are required for verify — reviewer/classifier smoke tests use fixtures and mocks.

## Quick path

```bash
# From repo root (network once if deps missing)
FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh

# After deps are installed
bash scripts/verify.sh
# or: make verify
```

**macOS / externally managed Python:** use a venv (verify auto-activates `.venv` when present):

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r scripts/requirements.txt
bash scripts/verify.sh
```

After `bash hooks/install.sh`, `pre-push` runs `scripts/verify.sh` when that file exists.

## What verify runs

| Step | Purpose |
|------|---------|
| `bash -n` on hooks and operational shell scripts | Syntax safety |
| `python3 -m py_compile` on governance Python entrypoints | Import/syntax safety |
| `scripts/test-review.py` | Reviewer routing, JSON validation, MCP shim (offline) |
| `scripts/test-classify.py` | Classifier fallback without live API |
| `scripts/test-hooks.sh` | Temp-repo `commit-msg` + `pre-push` trailer behavior |
| `scripts/test-dispatch.sh` | Dispatcher branch/base selection |
| MCP shim / server smoke | Tool registration without starting a server |
| Workflow YAML checks | `foreman-trailer-check.yml` + **CI parity** for `test-foreman-tooling.yml` |

## CI parity contract

Hosted `test-foreman-tooling.yml` must stay a thin wrapper:

1. Checkout
2. Python 3.12
3. `FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh`

`verify.sh` asserts this shape so local and GitHub cannot drift silently.

## Not covered by verify (human / hosted)

| Gap | Where documented |
|-----|------------------|
| Trailer-check pass/fail on GitHub runners | `.github/VALIDATION_CHECKLIST.md` |
| Live Anthropic/OpenAI reviewer/classifier calls | `scripts/README.md` (optional keys) |
| Downstream template drift | `scripts/foreman-drift-check.sh` |
| `Reviewed-By` + merge readiness | `scripts/foreman-merge-check.sh`, `AGENTS.project.md` §3 |

## Open draft PR survey (2026-10-01)

Surveyed **open drafts only** — no merges, no external writes.

| PR | Branch | Focus | Overlap with other drafts |
|----|--------|-------|---------------------------|
| [#7](https://github.com/trevor-commits/foreman/pull/7) | `cursor/usage-burn-reliability-741a` | `scripts/verify.sh`, `Makefile`, pre-push self-check, CI delegates to verify, clone docs | Touches `test-foreman-tooling.yml`, `scripts/README.md`, `todo.md` |
| [#6](https://github.com/trevor-commits/foreman/pull/6) | `cursor/drift-discovery-d2e1` | Tighter `foreman-drift-check` discovery (exclude `~/.claude`, Desktop, editor extensions) | Same workflow + `scripts/README.md` + `todo.md` — **merge #7 first**, then rebase #6 |

**Recommendation:** Land reliability/verify (#7) before drift-discovery (#6) to avoid workflow/README conflicts.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `missing Python packages` | `FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh` or venv + `pip install -r scripts/requirements.txt` |
| `mcp` installed but import fails | Wrong `python3` on PATH; activate `.venv` or use the same interpreter you pip’d into |
| pre-push blocks with verify failure | Run `bash scripts/verify.sh` locally; fix reported step |
| Need to push without gates | Emergency only: `git push --no-verify` (document in `DECISIONS.md` if used) |
