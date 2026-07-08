# WhatKey Glossary

Plain-English definitions of the measurement terms used across the log entries
and reports. PROTOCOL.md is the normative source; this file explains, it does
not define. Log entries should link here rather than re-explain terms, and keep
their own plain-English sections for interpreting specific results.

---

**Abstention.** The detector saying nothing rather than naming a key. A
first-class outcome, never counted as an error: on genuinely ambiguous music,
staying quiet is the correct answer.

**Accuracy on claimed events.** Of the events where the detector was willing to
name a key, the fraction it got right. Always reported together with coverage;
either number alone is meaningless, because a detector can trade one for the
other.

**Bootstrap CI95.** A 95% confidence interval computed by
[resampling](https://en.wikipedia.org/wiki/Bootstrapping_%28statistics%29):
re-draw the per-piece results (with replacement) thousands of times, compute the
average difference each time, and report the range the middle 95% of those
averages fall in. Plainly: the plausible range for the true average improvement,
given only these pieces. If the whole interval sits above zero, even the
pessimistic reading is a win. Ours uses a fixed seed so the interval reproduces
exactly.

**Censored modulation.** An annotated key change the detector never caught up
with: it did not reach the new key before the next change (or the piece)
arrived. Counted separately rather than averaged into lag, because "never got
there" is not a large lag, it is a miss. (The name borrows from
[censoring in statistics](https://en.wikipedia.org/wiki/Censoring_%28statistics%29):
a value known only to exceed what was observed.)

**Claim.** The detector's top-ranked key at one event, when it is confident
enough to speak. Every metric scores the claim; the rest of the ranked list is
diagnostic.

**Coverage.** The fraction of events where the detector made a claim rather than
abstaining. The partner number to accuracy on claimed events.

**Coverage-accuracy curve.** What happens to both numbers as the confidence
threshold sweeps from lax to strict: coverage falls, accuracy should rise. The
curve describes a detector's calibration without depending on any one threshold
choice, which is why the protocol reports it rather than a single operating
point.

**Emission.** In the HMM, the per-event observation model: how likely the chords
we just heard would be under each candidate key. Ours converts the hybrid
detector's per-key scores (both blend terms at zero in the shipped
configuration, so pure profile correlation) into a probability distribution with
a [softmax](https://en.wikipedia.org/wiki/Softmax_function); its temperature
sets how decisive one event is allowed to be. Emissions must be memoryless (one
event's worth of evidence), or history gets counted twice.

**Emission memory (decay half-life).** How much recent context the emission
scorer integrates when judging "the chords we just heard": pitch-class evidence
decays exponentially with this half-life. Short memory makes each emission a
snapshot of the immediate harmony, quick to see excursions; long memory makes it
a summary of the current section. Log entries 2026-07-07-16/17 found this dial
selects which timescale of key structure the detector reports (see Section scale
vs. tonicization scale).

**Event.** One committed chord from the history capture: a held identity with
its ranked candidates, voicing, timing, and duration. The unit everything is
scored over, each counting once regardless of how long it was held.

**Exact vs. MIREX-weighted.** Exact scores a claim 1 only for the annotated key.
[MIREX-weighted](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection) gives
partial credit for musically close misses: the key a fifth away 0.5, the
relative major/minor 0.3, the parallel major/minor 0.2. A gap between the two
numbers means the errors are mostly neighboring keys, not random ones.

**Filtered posterior (forward algorithm).** The
[forward algorithm](https://en.wikipedia.org/wiki/Forward_algorithm) run
causally: after each event, the probability of each key given everything heard
so far, and nothing from the future (unlike Viterbi, which needs the whole
piece). This is what the HMM claims from, and why its confidence is a true
probability.

**Fixture.** A stored, labeled event stream the harness replays: what the
detector would have seen live, plus the ground-truth keys only the scorer may
read. Versioned like a dataset because fixtures embed engine output.

**Global vs. local key.** Global: one key per piece, the whole-piece answer the
older literature reports. Local: the key at each moment, which is what the app
displays and what modulation tracking is about.

**Hidden Markov model (HMM).** A
[model](https://en.wikipedia.org/wiki/Hidden_Markov_model) that treats the key
as a hidden state we never observe directly: each chord event gives noisy
evidence (the emission), and the key itself changes only occasionally (the
transitions). Inference balances the two, so an established key persists through
momentary contradictions but yields to sustained ones.

**Margin floor.** The confidence bar for speaking at all. At each event the
detector ranks all 24 keys; if the leader is not ahead of the runner-up by at
least the floor, it abstains rather than naming a narrow leader. Higher floor:
fewer, more accurate claims. It gates every claim, not just key changes.

**Matched-coverage comparison.** Grading two detectors on the identical subset
of events (the ones a reference run claimed on), so neither gets an advantage
from skipping harder questions. This is how "different coverage" is ruled out as
the explanation for an accuracy difference.

**Mode tilt.** A per-event nudge applied within one parallel pair of keys (same
tonic, major vs. minor): when the chord just played is rooted on that tonic and
has a clearly major or minor home quality, emission mass shifts toward the
matching mode. The pair's total is preserved, so the tilt can pick between a
key's twins but can never favor a different tonic, which is why it avoids the
problems that removed its parent rules (log entry 2026-07-07-23).

**Modulation lag.** After an annotated
[key change](https://en.wikipedia.org/wiki/Modulation_%28music%29), how many
events pass before the detector's claim arrives in the new key. Reported as
median and p90 (the [90th percentile](https://en.wikipedia.org/wiki/Percentile),
the value only the worst tenth of cases exceed), with censored modulations
counted separately.

**Paired statistics.** Comparing two detectors
[piece by piece](https://en.wikipedia.org/wiki/Paired_difference_test) (who won
on _this_ piece?) instead of comparing their overall averages, then testing
whether one wins consistently (Wilcoxon signed-rank). An average can be won on a
few long pieces while losing on most; a paired win cannot. The protocol requires
this standard for decisions like changing the default profile pair.

**Profile pair.** A published pair of 12-number templates (one major, one minor)
describing how strongly each scale degree characterizes a key. The
profile-correlation detector matches the recent pitch histogram against all 24
rotations of the pair by
[Pearson correlation](https://en.wikipedia.org/wiki/Pearson_correlation_coefficient);
which pair is used matters more than the matching formula. The published sources
for each pair are cited in the
[design doc's references](temporal-context-key-detection.md#references), and
their values are verified against reference implementations (log entry
2026-07-06-08).

**Posterior calibration / reliability.** Whether a probability number should be
taken literally. If the detector says "C major, 80%" on 100 events, a calibrated
detector should be right on about 80 of them. The harness checks this by putting
events into confidence bands (0-10%, 10-20%, ..., 90-100%) and comparing each
band's average confidence with its actual accuracy.

The summary numbers are compact ways to read the same idea:
[expected calibration error](https://en.wikipedia.org/wiki/Expected_calibration_error)
(ECE) is the average confidence-vs-accuracy gap across the bands; lower is
better.
[Negative log likelihood](<https://en.wikipedia.org/wiki/Loss_functions_for_classification#Cross_entropy_loss_(log_loss)>)
penalizes putting too little probability on the true key; lower is better. The
[Brier score](https://en.wikipedia.org/wiki/Brier_score) is the squared error of
the whole probability distribution; lower is better. This is different from the
coverage-accuracy curve: abstentions can be useful even when the raw posterior
probabilities are overconfident.

**Section scale vs. tonicization scale.** Two granularities of "the key," both
legitimate. Section scale is the home key of a stretch of music, what a song's
key or a movement's key names; tonicization scale additionally tracks brief
excursions, the few measures an analyst marks as V-of or the relative minor.
Corpus labels come at different scales (Isophonics song keys and ASAP key
signatures are section-scale; When in Rome analyst local keys are
tonicization-scale), so accuracy numbers are only comparable against the same
ruler. WhatChord ships the section scale (log entry 2026-07-07-17).

**Self-transition.** The HMM's probability that the key this event is the same
as the key last event. Higher values mean a steadier detector that needs more
sustained evidence to change its mind: the principled version of the persistence
that decay tuning and claim hysteresis approximated. The remaining probability
spreads over other keys, nearer ones on the circle of fifths getting more.

**Spurious switch.** A key switch the annotation gives no reason for: the
labeled key did not change across the window and the detector's new claim does
not land on it. The stability metric counts these per piece; a lagged catch-up
switch onto the annotated key is not spurious.

**Time to first claim.** How many events pass before the detector commits to any
key at all. Trades off against stability and lag, which is why all three are
reported and never blended.

**Warmup.** The `minEvents` rule: the detector abstains until it has seen a
minimum number of events (currently 3), regardless of confidence, so it never
guesses a key from one chord.

**Wilcoxon signed-rank test.** The
[statistical test](https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test)
behind our paired comparisons. It looks at the piece-by-piece differences
between two detectors, ranks them by size, and asks: if the two were actually
equally good, how often would luck alone produce differences this consistently
one-sided? The answer is the p-value; a small one (conventionally below 0.05)
means the win is unlikely to be corpus noise. It makes no assumption about the
differences following any particular distribution, which is why it is the
standard choice for this kind of comparison. Implemented in
`tool/whatkey_compare.py`.
