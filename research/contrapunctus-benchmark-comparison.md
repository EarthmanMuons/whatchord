# Contrapunctus Benchmark Comparison

In June 2026, we reviewed the [Contrapunctus engine benchmark][engine-page] and
its [public evaluation repository][bench-repo] to determine whether its corpus
or methodology could improve WhatChord's chord analyzer.

The research produced one analyzer correction, a reusable benchmark harness, and
clearer boundaries around what the corpus can and cannot measure for WhatChord.

## Conclusions

- Contrapunctus's headline Roman-numeral accuracy is not directly comparable to
  WhatChord's isolated chord-identification task.
- A clean-event slice of the same corpus is valuable for testing WhatChord's
  root identification and surfaced alternatives.
- The expanded benchmark covers 473 pieces and 20,437 clean events. WhatChord
  selects the analyst root on 94.95% of clean events and either selects or
  visibly surfaces it on 99.76%.
- The review found one legitimate analyzer issue: octave doubling could make an
  incomplete fifthless sixth chord outrank a complete inverted minor or
  diminished triad. Correcting it produced 124 clean-event gains and no clean
  losses in the initial benchmark.
- No mainstream analyst root is currently absent from WhatChord's candidates or
  hidden outside the alternatives shown to users.
- The remaining primary-label disagreements are contextual or inherently
  ambiguous. They do not justify another isolated-voicing ranking change.

## Scope Difference

Contrapunctus performs autonomous Roman-numeral analysis over complete MusicXML
scores. Given a score, it detects local keys and emits one functional Roman
numeral for every annotated event. Its production engine combines rule-based key
detection, rule-based chord-candidate generation, and a learned chord-label
reranker using tonic-rotated, windowed pitch-class features.

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

WhatChord and Contrapunctus answer different questions:

> WhatChord: Given the notes sounding now, what chord symbol would a musician
> expect for this observed voicing?

> Contrapunctus: Given this complete score and its surrounding harmonic
> sequence, what functional Roman numeral did the analyst intend at this event?

A score event may contain passing tones, suspensions, pedal tones, arpeggiation,
or incomplete chord tones. A contextual analyzer can correctly retain the
underlying Roman numeral while WhatChord should correctly name the literal
sonority currently sounding.

Contrapunctus's all-event exact percentage therefore must not be used as a
WhatChord accuracy target.

## Benchmark Method

The research harnesses are:

- [`tool/chord/when_in_rome_benchmark.py`](../tool/chord/when_in_rome_benchmark.py)
- [`tool/chord/when_in_rome_batch.dart`](../tool/chord/when_in_rome_batch.dart)

The Python harness reuses Contrapunctus's public alignment helpers to:

1. Read analyst Roman-numeral events from When-in-Rome.
2. Find the notes sounding at each annotated score position.
3. Send the pitch-class set, actual bass, note count, and analyst key to
   WhatChord.
4. Compare WhatChord's selected and generated roots with the analyst root.
5. Report a separate clean slice where the sounding pitch-class set exactly
   equals the analyst chord's pitch-class set.

The clean slice removes events where the literal sounding pitch set differs from
the annotation. It does not remove functional ambiguity, symmetric roots,
explicitly incomplete annotations, or annotation-house-style differences.

### Metrics

The benchmark uses these distinctions:

| Metric                       | Meaning                                                                                                  |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| Root exact                   | WhatChord selects the analyst root.                                                                      |
| Root visible                 | WhatChord selects the analyst root or surfaces it as an alternative.                                     |
| Candidate gap                | The analyst root is present in the sounding voicing but absent from WhatChord's full generated ranking.  |
| Hidden ranking divergence    | WhatChord generates the analyst root but does not surface it as an alternative.                          |
| Visible ranking divergence   | WhatChord selects a different root but surfaces the analyst root as an alternative.                      |
| Rootless annotation          | The analyst root is absent from the sounding pitch set and excluded by WhatChord's no-ghost-root policy. |
| Root + annotation bass exact | WhatChord selects the analyst root and the score's sounding bass matches the annotation inversion.       |

