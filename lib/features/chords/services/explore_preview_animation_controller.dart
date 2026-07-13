import 'package:flutter/foundation.dart';

import 'package:whatchord_app/core/core.dart';

@immutable
class ExplorePreviewAnimationState {
  const ExplorePreviewAnimationState({
    required this.activeNotes,
    required this.isRunning,
  });

  static const idle = ExplorePreviewAnimationState(
    activeNotes: <int>{},
    isRunning: false,
  );

  final Set<int> activeNotes;
  final bool isRunning;
}

class ExplorePreviewAnimationController {
  ExplorePreviewAnimationController({required this.onChanged});

  static const Duration _previewDuration = Duration(milliseconds: 1400);
  static const Duration _rolledPreviewStep = Duration(milliseconds: 180);
  static const Duration _rolledPreviewNoteDuration = Duration(
    milliseconds: 220,
  );
  static const Duration _rolledPreviewBlockGap = Duration(milliseconds: 260);
  static const Duration _rolledPreviewBlockDuration = Duration(
    milliseconds: 1400,
  );

  final ValueChanged<ExplorePreviewAnimationState> onChanged;
  final CancelableTimerSequence _timers = CancelableTimerSequence();

  ExplorePreviewAnimationState _state = ExplorePreviewAnimationState.idle;

  ExplorePreviewAnimationState get state => _state;

  void start(List<int> previewNotes) {
    final notes =
        previewNotes.map((note) => note.clamp(0, 127)).toSet().toList()..sort();
    if (notes.isEmpty) return;

    final generation = _timers.restart();

    void setActive(Set<int> notes) {
      _setState(
        ExplorePreviewAnimationState(
          activeNotes: Set<int>.unmodifiable(notes),
          isRunning: true,
        ),
      );
    }

    if (notes.length == 1) {
      setActive(notes.toSet());
      _timers.schedule(_previewDuration, finish, generation: generation);
      return;
    }

    final activeNotes = <int>{};
    for (var i = 0; i < notes.length; i++) {
      final midiNote = notes[i];
      final noteStart = _rolledPreviewStep * i;
      _timers.schedule(noteStart, (_) {
        activeNotes.add(midiNote);
        setActive(activeNotes);
      }, generation: generation);
      _timers.schedule(noteStart + _rolledPreviewNoteDuration, (_) {
        activeNotes.remove(midiNote);
        setActive(activeNotes);
      }, generation: generation);
    }

    final blockStart =
        _rolledPreviewStep * notes.length + _rolledPreviewBlockGap;
    _timers.schedule(
      blockStart,
      (_) => setActive(notes.toSet()),
      generation: generation,
    );
    _timers.schedule(
      blockStart + _rolledPreviewBlockDuration,
      finish,
      generation: generation,
    );
  }

  void finish(int generation) {
    if (!_timers.isCurrent(generation)) return;
    _setState(ExplorePreviewAnimationState.idle);
    _timers.cancel();
  }

  void cancel({bool notify = true}) {
    _timers.cancel();
    if (!notify) {
      _state = ExplorePreviewAnimationState.idle;
      return;
    }
    _setState(ExplorePreviewAnimationState.idle);
  }

  void dispose() {
    _timers.dispose();
  }

  void _setState(ExplorePreviewAnimationState state) {
    if (_state.activeNotes == state.activeNotes &&
        _state.isRunning == state.isRunning) {
      return;
    }
    _state = state;
    onChanged(state);
  }
}
