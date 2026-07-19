import 'package:flutter/foundation.dart';

import 'cancelable_timer_sequence.dart';
import 'preview_timings.dart';

@immutable
class PreviewAnimationState {
  const PreviewAnimationState({
    required this.activeNotes,
    required this.isRunning,
  });

  static const idle = PreviewAnimationState(
    activeNotes: <int>{},
    isRunning: false,
  );

  final Set<int> activeNotes;
  final bool isRunning;
}

/// Drives keyboard and tone highlights in step with audible previews.
///
/// The audio monitor schedules its own timer chain for the sound; both sides
/// read [PreviewTimings] so the highlight tracks the notes as they play.
class PreviewAnimationController {
  PreviewAnimationController({required this.onChanged});

  final ValueChanged<PreviewAnimationState> onChanged;
  final CancelableTimerSequence _timers = CancelableTimerSequence();

  PreviewAnimationState _state = PreviewAnimationState.idle;

  PreviewAnimationState get state => _state;

  /// Rolls each chord note in turn, then holds the full chord. A single note
  /// is simply held, matching the audio monitor's rolled preview.
  void startChord(List<int> previewNotes) {
    final notes =
        previewNotes.map((note) => note.clamp(0, 127)).toSet().toList()..sort();
    if (notes.isEmpty) return;

    final generation = _timers.restart();

    void setActive(Set<int> notes) {
      _setState(
        PreviewAnimationState(
          activeNotes: Set<int>.unmodifiable(notes),
          isRunning: true,
        ),
      );
    }

    if (notes.length == 1) {
      setActive(notes.toSet());
      _timers.schedule(PreviewTimings.hold, finish, generation: generation);
      return;
    }

    final activeNotes = <int>{};
    for (var i = 0; i < notes.length; i++) {
      final midiNote = notes[i];
      final noteStart = PreviewTimings.rolledStep * i;
      _timers.schedule(noteStart, (_) {
        activeNotes.add(midiNote);
        setActive(activeNotes);
      }, generation: generation);
      _timers.schedule(noteStart + PreviewTimings.rolledNoteDuration, (_) {
        activeNotes.remove(midiNote);
        setActive(activeNotes);
      }, generation: generation);
    }

    final blockStart =
        PreviewTimings.rolledStep * notes.length +
        PreviewTimings.rolledBlockGap;
    _timers.schedule(
      blockStart,
      (_) => setActive(notes.toSet()),
      generation: generation,
    );
    _timers.schedule(
      blockStart + PreviewTimings.rolledBlockDuration,
      finish,
      generation: generation,
    );
  }

  /// Steps a single-note highlight through a melodic run, preserving order.
  void startRun(List<int> previewNotes) {
    final notes = [for (final note in previewNotes) note.clamp(0, 127)];
    if (notes.isEmpty) return;

    final generation = _timers.restart();
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      _timers.schedule(PreviewTimings.sequenceStep * i, (_) {
        _setState(PreviewAnimationState(activeNotes: {note}, isRunning: true));
      }, generation: generation);
    }
    _timers.schedule(
      PreviewTimings.sequenceStep * notes.length,
      finish,
      generation: generation,
    );
  }

  void finish(int generation) {
    if (!_timers.isCurrent(generation)) return;
    _setState(PreviewAnimationState.idle);
    _timers.cancel();
  }

  void cancel() {
    _timers.cancel();
    _setState(PreviewAnimationState.idle);
  }

  void dispose() {
    _timers.dispose();
  }

  void _setState(PreviewAnimationState state) {
    if (_state.isRunning == state.isRunning &&
        setEquals(_state.activeNotes, state.activeNotes)) {
      return;
    }
    _state = state;
    onChanged(state);
  }
}
