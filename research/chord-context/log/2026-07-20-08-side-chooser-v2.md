# 2026-07-20: Side-chooser v2, conventional priors plus window

**Goal.** Rebuild the enharmonic side-chooser around the decomposition from
entry 2026-07-20-07 (cold starts are causally undecidable, modulation- reached
episodes suit the window), with the cold-start prior decided from engraving
practice per the direction settled in review.

**Setup.** The prior, fixed a priori and not fitted: fewer accidentals wins (Db
over C#, B over Cb, G# minor over Ab minor, Bb minor over A# minor); at the
six-accidental ties, the documented conventions F# major and Eb minor. Mechanism
v2: the piece's first key episode takes the prior; each later claimed-key change
re-decides by the running line-of-fifths center; the side holds within an
episode. A v3 variant added spelling inertia (remember each key's side for the
piece, decide only on first arrival). The harness now also splits tone tallies
by episode type.

```sh
dart run tool/chord-context/spelling_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development --alpha 0.15 \
  --out build/chord-context/spelling/dcml-dev-v2-0.15
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/spelling/dcml-dev-v2-0.15/report.json \
  --arm sideChosen --baseline-arm inferred
```

**What happened.**

- v2 turns the v1 alpha spike into a plateau: 98.39% / 98.57% / 98.54% tones at
  alpha 0.05 / 0.15 / 0.3 (baseline 98.04%, ceiling 99.41%).
- Both halves improve independently and alpha-stably: cold-start episodes 98.83%
  -> 99.21% (ceiling 99.58%, n=50,853 tones), modulation-reached 97.72% ->
  98.06-98.33% (ceiling 99.34%, n=119,688).
- Paired per-piece at 0.15: +0.0027 mean delta, CI95 [-0.0031, +0.0088], 24 wins
  / 14 losses / 884 ties, p = 0.21. Better than v1 (p = 0.48) but below the
  adoption bar.
- Loss taxonomy (the 14): a few genuinely irreducible minority-side cold starts
  (a C#-major Dvorak, an Ab-minor Tchaikovsky, where the conventional prior must
  lose); window errors on re-arrivals (a B-major mazurka); and detector
  mode-confusion interactions (an Eb-minor Liszt claimed as its relative major,
  flipping which prior row applies). The wins are dominated by F#-major pieces,
  the conventional side's largest constituency.
- v3 spelling inertia is a negative: 98.42% pooled, 21/14, p = 0.37. Re-deciding
  a key's side on re-arrival corrects more early mistakes than it introduces;
  freezing the first choice locks errors in. Rejected.

**Plain-English reading.** The practice-based prior fixes the coin-flip problem
completely: cold starts are now stable at every setting and recover half their
gap to the ceiling. The window genuinely helps the modulation half too. But the
paired-by-piece test still is not passed, because side choices are whole-piece
bets: a handful of pieces are engraved on the minority side and no causal
mechanism can ever win those, a few more lose to the key detector confusing
relative major and minor, and 24 wins against 14 losses is not yet statistically
decisive. The policy is better in expectation and much better pooled, but our
own bar asks for more certainty than one corpus's 38 affected pieces can give.

**Decisions.**

- v2 is the mechanism of record for Track B (priors plus episode-re-deciding
  window; inertia rejected); it is NOT adopted yet, per the paired bar.
- The evidence path to adoption is a second spelling ruler: When-in-Rome's
  fixture pipeline can carry note spellings (music21 pitches exist at extraction
  time and are currently dropped), giving an independent corpus for the same
  paired test. A mode-confusion guard (do not apply the minor-row prior when the
  claim's relative-major twin is nearly as probable) is the one mechanism
  improvement the loss taxonomy motivates.
- Deferred product observation, recorded for the eventual integration decision:
  for live playing the app's current fixed sides only misfire in the same places
  this measurement shows, and a user in F# major sees the wrong side today; even
  a not-yet-significant improvement may warrant product judgment eventually, but
  not while the measured bar is unmet.

**Next.**

- Extend the When-in-Rome extractor to emit spelling ground truth and run the
  same harness there.
- Prototype the mode-confusion guard; re-run the paired test with both changes.