Root-visible agreement is the product-relevant alternative-reading metric.
Top-three presence remains in `summary.json` only for continuity with the first
run; it is neither a product match nor a candidate-coverage boundary. Some
alternatives rank below third but are still surfaced by the app.

Root + annotation bass is a corpus-alignment metric, not WhatChord inversion
accuracy. WhatChord receives the score's actual lowest sounding note and
necessarily uses it as the slash bass.

## Expanded Results

The final run, completed June 15, 2026, covers six tonal genres selected for
their relevance to simultaneous chord identification:

| Genre                        |  Pieces | Aligned events | Clean events | Clean root exact | Clean root visible |
| ---------------------------- | ------: | -------------: | -----------: | ---------------: | -----------------: |
| Bach WTC                     |      24 |            935 |          376 |           93.62% |            100.00% |
| Brahms lieder                |       9 |            567 |          200 |           94.00% |            100.00% |
| Bach chorales                |     370 |         20,939 |       17,001 |           95.06% |             99.99% |
| Mozart sonatas               |      24 |          2,160 |          984 |           94.11% |             97.66% |
| Schubert lieder              |      39 |          2,698 |        1,466 |           93.45% |             98.36% |
| TAVERN variations            |       7 |          1,007 |          410 |           99.27% |            100.00% |
| **Event-weighted aggregate** | **473** |     **28,306** |   **20,437** |       **94.95%** |         **99.76%** |

The aggregate views answer different research questions and are calculated as
follows:

| Aggregate view                        | Calculation                                                                                          | Root exact | Root visible |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------: | -----------: |
| Clean events, event-weighted          | Matching clean events divided by all 20,437 clean events                                             |     94.95% |       99.76% |
| Clean events, genres weighted equally | Arithmetic mean of the six per-genre clean percentages, giving each genre one-sixth of the aggregate |     94.92% |       99.33% |
| All aligned events, event-weighted    | Matching aligned events divided by all 28,306 aligned events                                         |     79.95% |       84.94% |

The genre-balanced clean result of 94.92% exact and 99.33% visible is the
preferred headline for comparisons between future runs. It measures the
comparable clean-event task without allowing the 17,001 chorale events to mask
changes in smaller genres.

The event-weighted clean result describes overall agreement across every clean
event, but is dominated by chorales. The lower all-event result is expected
because those events include non-chord tones and contextual annotations. TAVERN
demonstrates the distinction particularly clearly: its all-event root agreement
is 59.19%, while its clean-event root agreement is 99.27%.

### Review Classification

The final clean-event review classification is:

| Flag                         | Events |
| ---------------------------- | -----: |
| Agree                        | 18,840 |
| Candidate gap                |      0 |
| Hidden ranking divergence    |      0 |
| Visible ranking divergence   |    804 |
| Rootless annotation          |     11 |
| Annotation bass difference   |    317 |
| Symmetric root               |    376 |
| Functional label             |     26 |
| Explicit or incomplete label |     63 |

There are no mainstream candidate-generation gaps and no hidden analyst roots.

## Analyzer Improvement

The first focused review found a complete `Dm/F` voicing with a doubled F for
which WhatChord selected fifthless root-position `F6`. Music21, Tonal, pychord,
and the When-in-Rome analyst selected `Dm/F`.

The previous behavior was deliberate rather than an accidental scoring bug: an
older golden case explicitly treated a root-position fifthless sixth chord with
a doubled root as legitimate. Re-evaluating that policy produced a reusable
correction:

> Sixth-chord completeness depends on distinct pitch classes, not total struck
> notes. Doubling a tone does not supply the missing fifth.

On the initial four-genre benchmark, the correction:

- raised clean root agreement from 89.62% to 93.72%;
- produced 124 clean-event gains and zero clean-event losses;
- resolved 101 minor-triad and 23 diminished-triad events;
- reduced visible ranking-divergence events from 183 to 59.

