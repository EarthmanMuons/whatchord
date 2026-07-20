# Chord-Context Evaluation Protocol

Status: FROZEN 2026-07-19 (owner decision, log entry 2026-07-19-03). Changes are
amendments appended to the Amendments section with a dated log entry, never
retuned against data an amendment exposes. The scoring implementation under
`tool/chord-context/` is the normative operational definition of each metric as
its code lands, with each landing recorded in a dated log entry; until a
metric's code exists, this document's prose governs it.

## Task

Score WhatChord's chord naming of observed sonorities against human-annotated
expected identities, event by event, to measure (a) current agreement, (b) the
oracle headroom addressable by contextual re-ranking, and (c) once contextual
layers exist, whether they improve agreement without destabilizing the display.
The unit of observation is an event: a set of sounding notes with onset and
duration, analyzed by the engine exactly as the app's live capture path would
(voicing evidence, default pruning).

## Rulers

Four corpora plus behavioral suites. Results are reported per ruler, never
pooled across rulers; disagreement between rulers is a tracked diagnostic.

1. **when-in-rome-v1** (committed fixtures; split inherited from WhatKey,
   `research/whatkey/data/splits/when-in-rome-v1.json`). Roman-numeral
   annotations; classical.
2. **dcml-distant-listening-v1** (build-only, CC BY-NC-SA 4.0, pinned tag
   `v3.1`; split `data/splits/dcml-distant-listening-v1.json`). DCML annotation
   standard with decomposed identities; classical, 16th century to WWII.
3. **isophonics-nc** (build-only via the ChoCo pins inherited from WhatKey,
   split `research/whatkey/data/splits/isophonics-nc-v1.json`). Human chord
   labels in Harte syntax; pop/rock. The music21-independent ruler.
4. **asap-nc** (build-only, split inherited from WhatKey) where its annotations
   support identity-level ground truth; performed MIDI, so also the
   timing-realism ruler for later stability metrics.
5. **Behavioral suites** (hand-authored pop-jazz charts with explicit expected
   labels; the planned comping suite for the Track D gate). Pass/fail probes,
   excluded from pooled statistics, like WhatKey's pop-jazz suite.

## Ground truth

No naming interpreter is treated as an oracle. Per ruler:

- **Roman-numeral corpora (When-in-Rome).** The annotation is the analyst's
  figure plus local key. music21 realizes the figure as a parser, not an oracle:
  an event is scoreable at full strictness only when the realized pitch set
  passes the sounding-set cross-check, and the realization plus quality mapping
  must pass a stratified hand-audit with a recorded error rate before the first
  frozen result.
- **DCML corpora.** Expected identity comes from the standard's decomposed
  columns (`chord_type`, `root`, `bass_note`, `chord_tones`), converted by
  line-of-fifths arithmetic only. Rows without a `chord_type` and
  `special`-column cases are categorized, not silently dropped.
- **Symbol corpora (Isophonics).** Expected identity is the human Harte label.
  Scoring happens in Harte space: candidates are formatted with the engine's
  `HarteChordFormatter` and compared under the semantic normalization rules from
  the chord-oracle work.
- **Acceptable-answer sets.** Functional labels without a single lead-sheet
  equivalent (augmented sixths, cadential six-four, symmetric-root chords) score
  against an explicit acceptable set or are excluded by category, never guessed.
  The category taxonomy (ok, extra-tones, mismatch, rootless, functional-label,
  symmetric-root, explicit-or-incomplete, unrealized, unlabeled,
  below-min-notes) is part of the frozen protocol; every event is counted in
  exactly one category and only ok/extra-tones/mismatch pools are scored, each
  reported separately.

**Label isolation.** Nothing a ranker, cue, or contextual layer consumes may
derive from annotations. Recorded candidate rankings use a fixed neutral context
(`C:maj`). When an evaluated system needs a key, it uses the key the app's own
detector infers from the event stream (the closed-loop arrangement), never the
annotated key. Annotated keys appear only in scoring and in explicitly-labeled
oracle diagnostics.

