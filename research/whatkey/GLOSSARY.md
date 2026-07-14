# WhatKey Glossary

Plain-English definitions of the measurement terms used across the log entries
and reports. PROTOCOL.md is the normative source; this file explains, it does
not define. Log entries should link here rather than re-explain terms, and keep
their own plain-English sections for interpreting specific results.

Each term is a heading so it can be linked directly from logs, reports, and pull
requests.

---

## Ablation

An experiment that removes, disables, or swaps one ingredient while keeping the
rest of the system fixed. The point is to ask whether that ingredient is
actually doing useful work, not just whether a final system performs well. In
WhatKey, examples include turning duration weighting, functional blends, or
recognizer-confidence weighting on and off under the same detector.

## Abstention

The detector saying nothing rather than naming a key. A first-class outcome,
never counted as an error: on genuinely ambiguous music, staying quiet is the
correct answer.

## Accuracy on claimed events

Of the events where the detector was willing to name a key, the fraction it got
right. Always reported together with coverage; either number alone is
meaningless, because a detector can trade one for the other.

## Bayesian online changepoint detection (BOCPD)

An adaptive-memory alternative to the HMM's fixed decay: instead of letting
evidence fade on a fixed half-life, it maintains a belief about where the
current musical section started and pools evidence back to that point. Built and
measured for the 24-key space; it catches more key changes but makes more false
switches on the section-key task, so it was not adopted (log entry
2026-07-07-26).

## Bootstrap CI95

