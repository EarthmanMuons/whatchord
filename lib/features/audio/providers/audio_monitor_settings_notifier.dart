import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';

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

    final (mode, muted) = _readModeAndMuted(prefs, defaults);
    final internalVolume =
        (prefs.getDouble(AudioPreferencesKeys.monitorInternalVolume) ??
                defaults.internalVolume)
            .clamp(0.0, 1.0);
    final midiOutVolume =
        (prefs.getDouble(AudioPreferencesKeys.monitorMidiOutVolume) ??
                defaults.midiOutVolume)
            .clamp(0.0, 1.0);

    return AudioMonitorSettings(
      mode: mode,
      internalVolume: internalVolume,
      midiOutVolume: midiOutVolume,
      muted: muted,
    );
  }

  /// Resolves the output mode and muted state, migrating the legacy on/off
  /// flag. Mute is the off switch, so a prior disabled monitor maps to muted.
  (AudioMonitorMode, bool) _readModeAndMuted(
    SharedPreferences prefs,
    AudioMonitorSettings defaults,
  ) {
    final storedMuted =
        prefs.getBool(AudioPreferencesKeys.monitorMuted) ?? defaults.muted;
    final storedMode = prefs.getString(AudioPreferencesKeys.monitorMode);

    if (storedMode != null) {
      return (AudioMonitorMode.fromName(storedMode), storedMuted);
    }

    final legacyEnabled = prefs.getBool(AudioPreferencesKeys.monitorEnabled);
    if (legacyEnabled == false) {
      return (AudioMonitorMode.internal, true);
    }
    return (defaults.mode, storedMuted);
  }

  Future<void> setMode(AudioMonitorMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(mode: mode);
    await prefs.setString(AudioPreferencesKeys.monitorMode, mode.name);
  }

  /// Sets the volume for the currently selected output, persisting each output's
  /// level independently.
  Future<void> setVolume(double volume) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final clamped = volume.clamp(0.0, 1.0);

    switch (state.mode) {
      case AudioMonitorMode.internal:
        state = state.copyWith(internalVolume: clamped);
        await prefs.setDouble(
          AudioPreferencesKeys.monitorInternalVolume,
          clamped,
        );
      case AudioMonitorMode.midiOut:
        state = state.copyWith(midiOutVolume: clamped);
        await prefs.setDouble(
          AudioPreferencesKeys.monitorMidiOutVolume,
          clamped,
        );
    }
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
    await prefs.remove(AudioPreferencesKeys.monitorInternalVolume);
    await prefs.remove(AudioPreferencesKeys.monitorMidiOutVolume);
    await prefs.remove(AudioPreferencesKeys.monitorMuted);
  }
}