## Splits

- Every ruler has a frozen, committed dev/test split before its first
  experiment; new corpora are split from metadata alone before any content
  inspection or fixture generation, with any schema-validation material excluded
  from the ruler (precedent: log entry 2026-07-19-02).
- Cross-corpus overlap rule: pieces present in more than one ruler must not
  straddle dev/test boundaries; overlapping groups are excluded from one ruler
  with a recorded reason (precedent: schubert_winterreise).
- All tuning and ablation happens on development splits. A test split is spent
  only for a declared result set, with an explicit harness flag and a dated log
  entry, at most once per result set.
- Harness discipline: split pins must match fixture manifests; fixture sets are
  versioned and immutable; results from different fixture versions are never
  pooled.

## Metrics

Normative definitions will live in the scoring code; in prose:

- **Agreement**: expected-identity match of the chosen candidate at three
  strictness levels: exact (root, quality, bass), root+quality, root-only.
  Extensions are recorded but not scored in v1.
- **Oracle ceilings**: best-ranked matching candidate bucketed by cost gap to
  the chosen candidate: top1, near-tie (within `nearTieWindow`), prune (within
  `rankingPruneMargin`), generated, absent; reported cumulatively.
- **Key-oracle diagnostic**: agreement when ranked under the annotated key,
  labeled as an oracle, never an evaluated system.
- **Stability** (defined when frame-accurate replay fixtures exist, by
  amendment): renames per committed event and frame-level flip rate during
  transitions.
- **Invariance guard**: with empty context, any contextual layer's output must
  be identical to the snapshot ranking, verified in tests.
- **Performance**: measured with the existing engine benchmark harness
  (`benchmark/`, `tool/benchmark.sh`), which was built for exactly this ("the
  time and memory impact of future engine changes (temporal context, key
  detection)") and gates on normalized time against a committed baseline with
  calibrated noise bands, never raw microseconds. The budget:
  - The snapshot path is untouched: `tool/benchmark.sh --check` passes against
    the committed baseline, analyze-call count and the deterministic operation
    counters are unchanged.
  - The contextual layer's own cost is measured by a benchmark entry that
    replays re-ranking with representative context over the same corpora and the
    same normalized-time methodology. Budget: it adds at most 5% to the snapshot
    baseline's cold normalized time, judged outside the combined uncertainty
    window exactly as `--check` judges regressions.
  - Device gate for app integration (design doc Phase 3): on-device profiling
    shows no dropped frames during note storms with the layer enabled, recorded
    in the integration decision's log entry.
  - Informative, not normative: at near-tie depth (a handful of candidates),
    re-rank cost is expected to be microseconds; if the benchmark shows it
    anywhere near the 5% budget, that is a design smell to investigate, not a
    budget to spend.

## Statistics and reporting

- Per-piece results with per-piece means; pooled event counts reported alongside
  but never alone (long pieces dominate pools).
- Accuracy comparisons: per-piece mean, bootstrap CI95, and Wilcoxon signed-rank
  paired A/B across pieces; report n everywhere; fix and record RNG seeds.
- Latency and count metrics: median and p90.
- Every experiment gets a dated `log/` entry with engine commit, fixture
  versions, and exact commands.

## Adoption bar

A ranking change (lever 0 rule, temporal cue, or promotion) is adopted only
when, on the development rulers:

1. It shows a statistically significant paired win (Wilcoxon) on agreement for
   at least one ruler and no significant regression on any ruler.
2. It does not regress the stability metrics (once defined) or the
   isolated-voicing expectations: changes must be context-conditional, and the
   empty-context invariance guard must hold.
3. The performance budget holds: `tool/benchmark.sh --check` passes, the
   contextual layer's benchmarked cost stays within its 5% normalized-time
   budget, and analyze-call count and operation counters are unchanged.
4. Negative and abandoned attempts are logged.

## Amendments

None.
