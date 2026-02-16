import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../models/audio_monitor_settings.dart';
import '../persistence/audio_preferences_keys.dart';

final audioMonitorSettingsNotifier =
    NotifierProvider<AudioMonitorSettingsNotifier, AudioMonitorSettings>(
      AudioMonitorSettingsNotifier.new,
    );

final audioMonitorEnabledProvider = Provider<bool>((ref) {
  return ref.watch(audioMonitorSettingsNotifier.select((s) => s.enabled));
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
      enabled:
          prefs.getBool(AudioPreferencesKeys.monitorEnabled) ??
          defaults.enabled,
      volume:
          (prefs.getDouble(AudioPreferencesKeys.monitorVolume) ??
                  defaults.volume)
              .clamp(0.0, 1.0),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(enabled: enabled);
    await prefs.setBool(AudioPreferencesKeys.monitorEnabled, enabled);
  }

  Future<void> setVolume(double volume) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final clamped = volume.clamp(0.0, 1.0);

    state = state.copyWith(volume: clamped);
    await prefs.setDouble(AudioPreferencesKeys.monitorVolume, clamped);
  }

  Future<void> clearAllAudioData() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = const AudioMonitorSettings.defaults();
    await prefs.remove(AudioPreferencesKeys.monitorEnabled);
    await prefs.remove(AudioPreferencesKeys.monitorVolume);
  }
}
