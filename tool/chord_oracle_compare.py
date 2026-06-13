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
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
DEFAULT_ORACLES = ("music21", "tonal", "pychord")
DEFAULT_REVIEWED_PATH = Path(__file__).with_name("chord_oracle_reviewed.json")
ORACLE_NAME_WIDTH = max(len(name) for name in DEFAULT_ORACLES)
DEFAULT_MIN_NOTES = 3
DEFAULT_MAX_NOTES = 7
DEFAULT_BASSES = "all"
DEFAULT_CASE_ORDER = "random"
DEFAULT_MAX_CASES = 200
DEFAULT_TOP = 4
DEFAULT_REPORT_LIMIT = 50
DEFAULT_JOBS = 8
REVIEW_FLAG_EXPLANATIONS = {
    "disagreement": "Comparable oracle labels were available, but none matched WhatChord's top label.",
    "oracle-split": "As many or more oracles disagreed with WhatChord as agreed.",
    "insufficient-oracle-labels": "Only one oracle returned a comparable primary label.",
    "unrecognized-by-oracles": "No oracle returned a comparable primary label.",
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
    "unrecognized-by-oracles": 5,
    "agree": 6,
}
REVIEW_LABELS = {
    "clearly-correct",
    "genuine-ambiguity",
    "context-dependent",
    "voicing-dependent",
    "oracle-limitation",
}


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


@dataclass(frozen=True)
class SemanticChordKey:
    root_pc: int
    degrees: tuple[str, ...]
    bass_pc: int | None = None

    def display(self) -> str:
        bass = "" if self.bass_pc is None else f"/bass{self.bass_pc}"
        degrees = ",".join(self.degrees) if self.degrees else "1"
        return f"pc{self.root_pc}{bass}:{{{degrees}}}"


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
            # Use the generated figure directly. chordSymbolFromChord reparses
            # this figure and can reject music21's own output, such as
            # "GsusaddF,omitD", by treating the suffix as a root accidental.
            figure = str(harmony.chordSymbolFigureFromChord(c) or "")
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
    parser.add_argument(
        "--jobs",
        type=int,
        default=DEFAULT_JOBS,
        help="Number of cases to analyze concurrently.",
    )
    parser.add_argument("--out-dir", type=Path, default=Path("build/oracle-compare"))
    parser.add_argument("--chord-debug", type=Path, default=Path("bin/chord-debug"))
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be at least 1")

    repo_root = Path(__file__).resolve().parents[1]
    chord_debug = args.chord_debug
    if not chord_debug.is_absolute():
        chord_debug = repo_root / chord_debug

    reviewed = load_reviewed(DEFAULT_REVIEWED_PATH)

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
        )
    )
    seed = args.seed
    if args.case_order == "random":
        if seed is None:
            seed = str(secrets.randbits(64))
        rng = random.Random(seed)
        rng.shuffle(generated_cases)

    cases = generated_cases[: args.max_cases] if args.max_cases else generated_cases

    case_generation = {
        "min_notes": args.min_notes,
        "max_notes": args.max_notes,
        "basses": args.basses,
        "all_transpositions": args.all_transpositions,
        "case_order": args.case_order,
        "seed": seed,
        "generated_cases": len(generated_cases),
        "selected_cases": len(cases),
        "max_cases": args.max_cases,
        "jobs": args.jobs,
    }
    reproduce_command = reproduction_command(
        case_generation=case_generation,
        max_cases=args.max_cases,
        top=args.top,
        report_limit=args.report_limit,
        oracles=[oracle.name for oracle in oracles],
        jobs=args.jobs,
    )

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        whats = list(
            executor.map(
                lambda case: run_whatchord(chord_debug, case, top=args.top),
                cases,
            )
        )
        oracle_inputs = [
            oracle_input_from_whatchord(what, fallback=case)
            for case, what in zip(cases, whats)
        ]
        oracle_results_by_case: list[dict[str, OracleResult]] = [
            {} for _ in cases
        ]
        for oracle in oracles:
            # music21 mutates shared module state while identifying symbols, so
            # preserve input order for deterministic results.
            if oracle.name == Music21Oracle.name:
                results = [
                    oracle.detect(notes, bass) for notes, bass in oracle_inputs
                ]
            else:
                results = list(
                    executor.map(
                        lambda input_data: oracle.detect(*input_data),
                        oracle_inputs,
                    )
                )
            for case_results, result in zip(oracle_results_by_case, results):
                case_results[oracle.name] = result

    rows = [
        build_row(case, what, oracle_results)
        for case, what, oracle_results in zip(cases, whats, oracle_results_by_case)
    ]

    for row in rows:
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
        reviewed=reviewed,
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


