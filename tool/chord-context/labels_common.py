"""Shared helpers for chord-context expected-identity labeling."""

from __future__ import annotations

# Interval sets (relative to the root) -> WhatChord ChordQuality enum names.
QUALITY_MASKS: dict[frozenset[int], str] = {
    frozenset(s): name
    for s, name in [
        ((0, 4, 7), "major"),
        ((0, 3, 7), "minor"),
        ((0, 3, 6), "diminished"),
        ((0, 4, 8), "augmented"),
        ((0, 4, 6), "majorFlat5"),
        ((0, 3, 8), "minorSharp5"),
        ((0, 7), "power"),
        ((0, 2, 7), "sus2"),
        ((0, 5, 7), "sus4"),
        ((0, 2, 5, 7), "sus2sus4"),
        ((0, 4, 7, 9), "major6"),
        ((0, 3, 7, 9), "minor6"),
        ((0, 4, 7, 10), "dominant7"),
        ((0, 2, 7, 10), "dominant7sus2"),
        ((0, 5, 7, 10), "dominant7sus4"),
        ((0, 4, 6, 10), "dominant7Flat5"),
        ((0, 4, 8, 10), "dominant7Sharp5"),
        ((0, 4, 7, 11), "major7"),
        ((0, 2, 7, 11), "major7sus2"),
        ((0, 5, 7, 11), "major7sus4"),
        ((0, 4, 6, 11), "major7Flat5"),
        ((0, 4, 8, 11), "major7Sharp5"),
        ((0, 3, 7, 10), "minor7"),
        ((0, 3, 8, 10), "minor7Sharp5"),
        ((0, 3, 7, 11), "minorMajor7"),
        ((0, 3, 6, 10), "halfDiminished7"),
        ((0, 3, 6, 9), "diminished7"),
    ]
}

# Base qualities tried, in order, when a larger set must reduce to a stack
# plus color tones (V9 and friends).
SUPERSET_PRIORITY = [
    "dominant7",
    "minor7",
    "major7",
    "halfDiminished7",
    "diminished7",
    "minorMajor7",
    "major",
    "minor",
    "diminished",
    "augmented",
]
MASKS_BY_NAME = {name: mask for mask, name in QUALITY_MASKS.items()}


def map_quality(intervals: frozenset[int]) -> tuple[str | None, list[int]]:
    """Root-relative interval set -> (ChordQuality enum name, extra intervals).

    Exact match first; then a known stack plus color tones; then a known stack
    missing only its fifth. Returns (None, []) when nothing fits.
    """
    exact = QUALITY_MASKS.get(intervals)
    if exact is not None:
        return exact, []
    for name in SUPERSET_PRIORITY:
        mask = MASKS_BY_NAME[name]
        if mask < intervals:
            return name, sorted(intervals - mask)
    for name in SUPERSET_PRIORITY:
        mask = MASKS_BY_NAME[name]
        if intervals < mask and mask - intervals == {7}:
            return name, []
    return None, []


def classify_figure(figure: str | None) -> str:
    """Coarse functional class used for transition-conditioned breakdowns.

    Works on both RomanText figures ("V65", "iiø42") and DCML chord labels
    ("V7(9)", "viio7/V"): classification keys off the leading Roman numeral
    of the part before any applied slash.
    """
    if not figure:
        return "none"
    primary = figure.split("/")[0]
    if "sus" in primary:
        return "sus"
    if primary.startswith(("vii", "VII")):
        return "dominant"
    if primary.startswith(("vi", "VI", "iii", "III")):
        return "other"
    if primary.startswith(("v", "V")):
        return "dominant"
    if primary.startswith(("ii", "II", "iv", "IV", "N", "Ger", "Fr", "It", "bII")):
        return "predominant"
    return "other"
