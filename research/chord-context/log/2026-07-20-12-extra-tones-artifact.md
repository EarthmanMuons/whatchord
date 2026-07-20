# 2026-07-20: The extra-tones market is a span-view artifact

**Goal.** Open the extra-tones capped-rule front (the largest remaining accuracy
pool: 40,834 dev events at 39.6% top-1 with a 71.8% prune ceiling, entry
2026-07-19-04) by characterizing the pool and settling the debt from entry -04:
is this real live headroom, or an artifact of aggregating notes over each
label's span? The extractor's onset-instant view existed for exactly this
measurement and had not been run.

**Setup.** Structure analysis over the span-view labels and recorded candidates;
then instant-view fixtures generated (`--view instant`) and the headroom harness
run on them.

```sh
python tool/chord-context/dcml_extract.py \
  --data-root /private/tmp/dlc-data \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --view instant \
  --out build/chord-context/fixtures
dart run tool/chord-context/headroom.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-instant \
  --labels build/chord-context/labels/dcml-distant-listening-v1-instant.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development \
  --out build/chord-context/headroom/dcml-dev-instant
```

**What happened.**

Span-view pool structure first (dev, n=40,834): half the pool is chord plus
exactly one extra tone (20,264), a third is two extras. Of the miss mass, 36% of
events see the engine choose a different root, and in 61% of those the chosen
root IS one of the extra tones: a melody or passing note promoted to root of a
common seventh stack (minor7 6,039, major7 3,000, dominant7 2,296). Another 20%
keep the root but change quality to absorb extras. The 40% scored correct are
extension-absorbing readings that match at root+quality.

Then the deciding measurement. Under the instant view the extra-tones category
collapses from 22.8% of dev events to 1.1% (53,889 to 2,557 full-set), with the
mass moving to below-min-notes (35.6%, arpeggiated instants of one or two notes)
and subset mismatches (18.9%). At real instants, the annotated chord's tones and
simultaneous extras rarely coexist; the big pool was manufactured by merging
each label's whole span, melody line included. The residual instant-view
extra-tones pool is small and unpromising (n=2,096, top-1 35.0%, near-tie adds
3.9 points).

Robustness bonus: the instant-view clean pool (n=48,448, top-1 98.0%, near-tie
ceiling 100.0%) reproduces the m7/6 finding exactly: all 945 clean-pool misses
are the same family (617 half-diminished, 328 minor7). Every adopted result is
now view-invariant.

**Plain-English reading.** The pool that looked like the next big opportunity
was mostly an accounting choice. When we credited a chord label with every note
sounded anywhere during its span, whole melodic lines got stacked onto each
chord, and the engine's readings of those stacks disagreed with the analyst's
simple labels. Sampling what actually sounds at an instant makes nearly all of
that disappear. The genuine live phenomenon this pool was standing in for,
melody tones accumulating over a held chord under the sustain pedal, is real but
is not what this corpus measures in either view; judging it needs replay
fixtures with real timing and pedal semantics, which is the initiative's
deferred stability work.

**Decisions.**

- The extra-tones capped-rule front is closed as a corpus artifact: no rule work
  is justified by this evidence. The melody-note-as-root characterization is
  retained as the failure signature to look for if the phenomenon ever
  re-emerges in a faithful fixture.
- The only recorded path that could revive the front: frame-accurate replay
  fixtures with pedal semantics (the protocol's deferred stability-metrics
  work), which would measure the real accumulation scenario instead of a
  windowing proxy.
- Span view remains the identity ruler of record (entry -04's decision stands);
  the instant view is retained as the artifact-control and has now paid for
  itself twice (this closure and the cross-view replication of the m7/6 result).

**Next.**

- Remaining open fronts, all previously recorded: the contextual side-following
  spelling residual, the chromatic-line rules, the history-relabel product, the
  When-in-Rome audit preconditions, and the Track D comping-suite gate.
