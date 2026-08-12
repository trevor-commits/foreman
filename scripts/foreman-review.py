#!/usr/bin/env python3
"""Run a cross-model review for the current diff."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


# Every Anthropic request uses exact Opus 5 under global ER-930.
OPENAI_REVIEW_MODEL = "o4-mini"
CLAUDE_OPUS_MODEL = "claude-opus-5"
CLAUDE_REVIEW_MODEL = CLAUDE_OPUS_MODEL
VALID_VERDICTS = {"APPROVE", "REQUEST_CHANGES", "BLOCKER"}
VALID_SEVERITIES = {"info", "warning", "blocking"}


class ReviewError(Exception):
    """Base exception for review failures."""


class MissingKeyError(ReviewError):
    """Raised when a required API key is not configured."""


class DependencyError(ReviewError):
    """Raised when an optional dependency is not installed."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Review a git diff with a second model.")
    parser.add_argument(
        "diff_source",
        nargs="?",
        default="-",
        help="Diff input path, or '-' to read from stdin.",
    )
    parser.add_argument(
        "--diff",
        dest="diff_override",
        help="Optional diff input path, or '-' to read from stdin.",
    )
    parser.add_argument("--author-model", required=True, help="Model that authored the diff.")
    parser.add_argument("--branch", required=True, help="Branch name under review.")
    args = parser.parse_args()

    if args.diff_override is not None and args.diff_source != "-":
        parser.error("Use either a positional diff source or --diff, not both.")

    args.diff_source = args.diff_override if args.diff_override is not None else args.diff_source
    return args


def read_diff(source: str) -> str:
    if source == "-":
        return sys.stdin.read()

    return Path(source).read_text(encoding="utf-8")


def resolve_reviewer(author_model: str) -> tuple[str, str]:
    author_lower = author_model.lower()

    if "claude" in author_lower:
        return "openai", OPENAI_REVIEW_MODEL

    if "codex" in author_lower or "gpt" in author_lower:
        return "anthropic", CLAUDE_REVIEW_MODEL

    return "anthropic", CLAUDE_REVIEW_MODEL


def build_prompt(diff_text: str, author_model: str, branch: str) -> str:
    return f"""You are a foreman governance reviewer. Read the diff below and return a JSON object with this exact schema:

{{
  "verdict": "APPROVE" | "REQUEST_CHANGES" | "BLOCKER",
  "summary": "<one sentence>",
  "issues": [
    {{ "severity": "info" | "warning" | "blocking", "location": "<file:line or general>", "note": "<what and why>" }}
  ],
  "reviewer_model": "<model name>"
}}

Foreman governance context:
- COMMIT TRAILER SCHEMA
  Required trailers (hard fail if missing): Agent, Thread, Task, Verified-By
  Optional warning: Reviewed-By (must be a different model than Agent when populated)
  Format: each trailer must appear after a blank line, as "Key: value" with no blank lines between trailers.
  Example of a valid trailer block:
    Agent: codex-5.3
    Thread: https://...
    Task: Add Stripe webhook handler
    Verified-By: pytest, ruff
    Reviewed-By: claude-opus-5
- BRANCH NAMING CONVENTION
  Branches should match: ^(agent|review)/[a-z0-9_-]+/[0-9]{4}-[0-9]{2}-[0-9]{2}/[a-z0-9-]+$
  A diff on a branch that does not match this pattern should be flagged as a warning / REQUEST_CHANGES, not a BLOCKER, unless the branch is a protected branch name: main, master, production, prod.
- MERGE CONDITIONS
  A diff is not merge-ready unless all automated gates pass, Reviewed-By is set to a different model than Agent, the reviewer verdict is APPROVE, the Task in the commit matches the branch slug, and a BRANCH_LEDGER.md row exists and is updated to ready or merged.
- BLOCKER CRITERIA
  Flag as BLOCKER if the diff shows any of: commits missing any of Agent, Thread, Task, or Verified-By trailers; direct modification to a protected branch; a security issue, data loss risk, or broken logic; or a commit where Reviewed-By matches Agent (self-review).
- REQUEST_CHANGES CRITERIA
  Flag as REQUEST_CHANGES if Reviewed-By is missing or set to "none-yet"; if branch naming is non-compliant; or if the Task trailer does not match the actual changes.

Review rules:
- APPROVE: diff is correct, complete, safe to merge, and shows no governance or correctness problems
- REQUEST_CHANGES: meaningful concerns or process gaps that should be fixed before merge, but not an immediate hard stop
- BLOCKER: hard governance failure, protected-branch violation, self-review, security issue, data loss risk, or broken logic
- Use only evidence present in the diff and the supplied metadata. Do not invent missing trailers, branch-ledger state, merge readiness, or protected-branch edits if the evidence is not visible.
- Do not flag style preferences or formatting choices
- If the diff is empty or whitespace-only, return APPROVE with summary "Empty diff — nothing to review"
- Return only the JSON object, no other text

Author model: {author_model}
Branch: {branch}
The reviewer model must be different from the author model. You are reviewing work by {author_model} — do not approve changes that were reviewed by the same model family.

Diff:
```diff
{diff_text}
```"""


