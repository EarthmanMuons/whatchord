#!/usr/bin/env python3
"""Run WhatChord and available chord-name oracles for one input.

This is a quick manual exploration companion to bin/chord-debug. It accepts the
same note and bass arguments commonly used with chord-debug, then prints the top
WhatChord result and the labels returned by available third-party oracles.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from chord_oracle_compare import (
    DEFAULT_ORACLES,
    ORACLE_NAME_WIDTH,
    Music21Oracle,
    PychordOracle,
    TonalOracle,
    oracle_note_name,
    semantic_key_from_whatchord,
    semantic_keys,
)

DEFAULT_TOP = 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare one chord-debug input against available oracles.",
        add_help=False,
    )
    parser.add_argument("--oracles", nargs="+", choices=DEFAULT_ORACLES)
    parser.add_argument(
        "--top",
        type=int,
        default=DEFAULT_TOP,
        help="Number of ranked WhatChord and oracle labels to show.",
    )
    parser.add_argument("-h", "--help", action="store_true")
    args, passthrough = parser.parse_known_args()

    if args.help or not passthrough:
        print_usage()
        return 0 if args.help else 2

    repo_root = Path(__file__).resolve().parents[1]
    chord_debug = repo_root / "bin/chord-debug"
    debug_args = [
        *passthrough,
        "--format=json",
        f"--top={args.top}",
    ]
    what = run_chord_debug(chord_debug, debug_args)
    input_data = what["input"]
    notes = tuple(oracle_note_name(item["label"]) for item in input_data["pitchClasses"])
    bass = oracle_note_name(input_data["bassLabel"])
    candidates = what.get("candidates", [])[: args.top]

    oracles = available_oracles(args.oracles or list(DEFAULT_ORACLES))
    oracle_results = {oracle.name: oracle.detect(notes, bass) for oracle in oracles}

    for name, result in oracle_results.items():
        if result.status != "ok":
            print(f"  {name}: ERROR {result.detail}")
            continue
        if not result.labels:
            detail = f" ({result.detail})" if result.detail else ""
            print(f"  {name.ljust(ORACLE_NAME_WIDTH)}: <no label>{detail}")
            continue
        labels = result.labels[: args.top]
        for index, label in enumerate(labels):
            semantic = semantic_keys([label])
            semantic_label = (
                f"  [semantic: {semantic[0].display()}]" if semantic else ""
            )
            prefix = name.ljust(ORACLE_NAME_WIDTH) if index == 0 else " " * ORACLE_NAME_WIDTH
            print(f"  {prefix}: {index + 1}. {label}  {semantic_label}")

    if not oracle_results:
        print("  <no oracles available>")

    print("---------")
    if candidates:
        for index, candidate in enumerate(candidates, start=1):
            semantic = semantic_key_from_whatchord(candidate)
            semantic_label = f"  [semantic: {semantic.display()}]" if semantic else ""
            print(f"  whatchord: {index}. {candidate.get('symbol', '')}{semantic_label}")
    else:
        print("  whatchord: <no candidate>")

    return 0


def print_usage() -> None:
    print(
        """Usage:
  bin/chord-oracle [notes...] [chord-debug options]

Examples:
  bin/chord-oracle C E G
  bin/chord-oracle C D E A --bass=E
  bin/chord-oracle 60 64 67 70 --top=2

Common chord-debug options such as --bass, --key, and --notation are forwarded.
Use --top=N to show multiple ranked WhatChord and oracle labels where available.
Use --oracles music21 tonal pychord to limit external oracle output.
"""
    )


def run_chord_debug(chord_debug: Path, args: list[str]) -> dict:
    result = subprocess.run(
        [str(chord_debug), *args],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        raise SystemExit(result.returncode)
    return json.loads(result.stdout)


def available_oracles(names: list[str]):
    registry = {
        "music21": Music21Oracle(),
        "tonal": TonalOracle(),
        "pychord": PychordOracle(),
    }
    out = []
    for name in names:
        oracle = registry[name]
        available, reason = oracle.available()
        if available:
            out.append(oracle)
        else:
            print(f"Skipping {name}: {reason}", file=sys.stderr)
    return out


if __name__ == "__main__":
    raise SystemExit(main())
