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
  bool _allowBootstrapOnNextStart = true;
  bool _needsBootstrapNoteOnSync = true;
  final Set<int> _eventDrivenPendingOn = <int>{};
  final Set<int> _eventDrivenPendingOff = <int>{};
  Set<int> _lastSoundingNotes = const <int>{};
  Set<int> _notesInEngine = const <int>{};
  Future<void> _controlOps = Future<void>.value();
  Future<void> _noteOps = Future<void>.value();

  @override
  AudioMonitorState build() {
    ref.listen<AudioMonitorSettings>(audioMonitorSettingsNotifier, (
      previous,
      next,
    ) {
      if (previous?.enabled == false && next.enabled) {
        // Enabling monitor should stay silent for already-held notes.
        _allowBootstrapOnNextStart = false;
      }
      _enqueueControl(_reconcile);
    });

    ref.listen<Set<int>>(soundingNoteNumbersProvider, (previous, next) {
      _lastSoundingNotes = Set<int>.unmodifiable(next);
      _enqueueControl(_syncSoundingNotes);
    });

    ref.onDispose(() {
      unawaited(_stopEngine());
    });

    _lastSoundingNotes = Set<int>.unmodifiable(
      ref.read(soundingNoteNumbersProvider),
    );
    _enqueueControl(_reconcile);

    return const AudioMonitorState.disabled();
  }

  void onInputNoteEvent(InputNoteEvent event) {
    if (_debugLog) {
      debugPrint(
        '[AUDIO_EVT] ${event.type.name} note=${event.noteNumber} '
        'vel=${event.velocity} running=${_engine?.isRunning == true}',
      );
    }
    final settings = ref.read(audioMonitorSettingsNotifier);
    final shouldRun = settings.enabled && !_backgrounded;
    final isRunning = _engine?.isRunning == true;

    if (shouldRun && isRunning) {
      _enqueueNote(() => _handleNoteEvent(event));
      return;
    }

    _enqueueControl(() async {
      if (shouldRun && !isRunning) {
        if (_debugLog) {
          debugPrint(
            '[AUDIO_EVT] engine not running; reconciling before event',
          );
        }
        await _reconcile();
      }
      await _handleNoteEvent(event);
    });
  }

  void setBackgrounded(bool backgrounded) {
    if (_backgrounded == backgrounded) return;
    _backgrounded = backgrounded;

    if (backgrounded) {
      // Force a silent baseline while backgrounded; on resume, audio should
      // only reflect fresh note events.
      _allowBootstrapOnNextStart = false;
      _resetTrackingForStop();
      _lastSoundingNotes = const <int>{};
      unawaited(_engine?.allNotesOff());
    }

    _enqueueControl(_reconcile);
  }

  void _enqueueControl(Future<void> Function() action) {
    _controlOps = _controlOps.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      state = AudioMonitorState(
        status: AudioMonitorStatus.error,
        errorMessage: error.toString(),
      );
    });
  }

  void _enqueueNote(Future<void> Function() action) {
    _noteOps = _noteOps.then((_) => action()).catchError((
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
      var startedNow = false;
      if (!engine.isRunning) {
        await engine.start();
        startedNow = true;
      }
      if (startedNow) {
        _needsBootstrapNoteOnSync = _allowBootstrapOnNextStart;
        _allowBootstrapOnNextStart = true;
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

    // Safety net: if input says nothing is sounding, force a full note-off to
    // recover from any missed per-note off events.
    if (_lastSoundingNotes.isEmpty) {
      if (_notesInEngine.isNotEmpty) {
        if (_debugLog) {
          debugPrint('[AUDIO_SYNC] forcing allNotesOff (no sounding notes)');
        }
        await engine.allNotesOff();
      }
      _resetTrackingForSilentState();
      _needsBootstrapNoteOnSync = false;
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
      if (_eventDrivenPendingOff.remove(midiNote)) {
        continue;
      }
      await engine.noteOff(midiNote);
    }
    if (_needsBootstrapNoteOnSync) {
      for (final midiNote in toTurnOn) {
        // Skip duplicate attack when a note-on event already handled this note.
        if (_eventDrivenPendingOn.remove(midiNote)) {
          continue;
        }
        _eventDrivenPendingOff.remove(midiNote);
        await engine.noteOn(midiNote);
      }
      _needsBootstrapNoteOnSync = false;
    }

    _notesInEngine = Set<int>.unmodifiable(_lastSoundingNotes);
  }

  Future<void> _handleNoteEvent(InputNoteEvent event) async {
    final engine = _engine;
    if (engine == null || !engine.isRunning) return;

    switch (event.type) {
      case InputNoteEventType.noteOn:
        await _handleNoteOnEvent(engine, event);
        break;

      case InputNoteEventType.noteOff:
        await _handleNoteOffEvent(engine, event);
        break;
    }
  }

  Future<void> _stopEngine() async {
    final engine = _engine;
    _resetTrackingForStop();
    if (engine == null) return;
    await engine.stop();
  }

  Future<void> _handleNoteOnEvent(
    AudioMonitorEngine engine,
    InputNoteEvent event,
  ) async {
    final midiNote = event.noteNumber.clamp(0, 127);
    final velocity = audioMonitorUseFixedVelocity
        ? audioMonitorFixedVelocity
        : event.velocity.clamp(1, 127);
    _eventDrivenPendingOn.add(midiNote);
    _eventDrivenPendingOff.remove(midiNote);
    final alreadySounding = _notesInEngine.contains(midiNote);

    // Only retrigger when the note is already sounding (e.g., restrikes
    // while sustained). Fresh notes should take the direct noteOn path.
    if (_debugLog) {
      debugPrint(
        '[AUDIO_NOTEON] ${alreadySounding ? "retrigger" : "on"} '
        'note=$midiNote vel=$velocity',
      );
    }
    if (alreadySounding) {
      await engine.noteOff(midiNote);
    }
    await engine.noteOn(midiNote, velocity: velocity);
    _notesInEngine = Set<int>.unmodifiable({..._notesInEngine, midiNote});
  }

  Future<void> _handleNoteOffEvent(
    AudioMonitorEngine engine,
    InputNoteEvent event,
  ) async {
    final midiNote = event.noteNumber.clamp(0, 127);
    final shouldStopImmediately = !_lastSoundingNotes.contains(midiNote);

    // If this note is no longer in sounding notes, stop it immediately.
    // If sustain is holding it, sounding-note sync will keep it alive.
    if (shouldStopImmediately) {
      await engine.noteOff(midiNote);
      _eventDrivenPendingOff.add(midiNote);
      _notesInEngine = Set<int>.unmodifiable(
        {..._notesInEngine}..remove(midiNote),
      );
    }
    if (_debugLog) {
      debugPrint(
        '[AUDIO_NOTEOFF] note=$midiNote immediate=$shouldStopImmediately',
      );
    }
  }

  void _resetTrackingForStop() {
    _notesInEngine = const <int>{};
    _needsBootstrapNoteOnSync = true;
    _eventDrivenPendingOn.clear();
    _eventDrivenPendingOff.clear();
  }

  void _resetTrackingForSilentState() {
    _notesInEngine = const <int>{};
    _eventDrivenPendingOn.clear();
    _eventDrivenPendingOff.clear();
  }
}
