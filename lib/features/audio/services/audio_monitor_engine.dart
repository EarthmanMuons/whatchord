import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio_debug.dart';
import 'audio_monitor_config.dart';
import 'pcm_output.dart';
import 'soundfont_synth_isolate.dart';

class AudioMonitorEngine {
  static const bool _debugLog = audioDebug;

  AudioMonitorEngine({required this.soundFontAssetPath});

  final String soundFontAssetPath;

  late final PcmOutput _pcm = PcmOutput(
    sampleRate: audioMonitorSampleRate,
    channelCount: 1,
    feedThresholdFrames: audioMonitorFeedThresholdFrames,
  );

  SoundFontSynthIsolateClient? _synth;

  bool _running = false;
  bool _feedInFlight = false;
  bool _feedQueued = false;
  double _volume = 1.0;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;

    final soundFont = await rootBundle.load(soundFontAssetPath);
    final synth = await SoundFontSynthIsolateClient.spawn(
      soundFontData: soundFont.buffer.asUint8List(),
      sampleRate: audioMonitorSampleRate,
    );

    await synth.setVolume(_volume);

    await _pcm.initialize(onFeed: _onFeedRequested);
    _synth = synth;
    _running = true;
    _pcm.start();
  }

  Future<void> stop() async {
    if (!_running && _synth == null) return;

    _running = false;
    _feedInFlight = false;
    _feedQueued = false;

    await _synth?.noteOffAll();
    await _synth?.dispose();
    _synth = null;

    await _pcm.release();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _synth?.setVolume(_volume);
  }

  Future<void> noteOn(int midiNote, {int velocity = 100}) async {
    if (!_running) return;
    if (_debugLog) {
      debugPrint('[AUDIO_ENG] noteOn note=$midiNote vel=$velocity');
    }
    await _synth?.noteOn(midiNote, velocity: velocity);
  }

  Future<void> noteOff(int midiNote) async {
    if (!_running) return;
    if (_debugLog) {
      debugPrint('[AUDIO_ENG] noteOff note=$midiNote');
    }
    await _synth?.noteOff(midiNote);
  }

  Future<void> allNotesOff() async {
    await _synth?.noteOffAll();
  }

  Future<void> _onFeedRequested(int remainingFrames) async {
    if (!_running) return;

    if (_feedInFlight) {
      _feedQueued = true;
      return;
    }

    _feedInFlight = true;
    try {
      await _fillUntilBuffered(remainingFrames);
    } finally {
      _feedInFlight = false;

      if (_feedQueued && _running) {
        _feedQueued = false;
        unawaited(_onFeedRequested(0));
      }
    }
  }

  Future<void> _fillUntilBuffered(int remainingFrames) async {
    var buffered = remainingFrames;
    while (_running && buffered < audioMonitorMaxBufferedFrames) {
      final synth = _synth;
      if (synth == null) return;

      final rendered = await synth.renderFrames(audioMonitorRenderChunkFrames);
      if (!_running || rendered.isEmpty) return;

      await _pcm.feed(rendered);
      buffered += audioMonitorRenderChunkFrames;
    }
  }
}