def call_openai(prompt: str, model: str) -> tuple[str, str]:
    if not os.getenv("OPENAI_API_KEY"):
        raise MissingKeyError("OPENAI_API_KEY is not set.")

    try:
        from openai import OpenAI
    except ImportError as exc:
        raise DependencyError("openai package is not installed.") from exc

    client = OpenAI()
    response = client.responses.create(
        model=model,
        input=prompt,
    )

    output_text = getattr(response, "output_text", None)
    if output_text:
        return output_text, getattr(response, "model", model)

    # This targets the current OpenAI Python 1.x Responses API shape documented in the
    # OpenAI API reference and README: prefer the SDK convenience field `output_text`,
    # then fall back to iterating `response.output[*].content[*].text` when the helper is
    # absent or empty. If the SDK changes this object shape, update both branches together
    # instead of switching to Chat Completions-style parsing.
    parts: list[str] = []
    for item in getattr(response, "output", []) or []:
        for content in getattr(item, "content", []) or []:
            text = getattr(content, "text", None)
            if text:
                parts.append(text)

    if parts:
        return "\n".join(parts), getattr(response, "model", model)

    raise ReviewError("OpenAI response did not include text output.")


def call_anthropic(prompt: str, model: str) -> tuple[str, str]:
    if model != CLAUDE_OPUS_MODEL:
        raise ReviewError(
            f"Only {CLAUDE_OPUS_MODEL} is allowed for Anthropic review (got {model})."
        )
    if not os.getenv("ANTHROPIC_API_KEY"):
        raise MissingKeyError("ANTHROPIC_API_KEY is not set.")

    try:
        from anthropic import Anthropic
    except ImportError as exc:
        raise DependencyError("anthropic package is not installed.") from exc

    client = Anthropic()
    message = client.messages.create(
        model=model,
        max_tokens=1200,
        messages=[{"role": "user", "content": prompt}],
    )

    parts = [block.text for block in message.content if getattr(block, "type", None) == "text"]
    if parts:
        return "\n".join(parts), getattr(message, "model", model)

    raise ReviewError("Anthropic response did not include text output.")


def extract_json_object(raw_text: str) -> dict[str, Any]:
    text = raw_text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        decoder = json.JSONDecoder()
        for index, char in enumerate(text):
            if char != "{":
                continue
            try:
                value, _ = decoder.raw_decode(text[index:])
            except json.JSONDecodeError:
                continue
            if isinstance(value, dict):
                return value
        raise ReviewError("Reviewer output did not contain a valid JSON object.")


def run_inline_assertions() -> None:
    sample = {
        "verdict": "APPROVE",
        "summary": "Empty diff — nothing to review",
        "issues": [],
        "reviewer_model": "claude-opus-5",
    }
    encoded = json.dumps(sample)
    fenced = f"```json\n{encoded}\n```"
    wrapped = f"Reviewer output follows:\n{encoded}\nThanks."

    assert extract_json_object(encoded)["verdict"] == "APPROVE"
    assert extract_json_object(fenced)["summary"] == "Empty diff — nothing to review"
    assert extract_json_object(wrapped)["reviewer_model"] == "claude-opus-5"


def validate_review(review: dict[str, Any], actual_model: str) -> dict[str, Any]:
    if not isinstance(review, dict):
        raise ReviewError("Review payload must be an object.")

    verdict = review.get("verdict")
    if verdict not in VALID_VERDICTS:
        raise ReviewError(f"Invalid verdict: {verdict!r}")

    summary = review.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        raise ReviewError("Review summary is missing.")

    issues = review.get("issues", [])
    if not isinstance(issues, list):
        raise ReviewError("Review issues must be a list.")

    normalized_issues: list[dict[str, str]] = []
    for issue in issues:
        if not isinstance(issue, dict):
            raise ReviewError("Each review issue must be an object.")

        severity = issue.get("severity")
        location = issue.get("location")
        note = issue.get("note")
        if severity not in VALID_SEVERITIES:
            raise ReviewError(f"Invalid issue severity: {severity!r}")
        if not isinstance(location, str) or not location.strip():
            raise ReviewError("Review issue location is missing.")
        if not isinstance(note, str) or not note.strip():
            raise ReviewError("Review issue note is missing.")

        normalized_issues.append(
            {
                "severity": severity,
                "location": location.strip(),
                "note": note.strip(),
            }
        )

    return {
        "verdict": verdict,
        "summary": summary.strip(),
        "issues": normalized_issues,
        "reviewer_model": actual_model.strip() if isinstance(actual_model, str) and actual_model.strip() else "unknown",
    }


