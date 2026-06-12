import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/services/cancelable_timer_sequence.dart';
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
  static const Duration _previewDuration = Duration(milliseconds: 1400);
  static const Duration _volumePreviewDuration = Duration(milliseconds: 350);
  static const Duration _rolledPreviewStep = Duration(milliseconds: 180);
  static const Duration _rolledPreviewNoteDuration = Duration(
    milliseconds: 220,
  );
  static const Duration _rolledPreviewBlockGap = Duration(milliseconds: 260);
  static const Duration _rolledPreviewBlockDuration = Duration(
    milliseconds: 1400,
  );
  static const Duration _sequencePreviewStep = Duration(milliseconds: 200);
  static const Duration _sequencePreviewNoteDuration = Duration(
    milliseconds: 200,
  );

  AudioMonitorEngine? _engine;
  bool _disposed = false;
  bool _backgrounded = false;
  bool _allowBootstrapOnNextStart = true;
  bool _needsBootstrapNoteOnSync = true;
  final Set<int> _eventDrivenPendingOn = <int>{};
  final Set<int> _eventDrivenPendingOff = <int>{};
  Set<int> _lastSoundingNotes = const <int>{};
  Set<int> _notesInEngine = const <int>{};
  final CancelableTimerSequence _previewSequence = CancelableTimerSequence();
  Future<void> _audioOps = Future<void>.value();

  @override
  AudioMonitorState build() {
    ref.listen<AudioMonitorSettings>(audioMonitorSettingsNotifier, (
      previous,
      next,
    ) {
      _enqueueAudioOperation(() async {
        if (previous?.enabled == false && next.enabled) {
          // Enabling monitor should stay silent for already-held notes.
          _allowBootstrapOnNextStart = false;
          _needsBootstrapNoteOnSync = false;
        }
        await _reconcile();
      });
    });

    ref.listen<Set<int>>(soundingNoteNumbersProvider, (previous, next) {
      final soundingNotes = Set<int>.unmodifiable(next);
      _enqueueAudioOperation(() async {
        _lastSoundingNotes = soundingNotes;
        await _syncSoundingNotes();
      });
    });

    ref.onDispose(() {
      _disposed = true;
      _cancelPreviewTimers();
      _enqueueAudioOperation(_stopEngine, runWhenDisposed: true);
    });

    _lastSoundingNotes = Set<int>.unmodifiable(
      ref.read(soundingNoteNumbersProvider),
    );
    _enqueueAudioOperation(_reconcile);

    return const AudioMonitorState.disabled();
  }

  void playPreviewNotes(Iterable<int> midiNotes) {
    final notes = midiNotes.map((note) => note.clamp(0, 127)).toSet().toList()
      ..sort();
    if (notes.isEmpty || _backgrounded) return;

    _enqueueAudioOperation(() => _playPreviewNotes(notes));
  }

  void playVolumePreviewNote(int midiNote) {
    if (_backgrounded || !ref.read(audioMonitorSettingsNotifier).enabled) {
      return;
    }

    _enqueueAudioOperation(
      () => _playPreviewNotes([
        midiNote.clamp(0, 127),
      ], duration: _volumePreviewDuration),
    );
  }

  void cancelPreviewNotes() {
    _cancelPreviewTimers();
    _enqueueAudioOperation(_finishPreview);
  }

  void playRolledPreviewNotes(Iterable<int> midiNotes) {
    final notes = midiNotes.map((note) => note.clamp(0, 127)).toSet().toList()
      ..sort();
    if (notes.isEmpty || _backgrounded) return;

    if (notes.length == 1) {
      _enqueueAudioOperation(() => _playPreviewNotes(notes));
      return;
    }

    _enqueueAudioOperation(() => _playRolledPreviewNotes(notes));
  }

  /// Plays [midiNotes] one after another as a melodic run, preserving their
  /// order and any repeats (unlike the chord previews, which sort and de-dupe).
  void playSequencePreviewNotes(Iterable<int> midiNotes) {
    final notes = [for (final note in midiNotes) note.clamp(0, 127)];
    if (notes.isEmpty || _backgrounded) return;

    _enqueueAudioOperation(() => _playSequencePreviewNotes(notes));
  }

  void onInputNoteEvent(InputNoteEvent event) {
    if (_debugLog) {
      debugPrint(
        '[AUDIO_EVT] ${event.type.name} note=${event.noteNumber} '
        'vel=${event.velocity} running=${_engine?.isRunning == true}',
      );
    }
    _enqueueAudioOperation(() async {
      final settings = ref.read(audioMonitorSettingsNotifier);
      final shouldRun = settings.enabled && !_backgrounded;
      final isRunning = _engine?.isRunning == true;
      if (!shouldRun) return;

      if (shouldRun && !isRunning) {
        if (_debugLog) {
          debugPrint(
            '[AUDIO_EVT] engine not running; reconciling before event',
          );
        }
        await _reconcile();
      }
      if (!_backgrounded) {
        await _handleNoteEvent(event);
      }
    });
  }

  void setBackgrounded(bool backgrounded) {
    if (_backgrounded == backgrounded) return;
    _backgrounded = backgrounded;

    if (backgrounded) {
      _enqueueAudioOperation(() async {
        // Force a silent baseline while backgrounded; on resume, audio should
        // only reflect fresh note events.
        _allowBootstrapOnNextStart = false;
        _resetTrackingForStop();
        _cancelPreviewTimers();
        _lastSoundingNotes = const <int>{};
        await _engine?.allNotesOff();
        await _reconcile();
      });
      return;
    }

    _enqueueAudioOperation(_reconcile);
  }

  void _enqueueAudioOperation(
    Future<void> Function() action, {
    bool runWhenDisposed = false,
  }) {
    _audioOps = _audioOps
        .then((_) async {
          if (_disposed && !runWhenDisposed) return;
          await action();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (_disposed) return;
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
      await engine.setVolume(settings.effectiveVolume);
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
    _cancelPreviewTimers();
    _resetTrackingForStop();
    if (engine == null) return;
    await engine.stop();
  }

  Future<void> _playPreviewNotes(
    List<int> midiNotes, {
    Duration duration = _previewDuration,
  }) async {
    final generation = _previewSequence.restart();

    if (_backgrounded) return;

    final engine = await _ensureEngineStarted();
    if (engine == null) return;

    final settings = ref.read(audioMonitorSettingsNotifier);
    await engine.setVolume(settings.effectiveVolume);
    await engine.allNotesOff();
    _resetTrackingForSilentState();

    for (final midiNote in midiNotes) {
      await engine.noteOn(midiNote, velocity: audioMonitorFixedVelocity);
    }

    _previewSequence.schedule(duration, (_) {
      _enqueuePreviewControl(generation, _finishPreview);
    }, generation: generation);
  }

  Future<void> _playRolledPreviewNotes(List<int> midiNotes) async {
    final generation = _previewSequence.restart();

    if (_backgrounded) return;

    final engine = await _ensureEngineStarted();
    if (engine == null) return;

    final settings = ref.read(audioMonitorSettingsNotifier);
    await engine.setVolume(settings.effectiveVolume);
    await engine.allNotesOff();
    _resetTrackingForSilentState();

    for (var i = 0; i < midiNotes.length; i++) {
      final midiNote = midiNotes[i];
      final noteStart = _rolledPreviewStep * i;
      _previewSequence.schedule(noteStart, (_) {
        _enqueuePreviewControl(generation, () async {
          await engine.noteOn(midiNote, velocity: audioMonitorFixedVelocity);
        });
      }, generation: generation);
      _previewSequence.schedule(noteStart + _rolledPreviewNoteDuration, (_) {
        _enqueuePreviewControl(generation, () async {
          await engine.noteOff(midiNote);
        });
      }, generation: generation);
    }

    final blockStart =
        _rolledPreviewStep * midiNotes.length + _rolledPreviewBlockGap;
    _previewSequence.schedule(blockStart, (_) {
      _enqueuePreviewControl(generation, () async {
        await engine.allNotesOff();
        for (final midiNote in midiNotes) {
          await engine.noteOn(midiNote, velocity: audioMonitorFixedVelocity);
        }
      });
    }, generation: generation);
    _previewSequence.schedule(blockStart + _rolledPreviewBlockDuration, (_) {
      _enqueuePreviewControl(generation, _finishPreview);
    }, generation: generation);
  }

  Future<void> _playSequencePreviewNotes(List<int> midiNotes) async {
    final generation = _previewSequence.restart();

    if (_backgrounded) return;

    final engine = await _ensureEngineStarted();
    if (engine == null) return;

    final settings = ref.read(audioMonitorSettingsNotifier);
    await engine.setVolume(settings.effectiveVolume);
    await engine.allNotesOff();
    _resetTrackingForSilentState();

    for (var i = 0; i < midiNotes.length; i++) {
      final midiNote = midiNotes[i];
      final noteStart = _sequencePreviewStep * i;
      _previewSequence.schedule(noteStart, (_) {
        _enqueuePreviewControl(generation, () async {
          await engine.noteOn(midiNote, velocity: audioMonitorFixedVelocity);
        });
      }, generation: generation);
      _previewSequence.schedule(noteStart + _sequencePreviewNoteDuration, (_) {
        _enqueuePreviewControl(generation, () async {
          await engine.noteOff(midiNote);
        });
      }, generation: generation);
    }

    final endStart = _sequencePreviewStep * midiNotes.length;
    _previewSequence.schedule(endStart + _sequencePreviewNoteDuration, (_) {
      _enqueuePreviewControl(generation, _finishPreview);
    }, generation: generation);
  }

  Future<void> _finishPreview() async {
    _cancelPreviewTimers();

    final engine = _engine;
    if (engine != null && engine.isRunning) {
      await engine.allNotesOff();
    }

    final settings = ref.read(audioMonitorSettingsNotifier);
    if (!settings.enabled || _backgrounded) {
      await _stopEngine();
      state = const AudioMonitorState.disabled();
    } else {
      await _syncSoundingNotes();
    }
  }

  Future<AudioMonitorEngine?> _ensureEngineStarted() async {
    final engine = _engine ??= AudioMonitorEngine(
      soundFontAssetPath: audioMonitorSoundFontAssetPath,
    );

    try {
      if (!engine.isRunning) {
        await engine.start();
      }
      return engine;
    } catch (e) {
      await _stopEngine();
      state = AudioMonitorState(
        status: AudioMonitorStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void _enqueuePreviewControl(int generation, Future<void> Function() action) {
    _enqueueAudioOperation(() async {
      if (!_previewSequence.isCurrent(generation) || _backgrounded) return;
      await action();
    });
  }

  void _cancelPreviewTimers() {
    _previewSequence.cancel();
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
