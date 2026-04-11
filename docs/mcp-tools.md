# Foreman MCP Tool Surface (Scaffold)

This document defines the planned MCP-facing governance tool surface for foreman.
It is intentionally a contract spec, not a server implementation. The current
proof-of-concept transport is `scripts/foreman-mcp-shim.py`, which exposes the
same tools through a CLI so different backends can validate the interface before
foreman commits to a specific MCP server framework.

## CLI Shim Contract

Invoke the shim as:

```bash
python3 scripts/foreman-mcp-shim.py --tool <name> --args '<json object>'
```

Behavior:
- Success: prints the tool result as JSON to stdout and exits `0`
- Failure: prints `{"error": {"code": "...", "message": "...", "details": ...}}`
  to stdout and exits non-zero

---

## `foreman_review(diff: str, author_model: str, branch: str) -> ReviewResult`

Wraps `scripts/foreman-review.py`.

### Input schema

```json
{
  "diff": "string",
  "author_model": "string",
  "branch": "string"
}
```

### Output schema

Matches the existing review JSON schema written by `scripts/foreman-review.py`:

```json
{
  "verdict": "APPROVE | REQUEST_CHANGES | BLOCKER",
  "summary": "string",
  "issues": [
    {
      "severity": "info | warning | blocking",
      "location": "string",
      "note": "string"
    }
  ],
  "reviewer_model": "string"
}
```

### Underlying command

```bash
printf '%s' "$DIFF" | python3 scripts/foreman-review.py --author-model "$AUTHOR_MODEL" --branch "$BRANCH" -
```

### Error cases

- `invalid_args`: missing or non-string `diff`, `author_model`, or `branch`
- `review_unavailable`: the underlying reviewer skipped because dependencies or API keys
  were missing, or it failed before producing review JSON
- `script_failed`: the wrapper could not execute `python3` or the review script
- `invalid_json`: the wrapper could not load the review JSON file the script reported

### API key requirements

- Empty or whitespace-only diffs: no API key required
- Claude-authored diffs: prefers `OPENAI_API_KEY`; falls back to `ANTHROPIC_API_KEY`
  when the OpenAI key is unavailable
- Codex/GPT-authored diffs: requires `ANTHROPIC_API_KEY`
- Live review also requires the corresponding SDK package (`openai` or `anthropic`)

---

## `foreman_dispatch(brief_path: str) -> DispatchResult`

Wraps `scripts/foreman-dispatch.sh`.

### Input schema

```json
{
  "brief_path": "string"
}
```

### Output schema

```json
{
  "model_tier": "string",
  "branch_name": "string",
  "hook_status": {
    "state": "installed | missing | unverifiable",
    "path": "string | null",
    "message": "string"
  }
}
```

### Underlying command

```bash
bash scripts/foreman-dispatch.sh "$BRIEF_PATH"
```

### Error cases

- `invalid_args`: missing or non-string `brief_path`
- `script_failed`: the dispatcher exited non-zero
- `parse_failed`: the shim could not recover `Resolved model tier`, `Proposed branch`,
  or hook status from the dispatcher output

### API key requirements

- No API key is required to invoke the dispatcher itself
- If classifier support is available, the dispatcher may use `ANTHROPIC_API_KEY`
  indirectly through `scripts/foreman-classify.py`
- Without an Anthropic key or package, the dispatcher falls back to `standard`

### Notes

- This tool is stateful because the underlying dispatcher may create or check out a branch
- `hook_status` reflects the local `commit-msg` hook check printed by the dispatcher

---

## `foreman_classify(brief_path: str) -> ClassifyResult`

Wraps `scripts/foreman-classify.py`.

### Input schema

```json
{
  "brief_path": "string"
}
```

### Output schema

```json
{
  "route": "cheap | standard | escalation",
  "confidence": 0.0,
  "reason": "string",
  "escalation_triggers": ["string"]
}
```

### Underlying command

```bash
python3 scripts/foreman-classify.py "$BRIEF_PATH"
```

### Error cases

- `invalid_args`: missing or non-string `brief_path`
- `script_failed`: the classifier exited non-zero
- `invalid_json`: the classifier did not return valid JSON

### API key requirements

- `ANTHROPIC_API_KEY` is optional
- Without the key or the `anthropic` package, the classifier returns:

```json
{
  "route": "standard",
  "confidence": 0.0,
  "reason": "no API key — defaulting to standard",
  "escalation_triggers": []
}
```

---

## `foreman_ledger_open(branch: str, agent: str, task: str, merge_condition: str, thread: str) -> void`

Appends a new row to the Active Branches table in `BRANCH_LEDGER.md`.

### Input schema

```json
{
  "branch": "string",
  "agent": "string",
  "task": "string",
  "merge_condition": "string",
  "thread": "string"
}
```

### Output schema

```json
null
```

### Underlying command

No standalone script exists yet. The shim edits `BRANCH_LEDGER.md` directly to validate
the eventual MCP tool contract before extracting ledger helpers into their own scripts.

### Error cases

- `invalid_args`: missing required string fields
- `ledger_conflict`: the branch already exists in the active or closed ledger
- `ledger_format_error`: the ledger file does not match the expected table structure
- `write_failed`: the shim could not persist the updated ledger file

### API key requirements

None.

---

## `foreman_ledger_close(branch: str, outcome: str) -> void`

Moves an active branch row from Active Branches to Closed Branches in `BRANCH_LEDGER.md`.

### Input schema

```json
{
  "branch": "string",
  "outcome": "string"
}
```

### Output schema

```json
null
```

### Underlying command

No standalone script exists yet. The shim edits `BRANCH_LEDGER.md` directly to validate
the eventual MCP tool contract before extracting ledger helpers into their own scripts.

### Error cases

- `invalid_args`: missing required string fields
- `ledger_not_found`: the branch was not present in the active ledger
- `ledger_format_error`: the ledger file does not match the expected table structure
- `write_failed`: the shim could not persist the updated ledger file

### API key requirements

None.
