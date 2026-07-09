import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/history/history.dart';
import 'package:whatchord/features/theory/theory.dart';

import 'inferred_key_notifier.dart';
import 'key_mode_notifier.dart';

final keyScreenshotSeedProvider =
    NotifierProvider<KeyScreenshotSeedNotifier, bool>(
      KeyScreenshotSeedNotifier.new,
    );

/// Screenshot fixture for the auto key view (debug/profile builds only).
///
/// Key detection listens only to live play, which emulators cannot provide,
/// so marketing screenshots of the posterior heatmap need a reproducible
/// stand-in. Seeding records a scripted G major phrase into chord history
/// exactly as live capture would (real analyzer candidates, real detector),
/// so the wheel, strip, status, and recent chords all show genuine output.
/// Toggling off clears the evidence and restores the pre-seed mode and
/// tonality, mirroring the home page demo snapshot behavior.
class KeyScreenshotSeedNotifier extends Notifier<bool> {
  _SeedSnapshot? _snapshot;

  @override
  bool build() => false;

  void toggle() {
    if (state) {
      _clear();
    } else {
      _seed();
    }
    state = !state;
  }

  void _seed() {
    _snapshot = _SeedSnapshot(
      mode: ref.read(keyModeProvider),
      tonality: ref.read(selectedTonalityProvider),
    );

    final history = ref.read(chordHistoryProvider.notifier);
    history.clear();
    ref.read(inferredKeyProvider.notifier).reset();
    unawaited(ref.read(keyModeProvider.notifier).setMode(KeyMode.auto));

    // Strictly after the reset marker so the recent chords strip re-seeds
    // these events when the page is reopened mid-session.
    final start = ref.read(historyClockProvider)();
    for (final (i, (notes, duration)) in _phrase.indexed) {
      history.record(
        _event(notes, start.add(Duration(milliseconds: i + 1)), duration),
      );
    }
  }

  void _clear() {
    final snapshot = _snapshot;
    _snapshot = null;

    ref.read(chordHistoryProvider.notifier).clear();
    ref.read(inferredKeyProvider.notifier).reset();
    if (snapshot == null) return;

    // setTonality updates state synchronously, so any knock-to-manual it
    // triggers has already happened before the mode is restored.
    unawaited(
      ref
          .read(selectedTonalityProvider.notifier)
          .setTonality(snapshot.tonality),
    );
    unawaited(ref.read(keyModeProvider.notifier).setMode(snapshot.mode));
  }

  /// A singer-songwriter run in G major: a Mixolydian bVII, a slash-bass
  /// walk-down, sus resolutions, and one secondary dominant. The claim stays
  /// clear (roughly 79% calibrated) while C, D, and the relative minors carry
  /// visible warmth, so the wheel reads as a graded posterior rather than a
  /// single lit cell, and the twelve chips overflow the strip so the scroll
  /// fade shows.
  static const _phrase = <(List<int>, Duration)>[
    ([43, 59, 62, 67], Duration(milliseconds: 1600)), // G
    ([41, 53, 57, 60], Duration(milliseconds: 1100)), // F
    ([48, 52, 55, 62], Duration(milliseconds: 1300)), // Cadd9
    ([47, 55, 62, 67], Duration(milliseconds: 800)), // G/B
    ([45, 55, 60, 64], Duration(milliseconds: 1200)), // Am7
    ([50, 55, 57, 60], Duration(milliseconds: 900)), // D7sus4
    ([38, 54, 57, 60], Duration(milliseconds: 1100)), // D7
    ([43, 54, 59, 62], Duration(milliseconds: 1800)), // Gmaj7
    ([40, 55, 62, 66], Duration(milliseconds: 1300)), // Em9
    ([45, 55, 61, 64], Duration(milliseconds: 1000)), // A7
    ([48, 52, 55, 59], Duration(milliseconds: 1400)), // Cmaj7
    ([50, 54, 57, 62], Duration(milliseconds: 2000)), // D
  ];

  /// Fixed ranking context so the fixture is identical regardless of the
  /// tonality selected on the device when the seed is toggled.
  static final _context = AnalysisContext(
    tonality: const Tonality(Tonic.c, TonalityMode.major),
    keySignature: const Tonality(Tonic.c, TonalityMode.major).keySignature,
    spellingPolicy: const NoteSpellingPolicy(preferFlats: false),
  );

  static ChordEvent _event(
    List<int> midiNotes,
    DateTime timestamp,
    Duration duration,
  ) {
    final sorted = [...midiNotes]..sort();
    var mask = 0;
    for (final note in sorted) {
      mask |= 1 << (note % 12);
    }
    final input = ChordInput(
      pcMask: mask,
      bassPc: sorted.first % 12,
      noteCount: sorted.length,
    );
    final voicing = ObservedVoicing.fromMidi(sorted);
    final candidates = ChordAnalyzer.analyze(
      input,
      context: _context,
      voicing: voicing,
    );
    return ChordEvent(
      timestamp: timestamp,
      input: input,
      voicing: voicing,
      candidates: [
        candidates.first,
        ...ChordCandidateRanking.alternatives(candidates),
      ],
      tonality: _context.tonality,
      duration: duration,
    );
  }
}

class _SeedSnapshot {
  final KeyMode mode;
  final Tonality tonality;

  const _SeedSnapshot({required this.mode, required this.tonality});
}
