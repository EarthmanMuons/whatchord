# 2026-07-20: History relabeling measured

**Goal.** Run the experiment entry 2026-07-20-13 sketched when the front was
kept open: does relabeling committed events with hindsight make them more
accurate (value path a), and does a relabeled stream improve key detection
(value path b)?

**Setup.** Engine at the lever 0 commit; DCML span-view and When-in-Rome
development splits; clean pool at root+quality; stable preset. Four arms:

- `base`: the live path (rank under the claim BEFORE each event), what the
  display showed.
- `retroKey`: rank under the claim AFTER the event, the half-step of hindsight
  only history has (the warm-up-recovery hypothesis).
- `retroResPolicy`: retroKey plus Rameau's resolution rule (flip a sixth chord
  to its seventh twin when the NEXT event's live root sits a fourth above the
  twin root), restricted to the lever 0 key cells.
- `retroResAll`: the same flip on resolution evidence alone, ignoring the key
  cells.

Value path (b): a second detector consumes the relabeled stream (recorded
candidates reordered so the relabeled identity leads); its claims are scored
against the annotated local keys. Run under all three key-behavior presets,
since detector memory length plausibly governs how much one corrected event can
matter.

```sh
dart run tool/chord-context/relabel_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development \
  --out build/chord-context/relabel/dcml-dev
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/relabel/dcml-dev/report.json \
  --arm retroResAll --baseline-arm base
```

**What happened.**

| arm            | DCML dev | WiR dev |
| -------------- | -------- | ------- |
| base           | 98.46%   | 98.93%  |
| retroKey       | 98.46%   | 99.00%  |
| retroResPolicy | 98.46%   | 99.00%  |
| retroResAll    | 98.91%   | 99.31%  |

1. **Hindsight key is worthless.** retroKey vs base: +0.0001 per piece, CI95
   [-0.0000, +0.0003], 6 wins / 3 losses / 914 ties, p = 0.12. By the time an
   event commits, the updated claim almost never renames it. The
   warm-up-recovery hypothesis is dead.
2. **Policy-scoped resolution is near-tautological with the shipped lever 0
   rule:** zero flips on both rulers. Verified structurally at the CLI ({F A C
   D} under C major already ranks Dm7/F first), so where the key conditions hold
   the engine has already flipped and resolution finds no sixth chord to act on.
   Resolution can only add information where key knowledge does not already
   decide.
3. **Resolution evidence itself is real and precise.** retroResAll vs base on
   DCML: +0.0069 per piece, CI95 [+0.0047, +0.0099], 144 wins / 3 losses / 776
   ties, p = 3.2e-25. All 245 flips are correct: 100% precision, no cell with a
   single error. WiR agrees in direction (+0.0026, 3/0/53, p = 0.18,
   underpowered at 56 pieces). This is the only mechanism measured in this
   initiative that beats the post-lever-0 baseline on identity.
4. **The relabeled stream does nothing for key detection, at any detector
   timescale.** Review asked whether the stable preset's 30-second emission
   memory was hiding the effect, since a shorter memory weights each event more
   heavily. Checking that exposed a flaw in the first run: the path-(b) stream
   had been built from `retroResPolicy`, the arm that makes zero flips, so the
   corrections never reached the detector at all. With the stream corrected to
   carry the all-scope relabeling, and run across all three presets:

   | preset   | base   | retroKey | retroResAll | flips (all correct) | key orig | key relabeled |
   | -------- | ------ | -------- | ----------- | ------------------- | -------- | ------------- |
   | stable   | 98.46% | 98.46%   | 98.91%      | 245/245             | 57.72%   | 57.71%        |
   | balanced | 98.47% | 98.48%   | 98.94%      | 251/251             | 59.63%   | 59.62%        |
   | reactive | 98.44% | 98.40%   | 98.87%      | 256/256             | 58.78%   | 58.81%        |

   Path (b) is flat or slightly negative at every timescale. The reason is
   magnitude, not memory: the relabeling touches ~250 of 182,732 dev events,
   about 0.13% of the stream, and no detector setting extracts signal from a
   change that small. Path (a) is stable across presets (resolution precision
   stays 100% in all three), and hindsight key stays worthless, turning slightly
   negative under reactive where the post-event claim can already have moved
   toward the next chord.

   Side observation for the separate default-preset question: balanced tracks
   annotated local keys best here (59.63% vs stable 57.72%), which reproduces
   the known WhatKey finding that short-memory settings suit local-key targets
   (`research/whatkey/log/2026-07-08-04`). This is local-key agreement, not the
   section-key stability the shipped default was chosen for, so it is
   corroboration of a known tradeoff rather than new grounds to switch; entry
   2026-07-20-03 separately found chord naming indifferent to the preset.

Composition of the 245 flips: 71 applied figures (cells a local-key rule
structurally cannot reach, where both traditions read the seventh), 109
chromatic and modal degrees outside both the policy cells and the m7/6 decision,
and 65 in cells the m7/6 decision deliberately kept as sixth chords for the
lead-sheet audience (34 vi65-as-tonic-I6, 31 borrowed major-key iiø65-as-IVm6).
So about 73% of the gain is product-neutral and 27% would override decided
policy.

**Plain-English reading.** Waiting for the next chord genuinely tells you
something the moment itself cannot: when a sixth-chord reading is followed by
the dominant of its seventh twin, the seventh reading is right, and in this
corpus it was right 245 times out of 245. That is the strongest identity signal
this initiative has found. Two things keep it from being a product yet. It only
works looking backwards, so it can never touch the live display, and the reason
we wanted a more accurate past, that the key detectors would do better on it,
turns out not to be true at all: the detectors score the same either way. What
is left is a passive history list that would be slightly more accurate, which is
real but modest, and about a quarter of the improvement would come from
overruling naming decisions we made deliberately for lead-sheet players.

**Decisions.**

- Value path (b) is closed: relabeling does not help key detection at any
  detector timescale, measured after correcting the stream so the flips actually
  reach the detector. The "corrected past feeds the detectors" argument does not
  survive, and the reason is structural (0.13% of the stream changes), so no
  detector tuning will revive it.
- Value path (a) is confirmed but narrow: relabeling is accurate when it fires
  and statistically decisive, but its only beneficiary is the passive history
  list.
- The product-respecting variant, if the front is ever built, is the resolution
  rule restricted to the non-policy cells (applied, chromatic, modal: 180 of 245
  flips, still 100% precision), leaving the deliberate lead-sheet cells alone.
  Recorded so the option does not have to be re-derived.
- No adoption proposed. The front now has data on both value paths and awaits a
  product judgment on whether a more accurate passive history list justifies a
  retrospective layer.

**Next.**

- Product decision on the front with these numbers in hand.
- Remaining fronts: the Track B residual (no adoption candidate) and the Track D
  comping-suite gate.
