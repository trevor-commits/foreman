#!/usr/bin/env python3
"""Run a cross-model review for the current diff."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


# Keep Anthropic model identifiers aligned with the canonical routing names in CLAUDE.md.
OPENAI_REVIEW_MODEL = "o4-mini"
CLAUDE_HAIKU_MODEL = "claude-haiku-4-5-20251001"
CLAUDE_SONNET_MODEL = "claude-sonnet-4-6"
CLAUDE_OPUS_MODEL = "claude-opus-4-6"
CLAUDE_REVIEW_MODEL = os.getenv("FOREMAN_ANTHROPIC_REVIEW_MODEL", CLAUDE_SONNET_MODEL)
# If a Claude-authored diff needs review but OPENAI_API_KEY is not configured, fall back to
# a second Claude model rather than skipping immediately. This keeps cross-model review
# working in Anthropic-only setups until the OpenAI path is validated more broadly.
CLAUDE_FALLBACK_MODEL = os.getenv(
    "FOREMAN_ANTHROPIC_FALLBACK_MODEL",
    CLAUDE_HAIKU_MODEL,
)
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
        if os.getenv("OPENAI_API_KEY"):
            return "openai", OPENAI_REVIEW_MODEL
        return "anthropic", CLAUDE_FALLBACK_MODEL

    if "codex" in author_lower or "gpt" in author_lower:
        return "anthropic", CLAUDE_REVIEW_MODEL

    return "anthropic", CLAUDE_REVIEW_MODEL


def build_prompt(diff_text: str, author_model: str, branch: str) -> str:
    return f"""You are a code reviewer. Read the diff below and return a JSON object with this exact schema:

{{
  "verdict": "APPROVE" | "REQUEST_CHANGES" | "BLOCKER",
  "summary": "<one sentence>",
  "issues": [
    {{ "severity": "info" | "warning" | "blocking", "location": "<file:line or general>", "note": "<what and why>" }}
  ],
  "reviewer_model": "<model name>"
}}

Rules:
- APPROVE: diff is correct, complete, and safe to merge
- REQUEST_CHANGES: meaningful concerns but not merge-blocking; author should fix before merge
- BLOCKER: security issue, data loss risk, broken logic, or missing required foreman trailers
- Do not flag style preferences as REQUEST_CHANGES — only flag things that affect correctness, safety, or compliance
- If the diff is empty or whitespace-only, return APPROVE with summary "Empty diff — nothing to review"
- Return only the JSON object, no other text

Author model: {author_model}
Branch: {branch}

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
        "reviewer_model": "claude-sonnet-4-6",
    }
    encoded = json.dumps(sample)
    fenced = f"```json\n{encoded}\n```"
    wrapped = f"Reviewer output follows:\n{encoded}\nThanks."

    assert extract_json_object(encoded)["verdict"] == "APPROVE"
    assert extract_json_object(fenced)["summary"] == "Empty diff — nothing to review"
    assert extract_json_object(wrapped)["reviewer_model"] == "claude-sonnet-4-6"


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


def write_review_file(review: dict[str, Any]) -> Path:
    candidates = [
        repo_root() / ".agent-runs",
        Path.cwd() / ".agent-runs",
        Path(tempfile.gettempdir()) / "foreman-agent-runs",
    ]

    for runs_dir in candidates:
        try:
            runs_dir.mkdir(parents=True, exist_ok=True)
            output_path = runs_dir / "last-review.json"
            output_path.write_text(json.dumps(review, indent=2) + "\n", encoding="utf-8")
            return output_path
        except OSError:
            continue

    return Path("<review-json-not-written>")


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
