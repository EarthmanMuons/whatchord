import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/services/cancelable_timer_sequence.dart';

import 'demo_mode_notifier.dart';
import 'demo_mode_variant_notifier.dart';
import 'demo_sequence_notifier.dart';

@immutable
class DemoNoteState {
  final Set<int> soundingNoteNumbers;
  final bool isPedalDown;

  const DemoNoteState({
    required this.soundingNoteNumbers,
    required this.isPedalDown,
  });

  DemoNoteState copyWith({Set<int>? soundingNoteNumbers, bool? isPedalDown}) {
    return DemoNoteState(
      soundingNoteNumbers: soundingNoteNumbers ?? this.soundingNoteNumbers,
      isPedalDown: isPedalDown ?? this.isPedalDown,
    );
  }
}

final demoNoteStateProvider =
    NotifierProvider<DemoNoteStateNotifier, DemoNoteState>(
      DemoNoteStateNotifier.new,
    );

class DemoNoteStateNotifier extends Notifier<DemoNoteState> {
  static const Duration _defaultNoteOnSpacing = Duration(milliseconds: 200);
  static const Duration _defaultResetGap = Duration(milliseconds: 50);
  static const Duration _animationNoteOnSpacing = Duration(milliseconds: 90);
  static const Duration _animationResetGap = Duration(milliseconds: 25);

  final CancelableTimerSequence _transitionSequence = CancelableTimerSequence();
  Set<int> _soundingNoteNumbers = const <int>{};
  bool _isPedalDown = false;

  @override
  DemoNoteState build() {
    ref.onDispose(_transitionSequence.dispose);

    final initialStep = _stepForCurrentIndex();
    _isPedalDown = initialStep.pedalDown ?? false;
    final initialState = DemoNoteState(
      soundingNoteNumbers: _soundingNoteNumbers,
      isPedalDown: _isPedalDown,
    );

    ref.listen<bool>(demoModeProvider, (previous, next) {
      if (!next) {
        _transitionSequence.cancel();
        _soundingNoteNumbers = const <int>{};
        _commitState();
        return;
      }

      _applyCurrentStep(transitionNotes: true);
    });

    ref.listen<DemoStep>(demoCurrentStepProvider, (previous, next) {
      if (identical(previous, next)) return;
      _applyCurrentStep(transitionNotes: ref.read(demoModeProvider));
    });

    if (ref.read(demoModeProvider)) {
      _applyCurrentStep(transitionNotes: true);
    }

    return initialState;
  }

  void togglePedal() => setPedalDown(!_isPedalDown);

  void setPedalDown(bool down) {
    _isPedalDown = down;
    _commitState();
  }

  void _applyCurrentStep({required bool transitionNotes}) {
    final step = _stepForCurrentIndex();
    _isPedalDown = step.pedalDown ?? false;
    _commitState();
    if (!transitionNotes) return;
    _transitionToNotes(step.notes ?? const <int>{});
  }

  DemoStep _stepForCurrentIndex() {
    return ref.read(demoCurrentStepProvider);
  }

  void _transitionToNotes(Set<int> nextNotes) {
    final generation = _transitionSequence.restart();

    // Force a clean note-off baseline before arpeggiating into the next step.
    _soundingNoteNumbers = const <int>{};
    _commitState();

    if (nextNotes.isEmpty) return;

    final orderedNotes = nextNotes.toList()..sort();
    final isAnimation =
        ref.read(demoModeVariantProvider) == DemoModeVariant.animation;
    final resetGap = isAnimation ? _animationResetGap : _defaultResetGap;
    final noteOnSpacing = isAnimation
        ? _animationNoteOnSpacing
        : _defaultNoteOnSpacing;

    for (var index = 0; index < orderedNotes.length; index++) {
      final note = orderedNotes[index];
      _transitionSequence.schedule(resetGap + noteOnSpacing * index, (_) {
        _soundingNoteNumbers = Set<int>.unmodifiable({
          ..._soundingNoteNumbers,
          note,
        });
        _commitState();
      }, generation: generation);
    }
  }

  void _commitState() {
    state = DemoNoteState(
      soundingNoteNumbers: _soundingNoteNumbers,
      isPedalDown: _isPedalDown,
    );
  }
}

final demoSoundingNoteNumbersProvider = Provider<Set<int>>((ref) {
  return ref.watch(
    demoNoteStateProvider.select((state) => state.soundingNoteNumbers),
  );
});

final demoPedalDownProvider = Provider<bool>((ref) {
  return ref.watch(demoNoteStateProvider.select((state) => state.isPedalDown));
});
