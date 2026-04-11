#!/usr/bin/env python3
"""Summarize foreman reviewer telemetry for burn-in calibration."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path


LOG_PATH = Path(__file__).resolve().parent.parent / ".agent-runs" / "review-log.jsonl"
READINESS_WINDOW_DAYS = 14
READINESS_MIN_REVIEWS = 5


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Summarize reviewer telemetry from review-log.jsonl.")
    parser.add_argument("--days", type=int, help="Limit the report to the last N days.")
    return parser.parse_args()


def parse_timestamp(value: str) -> datetime:
    normalized = value.strip()
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def load_records(path: Path) -> list[dict]:
    records: list[dict] = []
    with path.open(encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line:
                continue
            record = json.loads(line)
            record["parsed_timestamp"] = parse_timestamp(record["timestamp"])
            records.append(record)
    return sorted(records, key=lambda item: item["parsed_timestamp"])


def filter_records(records: list[dict], days: int | None) -> list[dict]:
    if days is None:
        return list(records)
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    return [record for record in records if record["parsed_timestamp"] >= cutoff]


def author_prefix(author_model: str) -> str:
    lowered = author_model.lower()
    if "claude" in lowered:
        return "claude"
    if "codex" in lowered:
        return "codex"
    if "gpt" in lowered:
        return "gpt"
    return "unknown"


def pct(part: int, whole: int) -> str:
    if whole == 0:
        return "0.0%"
    return f"{(part / whole) * 100:.1f}%"


def print_no_telemetry_message() -> int:
    print(
        "No telemetry recorded yet. Run a review pass first: git diff main...HEAD | "
        "python3 scripts/foreman-review.py --author-model <model> --branch <branch> -"
    )
    return 0


def main() -> int:
    args = parse_args()

    if not LOG_PATH.exists() or LOG_PATH.stat().st_size == 0:
        return print_no_telemetry_message()

    records = load_records(LOG_PATH)
    if not records:
        return print_no_telemetry_message()

    report_records = filter_records(records, args.days)
    if not report_records:
        window = f"last {args.days} days" if args.days is not None else "selected window"
        print(f"No telemetry recorded in the {window}.")
        return 0

    total = len(report_records)
    first_seen = report_records[0]["parsed_timestamp"].date().isoformat()
    last_seen = report_records[-1]["parsed_timestamp"].date().isoformat()
    distinct_branches = sorted({record["branch"] for record in report_records})

    print("SUMMARY")
    print(f"Total reviews: {total}")
    print(f"Date range: {first_seen} to {last_seen}")
    print(f"Distinct branches reviewed: {len(distinct_branches)}")
    print("")

    print("VERDICT DISTRIBUTION")
    verdicts = ["APPROVE", "REQUEST_CHANGES", "BLOCKER"]
    for verdict in verdicts:
        count = sum(1 for record in report_records if record["verdict"] == verdict)
        print(f"{verdict}: {count} ({pct(count, total)})")
    print("")

    print("BLOCKER ANALYSIS")
    blockers = [record for record in report_records if record["verdict"] == "BLOCKER"]
    if not blockers:
        print("No BLOCKERs recorded — burn-in window looks clean.")
    else:
        for record in blockers:
            print(f"{record['timestamp']} | {record['branch']} | {record['summary']}")
    print("")

    print("REVIEWER MODEL USAGE")
    reviewer_counts: dict[str, int] = {}
    for record in report_records:
        reviewer = record["reviewer_model"]
        reviewer_counts[reviewer] = reviewer_counts.get(reviewer, 0) + 1
    for reviewer, count in sorted(reviewer_counts.items(), key=lambda item: (-item[1], item[0])):
        print(f"{reviewer}: {count}")
    print("")

    print("AUTHOR MODEL ROUTING")
    routing_counts: dict[str, dict[str, int]] = {prefix: {} for prefix in ("claude", "codex", "gpt", "unknown")}
    for record in report_records:
        prefix = author_prefix(record["author_model"])
        reviewer = record["reviewer_model"]
        routing_counts[prefix][reviewer] = routing_counts[prefix].get(reviewer, 0) + 1
    for prefix in ("claude", "codex", "gpt", "unknown"):
        reviewers = routing_counts[prefix]
        if not reviewers:
            print(f"{prefix}: none")
            continue
        parts = [f"{reviewer} ({count})" for reviewer, count in sorted(reviewers.items(), key=lambda item: (-item[1], item[0]))]
        print(f"{prefix}: {', '.join(parts)}")
    print("")

    print("DIFF SIZE DISTRIBUTION")
    diff_sizes = [record["diff_line_count"] for record in report_records]
    avg_diff = sum(diff_sizes) / len(diff_sizes)
    print(f"Min: {min(diff_sizes)}")
    print(f"Max: {max(diff_sizes)}")
    print(f"Avg: {avg_diff:.1f}")
    print("")

    print("HARD-GATE READINESS")
    readiness_records = filter_records(records, READINESS_WINDOW_DAYS)
    readiness_total = len(readiness_records)
    readiness_blockers = sum(1 for record in readiness_records if record["verdict"] == "BLOCKER")
    if readiness_total < READINESS_MIN_REVIEWS:
        print(
            f"INSUFFICIENT DATA: Only {readiness_total} reviews in the last {READINESS_WINDOW_DAYS} days — "
            "run more reviews before deciding"
        )
    elif readiness_blockers == 0:
        print(
            f"READY: {readiness_total} reviews, 0 BLOCKERs in the last {READINESS_WINDOW_DAYS} days — "
            "safe to promote FOREMAN_HARD_GATE=1"
        )
    else:
        print(
            f"NOT READY: {readiness_blockers} BLOCKERs in the last {READINESS_WINDOW_DAYS} days — "
            "review them before promoting hard gate"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
