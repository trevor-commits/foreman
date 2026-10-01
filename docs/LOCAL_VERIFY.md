# Local verification (CI parity)

Foreman’s **template repo** has no application `pytest` suite. The supported offline gate is
`scripts/verify.sh`, which mirrors the hosted job in `.github/workflows/test-foreman-tooling.yml`.

No API keys are required for verify — reviewer/classifier smoke tests use fixtures and mocks.
No live Anthropic/OpenAI calls, no drift-check against real downstream paths, and no git pushes.

## Offline verify checklist

Run from the **repository root**:

| # | Command | When |
|---|---------|------|
| 1 | `FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh` | First clone, CI image, or after `requirements.txt` changes (network once) |
| 2 | `bash scripts/verify.sh` | Every change before push; must pass without `FOREMAN_VERIFY_INSTALL` |
| 3 | `make verify` | Optional alias for step 2 |

**Success:** final line is `✅  foreman verify passed` and exit code `0`.

**Failure:** any step prints an error and exits `1` — fix the reported step and re-run step 2.

**This pass (cloud agent `bc-552fe519-19f4-5c20-aee1-ede8e07c9827`):** steps 1–3 — **pass** (~40s on a fresh cloud image after pip install).

### Copy-paste block (offline after deps)

```bash
cd "$(git rev-parse --show-toplevel)"
FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh   # once per machine / after requirements change
bash scripts/verify.sh && make verify             # every change before push
```

### Expected noise (not failures)

`scripts/test-review.py` may print `Reviewer error: OPENAI_API_KEY is not set` on stderr while
offline cases still report `PASS:` — verify does **not** require API keys.

### macOS / PEP 668

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r scripts/requirements.txt
bash scripts/verify.sh
```

Verify auto-prepends `.venv/bin` to `PATH` when that interpreter exists.

### pre-push vs hosted CI

| Context | Installs deps? | Notes |
|---------|----------------|-------|
| GitHub `test-foreman-tooling.yml` | Yes (`FOREMAN_VERIFY_INSTALL=1`) | Thin wrapper around `verify.sh` |
| `hooks/pre-push` | **No** | Runs `bash scripts/verify.sh` only — install deps locally first or push is blocked |
| Local manual | Your choice | Use step 1 once, then step 2 |

After `bash hooks/install.sh`, install deps before your first push on a new machine.

## Environment variables (verify-related)

| Variable | Effect |
|----------|--------|
| `FOREMAN_VERIFY_INSTALL=1` | `pip install -r scripts/requirements.txt` when PyYAML/mcp imports are missing |
| `FOREMAN_STRICT_BRANCH=1` | pre-push blocks non-`agent/…` branch names (not set by verify) |
| `FOREMAN_HARD_GATE=1` | pre-push blocks on reviewer `BLOCKER` (not set by verify) |

API keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`) are **not** read by `verify.sh`.

## What verify runs

| Step | Purpose |
|------|---------|
| `bash -n` on hooks, operational scripts, and `scripts/test-*.sh` | Syntax safety |
| `python3 -m py_compile` on governance + `scripts/test-*.py` | Import/syntax safety |
| Makefile / `pre-push` wiring asserts | `make verify` and hook delegate to `scripts/verify.sh` |
| `scripts/test-review.py` | Reviewer routing, JSON validation, MCP shim (offline) |
| `scripts/test-classify.py` | Classifier fallback without live API |
| `scripts/test-hooks.sh` | Temp-repo `commit-msg` + `pre-push` trailer behavior |
| `scripts/test-dispatch.sh` | Dispatcher branch/base selection |
| MCP shim / server smoke | Tool registration without starting a server |
| Workflow YAML checks | `foreman-trailer-check.yml` + **CI parity** for `test-foreman-tooling.yml` (checkout, Python 3.12, env) |
| Operator doc cross-links | `README.md`, `scripts/README.md`, `VALIDATION_CHECKLIST.md` reference `docs/LOCAL_VERIFY.md` |

## CI parity contract

Hosted `test-foreman-tooling.yml` must stay a thin wrapper:

1. Checkout
2. Python 3.12 (`actions/setup-python@v5`)
3. `FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh`

`verify.sh` asserts this shape (including `python-version: "3.12"` and a single `verify.sh` run step)
so local and GitHub cannot drift silently. Local Python may differ from 3.12; verify prints a note when it does.

## Not covered by verify (human / hosted)

| Gap | Where documented |
|-----|------------------|
| Trailer-check pass/fail on GitHub runners | `.github/VALIDATION_CHECKLIST.md` |
| Live Anthropic/OpenAI reviewer/classifier calls | `scripts/README.md` (optional keys) |
| Downstream template drift | `scripts/foreman-drift-check.sh` (see draft PR #6) |
| `Reviewed-By` + merge readiness | `scripts/foreman-merge-check.sh`, `AGENTS.project.md` §3 |
| Hosted workflow green on a real PR branch | Push and inspect Actions after merge |

## Open draft PR survey (2026-10-01)

Surveyed **open drafts only** — no merges, no API keys, no secrets in docs.

| PR | Branch | Focus | Overlap / sequencing |
|----|--------|-------|----------------------|
| [#7](https://github.com/trevor-commits/foreman/pull/7) | `cursor/usage-burn-reliability-741a` | `scripts/verify.sh`, `Makefile`, pre-push self-check, CI → verify, `docs/LOCAL_VERIFY.md` | Land **first** — defines verify contract |
| [#6](https://github.com/trevor-commits/foreman/pull/6) | `cursor/drift-discovery-d2e1` | `foreman-drift-check` discovery hardening + `test-drift-discovery.py` | Touches `test-foreman-tooling.yml`, `scripts/README.md`, `todo.md` — **rebase on #7** |

**Recommendation:** Merge reliability/verify (#7) before drift-discovery (#6). After #7 lands, rebase #6 and wire `scripts/test-drift-discovery.py` into `verify.sh` (today #6 runs it only in its own workflow copy).

**Constraints for this burn:** draft-only, no merge, no live API keys, no `foreman-drift-check.sh` against real `$HOME` trees.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `missing Python packages` | `FOREMAN_VERIFY_INSTALL=1 bash scripts/verify.sh` or venv + `pip install -r scripts/requirements.txt` |
| `pip install completed but imports still missing` | Wrong `python3` on PATH; use `.venv` or `which python3` after install |
| pre-push blocks with verify failure | Run `bash scripts/verify.sh` locally; fix reported step |
| `test-foreman-tooling.yml: CI parity contract` failed | Restore single `run:` step calling `verify.sh` with `FOREMAN_VERIFY_INSTALL=1` |
| Need to push without gates | Emergency only: `git push --no-verify` (document in `DECISIONS.md` if used) |
