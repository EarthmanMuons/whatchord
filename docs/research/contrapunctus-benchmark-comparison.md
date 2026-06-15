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

| Slice                                    | Events | Root exact | Root visible | Root + inversion |
| ---------------------------------------- | -----: | ---------: | -----------: | ---------------: |
| All aligned three-pitch-class events     |  6,360 |     60.20% |       64.72% |           55.41% |
| Clean pitch-set events                   |  3,026 |     93.72% |       98.45% |           88.90% |
| Clean events with analyst-matching bass  |  2,872 |     93.66% |       98.36% |           93.66% |
| Clean, non-symmetric mainstream families |  2,812 |     97.90% |      100.00% |           92.78% |

The low all-event number is expected and confirms that the full Roman-numeral
benchmark is the wrong product target. The clean-event results are the useful
signal.

### Results By Common Family

| Analyst chord family    | Events | Root exact | Root visible |
| ----------------------- | -----: | ---------: | -----------: |
| Major triad             |  1,531 |    100.00% |      100.00% |
| Minor triad             |    764 |    100.00% |      100.00% |
| Dominant seventh        |    337 |    100.00% |      100.00% |
| Major seventh           |     14 |    100.00% |      100.00% |
| Minor seventh           |     35 |     40.00% |      100.00% |
| Half-diminished seventh |     47 |     19.15% |      100.00% |
| Diminished triad        |     84 |    100.00% |      100.00% |
| Diminished seventh      |     89 |     33.71% |       66.29% |
| Augmented triad         |     18 |     22.22% |      100.00% |

These numbers need musical interpretation:

- Augmented triads and diminished sevenths are root-symmetric, so exact analyst
  root agreement is not a fair correctness measure.
- Inverted minor, minor-seventh, half-diminished, and diminished structures have
  common competing readings such as major-sixth or minor-sixth chords. The 100%
  visible result for minor-seventh and half-diminished families shows that
  WhatChord surfaces the analyst's reading as a near-tie alternative; their
  disagreement is primarily naming convention rather than missing coverage.
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
   task. The clean visible-alternative result shows that targeted ranking review
   is the higher-value next step.

## Reviewing Cases

Each benchmark run writes `report.txt` alongside the CSV and JSON outputs. The
report deduplicates equivalent events, records occurrence counts and sample
pieces, and emits a `bin/chord-debug` command for every review case.

Review the report in this order:

1. **Candidate gaps**: the analyst root is absent from WhatChord's candidate
   list. These are the highest-value cases because candidate generation or
   template coverage may be incomplete. First decide whether the analyst's
   contextual root is also a defensible isolated-voicing root.
2. **Hidden ranking divergences**: WhatChord generates the analyst root but does
   not surface it within the near-tie window. These are product-visible misses
   even when the root happens to rank second or third.
3. **Visible ranking divergences**: WhatChord selects a different reading but
   surfaces the analyst root as a near-tie alternative. Review these as naming
   policy questions rather than coverage failures.
4. **Annotation inversion differences**: WhatChord agrees on root, but the
   sounding score bass differs from the analyst's inversion. These are usually
   score/annotation or event-alignment questions rather than analyzer issues.
5. **Symmetric roots and functional labels**: classify and retain for research,
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
| Hidden ranking divergence       |      0 |                  0 |
| Visible ranking divergence      |     59 |                 34 |
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

## Expanded Corpus Validation

After the first review and analyzer correction, the benchmark was expanded with
the separately fetched Riemenschneider chorales and TAVERN scores. The expanded
run covers 473 pieces across six genres:

| Genre                        |  Pieces | Aligned events | Clean events | Clean root exact | Clean root visible |
| ---------------------------- | ------: | -------------: | -----------: | ---------------: | -----------------: |
| Bach WTC                     |      24 |            935 |          376 |           93.62% |            100.00% |
| Brahms lieder                |       9 |            567 |          200 |           94.00% |            100.00% |
| Bach chorales                |     370 |         20,939 |       17,001 |           95.06% |             99.99% |
| Mozart sonatas               |      24 |          2,160 |          984 |           94.11% |             97.66% |
| Schubert lieder              |      39 |          2,698 |        1,466 |           93.45% |             98.36% |
| TAVERN variations            |       7 |          1,007 |          410 |           99.27% |            100.00% |
| **Event-weighted aggregate** | **473** |     **28,306** |   **20,437** |       **94.95%** |         **99.76%** |

The aggregate is dominated by chorales, so the per-genre rows are more
informative than the event-weighted aggregate. They show that the corrected
analyzer holds across every included genre rather than merely fitting the
initial four-genre sample. TAVERN's low all-event agreement and high clean-event
agreement also confirm that the clean-event filter is separating literal
voicings from contextual or figural annotations as intended.

Giving each genre equal weight produces 94.92% clean root agreement and 99.33%
clean visible-root agreement. This is the more appropriate headline when
comparing future runs because it prevents the large chorale corpus from masking
changes in the smaller genres.