def load_reviewed(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            reviewed = {}
            for case_id, value in data.items():
                if isinstance(value, str):
                    reviewed[str(case_id)] = {
                        "label": "clearly-correct",
                        "note": value,
                    }
                elif isinstance(value, dict):
                    label = value.get("label")
                    note = value.get("note")
                    if label in REVIEW_LABELS and isinstance(note, str):
                        reviewed[str(case_id)] = {"label": label, "note": note}
            return reviewed
    except (json.JSONDecodeError, OSError) as error:
        print(f"Warning: could not load reviewed file {path}: {error}", file=sys.stderr)
    return {}


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
    jobs: int,
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
    if jobs != DEFAULT_JOBS:
        args.append(f"--jobs={jobs}")
    if case_generation["all_transpositions"]:
        args.append("--all-transpositions")
    if tuple(oracles) != DEFAULT_ORACLES:
        args.extend(["--oracles", *oracles])
    return " ".join(str(arg) for arg in args)


def generate_cases(
    *,
    min_notes: int,
    max_notes: int,
    basses: str,
    canonical_transpositions: bool,
) -> Iterable[Case]:
    seen = set()
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


def oracle_input_from_whatchord(
    what: dict,
    *,
    fallback: Case,
) -> tuple[tuple[str, ...], str]:
    input_data = what.get("input", {})
    pitch_classes = input_data.get("pitchClasses", [])
    notes = tuple(
        oracle_note_name(item.get("label", ""))
        for item in pitch_classes
        if isinstance(item, dict) and item.get("label")
    )
    bass = input_data.get("bassLabel")
    if notes and bass:
        return notes, oracle_note_name(bass)
    return fallback.notes, fallback.bass


def build_row(
    case: Case,
    what: dict,
    oracle_results: dict[str, OracleResult],
) -> dict[str, object]:
    candidates = what.get("candidates", [])
    best = candidates[0] if candidates else {}
    whatchord_label = comparable_label(str(best.get("symbol", "")))
    whatchord_key = semantic_key_from_whatchord(best)
    comparable_oracles = {
        name: comparable_labels([result.primary])
        for name, result in oracle_results.items()
        if comparable_labels([result.primary])
    }
    primary_semantic_oracles = {
        name: semantic_keys([result.primary])
        for name, result in oracle_results.items()
        if semantic_keys([result.primary])
    }
    all_semantic_oracles = {
        name: semantic_keys(result.labels)
        for name, result in oracle_results.items()
        if semantic_keys(result.labels)
    }
    comparable_primary_oracle_names = [
        name
        for name in oracle_results
        if name in comparable_oracles or name in primary_semantic_oracles
    ]
    matching_oracles = [
        name
        for name, labels in comparable_oracles.items()
        if whatchord_label and whatchord_label in labels
    ]
    semantic_matching_oracles = [
        name
        for name, keys in primary_semantic_oracles.items()
        if semantic_key_matches(whatchord_key, keys, case.pcs)
    ]
    for name in semantic_matching_oracles:
        if name not in matching_oracles:
            matching_oracles.append(name)
    disagreeing_oracles = [
        name
        for name in oracle_results
        if name in comparable_oracles or name in primary_semantic_oracles
        if name not in matching_oracles
    ]
    alternate_matching_oracles = [
        name
        for name, keys in all_semantic_oracles.items()
        if name not in matching_oracles
        and semantic_key_matches(whatchord_key, keys, case.pcs)
    ]
    review_flag = "agree"
    if not best:
        review_flag = "no-whatchord-candidate"
    elif any(result.status == "error" for result in oracle_results.values()):
        review_flag = "oracle-error"
    elif not comparable_primary_oracle_names:
        review_flag = "unrecognized-by-oracles"
    elif len(comparable_primary_oracle_names) == 1:
        review_flag = "insufficient-oracle-labels"
    elif not whatchord_label and whatchord_key is None:
        review_flag = "insufficient-oracle-labels"
    elif matching_oracles and disagreeing_oracles and len(disagreeing_oracles) >= len(matching_oracles):
        review_flag = "oracle-split"
    elif not matching_oracles and disagreeing_oracles:
        review_flag = "disagreement"

    normalized_parts = []
    if whatchord_label:
        normalized_parts.append(f"whatchord={whatchord_label}")
    normalized_parts.extend(
        f"{name}={' | '.join(labels)}"
        for name, labels in comparable_oracles.items()
    )
    semantic_parts = []
    if whatchord_key is not None:
        semantic_parts.append(f"whatchord={whatchord_key.display()}")
    semantic_parts.extend(
        f"{name}={' | '.join(key.display() for key in keys)}"
        for name, keys in all_semantic_oracles.items()
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
        "alternate_matching_oracles": " ".join(alternate_matching_oracles),
        "normalized_labels": " || ".join(normalized_parts),
        "semantic_labels": " || ".join(semantic_parts),
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


def semantic_keys(labels: Iterable[str]) -> tuple[SemanticChordKey, ...]:
    out = []
    seen = set()
    for label in labels:
        key = semantic_key_from_label(label)
        if key is None or key in seen:
            continue
        seen.add(key)
        out.append(key)
    return tuple(out)


def _key_intervals(
    key: SemanticChordKey, sounding_intervals: frozenset[int] | None
) -> frozenset[int]:
    """Chord-tone intervals (relative to root) for a key.

    Degrees are reduced to semitone intervals so enharmonically equal spellings
    (for example #11 and b5, or 9 and 2) compare as the same tone even when two
    sources render the symbol differently. When [sounding_intervals] is given,
    the result is restricted to tones actually present in the voicing, dropping
    symbol-implied-but-absent tones such as the omittable perfect fifth in "D9".
    """
    intervals = {
        DEGREE_TO_INTERVAL[degree]
        for degree in key.degrees
        if degree in DEGREE_TO_INTERVAL
    }
    if sounding_intervals is not None:
        intervals &= sounding_intervals
    return frozenset(intervals)


def semantic_key_matches(
    whatchord_key: SemanticChordKey | None,
    oracle_keys: Iterable[SemanticChordKey],
    sounding_pcs: Iterable[int] | None = None,
) -> bool:
    if whatchord_key is None:
        return False

    # Intervals are framed against whatchord's root; only same-root oracle keys
    # can match, so the same frame applies to both sides.
    sounding_intervals: frozenset[int] | None = None
    if sounding_pcs is not None:
        sounding_intervals = frozenset(
            (pc - whatchord_key.root_pc) % 12 for pc in sounding_pcs
        )

    whatchord_intervals = _key_intervals(whatchord_key, sounding_intervals)
    for oracle_key in oracle_keys:
        if oracle_key.root_pc != whatchord_key.root_pc:
            continue
        if _key_intervals(oracle_key, sounding_intervals) != whatchord_intervals:
            continue
        if oracle_key.bass_pc is None or whatchord_key.bass_pc is None:
            return True
        if oracle_key.bass_pc == whatchord_key.bass_pc:
            return True
    return False


def semantic_key_from_whatchord(candidate: dict) -> SemanticChordKey | None:
    try:
        root_pc = int(candidate["rootPc"])
    except (KeyError, TypeError, ValueError):
        return None

    roles = candidate.get("toneRolesByInterval", {})
    degrees = []
    if isinstance(roles, dict):
        for role in roles.values():
            degree = DEGREE_BY_ROLE.get(str(role))
            if degree:
                degrees.append(degree)

    bass_pc = None
    try:
        candidate_bass = int(candidate["bassPc"])
        if candidate_bass != root_pc:
            bass_pc = candidate_bass
    except (KeyError, TypeError, ValueError):
        pass

    return SemanticChordKey(
        root_pc=root_pc,
        bass_pc=bass_pc,
        degrees=sort_degrees(set(degrees)),
    )


def semantic_key_from_label(label: str) -> SemanticChordKey | None:
    parsed = parse_chord_label(label)
    if parsed is None:
        return None

    root_pc, quality, bass_pc, slash_suffix = parsed
    degrees = degrees_from_quality(quality, root_pc=root_pc)
    if slash_suffix:
        degrees.update(degrees_from_quality(slash_suffix, root_pc=root_pc, base_only=False))

    # If the slash bass note is a chord tone not already captured by the
    # quality description, add its degree. This catches cases like G#7/C#
    # where C# is the 11th but the "7" quality only describes {3, 5, b7}.
    if bass_pc is not None:
        bass_interval = (bass_pc - root_pc) % 12
        bass_degree = degree_from_interval(
            bass_interval, prefer_extensions=has_third(degrees)
        )
        if bass_degree and not _interval_covered_by_degrees(
            bass_interval, degrees
        ):
            degrees.add(bass_degree)

    if not degrees:
        return None

    return SemanticChordKey(
        root_pc=root_pc,
        bass_pc=bass_pc,
        degrees=sort_degrees(degrees),
    )


def parse_chord_label(label: str) -> tuple[int, str, int | None, str] | None:
    value = label.strip()
    if not value:
        return None

    normalized = value.replace("♯", "#").replace("♭", "b")
    normalized = normalized.replace("-", "b")
    normalized = re.sub(r"\s+", "", normalized)

    root_match = re.match(r"^([A-Ga-g](?:#{1,2}|b{1,2})?)(.*)$", normalized)
    if root_match is None:
        return None

    root_pc = pitch_class_number(root_match.group(1))
    if root_pc is None:
        return None

    rest = root_match.group(2)
    bass_pc = None
    slash_suffix = ""
    slash_match = re.search(r"/([A-Ga-g](?:#{1,2}|b{1,2})?)(.*)$", rest)
    if slash_match is not None:
        bass_pc = pitch_class_number(slash_match.group(1))
        slash_suffix = slash_match.group(2)
        rest = rest[: slash_match.start()]

    return root_pc, rest, bass_pc, slash_suffix


def degrees_from_quality(
    raw: str,
    *,
    root_pc: int,
    base_only: bool = True,
) -> set[str]:
    value = raw.strip()
    if not value:
        return {"3", "5"} if base_only else set()

    absolute_omit_intervals = {
        (pc - root_pc) % 12
        for pc in (
            pitch_class_number(match.group(1))
            for match in re.finditer(r"omit([A-Ga-g](?:#{1,2}|b{1,2})?)", value)
        )
        if pc is not None
    }
    value = re.sub(r"omit[A-Ga-g](?:#{1,2}|b{1,2})?", "", value)

    absolute_adds = {
        degree_from_interval((pc - root_pc) % 12, prefer_extensions=True)
        for pc in (
            pitch_class_number(match.group(1))
            for match in re.finditer(r"add([A-Ga-g](?:#{1,2}|b{1,2})?)", value)
        )
        if pc is not None
    }
    absolute_adds.discard("")
    value = re.sub(r"add[A-Ga-g](?:#{1,2}|b{1,2})?", "", value)

    compact = value.replace(" ", "")
    compact = compact.replace("(", "").replace(")", "")
    compact = compact.replace("Δ", "maj")
    if compact == "M":
        compact = "maj"
    elif compact.startswith("M"):
        compact = "maj" + compact[1:]
    compact = compact.replace("+", "aug")
    compact = re.sub(r"M(?=[79]|1[13])", "maj", compact)
    compact = compact.replace("major", "maj").replace("minor", "min")
    compact = compact.replace("dom", "")
    compact = compact.lower()
    # Normalize music21's 'o' prefix: o=dim, o7=dim7, o9/ob9/o11/o13=dim7+extension
    compact = re.sub(r"^o(?=[0-9b]|$)", "dim", compact)
    # dim+extension implies dim7 is present; expand so existing patterns work
    compact = re.sub(r"^(dim)(b?[9]|11|13)(?![0-9])", r"\g<1>7add\2", compact)
    # '7+' (augmented seventh) normalizes to '7aug' after the '+' substitution above;
    # swap to 'aug7' so the 'aug' prefix branch fires and the '#5' is included.
    compact = re.sub(r"^7aug", "aug7", compact)
    # 'dom7dim5': after 'dom' removal becomes '7dim5'; map 'dim5' to 'b5'.
    compact = compact.replace("dim5", "b5")
    # Leading-number sus ('7sus', '9sus4', …) → move number after sus so the
    # sus branch in base_degrees applies, then 'b7' is added from the digit.
    compact = re.sub(r"^(\d+)(sus4?)", r"\g<2>\g<1>", compact)
    # Plain 'sus' (music21 canonical for sus4 triad) → 'sus4'.
    if compact == "sus":
        compact = "sus4"
    # Expand headline-extension forms whose prefix blocks headline_extension().
    # Converts e.g. 'aug11' → 'aug7add9add11' so token matching picks up every
    # implied degree.  Prefixes that already work via headline_extension() (bare
    # '9'/'11'/'13', 'm9', etc.) are intentionally excluded from this pattern.
    def _expand_headline(m: re.Match) -> str:
        prefix, ext = m.group(1), m.group(2)
        seventh = "" if "7" in prefix else "7"
        stacked = "add9" if ext == "9" else f"add9add{ext}"
        return f"{prefix}{seventh}{stacked}"

    compact = re.sub(
        r"^(ø|aug(?:maj)?|mmaj|minmaj|maj)(9|11|13)(?![0-9])",
        _expand_headline,
        compact,
    )

    degrees = set(absolute_adds)
    if base_only:
        degrees.update(base_degrees(compact))

    degrees.update(extension_degrees(compact, has_third=has_third(degrees)))
    degrees = {
        degree
        for degree in degrees
        if DEGREE_TO_INTERVAL.get(degree) not in absolute_omit_intervals
    }
    return {degree for degree in degrees if degree}


def base_degrees(compact: str) -> set[str]:
    if not compact or compact == "maj":
        return {"3", "5"}
    headline = headline_extension(compact)
    if compact.startswith(("ø", "m7b5")) or "halfdim" in compact:
        return {"b3", "b5", "b7"}
    if compact.startswith("dim"):
        return {"b3", "b5", "bb7"} if "7" in compact else {"b3", "b5"}
    if compact.startswith("aug"):
        out = {"3", "#5"}
    elif compact.startswith("sus2") or "sus2" in compact:
        out = {"2", "5"}
    elif compact.startswith("sus") and not compact.startswith("sus2"):
        out = {"4", "5"}
    elif compact.startswith("minmaj") or compact.startswith("mmaj"):
        out = {"b3", "5", "7"}
    elif compact.startswith("min") or (compact.startswith("m") and not compact.startswith("maj")):
        out = {"b3", "5"}
    else:
        out = {"3", "5"}

    if "#5" in compact or "+5" in compact:
        out.discard("5")
        out.add("#5")
    if "b5" in compact:
        out.discard("5")
        out.add("b5")
    if "maj7" in compact or "ma7" in compact:
        out.add("7")
    elif ("7" in compact or headline is not None) and "bb7" not in out and "7" not in out:
        out.add("b7")
    if "b6" in compact:
        out.add("b13")
    if re.search(r"(^|[^0-9b#])6([^0-9]|$)", compact):
        out.add("6")
    return out


def extension_degrees(compact: str, *, has_third: bool) -> set[str]:
    out = set()
    token_patterns = (
        ("b13", "b13"),
        ("#11", "#11"),
        ("b9", "b9"),
        ("#9", "#9"),
        ("add#9", "#9"),
        ("addb9", "b9"),
        ("add13", "13"),
        ("add11", "11"),
        ("add9", "9"),
        ("add6", "13"),
        ("add4", "11" if has_third else "4"),
        ("add2", "9" if has_third else "2"),
    )
    for token, degree in token_patterns:
        if token in compact:
            out.add(degree)

    if re.search(r"(?<![a-z0-9#b])13(?![0-9])", compact):
        out.add("13")
    if re.search(r"(?<![a-z0-9#b])11(?![0-9])", compact):
        out.add("11")
    if re.search(r"(?<![a-z0-9#b])9(?![0-9])", compact):
        out.add("9")
    headline = headline_extension(compact)
    if headline == "9":
        out.add("9")
    elif headline == "11":
        out.update({"9", "11"})
    elif headline == "13":
        out.update({"9", "13"})
    return out


def headline_extension(compact: str) -> str | None:
    if re.match(r"^(maj|min|m)?13", compact):
        return "13"
    if re.match(r"^(maj|min|m)?11", compact):
        return "11"
    if re.match(r"^(maj|min|m)?9", compact):
        return "9"
    return None


def degree_from_interval(interval: int, *, prefer_extensions: bool) -> str:
    return {
        0: "1",
        1: "b9",
        2: "9" if prefer_extensions else "2",
        3: "#9",
        4: "3",
        5: "11" if prefer_extensions else "4",
        6: "#11",
        7: "5",
        8: "#5",
        9: "13" if prefer_extensions else "6",
        10: "b7",
        11: "7",
    }.get(interval % 12, "")


def has_third(degrees: set[str]) -> bool:
    return "3" in degrees or "b3" in degrees


def sort_degrees(degrees: set[str]) -> tuple[str, ...]:
    return tuple(sorted(degrees, key=lambda degree: (DEGREE_SORT_RANK.get(degree, 99), degree)))


DEGREE_SORT_RANK = {
    "2": 5,
    "b3": 10,
    "3": 11,
    "4": 15,
    "b5": 20,
    "5": 21,
    "#5": 22,
    "6": 30,
    "bb7": 38,
    "b7": 39,
    "7": 40,
    "b9": 50,
    "9": 51,
    "#9": 52,
    "11": 60,
    "#11": 61,
    "b13": 70,
    "13": 71,
}


DEGREE_TO_INTERVAL: dict[str, int] = {
    "1": 0,
    "b9": 1,
    "9": 2,
    "2": 2,
    "#9": 3,
    "b3": 3,
    "3": 4,
    "11": 5,
    "4": 5,
    "#11": 6,
    "b5": 6,
    "5": 7,
    "b13": 8,
    "#5": 8,
    "13": 9,
    "6": 9,
    "bb7": 9,
    "b7": 10,
    "7": 11,
}


def _interval_covered_by_degrees(interval: int, degrees: set[str]) -> bool:
    """True when any degree in the set maps to the given semitone interval."""
    for degree in degrees:
        if DEGREE_TO_INTERVAL.get(degree) == interval:
            return True
    return False


DEGREE_BY_ROLE = {
    "sus2": "2",
    "nine": "9",
    "add9": "9",
    "flat9": "b9",
    "sharp9": "#9",
    "addSharp9": "#9",
    "splitMinor3": "b3",
    "minor3": "b3",
    "major3": "3",
    "sus4": "4",
    "eleven": "11",
    "add11": "11",
    "sharp11": "#11",
    "flat5": "b5",
    "perfect5": "5",
    "sharp5": "#5",
    "sixth": "6",
    "flat13": "b13",
    "thirteenth": "13",
    "add13": "13",
    "dim7": "bb7",
    "flat7": "b7",
    "major7": "7",
}


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
    reviewed: dict[str, dict[str, str]] | None = None,
) -> None:
    if reviewed is None:
        reviewed = {}
    attention_rows = [
        row
        for row in sorted(rows, key=attention_sort_key)
        if needs_attention(row) and str(row["case_id"]) not in reviewed
    ]
    suppressed = sum(
        1
        for row in rows
        if needs_attention(row) and str(row["case_id"]) in reviewed
    )
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
    if suppressed:
        lines.append(f"({suppressed} previously reviewed cases suppressed -- see tool/chord_oracle_reviewed.json)")
        lines.append("")

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
        "insufficient-oracle-labels",
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
    if row["alternate_matching_oracles"]:
        lines.append(f"   alt matches: {row['alternate_matching_oracles']}")
    raw_labels = oracle_label_lines(row)
    if raw_labels:
        lines.append("   oracle labels:")
        lines.extend(f"     {line}" for line in raw_labels)
    if row["semantic_labels"]:
        lines.append(f"   semantic:    {row['semantic_labels']}")
    return lines


def chord_debug_command(row: dict[str, object]) -> str:
    notes = str(row["notes"]).split()
    bass = str(row["bass"])
    return " ".join(["bin/chord-debug", *notes, f"--bass={bass}"])


def oracle_label_lines(row: dict[str, object]) -> list[str]:
    lines = []
    for key, value in row.items():
        if (
            key.endswith("_labels")
            and key not in {"normalized_labels", "semantic_labels"}
            and value
        ):
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
    compact = compact.replace("+", "aug")
    compact = re.sub(r"M(?=[79]|1[13])", "maj", compact)
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
    # Normalize music21's 'o' prefix: o=dim, o7=dim7, o9/ob9/o11/o13=dim7+extension
    compact = re.sub(r"^o(?=[0-9b]|$)", "dim", compact)
    compact = re.sub(r"^(dim)(b?[9]|11|13)(?![0-9])", r"\g<1>7add\2", compact)
    # '7+' → '7aug' → swap to 'aug7' so the aug prefix is recognized
    compact = re.sub(r"^7aug", "aug7", compact)
    compact = compact.replace("dim5", "b5")
    compact = re.sub(r"^(\d+)(sus4?)", r"\g<2>\g<1>", compact)
    if compact == "sus":
        compact = "sus4"
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
    pc = pitch_class_number(note)
    if pc is None:
        return ""
    return f"pc{pc}"


def pitch_class_number(note: str) -> int | None:
    value = note.strip().replace("♯", "#").replace("♭", "b").replace("-", "b")
    if not value:
        return None
    letter = value[0].upper()
    pc_by_letter = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    if letter not in pc_by_letter:
        return None
    pc = pc_by_letter[letter]
    for accidental in value[1:]:
        if accidental == "#":
            pc += 1
        elif accidental == "b":
            pc -= 1
    return pc % 12


def _bass_first(notes: tuple[str, ...], bass: str) -> tuple[str, ...]:
    normalized_bass = oracle_note_name(bass)
    return (
        normalized_bass,
        *[oracle_note_name(note) for note in notes if note != bass],
    )


def _music21_voicing(notes: tuple[str, ...], bass: str) -> list[int]:
    bass_pc = pitch_class_number(oracle_note_name(bass)) or 0
    return [
        bass_pc + 48,
        *[
            (pitch_class_number(oracle_note_name(note)) or 0) + 60
            for note in notes
            if note != bass
        ],
    ]


def oracle_note_name(label: object) -> str:
    return str(label).replace("♯", "#").replace("♭", "b")


if __name__ == "__main__":
    raise SystemExit(main())
