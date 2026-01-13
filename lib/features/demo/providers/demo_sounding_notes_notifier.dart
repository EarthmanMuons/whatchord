import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_mode_notifier.dart';

/// Unified type: current sounding MIDI notes (unsorted set).
final demoSoundingNotesProvider =
    NotifierProvider<DemoSoundingNotesNotifier, Set<int>>(
      DemoSoundingNotesNotifier.new,
    );

class DemoStep {
  final Set<int> notes;

  const DemoStep({required this.notes});
}

class DemoSoundingNotesNotifier extends Notifier<Set<int>> {
  int _i = 0;

  // A short loop designed to exercise:
  // - single note
  // - dyad interval
  // - triad
  // - seventh
  // - inversion (slash bass)
  // - ambiguity / near-tie style pitch sets
  static final List<DemoStep> _steps = <DemoStep>[
    // Single note (C)
    DemoStep(notes: {60}),

    // Dyad (C to G -> P5)
    DemoStep(notes: {60, 67}),

    // Major triad; root position (C E G -> C)
    DemoStep(notes: {60, 64, 67}),

    // Major triad; 1st inversion (E G C -> C / E)
    DemoStep(notes: {64, 67, 72}),

    // Scale degree logic in C major (G B D -> G7)
    DemoStep(notes: {55, 59, 62, 65}),

    // Ambiguous C6/9 or Am11 / C depending on tonality (C E G A D -> ...)
    DemoStep(notes: {48, 57, 60, 64, 67, 74}),

    // Stable despite tonality (F# C E Bb -> C7#11 / F#)
    DemoStep(notes: {54, 60, 64, 70}),

    // Fully diminished symmetrical (Eb Gb Bbb Dbb -> Ebdim7)
    DemoStep(notes: {51, 54, 57, 60}),
  ];

  @override
  Set<int> build() {
    final enabled = ref.watch(demoModeProvider);
    if (!enabled) {
      _i = 0;
      return const <int>{};
    }

    return {..._steps[_i].notes};
  }

  /// Advance to the next demo step (wraps around).
  void next() {
    if (!ref.read(demoModeProvider)) return;
    _setStep(_i + 1);
  }

  /// Go to the previous demo step (wraps around).
  void prev() {
    if (!ref.read(demoModeProvider)) return;
    _setStep(_i - 1);
  }

  /// Jump to an explicit step index (wraps around).
  void goTo(int index) {
    if (!ref.read(demoModeProvider)) return;
    _setStep(index);
  }

  /// Reset to step 0 (and apply it).
  void reset() {
    if (!ref.read(demoModeProvider)) return;
    _setStep(0);
  }

  void _setStep(int index) {
    final len = _steps.length;
    if (len == 0) {
      _i = 0;
      state = const <int>{};
      return;
    }

    // True modulo wrap for negative indices.
    _i = ((index % len) + len) % len;

    // Copy to avoid leaking mutable backing sets.
    state = {..._steps[_i].notes};
  }
}