The change also corrected the older doubled-root golden. This demonstrates why
golden expectations should record current decisions without being treated as
permanent musical authority.

## Resolved Policy Questions

### Sixth Chords Versus Inverted Sevenths

All 804 visible ranking divergences in the expanded run belong to one coherent
ambiguity family:

- 400 analyst-labeled minor-seventh chords ranked second behind root-position
  major-sixth chords;
- 404 analyst-labeled half-diminished seventh chords ranked second behind
  root-position minor-sixth chords.

The analyst root is a visible alternative in every case. Chorales contribute 743
events, mostly first-inversion `ii6/5` and `iiø6/5` annotations. This is
expected contextual Roman-numeral behavior, while WhatChord's selected
sixth-chord label is a conventional isolated-voicing reading of the same pitch
set and bass.

Focused oracle comparisons support retaining the current preference:

| Pitch set | Bass | WhatChord | music21 | Tonal        | pychord   |
| --------- | ---- | --------- | ------- | ------------ | --------- |
| C E G A   | C    | C6        | Am7/C   | C6, Am7/C    | no label  |
| C E G A   | A    | Am7       | Am7     | Am7, C6/A    | Am7, C6/A |
| D F A B   | D    | Dm6       | Bm7b5/D | Dm6, Bm7b5/D | no label  |
| D F A B   | B    | Bm7b5     | Bm7b5   | Bm7b5, Dm6/B | no label  |

The structural results hold under transposition and selected-key changes.
Because both readings are normally diatonic together, key alone does not reveal
whether the sonority functions as an added-sixth chord or an inverted seventh
chord. That requires progression or voice-leading context outside WhatChord's
current observed-voicing input.

**Decision:** Keep the bass-rooted isolated-voicing preference, continue
surfacing the inverted seventh as an alternative, and do not promote the
Roman-numeral root from key context alone.

### Rootless Annotations

Eleven clean events use an analyst root absent from the sounding pitch set. All
are unusual incomplete or set-class annotations. Representative focused checks
produced no label from music21, Tonal, or pychord.

**Decision:** Retain WhatChord's no-ghost-root policy for solo-keyboard chord
identification. Rootless jazz or ensemble voicings would require a targeted
corpus and an explicit product mode before relaxing that policy.

### Functional And Symmetric Labels

The remaining non-visible clean events are:

- 23 functional augmented-sixth labels;
- 15 explicit-degree, incomplete, enharmonic-equivalent, or set-class labels
  whose analyst root is generated but not visible;
- 11 rootless annotations.

Augmented-sixth labels depend on tonal function and voice leading. Augmented
triads and diminished sevenths are root-symmetric, so exact analyst-root
agreement is not a fair correctness measure.

**Decision:** Do not add augmented-sixth chord families or optimize symmetric
root ordering solely to improve corpus agreement.

### Annotation Bass Differences

There are 317 clean events where WhatChord agrees on the root but the score's
actual lowest sounding note differs from the Roman-numeral inversion. Spot
checks confirmed that the events are correctly aligned. For example, Bach
Chorale 331 explicitly annotates `m9 b2 I`, while the clean D-major score
voicing has A in the bass. Mozart examples likewise include `I` over a fifth
bass and `I6` over a root bass.

**Decision:** Treat `root_and_annotation_bass_exact` as a source-alignment
metric, not as WhatChord inversion accuracy.

## Research Workflow

Each benchmark run writes `report.txt`, `events.csv`, and `summary.json`. The
report deduplicates equivalent cases, records occurrence counts and score
locations, shows score and annotation basses, and emits a reproducible
`bin/chord-debug` command.

Review report categories in this order:

1. **Candidate gaps**: determine whether a mainstream isolated-voicing root is
   missing from candidate generation.
2. **Hidden ranking divergences**: determine why a defensible generated root is
   not visible to the user.
3. **Visible ranking divergences**: review as naming-policy questions rather
   than coverage failures.
