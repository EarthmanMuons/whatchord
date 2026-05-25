#!/usr/bin/env python3
"""Compare WhatChord chord names with optional third-party oracle libraries.

This is a discovery harness, not a test oracle. Disagreement rows are prompts
for musical review, especially when mature tools disagree with each other.

Examples:
  python3 tool/chord_oracle_compare.py --max-cases 200
  python3 tool/chord_oracle_compare.py --min-notes 3 --max-notes 5 --basses all
  python3 tool/chord_oracle_compare.py --oracles music21 tonal pychord
"""

from __future__ import annotations

import argparse
import csv
import itertools
import json
import random
import re
import secrets
import shutil
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
DEFAULT_ORACLES = ("music21", "tonal", "pychord")
ORACLE_NAME_WIDTH = max(len(name) for name in DEFAULT_ORACLES)
DEFAULT_MIN_NOTES = 3
DEFAULT_MAX_NOTES = 7
DEFAULT_BASSES = "all"
DEFAULT_CASE_ORDER = "random"
DEFAULT_MAX_CASES = 500
DEFAULT_TOP = 4
DEFAULT_REPORT_LIMIT = 50
REVIEW_FLAG_EXPLANATIONS = {
    "disagreement": "Comparable oracle labels were available, but none matched WhatChord's top label.",
    "oracle-split": "At least one oracle matched WhatChord and at least one comparable oracle disagreed.",
    "insufficient-oracle-labels": "The row did not have enough comparable external chord labels for a useful comparison.",
    "oracle-error": "At least one oracle failed while processing the row.",
    "no-whatchord-candidate": "WhatChord did not produce a candidate for the input.",
    "agree": "Comparable oracle labels matched WhatChord's top label.",
}
REVIEW_PRIORITY = {
    "disagreement": 0,
    "oracle-split": 1,
    "no-whatchord-candidate": 2,
    "oracle-error": 3,
    "insufficient-oracle-labels": 4,
    "agree": 5,
}
PRACTICAL_INTERVAL_SETS = (
    (0, 4, 7),
    (0, 3, 7),
    (0, 3, 8),
    (0, 3, 6),
    (0, 4, 8),
    (0, 2, 7),
    (0, 5, 7),
    (0, 4, 7, 9),
    (0, 3, 7, 9),
    (0, 4, 7, 10),
    (0, 4, 7, 11),
    (0, 3, 7, 10),
    (0, 3, 8, 10),
    (0, 3, 6, 10),
    (0, 3, 6, 9),
    (0, 3, 7, 11),
    (0, 4, 8, 10),
    (0, 4, 8, 11),
    (0, 3, 4, 7),
    (0, 3, 4, 10),
    (0, 3, 4, 7, 10),
    (0, 3, 4, 7, 9),
    (0, 4, 7, 10, 1),
    (0, 4, 7, 10, 2),
    (0, 4, 7, 10, 3),
    (0, 4, 7, 10, 6),
    (0, 4, 7, 10, 8),
    (0, 4, 7, 10, 9),
    (0, 4, 7, 11, 2),
    (0, 3, 7, 10, 2),
    (0, 3, 7, 10, 5),
    (0, 3, 7, 10, 9),
)


@dataclass(frozen=True)
class Case:
    case_id: str
    pcs: tuple[int, ...]
    bass_pc: int

    @property
    def notes(self) -> tuple[str, ...]:
        return tuple(NOTE_NAMES[pc] for pc in self.pcs)

    @property
    def bass(self) -> str:
        return NOTE_NAMES[self.bass_pc]


@dataclass(frozen=True)
class OracleResult:
    status: str
    labels: tuple[str, ...] = ()
    detail: str = ""

    @property
    def primary(self) -> str:
        return self.labels[0] if self.labels else ""


class Oracle:
    name: str

    def available(self) -> tuple[bool, str]:
        raise NotImplementedError

    def detect(self, notes: tuple[str, ...], bass: str) -> OracleResult:
        raise NotImplementedError


