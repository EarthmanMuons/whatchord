import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_mode_notifier.dart';
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
  static const Duration _noteOnSpacing = Duration(milliseconds: 200);
  static const Duration _resetGap = Duration(milliseconds: 50);

  Timer? _timer;
  int _transitionEpoch = 0;
  Set<int> _soundingNoteNumbers = const <int>{};
  bool _isPedalDown = false;

  @override
  DemoNoteState build() {
    ref.onDispose(_cancelTimer);

    final initialStep = _stepForCurrentIndex();
    _isPedalDown = initialStep.pedalDown ?? false;
    final initialState = DemoNoteState(
      soundingNoteNumbers: _soundingNoteNumbers,
      isPedalDown: _isPedalDown,
    );

    ref.listen<bool>(demoModeProvider, (previous, next) {
      if (!next) {
        _cancelTimer();
        _transitionEpoch++;
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
    _cancelTimer();
    _transitionEpoch++;
    final epoch = _transitionEpoch;

    // Force a clean note-off baseline before arpeggiating into the next step.
    _soundingNoteNumbers = const <int>{};
    _commitState();

    if (nextNotes.isEmpty) return;

    final orderedNotes = nextNotes.toList()..sort();
    var index = 0;

    void scheduleNext(Duration delay) {
      _timer = Timer(delay, () {
        if (epoch != _transitionEpoch) return;

        _soundingNoteNumbers = Set<int>.unmodifiable({
          ..._soundingNoteNumbers,
          orderedNotes[index],
        });
        _commitState();
        index++;
        if (index >= orderedNotes.length) {
          _timer = null;
          return;
        }
        scheduleNext(_noteOnSpacing);
      });
    }

    scheduleNext(_resetGap);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
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
