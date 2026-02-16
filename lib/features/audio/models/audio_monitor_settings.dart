import 'package:meta/meta.dart';

@immutable
class AudioMonitorSettings {
  const AudioMonitorSettings({required this.enabled, required this.volume});

  const AudioMonitorSettings.defaults() : enabled = false, volume = 0.7;

  final bool enabled;
  final double volume;

  AudioMonitorSettings copyWith({bool? enabled, double? volume}) {
    return AudioMonitorSettings(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
    );
  }
}
