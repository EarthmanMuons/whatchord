# 2026-07-07: Event-count decay does not reconcile the corpora

**Goal.** Test the first detector-side reconciliation candidate from entries
13-14: if the emission-memory dial disagrees between corpora because their event
rates differ, decaying per committed event instead of per wall-clock second
should normalize it.

**Setup.** New `decayHalfLifeEvents` option on the three accumulator detectors
(a fixed decay factor per event, replacing wall-clock decay when set), threaded
through the hybrid and HMM; harness flag `--decay-half-life-events`. The
prediction, recorded before running: the corpora differ about 2x in event rate
but 30x in optimal half-life, so rate normalization cannot close the gap.

```sh
for ev in 1 2 4 8 16 32; do
  dart run tool/whatkey_harness.dart \
    --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hmm --decay-half-life-events "$ev" \
    --out "build/whatkey-harness/wir-dev-hmm-ev$ev"
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/asap-nc-v2 \
    --split-file research/whatkey/data/splits/asap-nc-v2.json \
    --detector hmm --decay-half-life-events "$ev" \
    --out "build/whatkey-harness/asap-dev-hmm-ev$ev"
done
```

**Results** (HMM at adopted defaults otherwise; development splits):

| events half-life | WiR exact | WiR modulations | ASAP within-pair | ASAP switches |
| ---------------- | --------- | --------------- | ---------------- | ------------- |
| 1                | 0.57      | 199/399         | 53%              | 1624          |
| 2                | 0.52      | 175/399         | 56%              | 1216          |
| 4                | 0.47      | 135/399         | 58%              | 870           |
| 8                | 0.47      | 120/399         | 61%              | 611           |
| 16               | 0.47      | 112/399         | 65%              | 396           |
| 32               | 0.47      | 114/399         | 68%              | 256           |

**The prediction held.** The two corpora remain monotonic in opposite directions
with no crossover: When in Rome is best at one event of memory (0.57 exact,
within noise of the wall-clock champion), ASAP keeps improving through 32. Event
units behave almost identically to wall-clock units, as a 2x rate difference
dictates. The dial's disagreement is therefore about how much a single committed
event can be trusted, which differs 30x between clean score reductions and
pedaled performance, and no unit conversion fixes that.

**Plain-English reading.** We tested whether the two corpora disagreed merely
because their chords arrive at different speeds, by making the detector forget
per chord instead of per second. Nothing changed: score-derived chords want to
be trusted individually and performance chords want to be averaged, in chord
units just as in seconds. The disagreement is about the chords themselves, not
the clock. What remains is either a detector that senses how messy its input is
and adjusts its own trust (the interesting path), or the plain product
observation that the app's live input always looks like the messy corpus, so the
shipped configuration should favor that domain while the clean corpus stays the
accuracy benchmark.

**Decisions.**

- Event-count decay: negative result, kept as an ablatable option.
- Champion unchanged.
- The reconciliation question is now sharply posed: per-event trust must either
  adapt to measured input noisiness or be set by deployment domain (a product
  decision, since live app input is performed-like, worth an explicit call
  rather than a silent default).

**Next.** Noise-adaptive emissions as the remaining research candidate: an
online noisiness estimate from observable stream statistics (identity churn rate
or event-duration distribution, both label-free) steering the emission memory
between the two corpus optima; validated by whether one adaptive detector
matches both per-corpus optima on both dev splits. Alternatively or
additionally, the deployment-domain default decision. Then mode-resolved ASAP
labels and the ablation pass.
