#!/usr/bin/env bash

set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "foreman-pr-prep.sh must run inside a git repository." >&2
  exit 1
fi

merge_check_script="$repo_root/scripts/foreman-merge-check.sh"
if [[ -f "$merge_check_script" ]]; then
  echo "━━━ merge-check summary ━━━" >&2
  bash "$merge_check_script" 2>&1 | head -20 >&2 || true
  echo "" >&2
fi

python3 - "$repo_root" <<'PY'
from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from datetime import date
from pathlib import Path


REQUIRED_TRAILERS = ("Agent", "Thread", "Task", "Verified-By", "Reviewed-By")
BRANCH_PATTERN = re.compile(r"^(agent|review)/[^/]+/([0-9]{4}-[0-9]{2}-[0-9]{2})/([a-z0-9-]+)$")

repo_root = Path(sys.argv[1])


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def has_ref(ref: str) -> bool:
    return (
        subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", ref],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        ).returncode
        == 0
    )


def parse_trailers(commit_body: str) -> dict[str, str]:
    trailers: dict[str, str] = {}
    for line in commit_body.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        if key in REQUIRED_TRAILERS and value.strip():
            trailers[key] = value.strip()
    return trailers


def ordered_unique(values: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value and value not in seen:
            seen.add(value)
            ordered.append(value)
    return ordered


def infer_model_tier(branch: str, agents: list[str]) -> str:
    candidates: list[str] = []
    branch_lower = branch.lower()
    if "/claude/" in branch_lower or branch_lower.startswith("review/claude"):
        candidates.append("standard")
    elif "/codex/" in branch_lower or "/gpt/" in branch_lower:
        candidates.append("standard")

    for agent in agents:
        lowered = agent.lower()
        if "haiku" in lowered:
            candidates.append("cheap")
        elif "opus" in lowered:
            candidates.append("escalation")
        elif any(token in lowered for token in ("sonnet", "codex", "gpt", "o1", "o3", "o4")):
            candidates.append("standard")

    unique = ordered_unique(candidates)
    if not unique:
        return "unknown"
    if len(unique) == 1:
        return unique[0]
    return f"mixed: {', '.join(unique)}"


def extract_acceptance_criteria(brief_path: Path) -> str:
    try:
        lines = brief_path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return "- [ ] TODO: fill in from task brief"

    collecting = False
    collected: list[str] = []

    for line in lines:
        stripped = line.strip()
        if not collecting:
            if stripped.startswith("**Acceptance Criteria:**"):
                collecting = True
                remainder = stripped[len("**Acceptance Criteria:**") :].strip()
                if remainder:
                    collected.append(remainder)
                continue
            if re.match(r"^#{1,6}\s+Acceptance Criteria$", stripped, flags=re.IGNORECASE):
                collecting = True
                continue
            continue

        if not stripped:
            if collected:
                break
            continue

        if re.match(r"^\*\*[A-Za-z0-9 _/-]+:\*\*$", stripped):
            break
        if re.match(r"^#{1,6}\s+", stripped):
            break

        collected.append(stripped)

    if not collected:
        return "- [ ] TODO: fill in from task brief"

    return "\n".join(collected)


def find_brief(branch: str) -> Path | None:
    match = BRANCH_PATTERN.match(branch)
    if not match:
        return None
    branch_date = match.group(2)
    slug = match.group(3)
    brief_path = repo_root / ".agent-runs" / f"{branch_date}-{slug}" / "brief.md"
    return brief_path if brief_path.exists() else None


def load_last_review() -> dict[str, object] | None:
    review_path = repo_root / ".agent-runs" / "last-review.json"
    if not review_path.exists():
        return None
    try:
        payload = json.loads(review_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return payload if isinstance(payload, dict) else None


def find_ledger_status(branch: str) -> tuple[bool, str]:
    ledger_path = repo_root / "BRANCH_LEDGER.md"
    if not ledger_path.exists():
        return False, "not available"

    current_section = ""
    try:
        lines = ledger_path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return False, "not available"

    for line in lines:
        stripped = line.strip()
        if stripped == "## Active Branches":
            current_section = "active"
            continue
        if stripped == "## Closed Branches":
            current_section = "closed"
            continue
        if not stripped.startswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.split("|")[1:-1]]
        if not cells or cells[0].strip("`") != branch:
            continue

        if current_section == "active" and len(cells) >= 7:
            return True, cells[6] or "not available"
        if current_section == "closed" and len(cells) >= 5:
            outcome = cells[4].lower()
            if "abandon" in outcome:
                return True, "abandoned"
            return True, "merged"

    return False, "not found"


def markdown_table_row(label: str, value: str) -> str:
    safe_value = value.replace("\n", " ").replace("|", "\\|")
    return f"| {label} | {safe_value} |"


branch = git("rev-parse", "--abbrev-ref", "HEAD").strip() or "not available"
today = date.today().isoformat()

base_ref = None
if has_ref("refs/heads/main"):
    base_ref = "main"
elif has_ref("refs/remotes/origin/main"):
    base_ref = "origin/main"

commit_shas: list[str] = []
if base_ref is not None:
    commit_shas = [sha for sha in git("rev-list", "--reverse", f"{base_ref}..HEAD", check=False).splitlines() if sha]
if not commit_shas:
    commit_shas = [git("rev-parse", "HEAD").strip()]

commit_bodies = [git("log", "-1", "--format=%B", sha) for sha in commit_shas]
trailers_by_commit = [parse_trailers(body) for body in commit_bodies]
last_commit_trailers = trailers_by_commit[-1] if trailers_by_commit else {}

tasks = ordered_unique([trailers.get("Task", "") for trailers in trailers_by_commit if trailers.get("Task")])
agents = ordered_unique([trailers.get("Agent", "") for trailers in trailers_by_commit if trailers.get("Agent")])
verified_checks = ordered_unique(
    [
        item.strip()
        for trailers in trailers_by_commit
        for item in trailers.get("Verified-By", "").split(",")
        if item.strip()
    ]
)

agent_counts = Counter(trailers.get("Agent", "") for trailers in trailers_by_commit if trailers.get("Agent"))
primary_agent = agent_counts.most_common(1)[0][0] if agent_counts else (last_commit_trailers.get("Agent") or "unknown")
agent_display = agents[0] if len(agents) == 1 else (f"mixed: {', '.join(agents)}" if agents else "not available")
thread_display = last_commit_trailers.get("Thread", "TODO: verify")
model_routing = infer_model_tier(branch, agents)

brief_path = find_brief(branch)
acceptance_criteria = extract_acceptance_criteria(brief_path) if brief_path else "- [ ] TODO: fill in from task brief"

review = load_last_review()
ledger_found, ledger_status = find_ledger_status(branch)

if tasks:
    what_this_pr_does = tasks[0] if len(tasks) == 1 else "\n".join(f"- {task}" for task in tasks)
else:
    subject = git("log", "-1", "--format=%s").strip()
    what_this_pr_does = subject or "TODO: summarize this branch"

print("## What does this PR do?")
print()
print(what_this_pr_does)
print()
print("## Agent Metadata")
print()
print("| Field | Value |")
print("|-------|-------|")
print(markdown_table_row("Agent", agent_display))
print(markdown_table_row("Thread", thread_display))
print(markdown_table_row("Branch", branch))
print(markdown_table_row("Date", today))
print(markdown_table_row("Model Routing", model_routing))
print()
print("## Acceptance Criteria")
print()
print(acceptance_criteria)
print()
print("## Verification")
print()
if verified_checks:
    for check in verified_checks:
        print(f"- {check}")
else:
    print("- [ ] TODO: fill in verification evidence")
print()
print("## Second-Model Review")
print()
if review:
    reviewer_model = str(review.get("reviewer_model", "not available"))
    verdict = str(review.get("verdict", "not available"))
    summary = str(review.get("summary", "not available"))
    issues = review.get("issues", [])
    print(f"- Reviewer model: {reviewer_model}")
    print(f"- Verdict: {verdict}")
    print(f"- Summary: {summary}")
    if isinstance(issues, list) and issues:
        for issue in issues:
            if not isinstance(issue, dict):
                continue
            severity = str(issue.get("severity", "info"))
            location = str(issue.get("location", "general"))
            note = str(issue.get("note", "TODO: verify"))
            print(f"- Issue: [{severity}] {location} — {note}")
    else:
        print("- Issues: none")
else:
    print(
        "- ⚠️ No reviewer output found. Run: "
        f"`git diff main...HEAD | python3 scripts/foreman-review.py --author-model {primary_agent} --branch {branch} -`"
    )
print()
print("## BRANCH_LEDGER.md")
print()
if ledger_found:
    print(f"- ✅ Row found — status: {ledger_status}")
else:
    print("- ⚠️ No row found — add one to BRANCH_LEDGER.md before merging")
print()
print("## Merge checklist")
print()
print("- [ ] `bash scripts/foreman-merge-check.sh` passes (all conditions green)")
print("- [ ] `BRANCH_LEDGER.md` row updated to `ready`")
print(f"- [ ] `bash scripts/foreman-close.sh {branch} merged` run after merge")
PY

echo "Copy the above and paste into your GitHub PR description." >&2
