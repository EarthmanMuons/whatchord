# Contrapunctus Benchmark Comparison

In June 2026, we reviewed the [Contrapunctus engine benchmark][engine-page] and
its [public evaluation repository][bench-repo] to determine whether its corpus
or methodology could improve WhatChord's chord analyzer.

The short conclusion is:

- Contrapunctus's headline result is not directly comparable to WhatChord.
- Its public corpus and evaluation discipline are valuable.
- A chord-identification-only slice of the same corpus is useful as a research
  benchmark for WhatChord.
- The first run supports the current engine's broad approach and identifies a
  focused set of ambiguous inversion families for review.

## What Contrapunctus Measures

Contrapunctus performs autonomous Roman-numeral analysis over complete MusicXML
scores. Given a score, it detects local keys and emits one functional Roman
numeral for every annotated event.

Its production engine combines:

- rule-based key detection;
- rule-based chord-candidate generation;
- a learned chord-label reranker using tonic-rotated, windowed pitch-class
  features.

The public benchmark compares Contrapunctus with AugmentedNet, AnalysisGNN, and
music21 on the [When-in-Rome][when-in-rome] Roman-numeral corpus. Its June 13,
2026 website snapshot reports:

| Measure                                  | Contrapunctus | AugmentedNet | AnalysisGNN | music21 |
| ---------------------------------------- | ------------: | -----------: | ----------: | ------: |
| All-piece exact Roman-numeral match      |        60.11% |       51.51% |      46.63% |  45.96% |
| Genre-balanced exact Roman-numeral match |        52.59% |       47.94% |      38.72% |  31.73% |
| Event-capped genre-balanced exact match  |        54.11% |       46.47% |      37.77% |  31.09% |

Music21 receives the analyst's local key because it has no autonomous key
detector, so its result is explicitly an easier-conditions upper bound. The
other engines receive raw MusicXML. Contrapunctus evaluates its learned reranker
out of sample by piece.

The public repository's latest committed result at the time of review is dated
June 11, 2026 and trails the website's June 13 snapshot slightly. The website
and repository both disclose their result dates and provenance.

## Why The Headline Is Not Our Benchmark

WhatChord and Contrapunctus answer different questions.

WhatChord asks:

> Given the notes sounding now, what chord symbol would a musician expect for
> this observed voicing?

Contrapunctus asks:

> Given this complete score and its surrounding harmonic sequence, what
> functional Roman numeral did the analyst intend at this event?

The difference matters. A score event may contain passing tones, suspensions,
pedal tones, arpeggiation, or incomplete chord tones. A contextual analyzer can
correctly retain the underlying Roman numeral while WhatChord should correctly
name the literal sonority currently sounding.

Contrapunctus's all-event exact percentage therefore must not be used as a
WhatChord accuracy target. Optimizing for it would push music-theory logic and
temporal assumptions into an engine intentionally designed for isolated live
MIDI input.

## The Comparable Slice

The research harnesses added for this review are:

- [`tool/when_in_rome_chord_benchmark.py`](../../tool/when_in_rome_chord_benchmark.py)
- [`tool/when_in_rome_chord_batch.dart`](../../tool/when_in_rome_chord_batch.dart)

The Python harness reuses Contrapunctus's public alignment helpers to:

1. Read analyst Roman-numeral events from When-in-Rome.
2. Find the notes sounding at each annotated score position.
3. Send the pitch-class set, actual bass, note count, and analyst key to
   WhatChord.
4. Compare WhatChord's selected root with the analyst-annotated chord root.
5. Report a separate clean slice where the sounding pitch-class set exactly
   equals the analyst chord's pitch-class set.

Root agreement on a clean event is the most useful comparable identity metric.
The harness also reports whether the analyst root appears in WhatChord's top
three candidates and whether the score's actual bass agrees with the annotated
inversion.

## Initial Results

The first measured pass selected four contrasting common-subset genres:

| Genre           | Pieces |
| --------------- | -----: |
| Bach WTC I      |     24 |
| Mozart sonatas  |     24 |
| Brahms lieder   |      9 |
| Schubert lieder |     39 |
| **Total**       | **96** |

Two pieces produced no qualifying three-pitch-class events, leaving 94 pieces
represented in event-level results.

| Slice                                    | Events | Root exact | Root in top 3 | Root + inversion |
| ---------------------------------------- | -----: | ---------: | ------------: | ---------------: |
| All aligned three-pitch-class events     |  6,360 |     58.38% |        71.18% |           53.47% |
| Clean pitch-set events                   |  3,026 |     89.62% |        97.62% |           84.86% |
| Clean events with analyst-matching bass  |  2,872 |     89.42% |        97.56% |           89.42% |
| Clean, non-symmetric mainstream families |  2,812 |     93.49% |       100.00% |           88.44% |

The low all-event number is expected and confirms that the full Roman-numeral
benchmark is the wrong product target. The clean-event results are the useful
signal.

