import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';

import '../audio_debug.dart';
import '../models/audio_monitor_settings.dart';
import '../models/audio_monitor_state.dart';
import '../models/audio_monitor_status.dart';
import '../services/audio_monitor_config.dart';
import '../services/audio_monitor_engine.dart';
import 'audio_monitor_settings_notifier.dart';

final audioMonitorNotifier =
    NotifierProvider<AudioMonitorNotifier, AudioMonitorState>(
      AudioMonitorNotifier.new,
    );

final audioMonitorStatusProvider = Provider<AudioMonitorStatus>((ref) {
  return ref.watch(audioMonitorNotifier.select((state) => state.status));
});

class AudioMonitorNotifier extends Notifier<AudioMonitorState> {
  static const bool _debugLog = audioDebug;

  AudioMonitorEngine? _engine;
  bool _backgrounded = false;
  Set<int> _lastSoundingNotes = const <int>{};
  Set<int> _notesInEngine = const <int>{};
  Future<void> _ops = Future<void>.value();

  @override
  AudioMonitorState build() {
    ref.listen<AudioMonitorSettings>(audioMonitorSettingsNotifier, (
      previous,
      next,
    ) {
      _enqueue(_reconcile);
    });

    ref.listen<Set<int>>(soundingNoteNumbersProvider, (previous, next) {
      _lastSoundingNotes = Set<int>.unmodifiable(next);
      _enqueue(_syncSoundingNotes);
    });
    ref.listen<InputNoteEvent?>(inputNoteEventsProvider, (previous, next) {
      if (next == null) return;
      if (_debugLog) {
        debugPrint(
          '[AUDIO_EVT] ${next.type.name} note=${next.noteNumber} '
          'vel=${next.velocity} running=${_engine?.isRunning == true}',
        );
      }
      _enqueue(() => _handleNoteEvent(next));
    });

    ref.onDispose(() {
      unawaited(_stopEngine());
    });

    _lastSoundingNotes = Set<int>.unmodifiable(
      ref.read(soundingNoteNumbersProvider),
    );
    _enqueue(_reconcile);

    return const AudioMonitorState.disabled();
  }

  void setBackgrounded(bool backgrounded) {
    if (_backgrounded == backgrounded) return;
    _backgrounded = backgrounded;

    if (backgrounded) {
      // Force a silent baseline while backgrounded; on resume, audio should
      // only reflect fresh note events.
      _lastSoundingNotes = const <int>{};
      _notesInEngine = const <int>{};
      unawaited(_engine?.allNotesOff());
    }

    _enqueue(_reconcile);
  }

  void _enqueue(Future<void> Function() action) {
    _ops = _ops.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      state = AudioMonitorState(
        status: AudioMonitorStatus.error,
        errorMessage: error.toString(),
      );
    });
  }

  Future<void> _reconcile() async {
    final settings = ref.read(audioMonitorSettingsNotifier);
    final shouldRun = settings.enabled && !_backgrounded;

    if (!shouldRun) {
      await _stopEngine();
      state = const AudioMonitorState.disabled();
      return;
    }

    state = state.copyWith(
      status: AudioMonitorStatus.starting,
      clearError: true,
    );

    final engine = _engine ??= AudioMonitorEngine(
      soundFontAssetPath: audioMonitorSoundFontAssetPath,
    );

    try {
      if (!engine.isRunning) {
        await engine.start();
      }
      await engine.setVolume(settings.volume);
      state = state.copyWith(
        status: AudioMonitorStatus.running,
        clearError: true,
      );
      await _syncSoundingNotes();
    } catch (e) {
      await _stopEngine();
      state = AudioMonitorState(
        status: AudioMonitorStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _syncSoundingNotes() async {
    final engine = _engine;
    if (engine == null || !engine.isRunning) {
      _notesInEngine = const <int>{};
      return;
    }

    final toTurnOff = _notesInEngine.difference(_lastSoundingNotes);
    final toTurnOn = _lastSoundingNotes.difference(_notesInEngine);
    if (_debugLog && (toTurnOff.isNotEmpty || toTurnOn.isNotEmpty)) {
      debugPrint(
        '[AUDIO_SYNC] off=${toTurnOff.toList()..sort()} '
        'on=${toTurnOn.toList()..sort()}',
      );
    }

    for (final midiNote in toTurnOff) {
      await engine.noteOff(midiNote);
    }
    for (final midiNote in toTurnOn) {
      await engine.noteOn(midiNote);
    }

    _notesInEngine = Set<int>.unmodifiable(_lastSoundingNotes);
  }

  Future<void> _handleNoteEvent(InputNoteEvent event) async {
    final engine = _engine;
    if (engine == null || !engine.isRunning) return;

    switch (event.type) {
      case InputNoteEventType.noteOn:
        final midiNote = event.noteNumber.clamp(0, 127);
        final velocity = event.velocity.clamp(1, 127);

        // Retrigger even if the note is already sounding (e.g., restrikes while sustained).
        if (_debugLog) {
          debugPrint('[AUDIO_NOTEON] retrigger note=$midiNote vel=$velocity');
        }
        await engine.noteOff(midiNote);
        await engine.noteOn(midiNote, velocity: velocity);
        _notesInEngine = Set<int>.unmodifiable({..._notesInEngine, midiNote});
        break;

      case InputNoteEventType.noteOff:
        // Sustain behavior is controlled by sounding-note sync.
        if (_debugLog) {
          debugPrint('[AUDIO_NOTEOFF] note=${event.noteNumber}');
        }
        break;
    }
  }

  Future<void> _stopEngine() async {
    final engine = _engine;
    _notesInEngine = const <int>{};
    if (engine == null) return;
    await engine.stop();
  }
}