4. **Rootless, symmetric, functional, and explicit labels**: classify against
   product scope before considering engine changes.
5. **Annotation bass differences**: audit score and analysis sources rather than
   changing chord identification.

For a potentially actionable family:

1. Run the report's `bin/chord-debug` command.
2. Compare the same notes with `bin/chord-oracle`.
3. Judge the case as an isolated live voicing, not as a Roman-numeral exercise.
4. Check transpositions, neighboring inversions, key contexts, and negative
   cases.
5. Change the engine only when one reusable musical principle explains a
   meaningful family.
6. Add focused positive and negative goldens, then rerun the corpus report to
   inspect gains and regressions.

## Methodological Lessons

Contrapunctus's strongest contribution to WhatChord is evaluation discipline:

1. Keep exact and defensible-visible-alternative metrics separate.
2. Preserve every event in the denominator.
3. Report both event-weighted and genre-balanced results.
4. Pin the evaluated piece intersection and record provenance.
5. Track negative experiments and resolved policy questions.
6. Treat external annotations and oracles as advisory evidence, not truth.
7. If WhatChord ever adds a learned ranking model, train and evaluate it on
   different complete pieces. Never split events from the same piece across
   training and evaluation, because repeated progressions and voicings would
   make the reported accuracy artificially optimistic.

The current evidence does not justify a learned reranker. WhatChord's
deterministic rules remain explainable, cross-platform, and strong on the
directly comparable task.

## Reproducing

Clone the public benchmark and initialize its corpus:

```sh
git clone https://github.com/Tomczik76/contrapunctus-bench.git /private/tmp/contrapunctus-bench
git -C /private/tmp/contrapunctus-bench checkout b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59
git -C /private/tmp/contrapunctus-bench submodule update --init corpus/When-in-Rome
```

Prepare the separately fetched chorale and TAVERN scores:

```sh
cd /private/tmp/contrapunctus-bench
python3 corpus/prep/fetch_kern_chorales.py
python3 corpus/prep/fetch_tavern_scores.py
```

Run the expanded six-genre validation from the WhatChord checkout:

```sh
mise run research:when-in-rome
```

The task installs `music21`, uses `/private/tmp/contrapunctus-bench` by default,
and writes the expanded report to `build/when-in-rome-chord-benchmark-expanded`.
Set `CONTRAPUNCTUS_BENCH_ROOT=/another/path` to use a different checkout. The
equivalent direct command is:

```sh
python tool/chord/when_in_rome_benchmark.py \
  /private/tmp/contrapunctus-bench \
  --groups bach-wtc mozart-sonatas-dcml brahms-lieder schubert-lieder \
    chorales tavern \
  --out-dir build/when-in-rome-chord-benchmark-expanded
```

The output directory contains:

```text
summary.json
events.csv
report.txt
```

Contrapunctus's corpus preparation scripts fetch the Riemenschneider chorales,
TAVERN scores, and Monteverdi material. Monteverdi should remain a separate
pre-tonal robustness study rather than being mixed into the tonal accuracy
aggregate.

## References And Provenance

The benchmark was completed on June 15, 2026 using these upstream snapshots:

| Project                               | Role                                               | Snapshot                            | License                                                                                                                    |
| ------------------------------------- | -------------------------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| [Contrapunctus benchmark][bench-repo] | Manifest, methodology, and score-alignment helpers | [`b9e011c8`][bench-snapshot]        | [Apache-2.0][bench-license] for harness, scoring, and methodology                                                          |
| [When-in-Rome][when-in-rome]          | Analyst Roman numerals and most scores             | [`aa7539f1`][when-in-rome-snapshot] | New repository content is [CC BY-SA 4.0][when-in-rome-license]; converted analyses retain varying original-source licenses |

Contrapunctus also distributes a compiled analysis engine under an
[evaluation-only license][engine-license]. This research did not use or
redistribute that engine; it reused the Apache-2.0 benchmark harness and public
corpus metadata.

