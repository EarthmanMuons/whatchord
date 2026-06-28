# Temporal Context and Key Detection: Implementation Plan

## Current State

WhatChord is a **stateless real-time analyzer**: each MIDI event triggers a
re-analysis, but no memory is kept between chord changes. The user manually sets
the tonality/key signature, which drives spellings but not analysis.

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
- `ChordCandidate`: identity + score
- `AnalysisContext`: tonality + keySignature + spellingPolicy (all user-set)
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
  final ObservedVoicing? voicing;     // live voicing; null only for a lone note
  final List<ChordCandidate> candidates; // ranked, best-first
  final Duration duration;            // how long this identity persisted

  ChordIdentity get identity => candidates.first.identity;
  double get score => candidates.first.score;
}
```

This captures everything a key-detection algorithm needs: raw notes, the ranked
identification with confidence, timing, and hold duration.

Store a single best-first `candidates` list and expose `identity`/`score` as
getters rather than as separate stored fields. This keeps one source of truth
and lets key detection use score gaps and confidence weighting without
re-running analysis.

`voicing` is nullable only for the lone-note case (the provider needs 2+ notes).
Because history records live MIDI only and gates out lookup/demo, a committed
chord event effectively always carries a voicing. When implementing, decide
whether single sustained notes are ever committed: if not, tighten `voicing` to
non-nullable and drop the lone-note case.

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
  using the same threshold.
- The previous identity is committed when the _new_ one appears, while notes are
  still sounding, so there is no empty-providers-on-release case to handle.
- `duration` is the time the identity was actually held, which Phase 2 weights
  by.
- Sustain pedal follows existing MIDI note-state semantics: pedal-held notes
  stay in the sounding set, so identity changes (and the final release) are
  driven by that merged set exactly as analysis already sees it.

**Stabilization.** To avoid recording finger-rolls and passing voicings, apply a
short debounce/hysteresis on identity changes and a minimum-duration threshold
before a snapshot is eligible to commit.

#### Live-only gating happens at capture, not at commit

Lookup and demo input must never enter history. The subtlety is that gating has
to guard _snapshot capture_, not the commit:

- There is no live-MIDI-only sounding-note provider today.
  `soundingNoteNumbersProvider` / `soundingNotesProvider` already **merge** demo
  and lookup notes in, and `chordInputProvider` includes lookup notes (only
  `observedVoicingProvider` excludes lookup). So both demo and lookup _do_ flow
  through `chordCandidatesProvider`; reusing the analysis chain without gating
  would leak them into history.
- Commit-time gating is not enough. `InputIdleNotifier.markIdleNow()` fires a
  release the instant demo/lookup toggles _off_, by which point
  `demoModeProvider` has already flipped to `false`. A commit-time
  `if (demoMode) skip` check would fail to skip and commit a stale demo chord.
- Therefore: **only ever update the in-progress snapshot while
  `!demoModeProvider && !lookupActiveProvider`.** With capture gated this way
  the toggle-timing race disappears and the flags do double duty. The cleaner
  long-term option is a dedicated live-only input provider feeding history; the
  capture-time flag check is the minimum and is required regardless.

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

## Phase 2: Key Detection Engine (future)

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
correlation score). The K-S profiles are 24 constant vectors (12 major + 12
minor).

Weighting strategies to implement:

- **Flat**: each event contributes equally to the pitch-class histogram.
- **Decay-weighted**: recent events contribute more. Exponential decay with a
  half-life of ~30 seconds. The decay is applied to the histogram bins, so older
  events fade out of the correlation naturally.

### 2b. Temperley Bayesian approach

```
P(key | events) ∝ P(events | key) × P(key)
```

For each candidate key, compute the likelihood of observing the chord sequence.
Uses chord root + quality as observables. `ScaleDegreeClassifier` already knows
which scale degrees are diatonic to a key, so likelihood estimation builds on
existing infrastructure.

Uniform prior over keys, or optionally a prior favoring closely-related keys
from the previously detected key (smooth transitions).

### 2c. Hidden Markov Model / Viterbi

Most sophisticated option. Models the key as a hidden state with:

- **Transition probabilities**: higher for circle-of-fifths neighbors, lower for
  distant keys.
- **Emission probabilities**: chord identities are more likely in certain keys
  (e.g. a `dominant7` on G is extremely likely in C major).

Viterbi decoding finds the most probable key sequence given the chord sequence.
More complex to implement and tune but handles key changes cleanly.

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
   can override.

2. **Should all events contribute, or only those with strong confidence?** A
   score threshold (e.g. only events where best candidate beats 2nd best by a
   clear margin) may improve signal quality.

3. **Which algorithm to implement first?** The weighted evidence model (2d) is
   the simplest to implement and validate. It can serve as a baseline while more
   sophisticated algorithms (2a/2b) are built and compared.

### Notes on Algorithm Tuning

- Chord voicings with ambiguous identities (low-confidence near-ties) should be
  weighted less or excluded from the key detection signal. The full best-first
  `candidates` list is retained precisely so an algorithm can measure the
  best-to-second score gap and down-weight near-ties without re-analyzing.
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
  (2a/2b/2d) and meant to be A/B compared, build a small offline harness that
  replays a recorded `List<ChordEvent>` (or a hand-authored fixture of known
  progressions with labeled keys) through each estimator. That makes the
  comparison reproducible and keeps tuning out of live-playing guesswork. The
  `ChordEvent` model serializes cleanly (1e), so capturing these dev fixtures is
  straightforward even though runtime history is never persisted.
- **Spelling feedback loop (later).** Once a key is inferred with confidence, it
  could optionally drive `AnalysisContext` spelling (the thing the user sets
  manually today), closing the loop from detection back to presentation. This is
  explicitly a separate decision from Phase 2's detection work (see Decision
  Point 1), but it is the natural payoff and worth keeping in view so the
  inferred-key type stays compatible with the manual `Tonality`/`KeySignature`
  the spelling policy already consumes.

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
   - Preserves the full best-first `candidates` list (score gaps intact).
   - Enforces `historyCapacity`; `recentEvents(window)` filters by age at read
     time.
8. **Stop and validate**: verify events are recorded correctly with tests and,
   if useful during development, temporary debug output that is removed before
   the PR is complete.

### Phase 2 (future PRs, in order)

1. Implement weighted evidence model (`KeySignatureEstimator.weightedEvidence`)
2. Add provider that reads history and returns inferred `Tonality?`
3. Add subtle UI indicator on home page
4. Implement K-S profile correlation for comparison
5. A/B compare algorithms on real playing sessions

---

## Open Questions

- [ ] Retention: `historyCapacity` (the single stored memory cap) plus a default
      read window for `recentEvents`. With the identity-change model, ~100
      events is a few minutes of active playing; confirm the cap default
      (`historyCapacityProvider`) and the default detection window.
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
