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
| All aligned three-pitch-class events     |  6,360 |     60.20% |        71.18% |           55.41% |
| Clean pitch-set events                   |  3,026 |     93.72% |        97.62% |           88.90% |
| Clean events with analyst-matching bass  |  2,872 |     93.66% |        97.56% |           93.66% |
| Clean, non-symmetric mainstream families |  2,812 |     97.90% |       100.00% |           92.78% |

The low all-event number is expected and confirms that the full Roman-numeral
benchmark is the wrong product target. The clean-event results are the useful
signal.

### Results By Common Family

| Analyst chord family    | Events | Root exact | Root in top 3 |
| ----------------------- | -----: | ---------: | ------------: |
| Major triad             |  1,531 |    100.00% |       100.00% |
| Minor triad             |    764 |    100.00% |       100.00% |
| Dominant seventh        |    337 |    100.00% |       100.00% |
| Major seventh           |     14 |    100.00% |       100.00% |
| Minor seventh           |     35 |     40.00% |       100.00% |
| Half-diminished seventh |     47 |     19.15% |       100.00% |
| Diminished triad        |     84 |    100.00% |       100.00% |
| Diminished seventh      |     89 |     33.71% |        66.29% |
| Augmented triad         |     18 |     22.22% |       100.00% |

These numbers need musical interpretation:

- Augmented triads and diminished sevenths are root-symmetric, so exact analyst
  root agreement is not a fair correctness measure.
- Inverted minor, minor-seventh, half-diminished, and diminished structures have
  common competing readings such as major-sixth or minor-sixth chords. The
  remaining 100% top-three result for minor-seventh and half-diminished families
  shows that candidate generation is strong; their disagreement is primarily
  ranking and use-case convention.
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
2. Review the remaining clean minor-seventh and half-diminished cases where the
   analyst root is not WhatChord's top choice. Only change the engine when a
   reusable isolated-voicing principle supports the change.
3. Keep using the report view to separate symmetric-root, functional,
   explicit-degree, and incomplete-label cases before evaluating ranking
   changes.
4. Expand the run to the separately fetched Riemenschneider chorales and TAVERN
   scores. Report genre-balanced results once those sources are present. Keep
   Monteverdi as a separate pre-tonal robustness study rather than mixing it
   into the tonal accuracy aggregate.
5. Do not add augmented-sixth chord families solely to improve corpus root
   agreement. Their meaning depends on tonal function and voice leading.
6. Do not add a learned reranker yet. WhatChord's existing deterministic rules
   remain explainable, cross-platform, and strong on its directly comparable
   task. The clean non-symmetric top-three result shows that targeted ranking
   review is the higher-value next step.

## Reviewing Cases

Each benchmark run writes `report.txt` alongside the CSV and JSON outputs. The
report deduplicates equivalent events, records occurrence counts and sample
pieces, and emits a `bin/chord-debug` command for every review case.

Review the report in this order:

1. **Candidate gaps**: the analyst root is absent from WhatChord's top three.
   These are the highest-value cases because candidate generation or template
   coverage may be incomplete. First decide whether the analyst's contextual
   root is also a defensible isolated-voicing root.
2. **Ranking divergences**: WhatChord generates the analyst root but selects a
   different reading. Review the most frequent deduplicated cases by family.
   Compare structural fit, bass role, normal musician naming, and the existing
   chord-oracle tools.
3. **Annotation inversion differences**: WhatChord agrees on root, but the
   sounding score bass differs from the analyst's inversion. These are usually
   score/annotation or event-alignment questions rather than analyzer issues.
4. **Symmetric roots and functional labels**: classify and retain for research,
   but do not optimize exact-root ranking against them without a product-level
   reason.

For candidate gaps and ranking divergences:

1. Run the report's `bin/chord-debug` command.
2. Run the same notes through `bin/chord-oracle` when the external oracles are
   available.
3. Judge the case as an isolated live voicing, not as a Roman-numeral exercise.
4. Check transpositions and neighboring inversions before proposing a rule.
5. Change the engine only when one reusable musical principle explains a
   meaningful family of cases.
6. Add focused positive and negative golden cases before changing a ranking
   rule, then rerun the corpus report to inspect gains and regressions.

The next likely review family is the recurring ambiguity between inverted
minor-seventh or half-diminished chords and root-position sixth chords. These
remain more ambiguous than the resolved triad case because both readings are
complete seventh/sixth structures. The review question is which label best
serves an isolated voicing in each bass, key, and conventional-use
configuration.

The initial four-genre report produced this review backlog:

| Flag                            | Events | Deduplicated cases |
| ------------------------------- | -----: | -----------------: |
| Candidate gap                   |      0 |                  0 |
| Ranking divergence              |     59 |                 34 |
| Annotation inversion difference |    144 |                 93 |
| Symmetric root                  |    107 |                 69 |
| Functional label                |     23 |                 16 |
| Explicit or incomplete label    |     71 |                 50 |

After separating unusual explicit-degree, incomplete, symmetric, and functional
annotations, the report found no actionable candidate-generation gaps in this
four-genre pass. The next review target is therefore the remaining minor-seventh
and half-diminished inversions competing with root-position sixth chords. Treat
them as coherent policy questions rather than 34 unrelated cases.

The first reviewed example was a complete `Dm/F` voicing with a doubled F.
WhatChord selected fifthless root-position `F6`; music21, Tonal, pychord, and
the When-in-Rome analyst selected `Dm/F`. This behavior was deliberate rather
than an accidental scoring bug: an older golden case explicitly treated a
root-position fifthless sixth chord with a doubled root as legitimate.

Re-evaluating that policy produced a reusable correction: sixth-chord
completeness now depends on distinct pitch classes, not total struck notes.
Doubling a tone does not supply the missing fifth. On this benchmark the change:

- raised clean root agreement from 89.62% to 93.72%;
- produced 124 clean-event gains and zero clean-event losses;
- resolved 101 minor-triad and 23 diminished-triad events;
- reduced ranking-divergence events from 183 to 59.

The change also reopened and corrected the older doubled-root golden. This is a
useful example of why golden expectations should record current decisions
without being treated as permanent musical authority.

## Corpus Expansion Priority

The separately fetched sources are not equally valuable to WhatChord:

1. **Riemenschneider chorales: high priority.** They add 370 common-subset
   pieces and roughly 21,628 annotated events. Their homophonic SATB texture is
   close to simultaneous live chord input and should provide the strongest
   validation of common triad, seventh, inversion, and voice-leading cases.
2. **TAVERN: medium priority.** Its seven common-subset variation sets add
   roughly 2,882 events. The figural and arpeggiated texture is less directly
   comparable, but it is useful for measuring how often the clean-event filter
   separates literal voicings from contextual annotations.
3. **Monteverdi: optional, separate report.** Its 48 madrigals are deliberately
   pre-tonal and excluded from Contrapunctus's tonal aggregate. They are useful
   for robustness and modal-edge-case research, not as a WhatChord accuracy
   target.

Fetch chorales and TAVERN after the first candidate-gap and ranking-family
review. That sequence lets the expanded corpus validate a review policy instead
of merely producing a larger unclassified queue.

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
build/when-in-rome-chord-benchmark/report.txt
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
