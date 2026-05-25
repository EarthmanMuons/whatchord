# Chord Naming Oracle Comparison

WhatChord needs a disciplined way to discover chord naming edge cases before
they appear as scattered bug reports or forum archaeology. The goal of this
research harness is not to outsource naming decisions to another library. The
goal is to find places where reasonable tools disagree, because those rows are
good candidates for closer musical review.

The comparison harness lives in
[`tool/chord_oracle_compare.py`](../../tool/chord_oracle_compare.py).

It compares WhatChord against optional third-party libraries:

- `music21`
- `tonal` or `@tonaljs/tonal`
- `pychord`

The harness treats every external library as an advisory oracle. A disagreement
is a triage signal, not proof that WhatChord is wrong.

For `music21`, the harness uses `harmony.chordSymbolFromChord()` so comparison
uses chord-symbol figures such as `C7`, `Am7/C`, and `Cm9`, not prose set-class
descriptions.

For tools that return multiple labels, the harness compares and reports only the
first label. Tonal's `Chord.detect()` returns weighted results sorted by
descending weight, so the first label is its preferred reading.

## Why This Shape

Chord naming has no single universally authoritative answer. Different tools
optimize for different use cases:

- score and analysis libraries often prefer theoretically complete names;
- JavaScript harmony helpers often prefer compact chord-symbol detection;
- interactive MIDI tools need stable, musician-expected labels for the observed
  voicing.

That means `music21` is useful as the most analysis-oriented comparison point,
but it should not be treated as a golden oracle. The most valuable cases are
where mature tools disagree with WhatChord's primary label.

## What Gets Generated

The harness generates pitch-class sets rather than scraping named chord lists.
It first builds a deterministic candidate pool:

1. Starts with a small set of practical seed shapes so common chord families are
   represented even in tiny samples.
2. Then enumerates chromatic pitch-class sets of size 3 through 7.
3. Canonicalizes transpositions so equivalent shapes are tested once.
4. Tests every pitch class in the set as the bass.

By default, it shuffles that candidate pool and stops after 500 cases unless a
different limit is requested. This makes routine sample runs more useful for
discovery while still avoiding over-weighting all 12 transpositions of the same
structure.

With the default 3- to 7-note range, canonical transposition handling, practical
seeds, and all bass choices, the generated pool is currently around sixteen
hundred cases. That is much smaller than every raw note-name combination because
transposition-equivalent pitch-class sets are collapsed before bass choices are
expanded. The seed list is only a supplement; the main discovery surface is the
randomized canonical pitch-class pool.

Random order is the default. Without `--seed`, the harness generates a seed,
prints it, and stores it in `chord_oracle_summary.json`. To reproduce the same
selected cases and order later:

```sh
python3 tool/chord_oracle_compare.py --seed 12345 --max-cases 20
```

Use `--case-order ordered` when you want stable enumeration without shuffling.

Use `--all-transpositions` when spelling or key-specific behavior is the thing
being investigated. The default canonical mode is better for finding structural
naming disagreements.

## WhatChord Entry Point

The harness calls WhatChord through:

```sh
bin/chord-debug C E G --bass=C --format=json
```

The JSON output keeps the comparison script from scraping human-readable debug
text. Each WhatChord row includes:

- display symbol;
- Harte-style label;
- quality token;
- score;
- second-ranked candidate;
- near-tie signal for diagnostics.

## Running

Install whichever advisory oracles you want to compare:

```sh
python3 -m pip install music21 pychord
npm install @tonaljs/tonal
```

If you use `mise`, `mise run oracle:install` handles this into local ignored
directories.

Then run a 500-case sample:

```sh
python3 tool/chord_oracle_compare.py --max-cases 500
```

For an exhaustive canonical pass over all 3- to 7-note pitch-class sets:

```sh
python3 tool/chord_oracle_compare.py --max-cases 0
```

To include every transposition instead of canonical representatives:

```sh
python3 tool/chord_oracle_compare.py --all-transpositions --max-cases 0
```

For quick manual exploration of a single voicing:

```sh
bin/chord-oracle C D E A --bass=E
```

It accepts the same note and option style as `bin/chord-debug`, then prints
WhatChord's top label plus available oracle labels.

Outputs are written to:

```text
build/oracle-compare/chord_oracle_comparison.csv
build/oracle-compare/chord_oracle_summary.json
build/oracle-compare/chord_oracle_report.txt
```

Start with `chord_oracle_report.txt`. The report focuses on rows most likely to
need attention, includes a review-flag legend, and gives copy/pasteable
`bin/chord-debug` commands for each case.

## Reading The CSV

The most important columns are:

| Column              | Meaning                                         |
| ------------------- | ----------------------------------------------- |
| `notes`             | Canonical pitch names sent to every tool        |
| `bass`              | Bass note passed to WhatChord and oracle inputs |
| `whatchord_symbol`  | WhatChord's top display label                   |
| `whatchord_harte`   | WhatChord's top Harte-style label               |
| `whatchord_second`  | WhatChord's second-ranked label                 |
| `*_labels`          | Raw labels returned by each external oracle     |
| `review_flag`       | High-level triage classification                |
| `normalized_labels` | Simple normalized labels used for comparison    |

The current review flags are:

| Flag                         | Meaning                                               |
| ---------------------------- | ----------------------------------------------------- |
| `agree`                      | Available tools normalized to the same primary label  |
| `oracle-split`               | At least one oracle matched WhatChord and one did not |
| `disagreement`               | Comparable oracle labels did not match WhatChord      |
| `oracle-error`               | An external tool failed on the row                    |
| `no-whatchord-candidate`     | WhatChord did not produce a candidate                 |
| `insufficient-oracle-labels` | Not enough comparable oracle labels were available    |

Rows marked `disagreement` should be sorted by musical importance before they
become implementation work. A dense chromatic cluster disagreement is less
important than a common shell voicing or altered dominant that appears in normal
playing.

## Recommended Review Workflow

1. Run a canonical pass with `music21` only.
2. Review `disagreement` rows first, especially when WhatChord's second
   candidate matches an oracle or looks musically plausible.
3. Re-run the interesting rows with `tonal` and `pychord` installed.
4. Promote only recurring, musically defensible issues into analyzer golden
   tests.
5. Keep generated CSV files out of source unless a snapshot is intentionally
   being documented.

The main engineering value is prioritization. The harness should help answer:

- Which ambiguous pitch-class sets produce fragile names?
- Which inversions change external-tool naming unexpectedly?
- Which WhatChord second candidates are more plausible than the primary label on
  rows where oracles disagree?
- Which external disagreements are actually notation differences rather than
  analysis differences?

## Limitations

The harness intentionally compares labels, not truth. Label normalization is
simple and conservative; it will flag some harmless spelling differences as
disagreements. That is acceptable for discovery because the output is meant to
be reviewed, not accepted automatically.

External libraries may also ignore bass, octave, or spelling in ways that differ
from WhatChord's real-time MIDI use case. This is another reason to treat the
report as an edge-case finder rather than a conformance suite.

Finally, generated pitch-class sets are not weighted by musical frequency. Use
the ChoCo coverage work alongside this harness: ChoCo helps identify which chord
vocabulary appears in real annotations, while oracle comparison helps identify
where naming and ranking are debatable.
