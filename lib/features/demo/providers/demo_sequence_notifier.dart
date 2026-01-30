import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/domain/models/tonality.dart';

final demoSequenceProvider =
    NotifierProvider<DemoSequenceNotifier, DemoSequenceState>(
      DemoSequenceNotifier.new,
    );

class DemoSequenceState {
  final int index;

  const DemoSequenceState({required this.index});
}

class DemoStep {
  final Set<int>? notes;
  final ThemeMode? themeMode;
  final Tonality? tonality;

  const DemoStep({this.notes, this.themeMode, this.tonality});
}

class DemoSequenceNotifier extends Notifier<DemoSequenceState> {
  static final List<DemoStep> steps = <DemoStep>[
    // 1) SCREENSHOT: portrait, light mode, Key: C major, C major
    const DemoStep(
      notes: {60, 64, 67},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 2) SCREENSHOT: portrait, dark mode, Key: C major, Am / C
    const DemoStep(
      notes: {60, 64, 69},
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 3) SCREENSHOT: landscape, dark mode, Key: E minor, F#m7(b5)
    const DemoStep(
      notes: {54, 57, 60, 64},
      themeMode: ThemeMode.dark,
      tonality: Tonality('E', TonalityMode.minor),
    ),

    // 4) SCREENSHOT: landscape, light mode, Key: C major, C7#11 / F#
    const DemoStep(
      notes: {54, 58, 60, 64},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 5) SCREENSHOT: portrait, light mode, Key: C major, C7#11 / F# (details screen)

    // Ambiguous C6/9 or Am11 / C depending on tonality (C E G A D -> ...)
    const DemoStep(
      notes: {48, 57, 60, 64, 67, 74},
      tonality: Tonality('C', TonalityMode.major),
    ),
    const DemoStep(
      notes: {48, 57, 60, 64, 67, 74},
      tonality: Tonality('A', TonalityMode.minor),
    ),

    // Fully diminished symmetrical (Eb Gb Bbb Dbb -> Ebdim7)
    const DemoStep(notes: {51, 54, 57, 60}),

    // Single note (C)
    const DemoStep(notes: {60}, tonality: Tonality('C', TonalityMode.major)),

    // // Dyad (C to E -> M3)
    const DemoStep(
      notes: {60, 64},
      tonality: Tonality('C', TonalityMode.major),
    ),
  ];

  @override
  DemoSequenceState build() {
    return const DemoSequenceState(index: 0);
  }

  DemoStep get currentStep => steps[state.index];

  void next() => _setIndex(state.index + 1);
  void prev() => _setIndex(state.index - 1);

  void goTo(int index) => _setIndex(index);
  void reset() => goTo(0);

  void _setIndex(int index) {
    final len = steps.length;
    if (len == 0) return;

    final nextIndex = ((index % len) + len) % len;
    state = DemoSequenceState(index: nextIndex);
  }
}
