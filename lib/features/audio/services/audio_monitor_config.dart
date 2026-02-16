import 'package:whatchord/core/audio/soundfont_assets.dart';

const String audioMonitorSoundFontAssetPath = SoundFontAssets.defaultPiano;

const int audioMonitorSampleRate = 44100;
const int audioMonitorFeedThresholdFrames = 2048;
const int audioMonitorRenderChunkFrames = 1024;
const int audioMonitorMaxBufferedFrames = 4096;