class Music21Oracle(Oracle):
    name = "music21"

    def available(self) -> tuple[bool, str]:
        try:
            import music21  # noqa: F401
        except ImportError as error:
            return False, str(error)
        return True, ""

    def detect(self, notes: tuple[str, ...], bass: str) -> OracleResult:
        from music21 import chord, harmony

        try:
            # music21 determines inversion from the lowest pitch, not the first
            # note. Keep the requested bass below the other pitch classes so
            # slash-chord comparisons use the same bass as WhatChord.
            c = chord.Chord(_music21_voicing(notes, bass))
            symbol = harmony.chordSymbolFromChord(c)
            figure = str(getattr(symbol, "figure", "") or "")
            if figure == "Chord Symbol Cannot Be Identified":
                return OracleResult("ok")
            return OracleResult("ok", (figure,))
        except Exception as error:  # pragma: no cover - depends on optional lib
            return OracleResult("ok", detail=f"music21 chord symbol unavailable: {error}")


class PychordOracle(Oracle):
    name = "pychord"

    def available(self) -> tuple[bool, str]:
        try:
            import pychord  # noqa: F401
        except ImportError as error:
            return False, str(error)
        return True, ""

    def detect(self, notes: tuple[str, ...], bass: str) -> OracleResult:
        try:
            from pychord import find_chords_from_notes

            chords = find_chords_from_notes(list(_bass_first(notes, bass)))
            return OracleResult("ok", tuple(str(chord) for chord in chords))
        except Exception as error:  # pragma: no cover - depends on optional lib
            return OracleResult("error", detail=str(error))


