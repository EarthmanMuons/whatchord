#!/usr/bin/env python3
"""Run WhatChord and available chord-name oracles for one input.

This is a quick manual exploration companion to bin/chord-debug. It accepts the
same note and bass arguments commonly used with chord-debug, then prints the top
WhatChord result and the labels returned by available third-party oracles.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from oracle_compare import (
    DEFAULT_ORACLES,
    DEFAULT_REVIEWED_PATH,
    NOTE_NAMES,
    Music21Oracle,
    PychordOracle,
    TonalOracle,
    canonical_pc_set,
    load_reviewed,
    oracle_note_name,
    semantic_key_from_whatchord,
    semantic_keys,
)

DEFAULT_TOP = 3


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

    if len(passthrough) == 1 and (expanded := _expand_case_id(passthrough[0])):
        passthrough = expanded

    repo_root = Path(__file__).resolve().parents[2]
    chord_debug = repo_root / "bin/chord-debug"
    debug_args = [
        *passthrough,
        "--format=json",
        f"--top={args.top}",
    ]
    what = run_chord_debug(chord_debug, debug_args)
    input_data = what["input"]
    notes = tuple(
        oracle_note_name(item["label"]) for item in input_data["pitchClasses"]
    )
    bass = oracle_note_name(input_data["bassLabel"])
    candidates = what.get("candidates", [])[: args.top]

    oracles = available_oracles(args.oracles or list(DEFAULT_ORACLES))
    oracle_results = {oracle.name: oracle.detect(notes, bass) for oracle in oracles}

    oracle_rows: list[tuple[str, str, str]] = []
    for name, result in oracle_results.items():
        if result.status != "ok":
            oracle_rows.append((name, f"ERROR {result.detail}", ""))
            continue
        if not result.labels:
            detail = f" ({result.detail})" if result.detail else ""
            oracle_rows.append((name, f"<no label>{detail}", ""))
            continue
        for index, label in enumerate(result.labels[: args.top]):
            semantic = semantic_keys([label])
            semantic_label = f"[semantic: {semantic[0].display()}]" if semantic else ""
            display_name = name if index == 0 else ""
            oracle_rows.append((display_name, f"{index + 1}. {label}", semantic_label))

    whatchord_rows: list[tuple[str, str, str]] = []
    if candidates:
        for index, candidate in enumerate(candidates, start=1):
            semantic = semantic_key_from_whatchord(candidate)
            semantic_label = f"[semantic: {semantic.display()}]" if semantic else ""
            whatchord_rows.append(
                ("whatchord", f"{index}. {candidate.get('symbol', '')}", semantic_label)
            )
    else:
        whatchord_rows.append(("whatchord", "<no candidate>", ""))

    all_rows = oracle_rows + whatchord_rows
    name_width = max(len(name) for name, _, _ in all_rows)
    body_width = max(
        (len(body) for _, body, semantic in all_rows if semantic), default=0
    )

    def format_row(row: tuple[str, str, str]) -> str:
        name, body, semantic = row
        prefix = f"  {name.rjust(name_width)}: "
        if not semantic:
            return f"{prefix}{body}"
        return f"{prefix}{body.ljust(body_width)}  {semantic}"

    for row in oracle_rows:
        print(format_row(row))
    if not oracle_results:
        print("  <no oracles available>")

    print("------------")
    for row in whatchord_rows:
        print(format_row(row))

    pcs = tuple(item["pc"] for item in input_data["pitchClasses"])
    matches = reviewed_matches(
        pcs, input_data["bassPc"], load_reviewed(DEFAULT_REVIEWED_PATH)
    )
    if matches:
        print("------------")
        print_reviewed_matches(matches)

    return 0


def reviewed_matches(
    pcs: tuple[int, ...],
    bass_pc: int,
    reviewed: dict[str, dict[str, str]],
) -> list[tuple[str, int, dict[str, str], str]]:
    """Find reviewed entries whose canonical pattern this voicing matches.

    The reviewed file is keyed by canonical (transposition-collapsed) case IDs,
    so any transposition of a reviewed shape resolves to the same entry. For
    each root that maps the input onto its canonical set, the offset is the
    interval between this run and the canonical example. Symmetric sets can map
    onto more than one reviewed case, so every distinct match is returned. Each
    match carries a chord-debug command for the canonical example's notes.
    """
    canonical = canonical_pc_set(pcs)
    matches: dict[str, tuple[str, int, dict[str, str], str]] = {}
    for root in sorted(set(pcs)):
        if tuple(sorted((pc - root) % 12 for pc in pcs)) != canonical:
            continue
        canonical_bass = (bass_pc - root) % 12
        case_id = f"{'-'.join(str(pc) for pc in canonical)}_b{canonical_bass}"
        entry = reviewed.get(case_id)
        if entry and case_id not in matches:
            notes = " ".join(NOTE_NAMES[pc] for pc in canonical)
            debug_cmd = f"bin/chord-debug {notes} --bass={NOTE_NAMES[canonical_bass]}"
            matches[case_id] = (case_id, root % 12, entry, debug_cmd)
    return [matches[key] for key in sorted(matches)]


def print_reviewed_matches(
    matches: list[tuple[str, int, dict[str, str], str]],
) -> None:
    for case_id, offset, entry, debug_cmd in matches:
        if offset == 0:
            shift = "same pitch level as the reviewed example"
        else:
            shift = f"+{offset} semitones from the reviewed example"
        print(f"   reviewed: {case_id}  [{entry['label']}]  ({shift})")
        print(f"             {entry['note']}")
        print(f"             replay: bin/chord-oracle {case_id}")
        print(f"                     {debug_cmd}")


def print_usage() -> None:
    print(
        """Usage:
  bin/chord-oracle [notes...] [chord-debug options]
  bin/chord-oracle <case-id>

Examples:
  bin/chord-oracle C E G
  bin/chord-oracle C D E A --bass=E
  bin/chord-oracle 60 64 67 70 --top=2
  bin/chord-oracle 0-1-4-7-10_b1

A case ID (e.g. from oracle_compare reports) is expanded to note names
automatically. Common chord-debug options such as --bass, --key, and --notation
are forwarded. Use --top=N to show multiple ranked WhatChord and oracle labels
where available. Use --oracles music21 tonal pychord to limit external oracle
output.
"""
    )


def _expand_case_id(arg: str) -> list[str] | None:
    """Expand a compare-tool case ID like '0-1-4-7-10_b1' to note + bass args."""
    m = re.match(r"^(\d+(?:-\d+)*)_b(\d+)$", arg)
    if not m:
        return None
    pcs = [int(x) for x in m.group(1).split("-")]
    bass_pc = int(m.group(2))
    if not all(0 <= pc <= 11 for pc in pcs) or not (0 <= bass_pc <= 11):
        return None
    if bass_pc not in pcs:
        return None
    return [NOTE_NAMES[pc] for pc in pcs] + [f"--bass={NOTE_NAMES[bass_pc]}"]


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
