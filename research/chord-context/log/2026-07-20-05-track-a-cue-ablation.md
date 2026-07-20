# 2026-07-20: Track A cue ablation against the post-lever-0 baseline

**Goal.** Phase 2 of the design doc: measure whether the proposed temporal cues
(prior-chord context) improve live naming beyond the shipped lever 0 baseline,
each cue independently, per the protocol's ablation discipline.

**Setup.** Engine at the lever 0 commit (the twin rule shipped, entry
2026-07-20-04). Baseline arm: the production path, a full re-rank under the
closed-loop inferred key (stable preset). Causal context signal: the previous
displayed identity (the baseline top of the prior event with three or more
sounding notes). Four cues as independent arms, each allowed to re-prefer a
near-tie candidate only:

- `appliedTonicization`: after a dominant7 on X, run the m7/6 twin flip against
  the transient tonic a fourth above X (mode-agnostic), aimed at the 259
  applied-figure misses a local-key rule cannot see.
- `postDominant`: after a dominant7 on X, prefer a near-tie candidate rooted a
  fourth above X.
- `dominantExpectation`: after a predominant in the inferred key, prefer a
  near-tie dominant7 on degree V.
- `rootContinuity`: prefer a near-tie candidate keeping the previous root.

Guide-tone continuity was deferred to a later round. Context decay was not
modeled (committed corpus events are contiguous); a live implementation would
add it, but it cannot rescue the results below.

```sh
dart run tool/chord-context/cue_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development \
  --out build/chord-context/cues/dcml-dev
dart run tool/chord-context/cue_eval.dart \
  --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
  --labels build/chord-context/labels/when-in-rome-v1.labels.json \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --split development \
  --out build/chord-context/cues/wir-dev
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/cues/dcml-dev/report.json --arm appliedTonicization
```

**What happened.** Clean pool, root+quality, baseline 98.46% (DCML dev) and
98.93% (WiR dev):

| cue                 | DCML flips (helped/hurt) | WiR flips (helped/hurt) |
| ------------------- | ------------------------ | ----------------------- |
| appliedTonicization | 17 (17/0)                | 0 (0/0)                 |
| postDominant        | 54 (2/52)                | 3 (0/3)                 |
| dominantExpectation | 0 (0/0)                  | 0 (0/0)                 |
| rootContinuity      | 1048 (130/918)           | 13 (0/13)               |

Paired statistics for the one survivor, appliedTonicization on DCML: mean
per-piece delta +0.0003, CI95 [+0.0001, +0.0007], 13 wins / 0 losses / 910 ties,
Wilcoxon p = 1.7e-03. Pooled it is +0.03 points; on When-in-Rome it never fires.

**Plain-English reading.** The initiative's founding hypothesis, that knowing
the previous chord would improve live naming, is now measured, and it mostly
does not survive contact with a good snapshot-plus-key baseline. Expecting a
dominant after a predominant never changes anything the engine does not already
get right. Snapping to the dominant's resolution root breaks far more names than
it fixes, because the near-tie list at that moment contains plausible-but-wrong
readings on that root. Keeping the previous chord's root is actively harmful at
naming time, since consecutive chords usually really are different; that idea
belongs to display smoothing, not naming. The one genuine effect is the narrow
one: after an applied dominant, briefly hearing the next chord in the tonicized
key catches a handful of applied predominants, with perfect precision, but it is
thirteen pieces in nine hundred.

**Decisions.**

- `postDominant`, `dominantExpectation`, and `rootContinuity` are rejected as
  naming cues, recorded as negatives. Root continuity is re-scoped as Track C
  material (frame-level display stability), where its cost-benefit is different
  in kind.
- `appliedTonicization` is confirmed positive (significant, zero-harm) but NOT
  adopted: shipping it requires the full temporal plumbing (live context view
  over the segmenter, a reranker layer, app providers), and +0.03 points does
  not earn that complexity on its own, per the same earn-its-complexity bar
  WhatKey used. It is banked: if a temporal layer is ever built for another
  reason (history relabeling, Track C), this cue rides along, already measured.
- Track A live re-ranking is concluded for now: the addressable clean-pool
  market was one enharmonic family, lever 0 captured the genre-agreed part of it
  snapshot-side, and the remaining live headroom (detector warm-up, deliberate
  lead-sheet disagreements, applied figures) is either unreachable causally or
  too small to justify machinery. The initiative's remaining value lives in the
  retrospective products (history relabeling via the resolution rule), Track B
  spelling, Track C stability, the extra-tones capped-rule market, and the Track
  D gate.

**Next.**

- Update the design doc's Track A section with this outcome.
- Pick the next track by product value: Track B (contextual spelling, with
  When-in-Rome's spelled pitches as ground truth) or the extra-tones capped-rule
  study are the measured candidates on existing rulers.
