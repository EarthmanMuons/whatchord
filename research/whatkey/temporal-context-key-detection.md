# Temporal Context and Key Detection: Implementation Plan

> **Status note (2026-07-07).** This is the design-time plan and algorithm
> reference; it is kept as written, with dated additions marked inline. Much of
> it has since been executed: Phase 1 shipped, the detector family through the
> 2c HMM is implemented and evaluated, and the adopted configuration is a causal
> HMM over pure profile-correlation emissions (log entries 2026-07-07-12 through
> -18). For current results and decisions, read [README.md](README.md) and
> [log/](log/); this document remains the source of truth for design rationale,
> the algorithm menu, and references. Sections below describe the pre-Phase-1
> codebase where they say "current".

## Current State

WhatChord is a **stateless real-time analyzer**: each MIDI event triggers a
re-analysis, but no memory is kept between chord changes. The user manually sets
the tonality/key signature, which drives spellings and also biases analysis:
several ranking tie-breakers are tonality-gated (diatonic, tonic,
harmonic-minor, and spelling-cleanliness rules), and the analyzer's LRU cache is
keyed on `AnalysisContext` for exactly this reason. Key detection therefore
cannot be treated as a pure output layer: anything that writes an inferred key
back into `AnalysisContext` changes how future chords are named (see Decision
Point 1).

Data flow:

```
MIDI HW → MidiNoteStateNotifier → input layer
       → chordInputProvider → ChordAnalyzer
       → chordCandidatesProvider
       → chordPresentationProvider
       → identityDisplayProvider → UI
```

Key structures already in place:

- `ChordInput`: pcMask, bassPc, noteCount (pure pitch-class, no octaves)
- `ObservedVoicing`: full MIDI note numbers with register (null for lookup pad)
- `ChordIdentity`: rootPc, quality, extensions, presentIntervalsMask, toneRoles
- `ChordCandidate`: identity + `cost` (unitless explanation cost, lower is
  better; `nearTieWindow` in `ranking_policy.dart` defines when candidates count
  as near-ties)
- `AnalysisContext`: tonality + keySignature + spellingPolicy (all user-set)
- `analysisModeProvider`: gates analysis by note count;
  `chordCandidatesProvider` returns an empty list for 0-2 sounding notes
  (`AnalysisMode.none`/`single`/`dyad`), so ranked candidates only exist for 3+
  notes
- `midiSoundingNoteNumbersProvider` (re-exported to the input layer as
  `midiNoteNumbersSource`): live-MIDI-only, pedal-aware sounding set, the raw
  source that history capture ultimately cares about
- `Tonality` / `KeySignature` / `ScaleDegree`: target output types for key
  detection already exist
- `InputIdleNotifier`: already tracks engagement/release transitions for the
  unified input surface. Release is one commit trigger for history (see 1b), not
  the segmentation primitive. Its engagement signal is derived from the _merged_
  sounding-note set (live + demo + lookup), so it cannot by itself isolate live
  input.

There is **no existing history, logging, or temporal tracking** of any kind.

---

## Phase 1: Temporal Data Foundation

Create a new feature `features/history/` to record a sliding-window history of
chord analysis results, with timestamps.

### 1a. Domain Model: `ChordEvent`

File: `features/history/models/chord_event.dart`

```dart
@immutable
class ChordEvent {
  final DateTime timestamp;
  final ChordInput input;             // raw pitch-class data
  final ObservedVoicing voicing;      // live voicing (always 3+ notes, see below)
  final List<ChordCandidate> candidates; // ranked, best-first
  final Tonality tonality;            // context the candidates were ranked under
  final Duration duration;            // how long this identity persisted

  ChordIdentity get identity => candidates.first.identity;
  double get cost => candidates.first.cost;
}
```

This captures everything a key-detection algorithm needs: raw notes, the ranked
identification with confidence, timing, and hold duration.

Store a single best-first `candidates` list and expose `identity`/`cost` as
getters rather than as separate stored fields. This keeps one source of truth
and lets key detection use cost gaps (best-to-second delta measured against
`nearTieWindow`) for confidence weighting without re-running analysis.