The six evaluated corpus groups have these upstream score and analysis sources,
as recorded in Contrapunctus's manifest:

| Group                      | Score source and license                                                    | Analysis source and license                                                       |
| -------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Bach WTC                   | When-in-Rome, CC BY-SA 4.0                                                  | When-in-Rome, CC BY-SA 4.0                                                        |
| Bach chorales              | [Craig Sapp bach-370-chorales][bach-chorales], license documented by source | When-in-Rome, CC BY-SA 4.0                                                        |
| Mozart sonatas             | [DCMLab Mozart piano sonatas][dcml-mozart], license documented by source    | When-in-Rome conversion under CC BY-SA 4.0; original license documented by source |
| Brahms and Schubert lieder | [OpenScore Lieder Corpus][openscore-lieder], CC0                            | When-in-Rome, CC BY-SA 4.0                                                        |
| TAVERN variations          | [TAVERN][tavern], license documented by source                              | When-in-Rome conversion under CC BY-SA 4.0; original license documented by source |

The chorale and TAVERN scores were fetched through the preparation scripts at
the pinned Contrapunctus benchmark commit. Those scripts download upstream
machine state rather than pinned upstream Git commits. The local preparation
produced 370 of 371 chorale scores and all 11 TAVERN scores; the benchmark's
common subset used 370 chorales and 7 TAVERN variation sets. A future
reproduction should record hashes or upstream commits for those fetched files if
bit-for-bit corpus provenance is required.

Focused case reviews used these advisory chord-identification libraries:

| Project            | Version used | License      |
| ------------------ | ------------ | ------------ |
| [music21][music21] | 10.1.0       | BSD-3-Clause |
| [Tonal][tonal]     | 4.10.0       | MIT          |
| [pychord][pychord] | 1.4.0        | MIT          |

These libraries were used as comparison evidence, not as benchmark truth or
runtime dependencies of WhatChord's analysis engine.

## Limitations And Future Boundaries

The expanded run is not the full 505-piece Contrapunctus common subset. It
covers the six tonal genres most directly useful to WhatChord and intentionally
excludes pre-tonal Monteverdi scores and other unprepared genres.

The harness scores root and bass agreement rather than full surface chord-symbol
spelling. WhatChord's ChoCo and chord-oracle research remain better tools for
vocabulary coverage, extensions, spelling, and display-label review.

Further work requires a new product question rather than additional tuning
against this corpus:

- a progression-aware mode could revisit functional Roman-numeral preferences;
- a rootless ensemble or jazz mode could revisit the no-ghost-root policy;
- a separate Monteverdi study could investigate modal and pre-tonal robustness.

[bench-repo]: https://github.com/Tomczik76/contrapunctus-bench
[bench-license]:
  https://github.com/Tomczik76/contrapunctus-bench/blob/b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59/LICENSE
[bench-snapshot]:
  https://github.com/Tomczik76/contrapunctus-bench/commit/b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59
[bach-chorales]: https://github.com/craigsapp/bach-370-chorales
[dcml-mozart]: https://github.com/DCMLab/mozart_piano_sonatas
[engine-license]:
  https://github.com/Tomczik76/contrapunctus-bench/blob/b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59/LICENSE-ENGINE.md
[engine-page]: https://www.contrapunctus.app/engine
[music21]: https://github.com/cuthbertLab/music21
[openscore-lieder]: https://github.com/OpenScore/Lieder
[pychord]: https://github.com/yuma-m/pychord
[tavern]: https://github.com/jcdevaney/TAVERN
[tonal]: https://github.com/tonaljs/tonal
[when-in-rome]: https://github.com/MarkGotham/When-in-Rome
[when-in-rome-license]: https://creativecommons.org/licenses/by-sa/4.0/
[when-in-rome-snapshot]:
  https://github.com/MarkGotham/When-in-Rome/commit/aa7539f1cf480997a68998405c0783ebf6339c16