A 95% confidence interval computed by
[resampling](https://en.wikipedia.org/wiki/Bootstrapping_%28statistics%29):
re-draw the per-piece results (with replacement) thousands of times, compute the
average difference each time, and report the range the middle 95% of those
averages fall in. Plainly: the plausible range for the true average improvement,
given only these pieces. If the whole interval sits above zero, even the
pessimistic reading is a win. Ours uses a fixed seed so the interval reproduces
exactly.

## Causal / streaming detector

A detector that answers as the music arrives, using only the present and past.
It cannot inspect the rest of the piece, revise earlier events, or wait until
the ending explains the beginning. This is stricter than an offline analyzer,
which may read the whole score or song before producing one answer. WhatKey
fixtures are stored on disk, but the harness still replays them causally: the
detector receives events in order and never sees future labels or future chords.

## Censored modulation

An annotated key change the detector never caught up with: it did not reach the
new key before the next change (or the piece) arrived. Counted separately rather
than averaged into lag, because "never got there" is not a large lag, it is a
miss. (The name borrows from
[censoring in statistics](https://en.wikipedia.org/wiki/Censoring_%28statistics%29):
a value known only to exceed what was observed.)

## Claim

The detector's top-ranked key at one event, when it is confident enough to
speak. Every metric scores the claim; the rest of the ranked list is diagnostic.

## Confidence weighting

Weighting each chord event by how sure the chord recognizer was about its
reading, so confidently identified chords would count more than ambiguous ones.
Tested repeatedly across detectors and timescales and never helped; the logs
record it as a no-op, permanently off.

## Coverage

The fraction of events where the detector made a claim rather than abstaining.
The partner number to accuracy on claimed events.

## Coverage-accuracy curve

What happens to both numbers as the confidence threshold sweeps from lax to
strict: coverage falls, accuracy should rise. The curve describes the whole menu
of trades a detector offers without depending on any one threshold choice, which
is why the protocol reports it rather than a single operating point.

## Development split and held-out split

The development split is the part of a corpus used while making choices:
selecting constants, comparing variants, diagnosing failures, and deciding what
to freeze. The held-out split (or test split) is set aside until those choices
are fixed, then evaluated once to check whether the result generalizes. If a
held-out result changes the model, constants, or reporting choices, it has been
used for tuning and is no longer a clean held-out test.

## Duration weighting

Weighting each chord event by how long it was held, so a whole-note chord
influences the key estimate more than a passing eighth. The one ingredient that
measured as helpful on every ruler tested; on by default.

## Emission

In the HMM, the per-event observation model: how likely the chords we just heard
would be under each candidate key. Ours scores each key by how well the recent
pitch classes match its profile, then converts those scores into a probability
distribution with a [softmax](https://en.wikipedia.org/wiki/Softmax_function);
its temperature sets how decisive one event is allowed to be. In the textbook
HMM an emission is memoryless (one event's worth of evidence), because the
transition model already carries the history and would otherwise count it twice;
ours deliberately relaxes that with the emission-memory window below, treating
the window as the detector's timescale selector rather than as a pure textbook
HMM emission.

## Emission memory (decay half-life)

How much recent context the emission scorer integrates when judging "the chords
we just heard": pitch-class evidence decays exponentially with this half-life.
Short memory makes each emission a snapshot of the immediate harmony, quick to
see excursions; long memory makes it a summary of the current section. Log
entries 2026-07-07-16/17 found this dial selects which timescale of key
structure the detector reports (see Section-key vs. local-key annotations).

## Event

One committed chord from live play: the chord the player held, with the
recognizer's ranked readings of it, its voicing, timing, and duration. The unit
everything is scored over, each counting once regardless of how long it was
held.

## Exact vs. MIREX-weighted

Exact scores a claim 1 only for the annotated key.
[MIREX-weighted](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection) gives
partial credit for musically close misses: the key a fifth away 0.5, the
relative major/minor 0.3, the parallel major/minor 0.2. A gap between the two
numbers means the errors are mostly neighboring keys, not random ones.

## Explanation cost

The chord recognizer's internal penalty for how awkwardly the sounding notes fit
one candidate chord reading; lower is better, and every event carries its ranked
candidates with their costs. The gap between the best and second-best cost is
the recognizer-confidence signal that confidence weighting tried, and failed, to
exploit.

## Filtered posterior (forward algorithm)

The [forward algorithm](https://en.wikipedia.org/wiki/Forward_algorithm) run
causally: after each event, the probability of each key given everything heard
so far, and nothing from the future (unlike
[Viterbi decoding](#viterbi-decoding), which waits for the ending before
explaining the beginning). This is what the HMM claims from, and why its
confidence is a true probability.

## Fixture

A stored, labeled event stream the harness replays: what the detector would have
seen live, plus the ground-truth keys only the scorer may read. Versioned like a
dataset because fixtures embed engine output.

## Functional blend

Mixes a second signal into the emission: instead of only asking which key's
scale the notes fit, it also asks which key the chord would have a familiar job
in (a V7 wants to be the dominant of somewhere). Valuable when the target is
tracking brief excursions, harmful when it is naming the section's key, and it
misreads blues harmony, so the shipped configuration leaves it at zero.

## Global vs. local key

Global: one key per piece, the whole-piece answer the older literature reports.
Local: the key at each moment, which is what the app displays and what
modulation tracking is about. This is a different distinction from annotation
granularity; a moment-by-moment detector can still report either kind of key
described under
[Section-key vs. local-key annotations](#section-key-vs-local-key-annotations).

## Hidden Markov model (HMM)

A [model](https://en.wikipedia.org/wiki/Hidden_Markov_model) that treats the key
as a hidden state we never observe directly: each chord event gives noisy
evidence (the emission), and the key itself changes only occasionally (the
transitions). Inference balances the two, so an established key persists through
momentary contradictions but yields to sustained ones.

## Hysteresis

A rule that makes the detector wait for repeated evidence before changing its
answer, like a thermostat that will not flip the furnace on and off for every
draft. In WhatKey's early experiments, claim hysteresis meant "do not adopt a
new key until it has appeared for several consecutive claiming events." It can
reduce flicker, but it also delays real modulations; the logs record it as a
mostly negative result for this detector.

## Margin floor

The confidence bar for speaking at all. At each event the detector ranks all 24
keys; if the leader is not ahead of the runner-up by at least the floor, it
abstains rather than naming a narrow leader. Higher floor: fewer, more accurate
claims. It gates every claim, not just key changes.

## Matched-coverage comparison

Grading two detectors on the identical subset of events (the ones a reference
run claimed on), so neither gets an advantage from skipping harder questions.
This is how "different coverage" is ruled out as the explanation for an accuracy
difference.

## Mode tilt

A per-event nudge within one parallel pair of keys (same tonic, major vs.
minor): when the chord just played is rooted on that tonic and is clearly major
or clearly minor, some probability shifts toward the matching twin. The pair's
total is preserved, so the tilt can pick between a key's twins but can never
favor a different tonic, which is why it avoids the problems that got its
broader ancestors removed (log entry 2026-07-07-23).

## Modulation lag

After an annotated
[key change](https://en.wikipedia.org/wiki/Modulation_%28music%29), how many
events pass before the detector's claim arrives in the new key. Reported as
median and p90 (the [90th percentile](https://en.wikipedia.org/wiki/Percentile),
the value only the worst tenth of cases exceed), with censored modulations
counted separately.

## One-shot evaluation

The first and only evaluation of a frozen result on a held-out split. "One-shot"
does not mean one command or one table; it means the result set was specified
before seeing the test data, then run without using those test outcomes to tune
the system. Additional diagnostic passes can be valid if they do not change the
claims, but any new model choice after seeing the test split belongs in a new,
clearly labeled study.

## Paired statistics

Comparing two detectors
[piece by piece](https://en.wikipedia.org/wiki/Paired_difference_test) (who won
on _this_ piece?) instead of comparing their overall averages, then testing
whether one wins consistently (Wilcoxon signed-rank). An average can be won on a
few long pieces while losing on most; a paired win cannot. The protocol requires
this standard for decisions like changing the default profile pair.

## P-value

A way to ask how surprising a result would be if two systems were actually tied.
For example: if system A beats system B on many pieces, the p-value asks how
often a pattern that strong would happen by chance. A small p-value is evidence
that the difference is real enough to take seriously. It does not say how large
the improvement is, so WhatKey reports the size of the effect alongside the
p-value.

## Posterior

The detector's updated probabilities after the newest chord event has been taken
into account. In the HMM, the posterior starts from the prior, adds the new
event's evidence, and normalizes the result so all key probabilities add to 1.
This is the distribution the detector claims from: if C major is the top
posterior key, C major is the current best guess.

## Posterior calibration / reliability

Whether a probability number should be taken literally. If the detector says "C
major, 80%" on 100 events, a calibrated detector should be right on about 80 of
them. The harness checks this by putting events into confidence bands (0-10%,
10-20%, ..., 90-100%) and comparing each band's average confidence with its
actual accuracy.

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

## Prior

The detector's probabilities before the newest chord event is used. In the HMM,
the prior is made by carrying the previous posterior forward through the
transition model: mostly keep the same key, but allow some chance of moving to a
nearby or distant key. Plainly, the prior is "what we expected before hearing
this chord"; the posterior is "what we believe after hearing it."

## Profile pair

A published pair of 12-number templates (one major, one minor) describing how
strongly each scale degree characterizes a key. The profile-correlation detector
tries the pair at every tonic in both modes (24 candidate keys) and asks which
best matches the recent pitch histogram by
[Pearson correlation](https://en.wikipedia.org/wiki/Pearson_correlation_coefficient).
The choice of pair measurably matters on the bare profile floor, though it
washed out inside the full detector (log entry 2026-07-07-09). The published
sources for each pair are cited in the
[design doc's references](temporal-context-key-detection.md#references), and
their values are verified against reference implementations (log entry
2026-07-06-08).

## Progression blend

Mixes cadence patterns into the emission: short chord-to-chord moves (like V7 to
I) vote for the key they resolve into. It helped an older detector's abstention
decisions but measured as a wash under the HMM, so the shipped configuration
leaves it at zero.

## Section-key vs. local-key annotations

Two granularities of "the key," both legitimate. Section-key annotations name
the home key of a stretch of music, the sense in which a whole song or movement
is "in G." Local-key annotations also track brief local assertions: the few
measures an analyst marks as V-of, a tonicization, or the relative minor. Corpus
labels come at different granularities (Isophonics song keys and ASAP key
signatures are section-key; When in Rome analyst local keys are local-key), so
accuracy numbers are only comparable against the same ruler. WhatChord ships the
section-key setting (log entry 2026-07-07-17). Older logs sometimes call the
local-key setting "tonicization-scale" or "reflex-scale."

## Self-transition

The HMM's probability that the key this event is the same as the key last event.
Higher values mean a steadier detector that needs more sustained evidence to
change its mind: the principled version of the persistence that decay tuning and
claim hysteresis approximated. The remaining probability spreads over other
keys, nearer ones on the circle of fifths getting more.

## Spurious switch

A key switch the annotation gives no reason for: the labeled key did not change
between the detector's previous claim and this one, and the new claim does not
land on the labeled key. The stability metric counts these per piece; a lagged
catch-up switch onto the annotated key is not spurious.

## Temperature scaling

The one-knob calibration fix: raise every probability to 1/T and renormalize. T
above 1 flattens an overconfident distribution toward honesty without ever
reordering the candidates, so rankings, claims, and abstention are untouched.
WhatKey applies it only to displayed probabilities (fit in log entry
2026-07-08-03); the detector's internal numbers stay raw.

## Time to first claim

How many events pass before the detector commits to any key at all. Trades off
against stability and lag, which is why all three are reported and never
blended.

## Transition model

The HMM's map of how likely the key is to move from one event to the next. Most
probability stays on the same key; the rest spreads to other keys, with closer
keys on the circle of fifths favored over distant ones. The transition model is
what turns the previous posterior into the next prior before the newest chord
evidence is added.

## Viterbi decoding

The offline counterpart to the filtered posterior: given a complete piece, the
[Viterbi algorithm](https://en.wikipedia.org/wiki/Viterbi_algorithm) finds the
single most probable key sequence over the whole thing at once, letting the
ending explain the beginning. Powerful for after-the-fact analysis, but not
causal: the protocol rules it out for the live detector, and offline Viterbi
results are not directly comparable with streaming ones (the paper cites offline
systems only as caveated anchors).

## Warmup

The `minEvents` rule: the detector abstains until it has seen a minimum number
of events (currently 3), regardless of confidence, so it never guesses a key
from one chord.

## Wilcoxon signed-rank test

The [statistical test](https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test)
behind our paired comparisons. It looks at the piece-by-piece differences
between two detectors, ranks them by size, and asks: if the two were actually
equally good, how often would luck alone produce differences this consistently
one-sided? The answer is the p-value; a small one (conventionally below 0.05)
means the win is unlikely to be corpus noise. It makes no assumption about the
differences following any particular distribution, which is why it is the
standard choice for this kind of comparison. Implemented in
`tool/whatkey/compare.py`.
