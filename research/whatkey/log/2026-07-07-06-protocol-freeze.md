# 2026-07-07: Protocol freeze

**Goal.** Pin the two remaining deferred metric definitions and freeze
PROTOCOL.md before the modulation-responsiveness work, which is squarely the
"serious tuning" the freeze was always meant to precede.

**Setup.** Documentation only, plus one supporting measurement:

```sh
# segment-length distribution informing the modulation-alignment pin
# (inline python over build/whatkey-fixtures/when-in-rome-v1 and the split
# file; counts events per annotated local-key segment on the dev split)
```

Result: of 399 annotated key changes on the development split, 11% lead segments
of 1 event and 27% of 2 events or fewer.

**Decisions.**

- **Modulation alignment pinned as implemented**: every annotated change counts
  (no minimum segment length); matched means the detector claims the new key
  before the next change or piece end; unmatched changes are censored and
  reported separately. The 27% short-segment share is recorded in the protocol
  as reading context for absolute censored rates rather than filtered out: a
  minimum-segment filter would add a tunable threshold to a frozen metric, and
  paired comparisons are unaffected either way.
- **Spurious-switch rule pinned as implemented** (from entry 2026-07-06-07's
  refinement): spurious only when the annotation did not change across the
  window and the switch does not land on the annotated key.
- **Global key pinned to the duration-weighted majority claim**, MIREX-scored
  against the first annotated local key. Empirically it was equal to or better
  than the final-event claim in every run so far (identical on the floor, 0.80
  vs 0.73 for the evidence model, 0.92 vs 0.78 on the hybrid's behavioral
  suite), and it is robust to end-of-piece wobble, which a streaming detector's
  final event is not. Final-event stays in per-piece JSON as a diagnostic.
- **Status flipped to FROZEN**, with the freeze header recording the fixture
  set, corpus and bench commits, split file, and the scoring implementation as
  the normative operational definition. Changes from here are dated amendments.

**Plain-English reading.**

- **Modulation alignment** answers: when the music changes key, did the detector
  ever arrive in the new key while it still mattered? It gets credit if its
  claim lands on the new key any time before the music moves on again; the lag
  is how many chords that took. If it never arrives, the change is counted as a
  plain miss ("censored") instead of pretending it was just very slow. We count
  every annotated change, even one-chord key areas no live detector could
  realistically catch, because filtering those out would mean choosing a cutoff,
  and a frozen rule should not contain a knob. The price is that the raw
  "matched" percentage looks worse than detectors deserve (about a quarter of
  the changes are those blink-and-miss-it areas), which is fine as long as every
  detector is graded on the same changes.
- **Global key** answers: if the detector had to give one key for the whole
  piece, what would it be? We pinned that to the key it spent the most
  (duration-weighted) time claiming, rather than whatever it happened to say on
  the last chord, for the same reason you would judge a navigator by the route
  they held rather than their final wobble into the parking lot. In every run so
  far the majority answer was as good or better, and it cannot be ruined by one
  noisy ending.

**Disclosure.** One tuning decision predates the freeze: the hybrid's functional
blend was selected on the development split (entry 2026-07-07-04) while the
protocol was still draft. It was development-split-only, fully logged with a
sweep table and paired test, and the test split has never been evaluated, so the
freeze's core guarantee (an untouched held-out split) holds. Recorded here
rather than papered over.

**Next.** Modulation responsiveness, now under the frozen protocol: decay
half-life sweep on the hybrid, then claim-level hysteresis if the sweep alone
cannot buy responsiveness without stability cost. All adoption decisions via
paired comparisons on the development split.
