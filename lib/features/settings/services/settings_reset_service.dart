import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/persistence/core_preferences_keys.dart';
import 'package:whatchord/core/providers/app_palette_notifier.dart';
import 'package:whatchord/core/providers/app_theme_mode_notifier.dart';
import 'package:whatchord/core/providers/shared_preferences_provider.dart';
import 'package:whatchord/features/audio/audio.dart';
import 'package:whatchord/features/demo/demo.dart';
import 'package:whatchord/features/midi/midi.dart';
import 'package:whatchord/features/onboarding/onboarding.dart';
import 'package:whatchord/features/theory/theory.dart';

final settingsResetProvider = Provider<SettingsResetService>((ref) {
  return SettingsResetService(ref);
});

class SettingsResetService {
  SettingsResetService(this._ref);
  final Ref _ref;

  Future<void> resetAllToDefaults() async {
    final prefs = _ref.read(sharedPreferencesProvider);

    // Exit demo first so any snapshot restoration happens before preference
    // keys are cleared. Otherwise demo shutdown can re-persist old values.
    _ref
        .read(demoModeProvider.notifier)
        .setEnabledFor(enabled: false, variant: DemoModeVariant.interactive);

    // Core preferences
    await prefs.remove(CorePreferencesKeys.themeMode);
    await prefs.remove(CorePreferencesKeys.appPalette);

    // Theory preferences
    await prefs.remove(TheoryPreferencesKeys.chordNotationStyle);
    await prefs.remove(TheoryPreferencesKeys.selectedTonality);

    // Cancel any reconnect/backoff workflow before mutating persisted MIDI data.
    // This immediately normalizes connection UI to "Not connected" when idle.
    final connectionState = _ref.read(midiConnectionStateProvider.notifier);
    await connectionState.cancel(reason: 'settings_reset');

    // MIDI preferences (delegate to MIDI's own reset)
    await _ref.read(midiPreferencesProvider.notifier).clearAllMidiData();
    await _ref.read(audioMonitorSettingsNotifier.notifier).clearAllAudioData();
    await _ref.read(midiSettingsOnboardingProvider.notifier).reset();

    // Force rebuilds
    _ref.invalidate(appThemeModeProvider);
    _ref.invalidate(appPaletteProvider);
    _ref.invalidate(chordNotationStyleProvider);
    _ref.invalidate(selectedTonalityProvider);
    _ref.invalidate(audioMonitorSettingsNotifier);
    _ref.invalidate(midiSettingsOnboardingProvider);

    // Ensure transport is disconnected after reset.
    await connectionState.disconnect();
  }
}
