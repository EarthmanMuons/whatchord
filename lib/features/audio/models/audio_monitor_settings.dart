import 'package:meta/meta.dart';

import 'audio_monitor_mode.dart';

@immutable
class AudioMonitorSettings {
  const AudioMonitorSettings({
    required this.mode,
    required this.volume,
    required this.muted,
  });

  const AudioMonitorSettings.defaults()
    : mode = AudioMonitorMode.internal,
      volume = 0.7,
      muted = false;

  final AudioMonitorMode mode;
  final double volume;
  final bool muted;

  /// Whether the monitor produces any sound. Muting is the off switch.
  bool get isActive => !muted;

  /// Whether the selected output is the built-in soundfont synth.
  bool get isInternal => mode == AudioMonitorMode.internal;

  /// Whether the selected output is an external MIDI device.
  bool get isMidiOut => mode == AudioMonitorMode.midiOut;

  /// Whether the internal synth should be running (internal mode, not muted).
  bool get playsInternal => isInternal && !muted;

  /// Volume applied to playback, accounting for mute. The stored [volume] is
  /// preserved while muted so unmuting restores the prior level.
  double get effectiveVolume => muted ? 0.0 : volume;

  AudioMonitorSettings copyWith({
    AudioMonitorMode? mode,
    double? volume,
    bool? muted,
  }) {
    return AudioMonitorSettings(
      mode: mode ?? this.mode,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
    );
  }
}