Top-three presence remains in `summary.json` only for continuity with the first
run. It is not treated as a product match or a coverage boundary. A non-primary
reading counts as visible only when it falls within WhatChord's near-tie window
and would therefore be surfaced to the user. Candidate generation is checked
against the full ranked result. In this run, visible agreement is higher than
top-three presence because some near-tie alternatives rank below third but are
still surfaced by the app.

The expanded review report contains:

| Flag                            | Events |
| ------------------------------- | -----: |
| Candidate gap                   |      0 |
| Hidden ranking divergence       |      0 |
| Visible ranking divergence      |    804 |
| Annotation inversion difference |    317 |
| Symmetric root                  |    376 |
| Functional label                |     26 |
| Explicit or incomplete label    |     74 |

All 804 visible ranking divergences are one coherent ambiguity family:

- 400 analyst-labeled minor-seventh chords ranked second behind root-position
  major-sixth chords;
- 404 analyst-labeled half-diminished seventh chords ranked second behind
  root-position minor-sixth chords.

The analyst root is WhatChord's second, visible near-tie candidate in every
case. Chorales contribute 743 of the 804 events, mostly first-inversion `ii6/5`
and `iiø6/5` annotations. This is expected contextual Roman-numeral behavior,
while WhatChord's selected sixth-chord label is a conventional isolated-voicing
reading of the same pitch set and bass.

### Sixth Versus Inverted Seventh Policy Review

Focused examples, external oracles, transpositions, and negative cases support
retaining the current preference:

| Pitch set | Bass | WhatChord | music21 | Tonal        | pychord   |
| --------- | ---- | --------- | ------- | ------------ | --------- |
| C E G A   | C    | C6        | Am7/C   | C6, Am7/C    | no label  |
| C E G A   | A    | Am7       | Am7     | Am7, C6/A    | Am7, C6/A |
| D F A B   | D    | Dm6       | Bm7b5/D | Dm6, Bm7b5/D | no label  |
| D F A B   | B    | Bm7b5     | Bm7b5   | Bm7b5, Dm6/B | no label  |

The same structural results hold under transposition. They also hold when the
selected key changes: `C6` versus `Am7/C` and `Dm6` versus `Bm7b5/D` remain
ambiguous because both readings are normally diatonic together. Key alone does
not reveal whether the sonority is functioning as an added-sixth chord or an
inverted seventh chord; that requires progression or voice-leading context
outside WhatChord's current observed-voicing input.

The negative cases are decisive:

- When the seventh-chord root is in the bass, WhatChord and the available
  oracles converge on the root-position seventh chord.
- When the sixth-chord root is in the bass, Tonal and WhatChord prefer the
  root-position sixth while music21 applies its analysis-oriented inverted
  seventh convention.
- When neither competing root is in the bass, the oracle split persists rather
  than revealing a stable key-context rule.

The recommended policy is therefore to keep the bass-rooted isolated-voicing
preference and continue surfacing the inverted seventh as a near-tie
alternative. Do not promote the Roman-numeral root from key context alone. A
future progression-aware analysis mode could revisit the choice because it would
have the functional evidence that the corpus annotations use.

## Corpus Expansion Priority

The separately fetched sources are not equally valuable to WhatChord:

1. **Riemenschneider chorales: completed.** Their homophonic SATB texture
   provided the strongest validation of common triad, seventh, inversion, and
   voice-leading cases.
2. **TAVERN: completed.** Its figural and arpeggiated texture confirmed that the
   clean-event filter separates literal voicings from contextual annotations.
3. **Monteverdi: optional, separate report.** Its 48 madrigals are deliberately
   pre-tonal and excluded from Contrapunctus's tonal aggregate. They are useful
   for robustness and modal-edge-case research, not as a WhatChord accuracy
   target.

Do not mix Monteverdi into the tonal accuracy aggregate. Fetch and run it only
when there is a specific modal or pre-tonal robustness question to investigate.

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

Run the expanded six-genre validation:

```sh
./.venv/bin/python tool/when_in_rome_chord_benchmark.py \
  /private/tmp/contrapunctus-bench \
  --groups bach-wtc mozart-sonatas-dcml brahms-lieder schubert-lieder \
    chorales tavern \
  --out-dir build/when-in-rome-chord-benchmark-expanded
```

Outputs are written under the selected output directory. The default run uses
`build/when-in-rome-chord-benchmark`; the expanded command above uses
`build/when-in-rome-chord-benchmark-expanded`. Each contains:

```text
summary.json
events.csv
report.txt
```

Contrapunctus's separate corpus preparation scripts fetch the Riemenschneider
chorales, TAVERN scores, and Monteverdi material when a broader run is needed.

## Limitations

The expanded run is not the full 505-piece Contrapunctus common subset. It
covers the six tonal genres most directly useful to WhatChord and intentionally
excludes the pre-tonal Monteverdi scores. It also excludes Contrapunctus genres
that were not part of the initial comparable slice or separately prepared
expansion.

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
