# Memory Directory

Durable knowledge that persists across sessions, tools, and models.
Agents should read relevant files here before starting a task.
Humans and agents should update these files when context changes.

## Files

| File | Contains |
|------|---------|
| `projects.md` | Index of all projects using foreman, with current status |
| `people.md` | People, roles, and context (add if working with collaborators) |

Add more files as needed — one topic per file. Keep entries short and dated.

## Rules

- Keep entries concise. This is reference material, not a journal.
- Include dates on every entry so stale context is obvious.
- Never store secrets, credentials, tokens, or PII here.
- When an entry is no longer accurate, update or delete it — stale memory
  is worse than no memory because it misleads agents confidently.