### Results By Common Family

| Analyst chord family    | Events | Root exact | Root in top 3 |
| ----------------------- | -----: | ---------: | ------------: |
| Major triad             |  1,531 |    100.00% |       100.00% |
| Minor triad             |    764 |     86.78% |       100.00% |
| Dominant seventh        |    337 |    100.00% |       100.00% |
| Major seventh           |     14 |    100.00% |       100.00% |
| Minor seventh           |     35 |     40.00% |       100.00% |
| Half-diminished seventh |     47 |     19.15% |       100.00% |
| Diminished triad        |     84 |     72.62% |       100.00% |
| Diminished seventh      |     89 |     33.71% |        66.29% |
| Augmented triad         |     18 |     22.22% |       100.00% |

These numbers need musical interpretation:

- Augmented triads and diminished sevenths are root-symmetric, so exact analyst
  root agreement is not a fair correctness measure.
- Inverted minor, minor-seventh, half-diminished, and diminished structures have
  common competing readings such as major-sixth or minor-sixth chords. The 100%
  top-three result shows that candidate generation is strong; the disagreement
  is primarily ranking and use-case convention.
- Italian and German augmented-sixth labels do not map to a distinct WhatChord
  chord family. They are functional, key-dependent readings rather than isolated
  chord-symbol identities.

## Useful Lessons From Their Evaluation

Contrapunctus's strongest contribution to WhatChord is methodological:

1. Keep exact and defensible-alternate metrics separate. Their tiered scoring
   makes ambiguity visible without quietly inflating the headline.
2. Preserve every event in the denominator. Missing predictions must not
   disappear from a benchmark.
3. Report both event-weighted and genre-balanced results. Large homogeneous
   corpora such as chorales can otherwise dominate conclusions.
4. Pin the evaluated piece intersection and record provenance. Corpus drift can
   change aggregate results without an engine change.
5. Track negative experiments. Contrapunctus found that learned key detectors,
   larger rerankers, Viterbi selection, and several temporal support features
   did not improve its target metric.
6. Evaluate learned behavior out of sample by piece. If WhatChord ever
   experiments with a learned ranking prior, corpus pieces must be grouped
   across folds to prevent leakage.

## Recommendations

1. Keep the new harness as a research benchmark, not a golden test or product
   oracle. Analyst Roman numerals remain advisory evidence.
2. Review clean inverted minor, minor-seventh, half-diminished, and diminished
   cases where the analyst root is not WhatChord's top choice. Only change the
   engine when a reusable isolated-voicing principle supports the change.
3. Add a report view that separates symmetric-root cases and unsupported
   functional labels before using the aggregate to evaluate ranking changes.
4. Expand the run to the separately fetched Riemenschneider chorales and other
   available genres. Report genre-balanced results once those sources are
   present.
5. Do not add augmented-sixth chord families solely to improve corpus root
   agreement. Their meaning depends on tonal function and voice leading.
6. Do not add a learned reranker yet. WhatChord's existing deterministic rules
   remain explainable, cross-platform, and strong on its directly comparable
   task. The clean non-symmetric top-three result shows that targeted ranking
   review is the higher-value next step.

## Reproducing

Clone the public benchmark and initialize its corpus:

```sh
git clone --depth 1 https://github.com/Tomczik76/contrapunctus-bench.git /private/tmp/contrapunctus-bench
git -C /private/tmp/contrapunctus-bench submodule update --init --depth 1 corpus/When-in-Rome
```

Run the comparable WhatChord slice:

```sh
./.venv/bin/python tool/when_in_rome_chord_benchmark.py \
  /private/tmp/contrapunctus-bench \
  --groups bach-wtc mozart-sonatas-dcml brahms-lieder schubert-lieder
```

Outputs are written to:

```text
build/when-in-rome-chord-benchmark/summary.json
build/when-in-rome-chord-benchmark/events.csv
```

Contrapunctus's separate corpus preparation scripts fetch the Riemenschneider
chorales, TAVERN scores, and Monteverdi material when a broader run is needed.

## Limitations

This first run is not the full 505-piece Contrapunctus common subset. It covers
the public scores available immediately from the When-in-Rome submodule and does
not include the separately fetched chorale, TAVERN, or Monteverdi score sources.

The analyst annotation remains contextual even on a clean pitch-set event. Exact
pitch-set equality removes non-chord tones, but it does not remove functional
ambiguity, root symmetry, or annotation-house-style differences.

Finally, the harness currently scores root and bass agreement rather than full
surface chord-symbol spelling. WhatChord's existing ChoCo and chord-oracle
research remain better tools for vocabulary coverage, extensions, spelling, and
display-label review.

[bench-repo]: https://github.com/Tomczik76/contrapunctus-bench
[engine-page]: https://www.contrapunctus.app/engine
[when-in-rome]: https://github.com/MarkGotham/When-in-Rome