`voicing` is non-nullable, resolved by an existing gate: `analysisModeProvider`
only yields `AnalysisMode.chord` for 3+ notes, and `chordCandidatesProvider`
returns an empty list otherwise. An event with a non-empty `candidates` list
therefore always has 3+ live (non-lookup) notes, so a real voicing always
exists. The flip side: single notes and dyads never enter history at all, which
discards melodic and bass-line key evidence between chords. That is acceptable
for v1; revisit if Phase 2 detectors want melody (see 2e's bass-line note).

Store the `tonality` from the `AnalysisContext` active at analysis time. The
candidates were ranked under that context (tonality-gated tie-breakers), so a
mid-session tonality change (manual today, possibly inferred later) makes
history context-heterogeneous. One enum-pair field costs nothing, lets detectors
de-bias or discard cross-context events, and is required to reason about the
write-back feedback loop (Decision Point 1).

Populate `candidates` from the existing near-tie definition rather than an
ad-hoc "top ~3": `bestChordCandidateProvider` plus
`ChordCandidateRanking.alternatives` (surfaced by
`alternativeChordCandidatesProvider`) already encode what counts as a relevant
alternative. Reuse that so history and the UI agree on what "alternative" means.

### 1b. State: `ChordHistoryNotifier`

File: `features/history/providers/chord_history_notifier.dart`

```dart
class ChordHistoryNotifier extends Notifier<List<ChordEvent>> {
  void record(ChordEvent event);  // append + trim oldest
  void clear();

  List<ChordEvent> recentEvents(Duration window);  // filtered view
}
```

The one retention bound is not a mutable field on the notifier. The codebase
factors tunables into their own providers (e.g. `inputIdleCooldownProvider`);
follow that pattern with `historyCapacityProvider` that the notifier watches.
See **Retention** below for why a single bound is enough.

#### Segmentation: commit on identity change

The unit of history is a held chord identity, not an engagement. The notifier
tracks the **currently-analyzed identity** and commits the _previous_ identity
at the moment a new, different one stabilizes. Release is just one more commit
trigger, not the segmentation rule. This is what Phase 2 needs: a sequence of
chords. Segmenting on release instead would collapse a pedaled or legato
progression (where the sounding set never empties until the end) into a single
`ChordEvent` whose pcMask is the union of every note played.

- Maintain a single in-progress snapshot: the current `ChordEvent` data plus the
  timestamp it began. When the analyzed identity changes (and the previous one
  persisted past a minimum-duration threshold), commit the previous snapshot
  with `duration = now - startedAt`, then start a new snapshot.
- Commit the final in-progress snapshot on release (sounding set becomes empty),
  using the same threshold. Treat "candidates became empty" the same way: the
  note count dropping below 3 leaves `AnalysisMode.chord`, and
  `chordCandidatesProvider` returns `[]` well before the sounding set empties. A
  decay from Cmaj7 down to a held single C should commit the Cmaj7, not wait for
  full silence.
- The previous identity is committed when the _new_ one appears, while notes are
  still sounding, so there is no empty-providers-on-release case to handle.
- `duration` is the time the identity was actually held, which Phase 2 weights
  by.
- Sustain pedal follows existing MIDI note-state semantics: pedal-held notes
  stay in the sounding set, so identity changes (and the final release) are
  driven by that merged set exactly as analysis already sees it.

**Stabilization.** To avoid recording finger-rolls and passing voicings, apply a
short debounce/hysteresis on identity changes and a minimum-duration threshold
before a snapshot is eligible to commit. As implemented, one threshold serves
both roles: a different identity becomes a _pending challenger_ that only ends
(commits) the current chord once it has itself persisted past the threshold, and
the same threshold drops short-lived commits. A challenger that vanishes back
into the current identity was a blip, and the current chord continues as one
uninterrupted event, so duration weighting is not fragmented by transients. The
committed chord ends at the challenger's onset, and events snapshot their frame
(input, voicing, candidates, tonality) at identity onset; same-identity changes
mid-hold neither update the snapshot nor re-segment the event, keeping stored
candidates consistent with the stored tonality they were ranked under.

#### Live-only gating happens at capture, not at commit

Lookup and demo input must never enter history. The subtlety is that gating has
to guard _snapshot capture_, not the commit:

- A live-MIDI-only _sounding set_ exists (`midiSoundingNoteNumbersProvider`,
  re-exported as `midiNoteNumbersSource`; `liveSoundingNoteNumbersProvider`
  additionally exists but swaps to demo notes in demo mode), but there is no
  live-MIDI-only _analysis_ chain. `soundingNoteNumbersProvider` /
  `soundingNotesProvider` **merge** demo and lookup notes in, and
  `chordInputProvider` includes lookup notes (only `observedVoicingProvider`
  excludes lookup). So both demo and lookup _do_ flow through
  `chordCandidatesProvider`; reusing the analysis chain without gating would
  leak them into history.
- Commit-time gating is not enough. `InputIdleNotifier.markIdleNow()` fires a
  release the instant demo/lookup toggles _off_, by which point
  `demoModeProvider` has already flipped to `false`. A commit-time
  `if (demoMode) skip` check would fail to skip and commit a stale demo chord.
- Therefore: **only ever update the in-progress snapshot while
  `!demoModeProvider && !lookupActiveProvider`.** With capture gated this way
  the toggle-timing race disappears and the flags do double duty. The cleaner
  long-term option is a dedicated live-only analysis chain feeding history
  (cheaper than it sounds, since `midiNoteNumbersSource` already provides the
  live sounding set; only the `ChordInput`/candidates derivation needs a live
  variant, at the cost of running the analyzer redundantly while demo or lookup
  is active). The capture-time flag check is the minimum and is required
  regardless.

**Retention**: One stored bound, one read-time view.

- **`historyCapacity`** (a count) is the only stored bound, the memory cap.
  Enforce it on every `record()` by dropping the oldest entries beyond the
  count. A count bounds memory completely, so no age-based purge is needed.
- **Age filtering is a read concern, not stored state.** `recentEvents(window)`
  filters by timestamp at read time, with whatever window the consumer cares
  about. An on-`record()` age purge would only run when something new is played
  (a paused session would never shed stale events) and would bake one window
  into storage when different consumers want different windows. Keep age out of
  the notifier's state entirely.

### 1c. Feature Barrel

File: `features/history/history.dart`

```dart
export 'models/chord_event.dart';
export 'providers/chord_history_notifier.dart';
```

### 1d. Integration

To activate the notifier, add a lifecycle provider in the history feature:

File: `features/history/providers/app_chord_history_lifecycle_provider.dart`

```dart
final appChordHistoryLifecycleProvider = Provider<void>((ref) {
  ref.watch(chordHistoryProvider);
});
```

This follows the existing ownership pattern of `appMidiLifecycleProvider` and
`appAudioMonitorLifecycleProvider`: the lifecycle provider lives in the feature
that owns the side effect, is exported from that feature's barrel, and is
watched in `MyApp.build()` in `main.dart`.

### 1e. Persistence

**Never persisted, by design.** History is in-memory only and stays that way
beyond Phase 1. Recorded chords are a transient analysis signal, not user data
worth keeping, and never writing them to disk keeps the privacy question moot
permanently rather than just for Phase 1. The history is rebuilt naturally from
live play each session; clearing on app exit is the intended behavior, not a
limitation.

The `ChordEvent` model still serializes cleanly (ints, enums, timestamps), but
that is only for developer-authored or dev-captured test fixtures (see the
benchmark harness in Phase 2), not for runtime persistence of a user's session.

### 1f. Feature Placement Rationale

`features/history/` is a new top-level feature rather than living under
`theory/` because:

- The theory engine is a pure analysis function: no state, no time.
- History is temporal state management, a distinct concern.
- `theory/` is a dependency of `history/`, never the reverse, which avoids
  circular imports.
- Follows the existing pattern where `input/`, `midi/`, and `theory/` each own a
  distinct layer of the pipeline.

---

## Phase 2: Key Detection Engine (in progress; detectors 2a-2e built)

Once `ChordHistoryNotifier` exists, key detection algorithms can consume it
without touching UI or MIDI code. All algorithms operate on `List<ChordEvent>`.

### 2a. Krumhansl-Schmuckler (probe-tone profile correlation)

```
history.recentEvents(window)
  → aggregate pitch-class distribution
  → correlate with known K-S profiles (major + minor, all 12 tonics)
  → return ranked Tonality candidates
```

Implementation: pure-Dart static function `KeyEstimator.ksProfile(...)` that
takes `List<ChordEvent>` and returns `List<(Tonality, double)>` (tonality +
correlation score). The profiles are 24 constant vectors (12 major + 12 minor),
derived from 2 base vectors by rotation.

Make the profile pair a parameter, not a constant: the literature is clear that
profile choice matters more than the correlation formula. The original
Krumhansl-Kessler probe-tone profiles are the historical baseline but are known
to underperform in minor; Temperley's 1999 revision and the corpus-trained
Albrecht-Shanahan (2013) profiles both do better, the latter specifically on
minor-mode pieces (see References). Shipping one algorithm with 3 profile pairs
gives the benchmark harness cheap A/B material.

Weighting strategies to implement:

- **Flat**: each event contributes equally to the pitch-class histogram.
- **Duration-weighted**: scale each event's contribution by `duration`. A chord
  held four bars is far stronger evidence than a passing half-beat hit, and
  duration weighting is standard in this family of algorithms (Temperley 1999).
- **Decay-weighted**: recent events contribute more. Exponential decay with a
  half-life of ~30 seconds. The decay is applied to the histogram bins, so older
  events fade out of the correlation naturally.

These compose (duration x decay is the natural default).

### 2b. Temperley Bayesian approach

```
P(key | events) ∝ P(events | key) × P(key)
```

For each candidate key, compute the likelihood of observing the chord sequence.
Uses chord root + quality as observables. `ScaleDegreeClassifier` already knows
which scale degrees are diatonic to a key, so likelihood estimation builds on
existing infrastructure.

Uniform prior over keys, or optionally a prior favoring closely-related keys
from the previously detected key (smooth transitions). Temperley's Bayesian
formulation (2002; expanded in _Music and Probability_, 2007) is the reference
model here; it subsumes the profile approach, since a key profile is just an
emission distribution.

### 2c. Hidden Markov Model / Viterbi

Most sophisticated option. Models the key as a hidden state with:

- **Transition probabilities**: higher for circle-of-fifths neighbors, lower for
  distant keys.
- **Emission probabilities**: chord identities are more likely in certain keys
  (e.g. a `dominant7` on G is extremely likely in C major).

Viterbi decoding finds the most probable key sequence given the chord sequence.
More complex to implement and tune but handles key changes cleanly.

This is the best-studied structure in the modern literature. Nápoles López,
Arthur & Fujinaga (2019) get strong global and local key results from an HMM
whose emissions are plain key profiles over pitch-class observations (the
`justkeydding` implementation; see References), which suggests a useful
sequencing: an HMM over per-event pitch classes is a small step up from 2a, and
chord-identity emissions (root + quality relative to key, the Raphael & Stoddard
2004 approach to harmonic analysis) can come after. For streaming use, run
Viterbi over the sliding window, or use the forward algorithm's filtered
posterior; the transition matrix then doubles as the modulation hysteresis that
2d has to hand-roll.

### 2d. Weighted Evidence Model (simplest hybrid)

Maintain a running score per key, updated incrementally as each chord event
arrives:

- Root diatonic to key: +2
- All chord tones diatonic to key: +3
- Chromatic chord tones: -1 per tone outside the key
- Dominant function on V (e.g. G7 in C major): +4 bonus for the tonic key
- Leading-tone diminished (e.g. B° in C major): +3 bonus for the tonic key
- Decay: all scores multiplied by a factor (e.g. 0.95) at each event, so old
  evidence fades

**Minor-mode trap.** Do not implement "diatonic to key" with
`Tonality.containsPitchClass`: it models natural minor only, so in A minor the
G# of E7 would take a chromatic penalty on the single strongest indicator of A
minor (the dominant with its leading tone). `ScaleDegreeClassifier` already
evaluates harmonic minor as a source (`ScaleDegreeSource`); route diatonicity
checks through it, or the model will systematically underrate minor keys, the
classic failure mode profile algorithms suffer from too (see Albrecht-Shanahan).

The key with the highest running score wins. This naturally handles key changes
via score overtaking. Advantages:

- No need to scan full history on each event; it is an incremental update.
- Easy to tune: each rule is a small, testable function.
- Naturally expresses musician-like reasoning about key.
- The decay factor controls responsiveness vs. stability.

### 2e. Functional / progression features (the strongest signal)

The history stream carries far more than pitch classes. By the time an event is
recorded we already know, per chord, its quality, root, extensions, inversion,
and (once a key hypothesis exists) its scale-degree function and enharmonic
spelling. That makes functional-harmony patterns scoreable directly, and those
patterns carry vastly more key information than a raw pitch-class frequency
profile. This is the argument for the sequence/functional models (2b/2c/2d): the
K-S histogram (2a) discards ordering and function and is best treated as a
floor, not the goal.

Patterns worth scoring (each evaluated _per candidate key_, since function is
key-relative; the same chord stream gets a different functional reading under
each tonic hypothesis, which is exactly what 2b/2c/2d already iterate over):

- Authentic cadence (V to I), the strongest tonic evidence.
- ii to V to I, and the longer vi to ii to V to I.
- Deceptive cadence (V to vi).
- Secondary dominants (V/x resolving to x), identifiable by the chromatic
  secondary leading tone.
- Borrowed chords / modal interchange (e.g. iv or bVII in a major key).
- Leading-tone diminished resolving to I.

Extensions and inversion sharpen these rather than just confirming the root:

- A `dominant7` is stronger cadential evidence than a bare dominant triad; a
  tritone (3rd + b7) pins the dominant function.
- Inversion / bass distinguishes a real cadence from passing motion: a root
  position V to I is a stronger signal than an inverted one, and a cadential 6-4
  (I64 to V) is itself a tonic marker. `ChordEvent.input.bassPc` (and `voicing`
  when present) supplies this.

Practical shape: implement these as a small library of pattern detectors over a
sliding window of recent events, each emitting a weighted vote for the key(s) it
implies. The weighted evidence model (2d) is the natural first consumer; its
existing per-chord rules (dominant-on-V, leading-tone diminished) are degenerate
one-chord cases of this same idea, so this generalizes 2d from single-chord
features to progression features. It also multiplies the design space, which
makes the offline benchmark harness (see Further Phase 2 thoughts) a
prerequisite rather than a nicety: fixtures should carry functional labels
(cadence points, applied dominants) so detectors can be scored against ground
truth, not just final-key accuracy.

### Decision Points for Phase 2

Questions to resolve before implementing any algorithm:

1. **Should the detected key auto-set the user's selected tonality, or be a
   separate "inferred" display?** Recommend: display as a secondary indicator
   ("Likely key: C major") without replacing the manual selection, so musicians
   can override. The stakes are higher than display alone: tonality biases
   ranking tie-breakers, so auto-setting it also changes what the analyzer names
   subsequent chords, closing a loop (inferred key -> tonality -> candidate
   ranking -> history -> inferred key). Display-only inference stays out of that
   loop entirely. Any later write-back needs hysteresis plus the per-event
   `tonality` field (1a) to keep history interpretable, and should be validated
   in the harness by re-running detection with the loop closed.

2. **Should all events contribute, or only those with strong confidence?** A
   cost-gap threshold (e.g. only events where the best candidate beats the 2nd
   best by a clear margin relative to `nearTieWindow`) may improve signal
   quality.

3. **Which algorithm to implement first?** Profile correlation (2a) is the
   cheapest to build (a histogram and 24 dot products) and is the established
   floor every published system is measured against, so implement it first as
   the harness's baseline. The weighted evidence model (2d) follows as the first
   model that actually uses chord identities, and everything later must beat
   both on the harness to earn its complexity.

### Notes on Algorithm Tuning

- Chord voicings with ambiguous identities (low-confidence near-ties) should be
  weighted less or excluded from the key detection signal. The full best-first
  `candidates` list is retained precisely so an algorithm can measure the
  best-to-second cost gap and down-weight near-ties without re-analyzing. Better
  still, ambiguity is signal for the histogram approaches: a near-tie's pitch
  classes are unambiguous even when its name is not, so 2a can use every event
  while the functional detectors (2e) apply the cost-gap filter.
- The `duration` field on `ChordEvent` lets algorithms weight longer-held chords
  more heavily; a chord played for 4 bars matters more than one for a beat.
- Key detection should only activate when at least N chord events have been
  collected (e.g. N=3) to avoid wild guesses from insufficient data.
- **Decay on elapsed time, not on engagement boundaries.** Confidence decay
  should be a function of wall-clock time since the most recent event (or
  applied per event using the inter-event gap), so a held pause inside one
  engagement and a pause between engagements behave the same. This composes
  directly with the decay-weighted K-S histogram (2a) and the per-event decay
  factor in the weighted evidence model (2d): same time-based decay, just
  applied to different accumulators. Engagement state stays a UI/idle concern,
  out of detection.

### Further Phase 2 thoughts

- **Key changes vs. transient excursions.** The hard part of real detection is
  distinguishing a genuine modulation from a tonicization or a
  borrowed/secondary dominant. The HMM/Viterbi option (2c) handles this most
  cleanly via transition costs; the cheaper models (2d especially) need
  hysteresis: require the new key to lead by a margin for a sustained span
  before switching, to avoid flapping on a single V/V.
- **Bass line carries key information** that pure pitch-class histograms
  discard. Beyond the inversion cues in 2e, cadential bass motion itself
  (scale-degree 5 to 1) is a strong tonic signal worth a dedicated detector over
  `ChordEvent.input.bassPc`.
- **Surface confidence, not just a winner.** The UI indicator should reflect the
  margin between the top key candidates (e.g. "C major" firmly vs. "C major?"
  when ambiguous), and degrade gracefully to no claim below a confidence floor
  rather than always asserting some key.
- **Evaluation harness before tuning.** Because several algorithms are planned
  (2a/2b/2c/2d) and meant to be A/B compared, build a small offline harness that
  replays serialized `List<ChordEvent>` fixtures through each estimator. That
  makes the comparison reproducible and keeps tuning out of live-playing
  guesswork. Most of the fixture pipeline already exists:
  `tool/when_in_rome_chord_benchmark.py` parses When in Rome pieces (RomanText
  annotations via music21) and drives the real engine in batch through
  `tool/when_in_rome_chord_batch.dart`. RomanText carries the analyst's local
  key at every annotation, so the same corpus yields time-aligned key ground
  truth with explicit modulation boundaries, and the Roman numerals themselves
  are the functional labels (cadence points, applied dominants) that 2e's
  detectors need scoring against. Extend that tooling to emit `ChordEvent`
  fixtures (chord stream and durations from the score, candidates from the real
  engine, labeled local key per event) and check in a curated subset as test
  fixtures. Follow the `tool/chord_rule_ablation.py` pattern for the compare
  loop.
- **Corpus balance.** When in Rome skews common-practice classical. Complement
  it with a small set of hand-authored pop/jazz fixtures (I-V-vi-IV loops,
  ii-V-I chains, 12-bar blues, modal vamps, and a few deliberately ambiguous
  ones like an Am-F-C-G four-chord loop) closer to what a player actually
  noodles. These are also where the "no claim below the confidence floor"
  behavior gets tested: a modal vamp has no single right answer, and asserting
  one confidently is a worse outcome than staying quiet.
- **Metrics.** Score more than final-key accuracy. Use the
  [MIREX key-detection task's weighting](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection)
  for near misses (exact 1.0, perfect fifth 0.5, relative major/minor 0.3,
  parallel major/minor 0.2), plus time-aligned local-key accuracy, modulation
  lag (events between an annotated key change and the detector switching),
  stability (spurious switches per piece), and time-to-first-claim (how many
  events before the detector commits at all). The last three trade off against
  each other, which is exactly what the A/B comparison needs to expose.
- **Spelling feedback loop (later).** Once a key is inferred with confidence, it
  could optionally drive `AnalysisContext` spelling (the thing the user sets
  manually today), closing the loop from detection back to presentation. This is
  explicitly a separate decision from Phase 2's detection work (see Decision
  Point 1, including the ranking feedback loop it creates), but it is the
  natural payoff and worth keeping in view so the inferred-key type stays
  compatible with the manual `Tonality`/`KeySignature` the spelling policy
  already consumes. Joint estimation of pitch spelling and local key from MIDI
  is an active research area (see the Bouquillard & Jacquemard reference),
  reinforcing that spelling and key are one inference problem, deferred here on
  purpose.
- **Future model directions (post-HMM, added 2026-07-07).** The shipped detector
  is a causal filtered HMM over profile-correlation emissions, at measured
  parity with offline whole-piece baselines on section-scale labels (log entries
  2026-07-07-18/-19), and the ablations established that the problem is
  section-scale persistence over noisy-but-unbiased per-event evidence. Given
  that, the credible next rungs if headroom appears:
  - **HSMM (explicit-duration HMM).** The HMM's self-transition implies
    geometric key-dwell times; real sections have long, non-geometric durations.
    Modeling dwell explicitly is the probabilistic form of the timescale finding
    (log entry 2026-07-07-16) and stays causal-compatible.
  - **Bayesian online changepoint detection.** Maintains a posterior over "when
    did the current key section start," handling the timescale question natively
    instead of via a fixed decay, and composes naturally with abstention.
  - **Ruled out for this setting**: neural sequence models (offline,
    score-hungry, heavy for on-device causal inference; the accuracy state of
    the art for symbolic local key, but the wrong tool here), particle filters
    (pointless over 24 exact states), and spiral-array tracking (approximated
    already by the decayed histogram).
  - **The ceiling argument**: at parity with systems that read the whole song in
    advance, part of the residual error is label quirkiness and genuine
    ambiguity, not model error. Pursue smarter temporal models only if the
    test-split evaluation or performed-input mode accuracy reveals headroom
    worth the complexity; the higher-expected-value work is data-side and
    product-side.
- **Mode disambiguation (added 2026-07-07).** Mode errors are ~10% of claims on
  both rulers once the timescale trade is filtered out (log entries
  2026-07-07-21/-22: parallel-dominated on performed classical, relative
  slightly ahead on pop), roughly 40% of all residual error. Profile correlation
  is intrinsically weak here: parallel keys share tonic, 2, 4, and 5, and
  practical minor borrows the raised 6th and 7th, so the discriminating evidence
  collapses to roughly one pitch class (the third), easily outvoted in a
  12-dimensional correlation; dominant-heavy minor passages and genuine mode
  mixture (borrowed iv/bVI, Picardy, pop's Mixolydian bVII) set a real ambiguity
  floor. Candidate techniques, in order of architectural fit:
  - **Hierarchical tonic-then-mode**: sum posterior mass over each parallel pair
    to pick the tonic (already correct in these errors), then decide mode by a
    focused likelihood ratio over only the distinguishing degrees. Causal,
    cheap, leaves the HMM untouched.
  - **Tonic chord quality as evidence (our unique asset)**: we observe symbolic
    chord identities, so the quality of chords rooted on the candidate tonic is
    the most direct mode cue available. This is an extraction, not new
    machinery: the evidence model's zeroed `tonicBonusPoints` path already
    computes exactly this check (`rootInterval == 0` plus
    `KeySpace.tonicQualities`). It was rejected as a tonic-selection force
    because rewarding every chord's own would-be tonic fights modulation
    tracking (log entry 2026-07-07-11), but reapplied as a zero-sum tilt
    _within_ each parallel pair it cannot touch the tonic marginal at all: both
    hypotheses share the tonic pitch class, and only the mode side of the pair
    moves. The ablation verdicts against the functional blend therefore do not
    apply to this slice by construction. One tilt-strength parameter; a
    mode-specific hysteresis would steady the displayed glyph. **Executed and
    shipped the same day** (log entry 2026-07-07-23,
    `HmmKeyDetector.modeTilt = 2`): significant paired exact wins on both
    development rulers, parallel confusion roughly halved everywhere measured,
    no behavioral or product-genre stability cost.
  - **Mode as a slow latent variable**: factor the 24 states into 12 tonics
    times 2 modes with mode self-transition well above tonic's (sections change
    more often than mode does); composes with the HSMM direction above.
  - **Product-level hedging (cheapest)**: show the tonic confidently and
    withhold the mode glyph when the parallel-pair posterior gap is under a
    mode-specific margin; converts the dominant residual error into honest
    abstention with zero model risk.
  - **Minor-profile mixture emissions** (natural/harmonic/melodic as a mixture):
    lowest priority; touches shared machinery and risks tonic accuracy already
    at parity.
  - **Relative-pair tilt (the analogous move for relative errors)**: the same
    zero-sum pattern generalizes; for relative twins the shared quantity is the
    key signature (distance zero in the transition kernel), so a
    within-relative-pair tilt cannot add evidence for any other signature and
    cannot fight modulation between signatures. The crux is weaker evidence: the
    rival's tonic chord is ordinary diatonic harmony there (Am in C major is
    just vi, common), not rare mode mixture, so isolated chord quality fires
    constantly for the twin and the usable strength is tiny. Sharper cues, in
    increasing promise: cadential bigrams (a dominant-quality chord resolving
    down a fifth onto a tonic-quality chord, an extraction from the retired
    progression detector, rescoped to the pair; scoped excursion-re-import risk
    since V/vi tonicization is a cadence into the relative minor), bass
    placement (fire only when root is also the bass, using the register we
    capture but no detector reads), and duration-weighting the tilt. Lower
    expected value than the parallel tilt: smaller error pool (4-6% of claims,
    and MIREX's most forgivable miss at 0.3), genuine-ambiguity ceiling
    (relative twins share every pitch class; the Am-F-C-G probe's abstention
    must survive), and a relative flip moves the displayed tonic letter, the
    most visible possible wobble.
  - Measurement path: tune on the Isophonics and When in Rome development splits
    (both mode-resolved), add mode-mixture probes to the pop-jazz behavioral
    suite, verify once on the ASAP overlap set. For relative-pair work the
    tripwire metrics are the mode-confusion table's relative row, the
    ambiguous-loop probe, and spurious switches.

---

## Performance Notes

Key detection is cheap because of rate, not because the math is trivial. The
optimized hot path (`ChordAnalyzer.analyze`, ~240 us cold / ~0.1 us cached per
`benchmark/baseline.json`) runs on every sounding-set change, i.e. every note
on/off during transitions. Detection runs once per _committed_ chord event,
after debounce and minimum-duration filtering: 1-2 per second at most in real
playing, roughly two orders of magnitude less often.

Per-event cost estimates, against that baseline:

- **Phase 1 history**: one `ChordIdentity` equality check per analysis frame
  plus an append-and-trim on commit. Sub-microsecond; ~100 events with 3-5
  candidates each is tens of KB. No extra analyzer calls: history consumes
  `chordCandidatesProvider` output, it never re-invokes `analyze()`.
- **Profile correlation (2a)**: 12-bin histogram over the window plus 24
  length-12 dot products; single-digit microseconds.
- **Weighted evidence (2d)**: incremental, 24 keys times a few bitmask checks
  per event with precomputed scale masks; low tens of microseconds even routed
  through `ScaleDegreeClassifier`.
- **Full-window Viterbi (2c)**: ~100 events x 24^2 transitions, ~58k
  multiply-adds; tens of microseconds.

The whole Phase 2 stack per committed chord costs about one cold `analyze()`
call or less. Run it synchronously in the commit path; no isolate.

Two rules keep it that way:

1. **Detection watches history, not the candidates provider.** History changes
   at commit rate; `chordCandidatesProvider` changes at note rate. Wiring
   detection to the latter would re-run it on every note toggle mid-transition.
2. **Write-back is the one path that touches the hot path.** The analyzer's LRU
   cache key includes `AnalysisContext`, so an inferred key auto-updating the
   context kills every entry under the old context and recomputes the current
   chord through the whole Riverpod chain. One recompute is imperceptible; a
   flapping detector would thrash the 512-entry cache with dual-context entries.
   This is the performance argument, alongside Decision Point 1's feedback-loop
   argument, for display-only inference in v1.

---

## Research Framing

This work is potentially publishable as research, not just an app feature. The
novelty is not key detection itself (a 30+ year literature); it is the setting:
**causal, streaming key inference from live performance input, over an
uncertainty-carrying chord-label stream, with an abstain option.** Published
work is almost entirely offline, score-based, and whole-piece. The closest
neighbors each miss a piece of it: Nápoles López et al. do local keys but
offline over clean pitch sequences; Chew's CEG is real-time but consumes raw
pitch events, not a recognizer's cost-ranked candidates. Key inference where the
observations carry recognizer confidence, and where abstention and latency are
first-class metrics, appears to be an open niche. The streaming metrics
themselves (modulation lag, stability, time-to-first-claim, abstain calibration)
are a methodological contribution if defined precisely and contrasted with
segment-accuracy evaluation.

Most of what makes work publishable is cheap if decided early and expensive or
impossible to retrofit. Steps by phase:

**Before any Phase 2 tuning (these have a deadline):**

- **Freeze a held-out test split now, by piece (better, by composer), and never
  tune against it.** Every price, decay constant, and profile choice tuned while
  watching the whole corpus contaminates it. Record the split in the repo before
  the first experiment.
- **Version fixtures like a dataset.** Fixtures embed the engine's candidate
  rankings, and the engine is a moving target that gets retuned; regenerating
  fixtures after a ranking change silently changes the dataset. Each fixture
  manifest records the engine commit, generation script parameters, and corpus
  source commits (When in Rome / contrapunctus-bench pins).
- **Check corpus licenses before committing derived fixtures.** When in Rome is
  a meta-corpus with heterogeneous licenses across sub-corpora; sort out
  redistribution of derivatives per sub-corpus, and record provenance per
  fixture.
- **Write the evaluation protocol down first**: metrics, split, corpus versions,
  baselines. This document is the start of that; keep it current.

**During development:**

- **Run external baselines on the same fixtures, not just our own algorithms.**
  music21's Krumhansl variants are nearly free (the fixture pipeline already
  sits on music21) and justkeydding runs on the same pitch streams. Without an
  external reference point, "our 2d beats our 2a" is an engineering note, not a
  result.
