import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

class PcmOutput {
  PcmOutput({
    required this.sampleRate,
    required this.channelCount,
    required this.feedThresholdFrames,
  });

  final int sampleRate;
  final int channelCount;
  final int feedThresholdFrames;

  bool _initialized = false;

  Future<void> initialize({
    required Future<void> Function(int remainingFrames) onFeed,
  }) async {
    if (_initialized) return;

    FlutterPcmSound.setFeedCallback((remainingFrames) {
      unawaited(onFeed(remainingFrames));
    });
    await FlutterPcmSound.setLogLevel(LogLevel.none);
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: channelCount,
      iosAudioCategory: IosAudioCategory.ambient,
      iosAllowBackgroundAudio: false,
    );
    await FlutterPcmSound.setFeedThreshold(feedThresholdFrames);

    _initialized = true;
  }

  void start() {
    if (!_initialized) return;
    FlutterPcmSound.start();
  }

  Future<void> feed(Int16List monoFrames) async {
    if (!_initialized || monoFrames.isEmpty) return;
    await FlutterPcmSound.feed(
      PcmArrayInt16(bytes: ByteData.sublistView(monoFrames)),
    );
  }

  Future<void> release() async {
    if (!_initialized) return;
    FlutterPcmSound.setFeedCallback(null);
    await FlutterPcmSound.release();
    _initialized = false;
  }
}
