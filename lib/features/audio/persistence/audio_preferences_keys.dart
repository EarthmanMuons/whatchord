/// Storage keys for audio monitor preferences.
abstract final class AudioPreferencesKeys {
  static const String monitorMode = 'audio.monitor.mode';
  static const String monitorInternalVolume = 'audio.monitor.internalVolume';
  static const String monitorMidiOutVolume = 'audio.monitor.midiOutVolume';
  static const String monitorMuted = 'audio.monitor.muted';

  /// Legacy on/off flag, replaced by [monitorMode]. Read once for migration.
  static const String monitorEnabled = 'audio.monitor.enabled';
}
