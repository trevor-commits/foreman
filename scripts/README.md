# Foreman Scripts

Install Python reviewer dependencies with:

```bash
python3 -m pip install -r scripts/requirements.txt
```

If your system Python is externally managed (for example Homebrew Python on macOS),
install these packages in a virtual environment instead of forcing a global install.

Environment variables:
- `ANTHROPIC_API_KEY` for the default reviewer path and the Claude fallback path
- `OPENAI_API_KEY` for reviewing Claude-authored diffs with `o4-mini`

If `OPENAI_API_KEY` is missing when the author model is Claude, `foreman-review.py`
falls back to a second Claude model instead of failing immediately.

## Live Validation Setup

The reviewer and classifier require Anthropic and OpenAI SDKs. Install once per environment:

```bash
pip3 install -r scripts/requirements.txt --break-system-packages
```

Or in a virtualenv:

```bash
python3 -m venv .venv && source .venv/bin/activate && pip install -r scripts/requirements.txt
```

Required env vars:
- `ANTHROPIC_API_KEY` — for reviewer (Claude-authored diffs) and Haiku classifier
- `OPENAI_API_KEY` — for reviewer (Codex/GPT-authored diffs); optional if Anthropic-only setup

## Telemetry And Calibration

- `scripts/foreman-review.py` writes the latest review to `.agent-runs/last-review.json` and appends telemetry to `.agent-runs/review-log.jsonl`
- `scripts/foreman-calibration.py` summarizes reviewer telemetry and prints the hard-gate readiness decision
- Burn-in checkpoint command: `python3 scripts/foreman-calibration.py --days 14`
