# 2026-07-20: Line-of-fifths side-chooser, first attempt

**Goal.** Recover the enharmonic-side gap measured in entry 2026-07-20-06
(production 98.04% tones vs. 99.41% under the true key) with a causal
line-of-fifths window: a decayed running center of the app's own spellings
chooses which side of an ambiguous key (F#/Gb, C#/Db, B/Cb major; G#/Ab, D#/Eb,
A#/Bb minor) the inferred claim lands on.

**Setup.** New `sideChosen` arm in `spelling_eval.dart`: EWMA center over the
spelled tpcs of every event (alpha configurable, seed 0 = C), candidate sides
enumerated from the 15 key signatures, side picked by distance from the
candidate's diatonic center to the running center. A second variant holds the
chosen side for the duration of a key episode (re-deciding only when the claimed
pc/mode changes).

```sh
dart run tool/chord-context/spelling_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development --alpha 0.15 \
  --out build/chord-context/spelling/dcml-dev-side
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/spelling/dcml-dev-side/report.json \
  --arm sideChosen --baseline-arm inferred
```

**What happened.** At alpha 0.15, pooled tone accuracy 98.60% (from 98.04%;
identity unchanged), recovering about 41% of the gap to the annotated ceiling,
and the one-directional flat-for-sharp confusion bulk disappears. But the result
does not survive scrutiny:

- Paired per-piece: mean delta +0.0017, CI95 [-0.0047, +0.0083], 24 wins / 17
  losses / 881 ties, Wilcoxon p = 0.48. Not significant: the effect lives in ~41
  pieces and the chooser bets whole pieces, winning 24 and losing 17.
- Alpha sensitivity is a spike, not a plateau: 0.05 gives 98.00% and 0.3 gives
  97.91% (both below baseline), only 0.15 gives 98.60%.
- Episode-holding changes nothing at any alpha (identical numbers), so there was
  no mid-episode oscillation to fix; the fragility is entirely in the initial
  decision.

**Plain-English reading.** The window idea works exactly where its theory says
it should: when a piece modulates into an ambiguous key from established
material, the recent spelling trail points at the right side. But for a piece
that starts in F# major, the app has heard nothing yet when the key is claimed;
a pitch-class stream contains no information at all about whether the composer
wrote F# or Gb, so the chooser is flipping a seeded coin, and the alpha spike is
that coin landing luckily at one setting. Whole-piece bets that lose cancel the
wins in the paired test even though the pooled number looks good.

**Decisions.**

- Not adoptable as measured: fails the paired bar, and the alpha sensitivity
  marks the mechanism as fragile. Recorded per the protocol with the diagnosis
  rather than tuned further into the spike.
- The problem decomposes: (a) modulation-reached episodes, where the window is
  the right mechanism and appears to work; (b) cold-start ambiguous keys, which
  are causally undecidable from pitch classes and need a prior (the conventional
  side per key, e.g. sharp-side F# major over Gb) or a user-visible choice. A v2
  should treat these separately and measure them separately; the prior's
  provenance (general practice vs. fitted to this corpus) needs deciding before
  it is tuned, to keep dev-fitting honest.
- The manual-key path is unaffected throughout: a user-selected key carries its
  own side and always wins; everything here concerns the auto-detected key only.

**Next.**

- Split the harness's side metric by episode type (cold-start vs.
  modulation-reached) to size each half of the decomposition.
- Decide the cold-start prior policy, then re-evaluate v2 against the paired
  bar.
