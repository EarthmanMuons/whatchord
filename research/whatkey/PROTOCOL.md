# WhatKey Evaluation Protocol

**Status: DRAFT.** This protocol must be frozen before the first tuning
experiment runs. After the freeze, changes are amendments: append a dated entry
to the Amendments section and a log entry explaining why, and never retune
against data the amendment exposes. Tuning before freezing invalidates the
held-out split, which is the one mistake this document exists to prevent.

## Task definition

Streaming local-key estimation with abstention. The input is a causal stream of
`ChordEvent`s (see `lib/features/history/`): ranked chord candidates with
explanation costs, voicing, analysis-time tonality, timestamps, and hold
durations. After each event, the detector outputs either a ranked list of
`(Tonality, confidence)` hypotheses or an explicit abstention. The detector
never sees the future and is never re-run on edited history.

Two evaluation views over the same outputs:

- **Global key:** the detector's final (or converged) claim per piece, for
  comparability with the published literature.
- **Local key:** the claim at each event, scored against time-aligned
  annotations, which is what the app actually displays.

## Metrics

Exact operational definitions (tie handling, alignment windows, smoothing) are
pinned at freeze time; the metric set is:

- **[MIREX-weighted](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection)
  key score** for near misses: exact 1.0, perfect fifth 0.5, relative
  major/minor 0.3, parallel major/minor 0.2. The weighting is only a scoring
  function, applied to our own corpora; scores are not comparable to MIREX
  leaderboard results, which were computed from audio on MIREX's own evaluation
  sets.
- **Time-aligned local-key accuracy**: fraction of evaluated events where the
  claim matches the annotated local key (also MIREX-weighted as a secondary
  view).
- **Modulation lag**: events between an annotated key change and the detector
  switching to the new key.
- **Stability**: spurious key switches per piece (switches not aligned to any
  annotated change).
- **Time-to-first-claim**: events before the detector first commits to any key.
- **Abstain calibration**: accuracy conditioned on claiming vs. abstaining; an
  abstention on genuinely ambiguous passages counts for the detector, not
  against it.

Lag, stability, and time-to-first-claim trade off against each other; report all
three, never a single blended score.

## Corpora and splits

- **When in Rome** (RomanText annotations): time-aligned local keys and
  modulation boundaries. Corpus commit pin recorded at freeze.
- **Hand-authored pop/jazz set**: I-V-vi-IV loops, ii-V-I chains, 12-bar blues,
  modal vamps, deliberately ambiguous progressions. Authored with labels before
  any detector sees them. This set is a directed behavioral suite, not a
  statistical sample: each fixture is a pass/fail probe of a known failure mode
  (abstention on vamps, stability through tonicizations, the harmonic-minor
  dominant). Report it per fixture and exclude it from pooled statistics and
  paired comparisons; statistical claims come from corpus-derived sets only.
- **ASAP** (performed piano MIDI, aligned scores, key-signature annotations):
  the bridge from quantized score events to realistic live input, replayed
  through the actual Phase 1 capture path.

**Split rules:** held-out test split by piece, and by composer where the corpus
allows, frozen and recorded in `data/` before the first experiment. All tuning,
ablation, and model selection happens on the development split only. The test
split is evaluated once per reported result set, not per iteration.

## Fixtures

Fixtures embed the engine's candidate rankings, and the engine gets retuned, so
fixtures are versioned like a dataset. Every fixture set records: engine commit,
generation script and parameters, corpus source and commit pins, and per-fixture
license/provenance. See `data/README.md`. Results are only comparable within a
fixture version.

Fixture candidates are ranked under a fixed neutral analysis context (default
`C:maj`), recorded in the manifest, never under the annotated key: several
ranking tie-breakers are tonality-gated, so ranking under ground truth would
leak the answer into the observations the detectors consume.

## Baselines

Our algorithms are only meaningful against external reference points on the same
fixtures:

- music21's Krumhansl-Schmuckler variants (Krumhansl-Kessler, Temperley,
  Albrecht-Shanahan profiles).
- justkeydding (Napoles Lopez et al. 2019), HMM with profile emissions.
- Internally, profile correlation (plan section 2a) is the floor every later
  model must beat to earn its complexity.

External baselines are offline and non-abstaining; they anchor the accuracy
metrics, while the streaming metrics are compared between our own variants.

## Ablations

Each ingredient toggles independently: profile pair, duration weighting, decay
weighting, recognizer-confidence weighting (cost gaps), and each functional
pattern detector. Recognizer-confidence weighting is the most novel claim and
gets the cleanest ablation: identical pipelines with it on and off.

## Reporting

- Per-piece results with paired comparisons across pieces; pooled event accuracy
  alone is not acceptable (a few long pieces dominate pools).
- Uncertainty on every headline number (CI95, matching the
  `benchmark/baseline.json` habit).
- Every experiment gets a dated entry in `log/` with the fixture version and
  engine commit it ran against.

## References

The MIREX weighting comes from the
[MIREX Audio Key Detection task](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection),
whose evaluation table is stable across task years. Every other system, profile
set, and corpus named here (Krumhansl-Schmuckler variants and their profile
pairs, justkeydding, When in Rome, RomanText, ASAP) is cited with links in the
[design doc's references](temporal-context-key-detection.md#references).

## Amendments

None. (Protocol not yet frozen.)
