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
    // Single note (C4)
    DemoStep(notes: {60}),

    // Dyad (C4 -> G4 = P5)
    DemoStep(notes: {60, 67}),

    // C major triad (root position)
    DemoStep(notes: {60, 64, 67}),

    // Cmaj7 (root position)
    DemoStep(notes: {60, 64, 67, 71}),

    // Cmaj7/E (inversion; E3 is bass)
    DemoStep(notes: {52, 60, 64, 67, 71}),

    // G7 (dominant seventh; test scale-degree logic in C major)
    DemoStep(notes: {55, 59, 62, 65}),

    // Ambiguous-ish: C E G A D (Am11/C style pitch set)
    // C3 A3 C4 E4 G4 D5
    DemoStep(notes: {48, 57, 60, 64, 67, 74}),
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
