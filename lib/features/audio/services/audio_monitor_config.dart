import 'package:whatchord/core/audio/soundfont_assets.dart';

const String audioMonitorSoundFontAssetPath = SoundFontAssets.defaultPiano;

const int audioMonitorSampleRate = 44100;
const int audioMonitorFeedThresholdFrames = 2048;
const int audioMonitorRenderChunkFrames = 1024;
const int audioMonitorMaxBufferedFrames = 4096;

// Playback tuning:
// keep event/retrigger flow velocity-capable, while defaulting playback to a
// fixed note-on velocity for the current SoundFont profile.
const bool audioMonitorUseFixedVelocity = true;
const int audioMonitorFixedVelocity = 100;
