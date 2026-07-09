#!/usr/bin/env python3
"""Verify or print the WhatKey headline result table.

The headline table in research/whatkey/README.md is intentionally reproducible
from committed result artifacts, without requiring access to the licensed
fixture corpora. This script reads those reports and checks the rounded table
values used on the landing page.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path


DEFAULT_ROOT = Path("research/whatkey/results/test-split-2026-07-07")
EXPECTED_ROWS = (
    ("WhatKey (causal, abstaining)", "0.88", "0.732", "0.782"),
    ("music21 Temperley-Kostka-Payne", "1.00", "0.637", "0.740"),
    ("music21 Krumhansl-Schmuckler", "1.00", "0.624", "0.726"),
    ("music21 Aarden-Essen", "1.00", "0.558", "0.690"),
)


@dataclass(frozen=True)
class HeadlineRow:
    label: str
    report_dir: str


ROWS = (
    HeadlineRow("WhatKey (causal, abstaining)", "test-iso-hmm-shipped"),
    HeadlineRow("music21 Temperley-Kostka-Payne", "test-iso-m21-temperleykostkapayne"),
    HeadlineRow("music21 Krumhansl-Schmuckler", "test-iso-m21-krumhanslschmuckler"),
    HeadlineRow("music21 Aarden-Essen", "test-iso-m21-aardenessen"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=DEFAULT_ROOT,
        help="Directory containing the headline report subdirectories.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if the rounded table differs from README values.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows = tuple(read_row(args.root, row) for row in ROWS)
    print(render_markdown(rows))

    if args.check and rows != EXPECTED_ROWS:
        print("Headline table mismatch.", file=sys.stderr)
        print("Expected:", file=sys.stderr)
        print(render_markdown(EXPECTED_ROWS), file=sys.stderr)
        return 1

    if args.check:
        print("Headline table matches committed report artifacts.")
    return 0


def read_row(root: Path, row: HeadlineRow) -> tuple[str, str, str, str]:
    report_path = root / row.report_dir / "report.json"
    try:
        report = json.loads(report_path.read_text())
    except FileNotFoundError:
        raise SystemExit(f"Missing report: {report_path}") from None

    summary = report["summary"]
    coverage = summary["coverage"]["meanPerPiece"]
    accuracy = summary["accuracyOnClaimed"]
    exact = accuracy["meanExactPerPiece"]
    mirex = accuracy["meanMirexPerPiece"]
    return (row.label, f"{coverage:.2f}", f"{exact:.3f}", f"{mirex:.3f}")


def render_markdown(rows: tuple[tuple[str, str, str, str], ...]) -> str:
    lines = [
        "| system                         | coverage | exact | MIREX |",
        "| ------------------------------ | -------- | ----- | ----- |",
    ]
    for label, coverage, exact, mirex in rows:
        lines.append(f"| {label:<30} | {coverage:<8} | {exact:<5} | {mirex:<5} |")
    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
