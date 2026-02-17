import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_mode_notifier.dart';
import 'demo_sequence_notifier.dart';

final demoSoundingNoteNumbersProvider =
    NotifierProvider<DemoSoundingNoteNumbersNotifier, Set<int>>(
      DemoSoundingNoteNumbersNotifier.new,
    );

class DemoSoundingNoteNumbersNotifier extends Notifier<Set<int>> {
  static const Duration _noteOnSpacing = Duration(milliseconds: 100);
  static const Duration _resetGap = Duration(milliseconds: 50);

  Timer? _timer;
  int _transitionEpoch = 0;

  @override
  Set<int> build() {
    ref.onDispose(_cancelTimer);

    ref.listen<bool>(demoModeProvider, (previous, next) {
      if (!next) {
        _cancelTimer();
        _transitionEpoch++;
        state = const <int>{};
        return;
      }

      _transitionToCurrentStep();
    });

    ref.listen<DemoSequenceState>(demoSequenceProvider, (previous, next) {
      if (!ref.read(demoModeProvider)) return;
      if (previous?.index == next.index) return;
      _transitionToCurrentStep();
    });

    if (!ref.read(demoModeProvider)) return const <int>{};

    // Apply step notes with the same transition used for step changes.
    _transitionToCurrentStep();
    return const <int>{};
  }

  void _transitionToCurrentStep() {
    final seq = ref.read(demoSequenceProvider);
    final step = DemoSequenceNotifier.steps[seq.index];
    _transitionToNotes(step.notes ?? const <int>{});
  }

  void _transitionToNotes(Set<int> nextNotes) {
    _cancelTimer();
    _transitionEpoch++;
    final epoch = _transitionEpoch;

    // Force a clean note-off baseline before arpeggiating into the next step.
    state = const <int>{};

    if (nextNotes.isEmpty) return;

    final orderedNotes = nextNotes.toList()..sort();
    var index = 0;

    void scheduleNext(Duration delay) {
      _timer = Timer(delay, () {
        if (epoch != _transitionEpoch) return;

        state = Set<int>.unmodifiable({...state, orderedNotes[index]});
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
}
