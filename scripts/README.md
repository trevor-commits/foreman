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