- **Design 2a-2e for ablation.** Each ingredient (profile pair, duration
  weighting, cost-gap confidence weighting, functional detectors) must toggle
  independently. Confidence weighting from the recognizer is the most novel
  claim and needs the cleanest ablation.
- **Report uncertainty.** Extend the benchmark habit (CI95 in
  `benchmark/baseline.json`) to the key harness: per-piece variance and paired
  comparisons across pieces, not pooled event accuracy. Small pooled deltas on a
  corpus dominated by a few composers are how false wins happen.
- **Keep dated experiment logs** (the existing initiative-log habit). They
  become the methods section almost verbatim.

**Performed vs. score-derived streams.** The fixtures are quantized score
reductions; the claim is about live playing, with finger rolls, pedal blur, and
noodling. The [ASAP dataset](https://github.com/fosfrancesco/asap-dataset)
closes most of this gap without collecting anything: real performed piano MIDI
aligned to scores, with key-signature change annotations, and repertoire
overlapping When in Rome's analyses (notably the Beethoven sonatas via BPS).
Replaying ASAP performances through the live capture path (Phase 1's actual
debounce and segmentation, not idealized score events) tests the whole system
under realistic input. No app-user data is ever collected for this; corpus and
personal dev captures suffice (see 1e).

**At publication time:** natural venues are ISMIR or TISMIR for the full study,
DLfM or SMC for an earlier methods-focused paper. Consider extracting the
harness plus fixtures as a standalone open repo; a runnable benchmark is often
the most cited artifact of this kind of paper.

---

## Implementation Order

### Phase 1 (initial PR)

1. Create `features/history/models/chord_event.dart`
2. Create `features/history/providers/chord_history_notifier.dart`
3. Create `features/history/history.dart` barrel
4. Create `features/history/providers/app_chord_history_lifecycle_provider.dart`
5. Wire into `main.dart` in `MyApp.build()`
6. Run `dart format .`, `flutter analyze`
7. Add focused provider/unit tests:
   - Commits the previous identity when a new identity stabilizes (pedaled
     legato progression yields multiple events, not one union chord).
   - Commits the final in-progress snapshot on release.
   - Respects the minimum-duration threshold (finger-rolls / passing voicings
     below threshold are not recorded).
   - Ignores lookup chords (capture gated while `lookupActiveProvider`).
   - Ignores demo chords, including the demo toggle-off release that fires after
     `demoModeProvider` has already flipped to false.
   - Preserves the full best-first `candidates` list (cost gaps intact) and the
     analysis-time `tonality`.
   - Enforces `historyCapacity`; `recentEvents(window)` filters by age at read
     time.
8. **Stop and validate**: verify events are recorded correctly with tests and,
   if useful during development, temporary debug output that is removed before
   the PR is complete.

### Phase 2 (future PRs, in order)

1. Build fixtures: extend the When in Rome tooling
   (`tool/when_in_rome_chord_benchmark.py` / `when_in_rome_chord_batch.dart`) to
   emit labeled `ChordEvent` fixtures; hand-author the pop/jazz set
2. Build the offline harness and metrics (MIREX weighting, local-key accuracy,
   modulation lag, stability, time-to-first-claim)
3. Implement profile correlation (`KeyEstimator.ksProfile`) as the floor, with
   the profile pair as a parameter (Krumhansl-Kessler, Temperley,
   Albrecht-Shanahan)
4. Implement weighted evidence model (`KeyEstimator.weightedEvidence`)
5. A/B on the harness, then add the provider that reads history and returns an
   inferred `(Tonality, confidence)?` plus the subtle home-page indicator
6. Grow toward progression detectors (2e) and the HMM (2c) as harness results
   justify

---

## Open Questions

- [ ] Retention: `historyCapacity` (the single stored memory cap) plus a default
      read window for `recentEvents`. With the identity-change model, ~100
      events is a few minutes of active playing. Phase 1 shipped with
      `historyCapacityProvider` = 100 and `historyMinChordDurationProvider` =
      200 ms (the latter doing double duty as the challenger-stabilization
      debounce and the commit minimum; split it into two providers if tuning
      ever needs them apart). The default detection window is still a Phase 2
      decision.
- [x] Chord event boundary for Phase 1: **commit on identity change**, with
      release as one more commit trigger, so pedaled/legato progressions are
      captured as a sequence. Stabilization (debounce + minimum duration) is
      part of Phase 1.
- [x] Should lookup pad chords go into history, or only live MIDI? Live MIDI
      only. Lookup and demo chords are display/interaction aids, not evidence
      for real-time key detection.
- [x] Privacy: is there any concern about recording played chords in memory?
      Resolved: in-memory only and never persisted to disk, in Phase 1 and
      beyond (see 1e). History is a transient session signal, so there is
      nothing to leak.

---

## References

Profile / distributional key finding:

- Krumhansl, C. L. (1990). _Cognitive Foundations of Musical Pitch_. Oxford
  University Press. Source of the original Krumhansl-Kessler probe-tone profiles
  behind 2a.
- Temperley, D. (1999).
  ["What's Key for Key? The Krumhansl-Schmuckler Key-Finding Algorithm Reconsidered"](https://doi.org/10.2307/40285812).
  _Music Perception_ 17(1). Duration weighting, revised profiles, and a catalog
  of the base algorithm's failure modes.
- Albrecht, J., & Shanahan, D. (2013).
  ["The Use of Large Corpora to Train a New Type of Key-Finding Algorithm"](https://online.ucpress.edu/mp/article-abstract/31/1/59/62597/The-Use-of-Large-Corpora-to-Train-a-New-Type-of).
  _Music Perception_ 31(1). Corpus-trained profiles, notably better in minor;
  the recommended default profile pair for 2a.

Sequence / probabilistic models:

- Temperley, D. (2007). _Music and Probability_. MIT Press. The Bayesian
  key-finding framework behind 2b (earlier form: "A Bayesian Approach to
  Key-Finding", ICMAI 2002).
- Raphael, C., & Stoddard, J. (2004). "Functional Harmonic Analysis Using
  Probabilistic Models". _Computer Music Journal_ 28(3). HMM harmonic analysis
  with chord-level observables, the precedent for 2c's chord-identity emissions.
- Nápoles López, N., Arthur, C., & Fujinaga, I. (2019).
  ["Key-Finding Based on a Hidden Markov Model and Key Profiles"](https://napulen.github.io/media/justkeydding/napoles19key.pdf)
  (DLfM 2019, [ACM page](https://dl.acm.org/doi/10.1145/3358664.3358675)).
  Reference implementation:
  [justkeydding](https://github.com/napulen/justkeydding). Global and local key
  from an HMM with profile emissions; the closest published analogue of 2c.

Geometric / real-time:

- Chew, E. (2000/2014). The
  [Spiral Array model](https://en.wikipedia.org/wiki/Spiral_array_model) and
  Center of Effect Generator
  ([overview](https://eniale.kcl.ac.uk/spiral-array-model/)). Real-time key
  finding as nearest-neighbor search in a tonal space; also covers pitch
  spelling and key-boundary detection, both adjacent to this plan's later
  phases.

Functional harmony / local key (state of the art, symbolic):

- Micchi, G., Gotham, M., & Giraud, M. (2020).
  ["Not All Roads Lead to Rome: Pitch Representation and Model Architecture for Automatic Harmonic Analysis"](https://transactions.ismir.net/articles/10.5334/tismir.45).
  _TISMIR_ 3(1). Frames local key as one head of a joint harmonic-analysis task,
  the mature version of 2e's "function is key-relative" argument.
- Nápoles López, N., Gotham, M., & Fujinaga, I. (2021).
  ["AugmentedNet"](https://archives.ismir.net/ismir2021/paper/000050.pdf) (ISMIR
  2021, [code](https://github.com/napulen/AugmentedNet)). Multitask
  Roman-numeral network with an explicit local-key task; its evaluation
  conventions are worth mirroring in the harness even though a neural model is
  out of scope in-app.
- Bouquillard, A., & Jacquemard, F. (2024).
  ["Engraving Oriented Joint Estimation of Pitch Spelling and Local and Global Keys"](https://arxiv.org/abs/2402.10247)
  (TENOR 2024). Joint spelling + local/global key from MIDI via dynamic
  programming; directly relevant to the spelling feedback loop.

Ground-truth corpora:

- Gotham, M., et al. (2023).
  ["When in Rome: A Meta-corpus of Functional Harmony"](https://transactions.ismir.net/articles/10.5334/tismir.165).
  _TISMIR_. Repo:
  [MarkGotham/When-in-Rome](https://github.com/MarkGotham/When-in-Rome). Already
  wired into `tool/when_in_rome_chord_benchmark.py`; RomanText annotations carry
  per-event local keys and modulation boundaries.
- Tymoczko, D., Gotham, M., Cuthbert, M. S., & Ariza, C. (2019).
  ["The RomanText Format: A Flexible and Standard Method for Representing Roman Numeral Analyses"](https://dspace.mit.edu/bitstream/handle/1721.1/137847/romantext.pdf)
  (ISMIR 2019). The annotation syntax the fixture extractor will parse (via
  music21).
- Foscarin, F., et al. (2020).
  ["ASAP: A Dataset of Aligned Scores and Performances for Piano Transcription"](https://archives.ismir.net/ismir2020/paper/000127.pdf)
  (ISMIR 2020). Repo:
  [fosfrancesco/asap-dataset](https://github.com/fosfrancesco/asap-dataset).
  Real performed piano MIDI aligned to scores, with key-signature change
  annotations; the bridge from score-derived fixtures to realistic live input
  (see Research Framing).

Evaluation:

- [MIREX Audio Key Detection task](https://music-ir.org/mirex/wiki/2019:Audio_Key_Detection)
  (music-ir.org wiki; the task definition is stable across years). Source of the
  standard near-miss weighting for key evaluation: same 1.0, perfect fifth 0.5,
  relative major/minor 0.3, parallel major/minor 0.2, other 0.0.