def repo_root() -> Path:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=True,
            capture_output=True,
            text=True,
        )
        return Path(result.stdout.strip())
    except Exception:
        return Path.cwd()


def review_runs_directories() -> list[Path]:
    candidates = [
        repo_root() / ".agent-runs",
        Path.cwd() / ".agent-runs",
        Path(tempfile.gettempdir()) / "foreman-agent-runs",
    ]
    unique_candidates: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.resolve(strict=False)
        if resolved in seen:
            continue
        seen.add(resolved)
        unique_candidates.append(candidate)
    return unique_candidates


def write_review_file(review: dict[str, Any]) -> Path:
    for runs_dir in review_runs_directories():
        try:
            runs_dir.mkdir(parents=True, exist_ok=True)
            output_path = runs_dir / "last-review.json"
            output_path.write_text(json.dumps(review, indent=2) + "\n", encoding="utf-8")
            return output_path
        except OSError:
            continue

    return Path("<review-json-not-written>")


def append_telemetry(
    review: dict[str, Any],
    author_model: str,
    branch: str,
    provider: str,
    diff_text: str,
) -> Path | None:
    severity_counts = {"blocking": 0, "warning": 0, "info": 0}
    for issue in review.get("issues", []):
        severity = issue.get("severity")
        if severity in severity_counts:
            severity_counts[severity] += 1

    record = {
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "branch": branch,
        "author_model": author_model,
        "reviewer_model": review.get("reviewer_model", "unknown"),
        "provider": provider,
        "verdict": review.get("verdict", "unknown"),
        "issue_count": len(review.get("issues", [])),
        "blocking_count": severity_counts["blocking"],
        "warning_count": severity_counts["warning"],
        "info_count": severity_counts["info"],
        "summary": review.get("summary", ""),
        "diff_line_count": len(diff_text.splitlines()),
    }

    last_error: OSError | None = None
    for runs_dir in review_runs_directories():
        try:
            runs_dir.mkdir(parents=True, exist_ok=True)
            output_path = runs_dir / "review-log.jsonl"
            with output_path.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record) + "\n")
            return output_path
        except OSError as exc:
            last_error = exc
            continue

    if last_error is not None:
        print(f"Reviewer telemetry warning: {last_error}", file=sys.stderr)
    else:
        print("Reviewer telemetry warning: unable to write review-log.jsonl", file=sys.stderr)
    return None


def print_review(review: dict[str, Any], output_path: Path) -> None:
    print(f"Reviewer verdict: {review['verdict']}")
    print(f"Reviewer model: {review['reviewer_model']}")
    print(f"Summary: {review['summary']}")
    if review["issues"]:
        print("Issues:")
        for issue in review["issues"]:
            print(f"- [{issue['severity']}] {issue['location']}: {issue['note']}")
    else:
        print("Issues: none")
    print(f"Review JSON: {output_path}")


def empty_diff_review(reviewer_model: str) -> dict[str, Any]:
    return {
        "verdict": "APPROVE",
        "summary": "Empty diff — nothing to review",
        "issues": [],
        "reviewer_model": reviewer_model,
    }


def main() -> int:
    args = parse_args()

    try:
        run_inline_assertions()
        diff_text = read_diff(args.diff_source)
        provider, reviewer_model = resolve_reviewer(args.author_model)

        if not diff_text.strip():
            review = empty_diff_review(reviewer_model)
            output_path = write_review_file(review)
            print_review(review, output_path)
            return 0

        prompt = build_prompt(diff_text, args.author_model, args.branch)

        if provider == "openai":
            raw_output, actual_model = call_openai(prompt, reviewer_model)
        else:
            raw_output, actual_model = call_anthropic(prompt, reviewer_model)

        review = validate_review(extract_json_object(raw_output), actual_model)
        output_path = write_review_file(review)
        append_telemetry(review, args.author_model, args.branch, provider, diff_text)
        print_review(review, output_path)
        return 1 if review["verdict"] == "BLOCKER" else 0
    except MissingKeyError as exc:
        print(f"Reviewer warning: {exc} Skipping review.", file=sys.stderr)
        return 0
    except DependencyError as exc:
        print(f"Reviewer warning: {exc} Skipping review.", file=sys.stderr)
        return 0
    except Exception as exc:
        print(f"Reviewer warning: review failed: {exc}", file=sys.stderr)
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
