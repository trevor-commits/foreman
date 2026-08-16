# Foreman MCP Tool Surface

This document defines the planned MCP-facing governance tool surface for foreman.
The contract now has a real server implementation at `scripts/foreman-mcp-server.py`
using the official `mcp` package (FastMCP). The CLI shim at
`scripts/foreman-mcp-shim.py` remains in place so CLI callers and the MCP server
share the same tool contract and underlying wrappers.

## CLI Shim Contract

Invoke the shim as:

```bash
python3 scripts/foreman-mcp-shim.py --tool <name> --args '<json object>'
```

Behavior:
- Success: prints the tool result as JSON to stdout and exits `0`
- Failure: prints `{"error": {"code": "...", "message": "...", "details": ...}}`
  to stdout and exits non-zero

The FastMCP server exposes the same tool names and payload shapes over MCP.

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
- Claude-authored diffs: requires `OPENAI_API_KEY`. There is no Anthropic fallback.
- Codex/GPT-authored diffs: requires `ANTHROPIC_API_KEY`
- Live review also requires the corresponding SDK package (`openai` or `anthropic`)
- Missing credentials, dependencies, or provider execution return `review_unavailable`
  instead of reporting a successful skipped review

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

---

## `foreman_status() -> StatusResult`

Returns the current branch governance state as structured data.

### Input schema

```json
{}
```

### Output schema

```json
{
  "branch": "string",
  "branch_compliant": true,
  "protected_branch": false,
  "last_commit_trailers": {
    "Agent": "string | null",
    "Thread": "string | null",
    "Task": "string | null",
    "Verified-By": "string | null",
    "Reviewed-By": "string | null"
  },
  "last_review": {
    "verdict": "APPROVE | REQUEST_CHANGES | BLOCKER",
    "summary": "string",
    "issues": [],
    "reviewer_model": "string"
  },
  "ledger": {
    "row_found": true,
    "status": "string"
  }
}
```

### Underlying command

No standalone script exists yet. The shim inspects git state, commit trailers,
`.agent-runs/last-review.json`, and `BRANCH_LEDGER.md` directly.

### Error cases

- `git_failed`: current branch or last commit could not be read
- `invalid_json`: `.agent-runs/last-review.json` existed but could not be parsed

### API key requirements

None.
