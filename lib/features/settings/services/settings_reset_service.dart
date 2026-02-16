import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/persistence/core_preferences_keys.dart';
import 'package:whatchord/core/providers/app_palette_notifier.dart';
import 'package:whatchord/core/providers/app_theme_mode_notifier.dart';
import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/theory/theory.dart';

final settingsResetProvider = Provider<SettingsResetService>((ref) {
  return SettingsResetService(ref);
});

class SettingsResetService {
  SettingsResetService(this._ref);
  final Ref _ref;

  Future<void> resetAllToDefaults() async {
    final prefs = _ref.read(sharedPreferencesProvider);

    // Core preferences
    await prefs.remove(CorePreferencesKeys.themeMode);
    await prefs.remove(CorePreferencesKeys.appPalette);

    // Theory preferences
    await prefs.remove(TheoryPreferencesKeys.chordNotationStyle);

    // MIDI preferences (delegate to MIDI's own reset)
    await _ref.read(midiPreferencesProvider.notifier).clearAllMidiData();
    await _ref.read(audioMonitorSettingsNotifier.notifier).clearAllAudioData();

    // Force rebuilds
    _ref.invalidate(appThemeModeProvider);
    _ref.invalidate(appPaletteProvider);
    _ref.invalidate(chordNotationStyleProvider);
    _ref.invalidate(audioMonitorSettingsNotifier);

    // Reset MIDI connection state
    final connectionState = _ref.read(midiConnectionStateProvider.notifier);
    await connectionState.stopScanning();
    await connectionState.disconnect();
  }
}
