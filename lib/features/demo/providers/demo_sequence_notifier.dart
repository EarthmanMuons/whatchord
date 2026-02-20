import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/domain/models/tonality.dart';

import 'demo_mode_variant_notifier.dart';

final demoSequenceProvider =
    NotifierProvider<DemoSequenceNotifier, DemoSequenceState>(
      DemoSequenceNotifier.new,
    );

final demoCurrentStepProvider = Provider<DemoStep>((ref) {
  final steps = ref.watch(demoStepsProvider);
  final index = ref.watch(demoSequenceProvider.select((state) => state.index));
  if (steps.isEmpty || index < 0 || index >= steps.length) {
    return const DemoStep();
  }
  return steps[index];
});

final demoStepsProvider = Provider<List<DemoStep>>((ref) {
  final variant = ref.watch(demoModeVariantProvider);
  return switch (variant) {
    DemoModeVariant.interactive => DemoSequenceNotifier.interactiveSteps,
    DemoModeVariant.screenshot => DemoSequenceNotifier.screenshotSteps,
  };
});

class DemoSequenceState {
  final int index;

  const DemoSequenceState({required this.index});
}

class DemoStep {
  final Set<int>? notes;
  final bool? pedalDown;
  final ThemeMode? themeMode;
  final Tonality? tonality;
  final String? promptText;

  const DemoStep({
    this.notes,
    this.pedalDown,
    this.themeMode,
    this.tonality,
    this.promptText,
  });
}

class DemoSequenceNotifier extends Notifier<DemoSequenceState> {
  static final List<DemoStep> screenshotSteps = <DemoStep>[
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
      pedalDown: false,
      themeMode: ThemeMode.dark,
      tonality: Tonality('E', TonalityMode.minor),
    ),

    // 4) SCREENSHOT: landscape, light mode, Key: C major, C7#11 / F#
    const DemoStep(
      notes: {54, 58, 60, 64},
      pedalDown: true,
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 5) SCREENSHOT: portrait, light mode, Key: C major, C7#11 / F# (details screen)

    // Fully diminished symmetrical (Eb Gb Bbb Dbb -> Ebdim7)
    const DemoStep(notes: {51, 54, 57, 60}),
  ];

  static final List<DemoStep> interactiveSteps = <DemoStep>[
    const DemoStep(
      notes: {},
      promptText: 'Use the arrows to explore chord examples.',
    ),
    const DemoStep(
      notes: {60},
      promptText: 'A single note does not form a chord.',
    ),
    const DemoStep(notes: {60, 67}, promptText: 'Two notes form an interval.'),
    const DemoStep(
      notes: {60, 64, 67},
      promptText: 'Three notes form a triad.',
    ),
    const DemoStep(
      notes: {64, 67, 72},
      promptText: 'Inversions are detected automatically.',
    ),
    const DemoStep(
      notes: {60, 62, 64, 67, 69},
      promptText: 'Extensions and alterations are recognized.',
    ),
    const DemoStep(
      notes: {54, 57, 60, 64},
      promptText: 'Even complex harmonies are analyzed correctly.',
    ),
  ];

  @override
  DemoSequenceState build() {
    ref.listen<DemoModeVariant>(demoModeVariantProvider, (previous, next) {
      if (previous == null || previous == next) return;
      reset();
    });

    return const DemoSequenceState(index: 0);
  }

  DemoStep get currentStep {
    final steps = ref.read(demoStepsProvider);
    final index = state.index;
    if (steps.isEmpty || index < 0 || index >= steps.length) {
      return const DemoStep();
    }
    return steps[index];
  }

  void next() => _setIndex(state.index + 1);
  void prev() => _setIndex(state.index - 1);

  void goTo(int index) => _setIndex(index);
  void reset() => goTo(0);

  void _setIndex(int index) {
    final len = ref.read(demoStepsProvider).length;
    if (len == 0) return;

    final nextIndex = ((index % len) + len) % len;
    state = DemoSequenceState(index: nextIndex);
  }
}