class TonalOracle(Oracle):
    name = "tonal"

    def available(self) -> tuple[bool, str]:
        if shutil.which("node") is None:
            return False, "node was not found"
        result = subprocess.run(
            [
                "node",
                "-e",
                (
                    "for (const n of ['@tonaljs/tonal','tonal']) {"
                    "try { require(n); process.exit(0); } catch (_) {}"
                    "} process.exit(1);"
                ),
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            return False, "neither @tonaljs/tonal nor tonal could be required"
        return True, ""

    def detect(self, notes: tuple[str, ...], bass: str) -> OracleResult:
        script = (
            "let tonal;"
            "for (const n of ['@tonaljs/tonal','tonal']) {"
            "try { tonal = require(n); break; } catch (_) {}"
            "}"
            "const notes = JSON.parse(process.argv[1]);"
            "const labels = tonal.Chord.detect(notes) || [];"
            "console.log(JSON.stringify(labels));"
        )
        result = subprocess.run(
            ["node", "-e", script, json.dumps(list(_bass_first(notes, bass)))],
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            return OracleResult("error", detail=result.stderr.strip())
        try:
            return OracleResult("ok", tuple(json.loads(result.stdout)))
        except json.JSONDecodeError as error:
            return OracleResult("error", detail=str(error))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--min-notes", type=int, default=DEFAULT_MIN_NOTES)
    parser.add_argument("--max-notes", type=int, default=DEFAULT_MAX_NOTES)
    parser.add_argument(
        "--basses",
        dest="basses",
        choices=["lowest", "all"],
        default=DEFAULT_BASSES,
        help="Which bass choices to generate for each pitch-class set.",
    )
    parser.add_argument(
        "--all-transpositions",
        action="store_true",
        help="Generate every transposition instead of one canonical form.",
    )
    parser.add_argument(
        "--include-practical-seeds",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Start with common chord shapes before exhaustive chromatic sets.",
    )
    parser.add_argument(
        "--max-cases",
        type=int,
        default=DEFAULT_MAX_CASES,
        help="Stop after this many generated cases. Use 0 for no limit.",
    )
    parser.add_argument(
        "--case-order",
        choices=["ordered", "random"],
        default=DEFAULT_CASE_ORDER,
        help="Use deterministic generation order or seeded random order.",
    )
    parser.add_argument(
        "--seed",
        help="Seed for --case-order=random. If omitted, a seed is generated and reported.",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=DEFAULT_TOP,
        help="WhatChord candidate count.",
    )
    parser.add_argument(
        "--report-limit",
        type=int,
        default=DEFAULT_REPORT_LIMIT,
        help="Maximum number of attention rows to include in the text report.",
    )
    parser.add_argument(
        "--oracles",
        nargs="+",
        choices=DEFAULT_ORACLES,
        default=list(DEFAULT_ORACLES),
    )
    parser.add_argument("--out-dir", type=Path, default=Path("build/oracle-compare"))
    parser.add_argument("--chord-debug", type=Path, default=Path("bin/chord-debug"))
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    chord_debug = args.chord_debug
    if not chord_debug.is_absolute():
        chord_debug = repo_root / chord_debug

    oracles = _available_oracles(args.oracles)
    if not oracles:
        print("No optional oracles are available; install one of music21, tonal, or pychord.", file=sys.stderr)
        return 2

    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    summary = Counter()

    generated_cases = list(
        generate_cases(
            min_notes=args.min_notes,
            max_notes=args.max_notes,
            basses=args.basses,
            canonical_transpositions=not args.all_transpositions,
            include_practical_seeds=args.include_practical_seeds,
        )
    )
    seed = args.seed
    if args.case_order == "random":
        if seed is None:
            seed = str(secrets.randbits(64))
        random.Random(seed).shuffle(generated_cases)

    cases = generated_cases[: args.max_cases] if args.max_cases else generated_cases

    case_generation = {
        "min_notes": args.min_notes,
        "max_notes": args.max_notes,
        "basses": args.basses,
        "all_transpositions": args.all_transpositions,
        "include_practical_seeds": args.include_practical_seeds,
        "case_order": args.case_order,
        "seed": seed,
        "generated_cases": len(generated_cases),
        "selected_cases": len(cases),
        "max_cases": args.max_cases,
    }
    reproduce_command = reproduction_command(
        case_generation=case_generation,
        max_cases=args.max_cases,
        top=args.top,
        report_limit=args.report_limit,
        oracles=[oracle.name for oracle in oracles],
    )

    for case in cases:
        what = run_whatchord(chord_debug, case, top=args.top)
        oracle_results = {
            oracle.name: oracle.detect(case.notes, case.bass) for oracle in oracles
        }
        row = build_row(case, what, oracle_results)
        rows.append(row)
        summary[row["review_flag"]] += 1

    csv_path = args.out_dir / "chord_oracle_comparison.csv"
    json_path = args.out_dir / "chord_oracle_summary.json"
    report_path = args.out_dir / "chord_oracle_report.txt"
    write_csv(csv_path, rows)
    write_report(
        report_path,
        rows=rows,
        summary=summary,
        oracles=[oracle.name for oracle in oracles],
        case_generation=case_generation,
        reproduce_command=reproduce_command,
        csv_path=csv_path,
        json_path=json_path,
        limit=args.report_limit,
    )
    json_path.write_text(
        json.dumps(
            {
                "cases": len(rows),
                "oracles": [oracle.name for oracle in oracles],
                "case_order": args.case_order,
                "seed": seed,
                "case_generation": case_generation,
                "reproduce_command": reproduce_command,
                "review_flags": dict(summary),
                "csv": str(csv_path),
                "report": str(report_path),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"Compared {len(rows)} cases with: {', '.join(oracle.name for oracle in oracles)}")
    if seed is not None:
        print(f"Seed: {seed}")
    for flag, count in summary.most_common():
        print(f"{flag}: {count}")
    print(f"Wrote {csv_path}")
    print(f"Wrote {json_path}")
    print(f"Wrote {report_path}")
    return 0


def _available_oracles(names: Iterable[str]) -> list[Oracle]:
    registry: dict[str, Oracle] = {
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


def reproduction_command(
    *,
    case_generation: dict[str, object],
    max_cases: int,
    top: int,
    report_limit: int,
    oracles: list[str],
) -> str:
    args = [
        "mise",
        "exec",
        "--",
        "python",
        "tool/chord_oracle_compare.py",
        f"--seed={case_generation['seed']}",
    ]
    if case_generation["min_notes"] != DEFAULT_MIN_NOTES:
        args.append(f"--min-notes={case_generation['min_notes']}")
    if case_generation["max_notes"] != DEFAULT_MAX_NOTES:
        args.append(f"--max-notes={case_generation['max_notes']}")
    if case_generation["basses"] != DEFAULT_BASSES:
        args.append(f"--basses={case_generation['basses']}")
    if case_generation["case_order"] != DEFAULT_CASE_ORDER:
        args.append(f"--case-order={case_generation['case_order']}")
    if max_cases != DEFAULT_MAX_CASES:
        args.append(f"--max-cases={max_cases}")
    if top != DEFAULT_TOP:
        args.append(f"--top={top}")
    if report_limit != DEFAULT_REPORT_LIMIT:
        args.append(f"--report-limit={report_limit}")
    if case_generation["all_transpositions"]:
        args.append("--all-transpositions")
    if not case_generation["include_practical_seeds"]:
        args.append("--no-include-practical-seeds")
    if tuple(oracles) != DEFAULT_ORACLES:
        args.extend(["--oracles", *oracles])
    return " ".join(str(arg) for arg in args)


def generate_cases(
    *,
    min_notes: int,
    max_notes: int,
    basses: str,
    canonical_transpositions: bool,
    include_practical_seeds: bool,
) -> Iterable[Case]:
    seen = set()
    if include_practical_seeds:
        for intervals in PRACTICAL_INTERVAL_SETS:
            pcs = tuple(sorted(pc % 12 for pc in intervals))
            for case in cases_for_pc_set(pcs, basses=basses):
                if case.case_id in seen:
                    continue
                seen.add(case.case_id)
                yield case

    for size in range(min_notes, max_notes + 1):
        for pcs in itertools.combinations(range(12), size):
            canonical = canonical_pc_set(pcs) if canonical_transpositions else pcs
            canonical_key = f"set:{canonical}"
            if canonical_transpositions and canonical_key in seen:
                continue
            seen.add(canonical_key)
            for case in cases_for_pc_set(canonical, basses=basses):
                if case.case_id in seen:
                    continue
                seen.add(case.case_id)
                yield case


def cases_for_pc_set(pcs: tuple[int, ...], *, basses: str) -> Iterable[Case]:
    bass_choices = pcs if basses == "all" else (pcs[0],)
    for bass_pc in bass_choices:
        case_id = f"{'-'.join(str(pc) for pc in pcs)}_b{bass_pc}"
        yield Case(case_id=case_id, pcs=pcs, bass_pc=bass_pc)


def canonical_pc_set(pcs: tuple[int, ...]) -> tuple[int, ...]:
    rotations = []
    for root in pcs:
        rotations.append(tuple(sorted((pc - root) % 12 for pc in pcs)))
    return min(rotations)


def run_whatchord(chord_debug: Path, case: Case, *, top: int) -> dict:
    cmd = [
        str(chord_debug),
        *case.notes,
        f"--bass={case.bass}",
        "--format=json",
        f"--top={top}",
    ]
    result = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"WhatChord failed for {case.case_id}: {result.stderr}")
    return json.loads(result.stdout)


def build_row(
    case: Case,
    what: dict,
    oracle_results: dict[str, OracleResult],
) -> dict[str, object]:
    candidates = what.get("candidates", [])
    best = candidates[0] if candidates else {}
    whatchord_label = comparable_label(str(best.get("symbol", "")))
    comparable_oracles = {
        name: comparable_labels([result.primary])
        for name, result in oracle_results.items()
        if comparable_labels([result.primary])
    }
    matching_oracles = [
        name for name, labels in comparable_oracles.items() if whatchord_label in labels
    ]
    disagreeing_oracles = [
        name
        for name, labels in comparable_oracles.items()
        if whatchord_label not in labels
    ]
    review_flag = "agree"
    if not best:
        review_flag = "no-whatchord-candidate"
    elif any(result.status == "error" for result in oracle_results.values()):
        review_flag = "oracle-error"
    elif not whatchord_label or not comparable_oracles:
        review_flag = "insufficient-oracle-labels"
    elif matching_oracles and disagreeing_oracles:
        review_flag = "oracle-split"
    elif disagreeing_oracles:
        review_flag = "disagreement"

    normalized_parts = []
    if whatchord_label:
        normalized_parts.append(f"whatchord={whatchord_label}")
    normalized_parts.extend(
        f"{name}={' | '.join(labels)}"
        for name, labels in comparable_oracles.items()
    )

    row: dict[str, object] = {
        "case_id": case.case_id,
        "notes": " ".join(case.notes),
        "pcs": " ".join(str(pc) for pc in case.pcs),
        "bass": case.bass,
        "whatchord_symbol": best.get("symbol", ""),
        "whatchord_harte": best.get("harte", ""),
        "whatchord_quality": best.get("quality", ""),
        "whatchord_score": best.get("score", ""),
        "whatchord_second": candidates[1].get("symbol", "") if len(candidates) > 1 else "",
        "review_flag": review_flag,
        "matching_oracles": " ".join(matching_oracles),
        "disagreeing_oracles": " ".join(disagreeing_oracles),
        "normalized_labels": " || ".join(normalized_parts),
    }
    for name, result in oracle_results.items():
        row[f"{name}_status"] = result.status
        row[f"{name}_labels"] = " | ".join(result.labels)
        row[f"{name}_detail"] = result.detail
    return row


def comparable_labels(labels: Iterable[str]) -> tuple[str, ...]:
    out = []
    seen = set()
    for label in labels:
        comparable = comparable_label(label)
        if not comparable or comparable in seen:
            continue
        seen.add(comparable)
        out.append(comparable)
    return tuple(out)


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    fieldnames = list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_report(
    path: Path,
    *,
    rows: list[dict[str, object]],
    summary: Counter,
    oracles: list[str],
    case_generation: dict[str, object],
    reproduce_command: str,
    csv_path: Path,
    json_path: Path,
    limit: int,
) -> None:
    attention_rows = [
        row for row in sorted(rows, key=attention_sort_key) if needs_attention(row)
    ]
    if limit > 0:
        attention_rows = attention_rows[:limit]

    lines = [
        "Chord Oracle Review Report",
        "==========================",
        "",
        "Rows here are triage prompts for human musical review, not test failures.",
        "",
        "Run",
        "---",
        f"Cases reviewed:      {len(rows)}",
        f"Oracles:             {', '.join(oracles)}",
        f"Case order:          {case_generation['case_order']}",
        f"Seed:                {case_generation['seed'] or 'none'}",
        f"Generated case pool: {case_generation['generated_cases']}",
        f"Selected cases:      {case_generation['selected_cases']}",
        f"CSV:                 {csv_path}",
        f"Summary JSON:        {json_path}",
        f"Reproduce:           {reproduce_command}",
        "",
        "Review Flags",
        "------------",
        "",
    ]

    for flag in sorted(REVIEW_FLAG_EXPLANATIONS, key=flag_sort_key):
        lines.append(f"{flag} ({summary.get(flag, 0)})")
        lines.append(f"  {REVIEW_FLAG_EXPLANATIONS[flag]}")

    lines.extend(
        [
            "",
            "Attention Queue",
            "---------------",
            "",
        ]
    )

    if not attention_rows:
        lines.append("No rows require attention under the current triage rules.")
    else:
        for index, row in enumerate(attention_rows, start=1):
            if index != 1:
                lines.append("")
            lines.extend(attention_row_text(index, row))

    lines.extend(
        [
            "",
        ]
    )

    path.write_text("\n".join(lines), encoding="utf-8")


def attention_sort_key(row: dict[str, object]) -> tuple[int, int, str]:
    flag = str(row["review_flag"])
    note_count = len(str(row["notes"]).split())
    return REVIEW_PRIORITY.get(flag, 99), note_count, str(row["case_id"])


def flag_sort_key(flag: str) -> tuple[int, str]:
    return REVIEW_PRIORITY.get(flag, 99), flag


def needs_attention(row: dict[str, object]) -> bool:
    return str(row["review_flag"]) in {
        "disagreement",
        "oracle-split",
        "no-whatchord-candidate",
        "oracle-error",
    }


def attention_row_text(index: int, row: dict[str, object]) -> list[str]:
    flag = str(row["review_flag"])
    lines = [
        f"{index}. {row['case_id']} [{flag}]",
        f"   input:       {row['notes']}   bass={row['bass']}",
        f"   chord-debug: {chord_debug_command(row)}",
        f"   WhatChord:   {row['whatchord_symbol']}",
    ]
    if row["matching_oracles"]:
        lines.append(f"   matches:     {row['matching_oracles']}")
    if row["disagreeing_oracles"]:
        lines.append(f"   differs:     {row['disagreeing_oracles']}")
    raw_labels = oracle_label_lines(row)
    if raw_labels:
        lines.append("   oracle labels:")
        lines.extend(f"     {line}" for line in raw_labels)
    if row["normalized_labels"]:
        lines.append(f"   normalized:  {row['normalized_labels']}")
    return lines


def chord_debug_command(row: dict[str, object]) -> str:
    notes = str(row["notes"]).split()
    bass = str(row["bass"])
    return " ".join(["bin/chord-debug", *notes, f"--bass={bass}"])


def oracle_label_lines(row: dict[str, object]) -> list[str]:
    lines = []
    for key, value in row.items():
        if key.endswith("_labels") and key != "normalized_labels" and value:
            oracle = key[: -len("_labels")]
            primary = str(value).split(" | ")[0]
            lines.append(f"{oracle.ljust(ORACLE_NAME_WIDTH)}: {primary}")
    return lines


def comparable_label(label: str) -> str:
    value = label.strip()
    if not value:
        return ""

    normalized = value.replace("♯", "#").replace("♭", "b")
    normalized = normalized.split("/")[0].strip()
    normalized = normalized.replace("-", "b")
    match = re.match(r"^([A-Ga-g](?:#{1,2}|b{1,2})?)(.*)$", normalized)
    if match is None:
        return ""

    root = pitch_class_key(match.group(1))
    quality = comparable_quality_token(match.group(2))
    if root == "" or quality == "":
        return ""
    return f"{root}:{quality}"


def comparable_quality_token(raw: str) -> str:
    value = raw.strip()
    if not value:
        return "maj"

    phrase = re.sub(r"\s+", " ", value.lower())
    if any(
        word in phrase
        for word in (
            "cluster",
            "mirror",
            "tetrachord",
            "trichord",
            "pentatonic",
            "scale",
        )
    ):
        return ""
    phrase = phrase.replace(" chord", "").replace(" triad", "")
    phrase = phrase.replace("incomplete ", "")
    phrase = phrase.replace("major-seventh", "major seventh")
    phrase = phrase.replace("minor-seventh", "minor seventh")
    phrase = phrase.replace("dominant-seventh", "dominant seventh")
    phrase = phrase.replace("half-diminished", "half diminished")

    phrase_tokens = {
        "major": "maj",
        "minor": "min",
        "diminished": "dim",
        "augmented": "aug",
        "dominant seventh": "7",
        "major seventh": "maj7",
        "minor seventh": "min7",
        "diminished seventh": "dim7",
        "half diminished seventh": "m7b5",
    }
    if phrase in phrase_tokens:
        return phrase_tokens[phrase]

    compact = value.replace(" ", "")
    compact = compact.replace("♯", "#").replace("♭", "b")
    compact = compact.replace("Δ", "maj")
    if compact == "M":
        return "maj"
    if compact == "m":
        return "min"
    if compact.startswith("M"):
        compact = "maj" + compact[1:]
    compact = compact.lower()
    compact = compact.replace("major", "maj").replace("minor", "min")
    compact = compact.replace("dom", "")
    compact = compact.replace("minmaj", "minmaj")
    compact = compact.replace("mmaj", "minmaj")
    compact = compact.replace("m7b5", "m7b5")
    compact = compact.replace("ø7", "m7b5")
    compact = compact.replace("ø", "m7b5")
    compact = compact.replace("°", "dim")
    compact = compact.replace("(", "").replace(")", "")
    if compact in {"", "maj", "min", "m", "dim", "aug", "sus2", "sus4"}:
        return "min" if compact == "m" else (compact or "maj")
    if compact.startswith("maj"):
        return compact
    if compact.startswith("min"):
        return compact
    if compact.startswith("m"):
        return compact.replace("m", "min", 1)
    if compact.startswith(("dim", "aug", "sus", "9", "7", "6")):
        return compact
    return ""


def pitch_class_key(note: str) -> str:
    value = note.strip().replace("♯", "#").replace("♭", "b").replace("-", "b")
    if not value:
        return ""
    letter = value[0].upper()
    pc_by_letter = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    if letter not in pc_by_letter:
        return ""
    pc = pc_by_letter[letter]
    for accidental in value[1:]:
        if accidental == "#":
            pc += 1
        elif accidental == "b":
            pc -= 1
    return f"pc{pc % 12}"


def _bass_first(notes: tuple[str, ...], bass: str) -> tuple[str, ...]:
    return (bass, *[note for note in notes if note != bass])


def _music21_voicing(notes: tuple[str, ...], bass: str) -> list[str]:
    return [f"{bass}3", *[f"{note}4" for note in notes if note != bass]]


if __name__ == "__main__":
    raise SystemExit(main())
