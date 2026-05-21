import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

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
    DemoModeVariant.animation => DemoSequenceNotifier.animationSteps,
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
  static final List<DemoStep> animationSteps = <DemoStep>[
    // Dm7 -- ii chord, root position
    const DemoStep(
      notes: {62, 65, 69, 72},
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),
    // G7/B -- V chord, first inversion
    const DemoStep(
      notes: {59, 62, 65, 67},
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),
    // Cmaj7 -- I chord, root position
    const DemoStep(
      notes: {60, 64, 67, 71},
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),
  ];

  static final List<DemoStep> screenshotSteps = <DemoStep>[
    // 1) SCREENSHOT: portrait, light mode, Key: C major -> C major
    const DemoStep(
      notes: {60, 64, 67},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 2) SCREENSHOT: portrait, dark mode, Key: C major -> G7/B
    const DemoStep(
      notes: {59, 62, 65, 67},
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 3) SCREENSHOT: portrait, light mode, Key: C major -> C6/9, explore mode
    const DemoStep(
      notes: {60, 64, 67, 69, 74},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 4) SCREENSHOT: landscape, dark mode, Key: C major -> Bm7(b5)
    const DemoStep(
      notes: {59, 62, 65, 69},
      pedalDown: true,
      themeMode: ThemeMode.dark,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 5) SCREENSHOT: landscape, light mode, Key: C major -> G7b9
    const DemoStep(
      notes: {55, 59, 62, 65, 68},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),

    // 6) SCREENSHOT: portrait, light mode, Key: C major -> Bm7(b5), why this chord
    const DemoStep(
      notes: {59, 62, 65, 69},
      themeMode: ThemeMode.light,
      tonality: Tonality('C', TonalityMode.major),
    ),
  ];

  static final List<DemoStep> interactiveSteps = <DemoStep>[
    const DemoStep(
      notes: {},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Use the arrows to explore chord examples.',
    ),
    // C, note
    const DemoStep(
      notes: {60},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Each note is analyzed in its musical context.',
    ),
    // Perfect 5th, interval
    const DemoStep(
      notes: {60, 67},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Two notes create an interval.',
    ),
    // C major, chord
    const DemoStep(
      notes: {60, 64, 67},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Three notes create a chord.',
    ),
    // C/E, inversion
    const DemoStep(
      notes: {64, 67, 72},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Chord inversions are detected automatically.',
    ),
    // C6/9, extended
    const DemoStep(
      notes: {60, 64, 67, 69, 74},
      tonality: Tonality('C', TonalityMode.major),
      promptText: 'Extended and altered chords are recognized.',
    ),
    // Bm7(b5)
    const DemoStep(
      notes: {59, 62, 65, 69},
      tonality: Tonality('C', TonalityMode.major),
      promptText:
          'Complex chords are analyzed accurately.\nAlternative interpretations may also be shown.',
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
