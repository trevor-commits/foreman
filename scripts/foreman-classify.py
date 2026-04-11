#!/usr/bin/env python3
"""Classify a foreman task brief into cheap, standard, or escalation."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


CLASSIFIER_MODEL = "claude-haiku-4-5-20251001"
VALID_ROUTES = {"cheap", "standard", "escalation"}
UPWARD_ROUTE = {
    "cheap": "standard",
    "standard": "escalation",
    "escalation": "escalation",
}


class ClassifierError(Exception):
    """Raised when classifier output cannot be trusted."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Classify a foreman task brief.")
    parser.add_argument("brief_path", help="Path to brief.md")
    return parser.parse_args()


def fallback_result(reason: str) -> dict[str, Any]:
    return {
        "route": "standard",
        "confidence": 0.0,
        "reason": reason,
        "escalation_triggers": [],
    }


def read_brief(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def extract_inline_field(brief_text: str, field: str) -> str:
    match = re.search(rf"^\*\*{re.escape(field)}:\*\*\s*(.+)$", brief_text, flags=re.MULTILINE)
    return match.group(1).strip() if match else ""


def extract_block_field(brief_text: str, field: str) -> str:
    match = re.search(
        rf"^\*\*{re.escape(field)}:\*\*\s*(.*?)(?=^\*\*[A-Z][^*]+:\*\*|\Z)",
        brief_text,
        flags=re.MULTILINE | re.DOTALL,
    )
    return match.group(1).strip() if match else ""


def build_prompt(brief_text: str) -> str:
    goal = extract_inline_field(brief_text, "Goal") or "not specified"
    acceptance = extract_block_field(brief_text, "Acceptance Criteria") or "not specified"
    constraints = extract_block_field(brief_text, "Constraints") or "not specified"
    requested_model = extract_inline_field(brief_text, "Model") or "not specified"

    return f"""You are a task router for foreman.

Classify this task into one of three tiers: [cheap, standard, escalation].

Return only JSON:
{{ "route": "cheap|standard|escalation", "confidence": 0.0-1.0, "reason": "one sentence", "escalation_triggers": ["list of specific concerns or empty array"] }}

Routing guidance:
- cheap: low-risk clerical, docs, summarization, classification, or narrowly scoped script work that is cheap to verify
- standard: normal implementation, refactor, or test-writing work with clear acceptance criteria
- escalation: architecture, ambiguous requirements, risky changes, policy-sensitive work, or tasks where failure would be costly

Task brief:
Goal:
{goal}

Acceptance Criteria:
{acceptance}

Constraints:
{constraints}

Requested Model:
{requested_model}
"""


def call_anthropic(prompt: str) -> tuple[str, str, bool]:
    if not os.getenv("ANTHROPIC_API_KEY"):
        result = fallback_result("no API key — defaulting to standard")
        return json.dumps(result), CLASSIFIER_MODEL, True

    try:
        from anthropic import Anthropic
    except ImportError:
        result = fallback_result("anthropic package not installed — defaulting to standard")
        return json.dumps(result), CLASSIFIER_MODEL, True

    client = Anthropic()
    message = client.messages.create(
        model=CLASSIFIER_MODEL,
        max_tokens=400,
        messages=[{"role": "user", "content": prompt}],
    )

    parts = [block.text for block in message.content if getattr(block, "type", None) == "text"]
    if parts:
        return "\n".join(parts), getattr(message, "model", CLASSIFIER_MODEL), False

    raise ClassifierError("Anthropic response did not include text output.")


def extract_json_object(raw_text: str) -> dict[str, Any]:
    text = raw_text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, flags=re.DOTALL)
        if not match:
            raise ClassifierError("Classifier output did not contain a JSON object.")
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError as exc:
            raise ClassifierError("Classifier output was not valid JSON.") from exc


def validate_result(result: dict[str, Any], actual_model: str) -> dict[str, Any]:
    route = result.get("route")
    if route not in VALID_ROUTES:
        raise ClassifierError(f"Invalid route: {route!r}")

    confidence = result.get("confidence")
    if not isinstance(confidence, (int, float)):
        raise ClassifierError("Classifier confidence must be numeric.")
    confidence = max(0.0, min(1.0, float(confidence)))

    reason = result.get("reason")
    if not isinstance(reason, str) or not reason.strip():
        raise ClassifierError("Classifier reason is missing.")

    triggers = result.get("escalation_triggers", [])
    if not isinstance(triggers, list) or any(not isinstance(item, str) for item in triggers):
        raise ClassifierError("Classifier escalation_triggers must be a list of strings.")

    return {
        "route": route,
        "confidence": confidence,
        "reason": reason.strip(),
        "escalation_triggers": [item.strip() for item in triggers if item.strip()],
        "classifier_model": actual_model,
    }


def apply_policy(result: dict[str, Any]) -> dict[str, Any]:
    route = result["route"]
    reason = result["reason"].rstrip()
    triggers = result["escalation_triggers"]
    classifier_model = result["classifier_model"]

    if triggers:
        if route != "escalation":
            reason = f"{reason.rstrip('.')} (policy override: escalation_triggers present)."
        route = "escalation"
    elif result["confidence"] < 0.7:
        routed = UPWARD_ROUTE[route]
        if routed != route:
            reason = f"{reason.rstrip('.')} (policy override: confidence below 0.7 routed upward to {routed})."
        route = routed

    return {
        "route": route,
        "confidence": result["confidence"],
        "reason": reason,
        "escalation_triggers": triggers,
        "classifier_model": classifier_model,
    }


def main() -> int:
    args = parse_args()
    brief_text = read_brief(args.brief_path)
    prompt = build_prompt(brief_text)

    raw_output, actual_model, used_fallback = call_anthropic(prompt)
    if used_fallback:
        print(raw_output)
        return 0

    result = validate_result(extract_json_object(raw_output), actual_model)
    print(json.dumps(apply_policy(result)))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ClassifierError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
