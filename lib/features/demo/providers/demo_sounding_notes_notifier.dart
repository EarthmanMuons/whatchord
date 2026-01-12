import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_mode_notifier.dart';

/// Unified type: current sounding MIDI notes (unsorted set).
final demoSoundingNotesProvider =
    NotifierProvider<DemoSoundingNotesNotifier, Set<int>>(
      DemoSoundingNotesNotifier.new,
    );

class DemoStep {
  final Set<int> notes;
  final Duration hold;

  const DemoStep({required this.notes, required this.hold});
}

class DemoSoundingNotesNotifier extends Notifier<Set<int>> {
  Timer? _timer;
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
    DemoStep(notes: {60}, hold: Duration(milliseconds: 1200)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 600)),

    // Dyad (C4 -> G4 = P5)
    DemoStep(notes: {60, 67}, hold: Duration(milliseconds: 1600)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 650)),

    // C major triad (root position)
    DemoStep(notes: {60, 64, 67}, hold: Duration(milliseconds: 1800)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 650)),

    // Cmaj7 (root position)
    DemoStep(notes: {60, 64, 67, 71}, hold: Duration(milliseconds: 2000)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 700)),

    // Cmaj7/E (inversion; E3 is bass)
    DemoStep(notes: {52, 60, 64, 67, 71}, hold: Duration(milliseconds: 2200)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 700)),

    // G7 (dominant seventh; test scale-degree logic in C major)
    DemoStep(notes: {55, 59, 62, 65}, hold: Duration(milliseconds: 2200)),
    DemoStep(notes: {}, hold: Duration(milliseconds: 700)),

    // Ambiguous-ish: C E G A D (Am11/C style pitch set)
    // C3 A3 C4 E4 G4 D5
    DemoStep(
      notes: {48, 57, 60, 64, 67, 74},
      hold: Duration(milliseconds: 2400),
    ),
    DemoStep(notes: {}, hold: Duration(milliseconds: 900)),
  ];

  @override
  Set<int> build() {
    // Watch demo mode; when it changes, this notifier rebuilds.
    final enabled = ref.watch(demoModeProvider);

    // Ensure we stop any existing timer on rebuild.
    _stopTimer();

    if (!enabled) {
      _i = 0;
      return const <int>{};
    }

    // Start sequence immediately.
    state = {..._steps[_i].notes};

    // Use a self-scheduling timer so each step can have its own duration.
    _scheduleNext();

    // Clean up when provider is disposed.
    ref.onDispose(_stopTimer);

    return state;
  }

  void _scheduleNext() {
    final step = _steps[_i];

    _timer = Timer(step.hold, () {
      // Advance.
      _i = (_i + 1) % _steps.length;
      state = _steps[_i].notes;

      // Continue.
      _scheduleNext();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
