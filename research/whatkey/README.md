# WhatKey

WhatKey is a streaming key-estimation system for [WhatChord](../../README.md).
It listens to the chords a musician plays on a MIDI keyboard, updates its belief
after each chord, and reports the current key when the evidence supports a
claim. Displayed probabilities are calibrated separately from the detector's
internal ranking.

Read the current draft: [paper/main.pdf](paper/main.pdf).

## Research question

This is not ordinary whole-piece key finding. Much of the key-detection
literature asks for a single key from a complete score or recording. WhatKey's
setting differs in three ways that compound:

1. **Causal and streaming.** The detector only ever sees the past, and it must
   update as each chord arrives from live MIDI playing with finger rolls, pedal
   blur, and wrong notes.
2. **Uncertain observations.** The input is not ground-truth notes but the
   output of WhatChord's chord recognizer: ranked candidates with explanation
   costs.
3. **Abstention as part of the task.** A modal vamp has no single right answer;
   the detector must sometimes say "not enough evidence" rather than force a key
   label onto ambiguous music, so stability and knowing when not to answer are
   measured alongside accuracy.

That combination is an underexplored setting, so the work is organized as a
research project rather than only an app feature: a frozen evaluation protocol,
versioned fixtures, external baselines, dated experiment logs, and a one-shot
held-out evaluation.

## Main result

The final detector is a compact hidden Markov model run strictly forward in
time. It keeps a probability distribution over the 24 major and minor keys,
updates it from recent chord evidence, and abstains when the leading candidates
are too close. The detector uses raw posterior probabilities for ranking and
abstention; numbers shown to users pass through a display-only calibration step.

On held-out pop-song fixtures, it reached parity with standard offline music21
key finders that read the whole song before answering. Its point estimates were
higher in this evaluation, but the paired statistics support the more
conservative claim: parity under stricter operating constraints.

| system                         | coverage | exact | MIREX |
| ------------------------------ | -------- | ----- | ----- |
| WhatKey (causal, abstaining)   | 0.88     | 0.732 | 0.782 |
| music21 Temperley-Kostka-Payne | 1.00     | 0.637 | 0.740 |
| music21 Krumhansl-Schmuckler   | 1.00     | 0.624 | 0.726 |
| music21 Aarden-Essen           | 1.00     | 0.558 | 0.690 |

Reading the table: **coverage** is how often the system names a key, **exact**
is how often that key is exactly right, and **MIREX** is the field's weighted
score for musically close misses. The offline systems always answer, so their
coverage is 1.00. WhatKey declined to answer on the most ambiguous 12% of
moments and was exactly right 73% of the time when it did. The evaluation also
tracks wrong key switches, real key-change detection and lag, and time to first
claim.

## What the paper argues

**Memory selects an annotation target.** A short memory fits local-key labels; a
longer memory fits section-key labels. Both are musically defensible, and
different annotation traditions reward different answers, even on the same
performances. The selected default favors section-key stability because the
target interface is a glanceable key indicator, but the broader result is about
evaluation: key detectors can only be compared fairly when they are graded
against the same kind of answer key.

**Mode evidence can be isolated.** The most visible residual mistake is showing
the wrong mode, such as C minor instead of C major. The adopted rule uses the
quality of a home chord to choose within a same-tonic major/minor pair, while
preserving evidence for the tonic itself. That roughly halves parallel-mode
confusion without pulling the detector toward unrelated keys.

**Negative results are part of the record.** Additional chord-function rules
help only when the goal is local-key tracking; weighting evidence by the chord
recognizer's own confidence did not help in the tested settings; and
adaptive-memory models react faster but make more wrong switches. Each negative
result has a reproducible experiment behind it in the log.

**Confidence needs its own calibration.** The detector's raw posteriors are
overconfident, so WhatKey applies post-hoc temperature scaling only to displayed
probabilities. This makes the user-facing confidence number more honest without
changing the detector's ranked keys, abstention decisions, or paper results.

## Repository map

- [paper/](paper/): the paper source and tracked PDF
  (`mise research:whatkey-paper` rebuilds it).
- [log/](log/): dated experiment entries with exact commands, results, and
  plain-English readings.
- [GLOSSARY.md](GLOSSARY.md): plain-English definitions of the measurement
  terms.
- [PROTOCOL.md](PROTOCOL.md): how results are evaluated; frozen, with dated
  amendments.
- [temporal-context-key-detection.md](temporal-context-key-detection.md): the
  design-time plan and algorithm reference.
- [data/](data/) and [results/](results/): fixture, split, provenance, and
  committed one-shot test artifacts.
- Code: detectors in `lib/features/key/` (the code the harness benchmarks is the
  code the app runs), chord-event capture in `lib/features/history/`, and the
  harness, extractors, and paired statistics in `tool/`.

## Reproducing and data access

[REPRODUCING.md](REPRODUCING.md) has exact steps for rebuilding every fixture
set from pinned upstream checkouts, including the license-gated corpora that are
never committed, and for verifying the frozen development/test splits. Common
invocations are wrapped as `mise research:whatkey-*` tasks.

## Citation

If you build on this work, please cite the paper draft:

```bibtex
@misc{bullschaefer2026whatkey,
  author = {Bull Schaefer, Aaron},
  title  = {Streaming Key Estimation with Abstention from Live
            Chord-Recognition Output},
  year   = {2026},
  url    = {https://github.com/EarthmanMuons/whatchord/tree/main/research/whatkey},
  note   = {Draft. Protocol, experiment log, and evaluation artifacts in the
            linked repository directory.}
}
```

## License and data

The code is free, the committed data carries its sources' terms, and the gated
corpora are never committed at all:

- **Code** (detectors, harness, extractors, paper source): the repository's
  top-level [0BSD license](../../LICENSE).
- **Committed fixtures** (`data/fixtures/when-in-rome-v1/`): data artifacts
  under CC BY-SA 4.0 provenance from license-verified When in Rome sub-corpora;
  see [data/provenance/when-in-rome-v1.md](data/provenance/when-in-rome-v1.md).
- **Gated corpora** (ASAP, CC BY-NC-SA 4.0; Isophonics annotations,
  research-distributed): never committed; their extractors refuse to write
  inside `research/`, and they are rebuilt locally per REPRODUCING.md.
- **Split files and results artifacts**: identifiers, aggregate metrics, and
  detector outputs only, never corpus content; each redistribution decision is
  recorded in [data/NOTICE.md](data/NOTICE.md) and the dated log entries it
  points to.
