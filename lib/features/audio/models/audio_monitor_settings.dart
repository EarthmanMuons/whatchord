import 'package:meta/meta.dart';

@immutable
class AudioMonitorSettings {
  const AudioMonitorSettings({
    required this.enabled,
    required this.volume,
    required this.muted,
  });

  const AudioMonitorSettings.defaults()
    : enabled = true,
      volume = 0.7,
      muted = false;

  final bool enabled;
  final double volume;
  final bool muted;

  /// Volume applied to playback, accounting for mute. The stored [volume] is
  /// preserved while muted so unmuting restores the prior level.
  double get effectiveVolume => muted ? 0.0 : volume;

  AudioMonitorSettings copyWith({bool? enabled, double? volume, bool? muted}) {
    return AudioMonitorSettings(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
    );
  }
}
