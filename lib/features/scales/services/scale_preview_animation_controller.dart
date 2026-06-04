import 'package:flutter/foundation.dart';

import 'package:whatchord/core/core.dart';

@immutable
class ScalePreviewState {
  const ScalePreviewState({required this.activeNotes, required this.isRunning});

  static const idle = ScalePreviewState(activeNotes: <int>{}, isRunning: false);

  final Set<int> activeNotes;
  final bool isRunning;
}

/// Drives the keyboard and tone highlights in step with playback. The timings
/// mirror the audio monitor so the highlight tracks the notes as they sound.
class ScalePreviewAnimationController {
  ScalePreviewAnimationController({required this.onChanged});

  static const Duration _rolledStep = Duration(milliseconds: 180);
  static const Duration _rolledNoteDuration = Duration(milliseconds: 220);
  static const Duration _rolledBlockGap = Duration(milliseconds: 260);
  static const Duration _rolledBlockDuration = Duration(milliseconds: 1400);
  static const Duration _sequenceStep = Duration(milliseconds: 200);

  final ValueChanged<ScalePreviewState> onChanged;
  final CancelableTimerSequence _timers = CancelableTimerSequence();

  ScalePreviewState _state = ScalePreviewState.idle;

  /// Rolls each chord note in turn, then holds the full chord, matching the
  /// audio monitor's rolled chord preview.
  void startChord(List<int> notes) {
    if (notes.isEmpty) return;

    final generation = _timers.restart();
    final active = <int>{};

    void setActive(Set<int> notes) {
      _setState(
        ScalePreviewState(
          activeNotes: Set<int>.unmodifiable(notes),
          isRunning: true,
        ),
      );
    }

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final noteStart = _rolledStep * i;
      _timers.schedule(noteStart, (_) {
        active.add(note);
        setActive(active);
      }, generation: generation);
      _timers.schedule(noteStart + _rolledNoteDuration, (_) {
        active.remove(note);
        setActive(active);
      }, generation: generation);
    }

    final blockStart = _rolledStep * notes.length + _rolledBlockGap;
    _timers.schedule(
      blockStart,
      (_) => setActive(notes.toSet()),
      generation: generation,
    );
    _timers.schedule(
      blockStart + _rolledBlockDuration,
      finish,
      generation: generation,
    );
  }

  /// Steps a single-note highlight through a melodic run.
  void startRun(List<int> notes) {
    if (notes.isEmpty) return;

    final generation = _timers.restart();
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      _timers.schedule(_sequenceStep * i, (_) {
        _setState(ScalePreviewState(activeNotes: {note}, isRunning: true));
      }, generation: generation);
    }
    _timers.schedule(
      _sequenceStep * notes.length,
      finish,
      generation: generation,
    );
  }

  void finish(int generation) {
    if (!_timers.isCurrent(generation)) return;
    _setState(ScalePreviewState.idle);
    _timers.cancel();
  }

  void cancel() {
    _timers.cancel();
    _setState(ScalePreviewState.idle);
  }

  void dispose() {
    _timers.dispose();
  }

  void _setState(ScalePreviewState state) {
    if (_state.isRunning == state.isRunning &&
        _state.activeNotes == state.activeNotes) {
      return;
    }
    _state = state;
    onChanged(state);
  }
}
