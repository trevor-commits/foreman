#!/usr/bin/env python3
"""Standard-library smoke tests for foreman-review.py."""

from __future__ import annotations

import importlib.util
import json
import os
import sys
import tempfile
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
SCRIPT_PATH = ROOT_DIR / "scripts" / "foreman-review.py"


def load_module():
    spec = importlib.util.spec_from_file_location("foreman_review", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


module = load_module()


def run_test(description: str, fn) -> None:
    try:
        fn()
    except Exception as exc:  # noqa: BLE001 - keep the harness dependency-free.
        print(f"FAIL: {description}")
        print(f"  {type(exc).__name__}: {exc}")
        raise SystemExit(1) from exc
    print(f"PASS: {description}")


def test_empty_diff_review() -> None:
    os.environ.pop("OPENAI_API_KEY", None)
    provider, reviewer_model = module.resolve_reviewer("codex-5.3")
    assert provider == "anthropic", provider
    assert reviewer_model == "claude-sonnet-4-6", reviewer_model

    review = module.empty_diff_review(reviewer_model)
    assert review["verdict"] == "APPROVE", review
    assert review["summary"] == "Empty diff — nothing to review", review
    assert review["issues"] == [], review
    assert review["reviewer_model"] == "claude-sonnet-4-6", review


def test_codex_route_without_openai_key() -> None:
    os.environ.pop("OPENAI_API_KEY", None)
    provider, reviewer_model = module.resolve_reviewer("codex-5.3")
    assert provider == "anthropic", provider
    assert reviewer_model == "claude-sonnet-4-6", reviewer_model


def test_claude_route_without_openai_key() -> None:
    os.environ.pop("OPENAI_API_KEY", None)
    provider, reviewer_model = module.resolve_reviewer("claude-sonnet-4-6")
    assert provider == "anthropic", provider
    assert reviewer_model == "claude-haiku-4-5-20251001", reviewer_model


def test_extract_json_from_fence() -> None:
    payload = '```json\n{"verdict":"APPROVE","summary":"ok","issues":[],"reviewer_model":"test"}\n```'
    result = module.extract_json_object(payload)
    assert result["verdict"] == "APPROVE", result
    assert result["reviewer_model"] == "test", result


def test_extract_json_from_bare_string() -> None:
    payload = '{"verdict":"APPROVE","summary":"ok","issues":[],"reviewer_model":"test"}'
    result = module.extract_json_object(payload)
    assert result["summary"] == "ok", result
    assert result["issues"] == [], result


def test_validate_review_missing_verdict() -> None:
    bad_review = {"summary": "missing verdict", "issues": []}
    try:
        module.validate_review(bad_review, "test-model")
    except module.ReviewError:
        return
    raise AssertionError("validate_review should raise ReviewError when verdict is missing")


def test_validate_review_invalid_severity() -> None:
    bad_review = {
        "verdict": "REQUEST_CHANGES",
        "summary": "bad severity",
        "issues": [{"severity": "critical", "location": "foo.py:1", "note": "bad"}],
    }
    try:
        module.validate_review(bad_review, "test-model")
    except module.ReviewError:
        return
    raise AssertionError("validate_review should raise ReviewError for invalid issue severity")


def test_validate_review_accepts_valid_review_with_reviewer_model() -> None:
    good_review = {
        "verdict": "APPROVE",
        "summary": "looks good",
        "issues": [],
        "reviewer_model": "claude-sonnet-4-6",
    }
    result = module.validate_review(good_review, "o4-mini")
    assert result["verdict"] == "APPROVE", result
    assert result["summary"] == "looks good", result
    assert result["issues"] == [], result
    assert result["reviewer_model"] == "o4-mini", result


def test_validate_review_rejects_issue_missing_note() -> None:
    bad_review = {
        "verdict": "REQUEST_CHANGES",
        "summary": "missing note",
        "issues": [{"severity": "warning", "location": "foo.py:1"}],
        "reviewer_model": "claude-sonnet-4-6",
    }
    try:
        module.validate_review(bad_review, "test-model")
    except module.ReviewError:
        return
    raise AssertionError("validate_review should raise ReviewError when issue note is missing")


def test_append_telemetry_writes_jsonl_record() -> None:
    review = {
        "verdict": "REQUEST_CHANGES",
        "summary": "Needs branch cleanup",
        "issues": [
            {"severity": "warning", "location": "general", "note": "Rename the branch"},
            {"severity": "blocking", "location": "general", "note": "Do not self-review"},
        ],
        "reviewer_model": "claude-sonnet-4-6",
    }
    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        original_repo_root = module.repo_root
        module.repo_root = lambda: tmp_path
        try:
            output_path = module.append_telemetry(
                review,
                "codex-5.3",
                "agent/codex/2026-04-11/test-telemetry",
                "anthropic",
                "line 1\nline 2\nline 3\n",
            )
        finally:
            module.repo_root = original_repo_root

        assert output_path == tmp_path / ".agent-runs" / "review-log.jsonl", output_path
        payload = output_path.read_text(encoding="utf-8").strip()
        record = json.loads(payload)
        assert record["branch"] == "agent/codex/2026-04-11/test-telemetry", record
        assert record["author_model"] == "codex-5.3", record
        assert record["reviewer_model"] == "claude-sonnet-4-6", record
        assert record["provider"] == "anthropic", record
        assert record["verdict"] == "REQUEST_CHANGES", record
        assert record["issue_count"] == 2, record
        assert record["blocking_count"] == 1, record
        assert record["warning_count"] == 1, record
        assert record["info_count"] == 0, record
        assert record["summary"] == "Needs branch cleanup", record
        assert record["diff_line_count"] == 3, record
        assert record["timestamp"].endswith("Z"), record


def main() -> int:
    tests = [
        ("empty diff returns APPROVE without an API call", test_empty_diff_review),
        ("codex author routes to anthropic sonnet", test_codex_route_without_openai_key),
        ("claude author without OPENAI_API_KEY routes to anthropic haiku", test_claude_route_without_openai_key),
        ("extract_json_object parses markdown-fenced JSON", test_extract_json_from_fence),
        ("extract_json_object parses bare JSON", test_extract_json_from_bare_string),
        ("validate_review rejects missing verdict", test_validate_review_missing_verdict),
        ("validate_review rejects invalid severity", test_validate_review_invalid_severity),
        ("validate_review accepts a valid review payload with reviewer_model", test_validate_review_accepts_valid_review_with_reviewer_model),
        ("validate_review rejects an issue missing note", test_validate_review_rejects_issue_missing_note),
        ("append_telemetry writes a JSONL telemetry record", test_append_telemetry_writes_jsonl_record),
    ]

    for description, fn in tests:
        run_test(description, fn)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
