# 2026-07-07: Weighted evidence model v1 does not beat the floor

**Goal.** Implement the weighted evidence detector (design plan section 2d), the
first model using chord identities and recognizer confidence, and score it
against the anchored profile-correlation floor.

**Setup.**

- New `WeightedEvidenceKeyDetector` in `lib/features/key/`: running score per
  key with the design's rules (+2 diatonic root, +3 all tones diatonic, -1 per
  chromatic tone, +4 dominant-seventh-family on the fifth degree, +3
  leading-tone diminished), plus one addition made during behavioral testing: +2
  for a plain major triad on the fifth degree (dominant function without the
  tritone, design section 2e's distinction). Minor keys score against natural
  union harmonic minor, mirroring `ScaleDegreeClassifier`'s sources, so E7's G#
  is evidence for A minor, not a penalty. Time decay (30 s half-life), duration
  weighting, and recognizer-confidence weighting (best-to-second cost gap
  against the near-tie window) as toggles. Confidence is points per weighted
  event; margin floor default 0.5.
- Harness: `--detector profile|evidence`, `--confidence-weighting on|off`.
- Fixtures and split as in entries 07-09. Commands recorded in
  `build/whatkey-harness/*evidence*/report.json`.

**Results, behavioral suite.** The functional rules behave as designed where
functions exist: the modulating ii-V-I chain is finally tracked (1 of 2
modulations matched, lag 2, exact 0.40 vs the profile floor's 0.17 with both
censored), minor-with-E7 and ii-V-I are perfect, and the ambiguous fixtures
still get abstention or acceptable keys (7/8, 7/7). Two instructive failures:

- **12-bar blues never claims, and that is structurally correct for this
  model**: a V7 is identical in a key's major and harmonic-minor forms, so C7
  votes F major and F minor equally, and an all-dominant-seventh stream never
  breaks the mode tie. Worse, functionally C7 reads as V-of-F, so Roman-numeral
  rules mis-key blues toward the subdominant; the histogram won blues
  statistically. A blues/mode heuristic or the 2e pattern layer owns this.
- **Secondary dominants flip it briefly** (one wrong claim on the V/V): the
  evidence model reacts faster to functional signals than the histogram, so
  single tonicizations can flap it. This is the hysteresis need the design
  predicted (2c/2d).

**Results, development split** (defaults; sweep at floors 0-2):

| detector                 | coverage | exact | MIREX | modulations |
| ------------------------ | -------- | ----- | ----- | ----------- |
| profile floor (entry 07) | 0.67     | 0.45  | 0.59  | 116/399     |
| evidence, floor 0.5      | 0.40     | 0.44  | 0.58  | 59/399      |
| evidence, floor 0.25     | 0.59     | 0.42  | 0.56  |             |
| evidence, floor 0.10     | 0.76     | 0.41  | 0.55  |             |

The evidence curve sits below the profile curve at every coverage, and
modulation matching is worse (59 vs 116 of 399), though with median lag 1 when
it does catch one. Matched to the profile's claimed events, evidence scores 0.47
exact vs the profile's 0.45, but abstains on much of that subset. Confidence
weighting on vs off is a wash (0.44/0.45 exact, 59/62 modulations) even though
10.8% of corpus events carry near-tie identities; down-weighting them just does
not change outcomes on clean score-derived input. Its value, if any, should
appear on performed input (ASAP) where identities are actually noisy.

**Reading.** The design's "everything must beat both 2a and 2d" now has content:
2d v1, at the design's untuned point values, loses to 2a on the classical corpus
while winning the functional probes 2a fails. The natural explanations: romantic
harmony is dense with non-functional sonorities where per-chord function rules
mislead but histograms are robust, and purely diatonic or dominant-heavy
stretches leave the rules tied between relative/parallel keys where profile
shapes still discriminate. The two models fail in complementary places, which
argues for a hybrid (histogram base term plus functional bonuses) or the 2e
progression layer, rather than point-value tuning alone.

**Decisions.**

- Kept the dominant-triad bonus (+2): it resolved the pop-loop relative-key tie
  in a principled way and did not regress the suite.
- No point-value tuning yet: v1 is the design's stated values, recorded
  untouched as the honest starting point. Tuning, hybridization, and 2e are now
  clearly separable follow-ups.
- Blues stays a failing probe for function-only models by design; do not paper
  over it with a special case.

**Next.** Three candidate directions, in rough order of expected value per
effort: a hybrid detector (profile correlation as the base score, functional
bonuses as adjustments), claim hysteresis to absorb tonicizations, and the 2e
progression detectors. Paired per-piece statistics for any comparison that picks
a winner.
