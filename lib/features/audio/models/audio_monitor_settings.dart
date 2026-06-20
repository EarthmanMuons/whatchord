import 'package:meta/meta.dart';

import 'audio_monitor_mode.dart';

@immutable
class AudioMonitorSettings {
  const AudioMonitorSettings({
    required this.mode,
    required this.internalVolume,
    required this.midiOutVolume,
    required this.muted,
  });

  const AudioMonitorSettings.defaults()
    : mode = AudioMonitorMode.internal,
      internalVolume = 0.7,
      midiOutVolume = 0.5,
      muted = false;

  final AudioMonitorMode mode;

  /// Playback volume for the internal soundfont synth (0-1).
  final double internalVolume;

  /// Playback volume for MIDI Out, mapped onto note velocity (0-1). Defaults
  /// lower than internal so an external instrument is not surprisingly loud.
  final double midiOutVolume;

  final bool muted;

  /// Whether the monitor produces any sound. Muting is the off switch.
  bool get isActive => !muted;

  /// Whether the selected output is the built-in soundfont synth.
  bool get isInternal => mode == AudioMonitorMode.internal;

  /// Whether the selected output is an external MIDI device.
  bool get isMidiOut => mode == AudioMonitorMode.midiOut;

  /// Whether the internal synth should be running (internal mode, not muted).
  bool get playsInternal => isInternal && !muted;

  /// Volume for the currently selected output.
  double get volume => switch (mode) {
    AudioMonitorMode.internal => internalVolume,
    AudioMonitorMode.midiOut => midiOutVolume,
  };

  /// Volume applied to playback, accounting for mute. The stored volume is
  /// preserved while muted so unmuting restores the prior level.
  double get effectiveVolume => muted ? 0.0 : volume;

  AudioMonitorSettings copyWith({
    AudioMonitorMode? mode,
    double? internalVolume,
    double? midiOutVolume,
    bool? muted,
  }) {
    return AudioMonitorSettings(
      mode: mode ?? this.mode,
      internalVolume: internalVolume ?? this.internalVolume,
      midiOutVolume: midiOutVolume ?? this.midiOutVolume,
      muted: muted ?? this.muted,
    );
  }
}
