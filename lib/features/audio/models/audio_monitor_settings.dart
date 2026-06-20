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

  /// Whether the monitor is doing anything at all (internal or MIDI out).
  bool get isActive => mode != AudioMonitorMode.off;

  /// Whether notes should sound through the built-in soundfont synth.
  bool get isInternal => mode == AudioMonitorMode.internal;

  /// Whether preview notes should be sent to an external MIDI device.
  bool get isMidiOut => mode == AudioMonitorMode.midiOut;

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
