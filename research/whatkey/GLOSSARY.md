# WhatKey Glossary

Plain-English definitions of the measurement terms used across the log entries
and reports. PROTOCOL.md is the normative source; this file explains, it does
not define. Log entries should link here rather than re-explain terms, and keep
their own plain-English sections for interpreting specific results.

**Abstention.** The detector saying nothing rather than naming a key. A
first-class outcome, never counted as an error: on genuinely ambiguous music,
staying quiet is the correct answer.

**Accuracy on claimed events.** Of the events where the detector was willing to
name a key, the fraction it got right. Always reported together with coverage;
either number alone is meaningless, because a detector can trade one for the
other.

**Censored modulation.** An annotated key change the detector never caught up
with: it did not reach the new key before the next change (or the piece)
arrived. Counted separately rather than averaged into lag, because "never got
there" is not a large lag, it is a miss.

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

**Event.** One committed chord from the history capture: a held identity with
its ranked candidates, voicing, timing, and duration. The unit everything is
scored over, each counting once regardless of how long it was held.

**Exact vs. MIREX-weighted.** Exact scores a claim 1 only for the annotated key.
MIREX-weighted gives partial credit for musically close misses: the key a fifth
away 0.5, the relative major/minor 0.3, the parallel major/minor 0.2. A gap
between the two numbers means the errors are mostly neighboring keys, not random
ones.

**Fixture.** A stored, labeled event stream the harness replays: what the
detector would have seen live, plus the ground-truth keys only the scorer may
read. Versioned like a dataset because fixtures embed engine output.

**Global vs. local key.** Global: one key per piece, the whole-piece answer the
older literature reports. Local: the key at each moment, which is what the app
displays and what modulation tracking is about.

**Margin floor.** The confidence bar for speaking at all. At each event the
detector ranks all 24 keys; if the leader is not ahead of the runner-up by at
least the floor, it abstains rather than naming a narrow leader. Higher floor:
fewer, more accurate claims. It gates every claim, not just key changes.

**Matched-coverage comparison.** Grading two detectors on the identical subset
of events (the ones a reference run claimed on), so neither gets an advantage
from skipping harder questions. This is how "different coverage" is ruled out as
the explanation for an accuracy difference.

**Modulation lag.** After an annotated key change, how many events pass before
the detector's claim arrives in the new key. Reported as median and p90, with
censored modulations counted separately.

**Paired statistics.** Comparing two detectors piece by piece (who won on _this_
piece?) instead of comparing their overall averages, then testing whether one
wins consistently (Wilcoxon signed-rank). An average can be won on a few long
pieces while losing on most; a paired win cannot. The protocol requires this
standard for decisions like changing the default profile pair.

**Profile pair.** A published pair of 12-number templates (one major, one minor)
describing how strongly each scale degree characterizes a key. The
profile-correlation detector matches the recent pitch histogram against all 24
rotations of the pair; which pair is used matters more than the matching
formula.

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
