import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../models/audio_monitor_mode.dart';
import '../models/audio_monitor_settings.dart';
import '../persistence/audio_preferences_keys.dart';

final audioMonitorSettingsNotifier =
    NotifierProvider<AudioMonitorSettingsNotifier, AudioMonitorSettings>(
      AudioMonitorSettingsNotifier.new,
    );

final audioMonitorActiveProvider = Provider<bool>((ref) {
  return ref.watch(audioMonitorSettingsNotifier.select((s) => s.isActive));
});

final audioMonitorVolumeProvider = Provider<double>((ref) {
  return ref.watch(audioMonitorSettingsNotifier.select((s) => s.volume));
});

class AudioMonitorSettingsNotifier extends Notifier<AudioMonitorSettings> {
  @override
  AudioMonitorSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final defaults = const AudioMonitorSettings.defaults();

    return AudioMonitorSettings(
      mode: _readMode(prefs, defaults.mode),
      volume:
          (prefs.getDouble(AudioPreferencesKeys.monitorVolume) ??
                  defaults.volume)
              .clamp(0.0, 1.0),
      muted: prefs.getBool(AudioPreferencesKeys.monitorMuted) ?? defaults.muted,
    );
  }

  /// Reads the stored mode, falling back to the legacy on/off flag so existing
  /// users keep their prior preference.
  AudioMonitorMode _readMode(
    SharedPreferences prefs,
    AudioMonitorMode fallback,
  ) {
    final stored = prefs.getString(AudioPreferencesKeys.monitorMode);
    if (stored != null) return AudioMonitorMode.fromName(stored);

    final legacy = prefs.getBool(AudioPreferencesKeys.monitorEnabled);
    if (legacy != null) {
      return legacy ? AudioMonitorMode.internal : AudioMonitorMode.off;
    }
    return fallback;
  }

  Future<void> setMode(AudioMonitorMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(mode: mode);
    await prefs.setString(AudioPreferencesKeys.monitorMode, mode.name);
  }

  Future<void> setVolume(double volume) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final clamped = volume.clamp(0.0, 1.0);

    state = state.copyWith(volume: clamped);
    await prefs.setDouble(AudioPreferencesKeys.monitorVolume, clamped);
  }

  Future<void> setMuted(bool muted) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(muted: muted);
    await prefs.setBool(AudioPreferencesKeys.monitorMuted, muted);
  }

  Future<void> clearAllAudioData() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = const AudioMonitorSettings.defaults();
    await prefs.remove(AudioPreferencesKeys.monitorMode);
    await prefs.remove(AudioPreferencesKeys.monitorEnabled);
    await prefs.remove(AudioPreferencesKeys.monitorVolume);
    await prefs.remove(AudioPreferencesKeys.monitorMuted);
  }
}
