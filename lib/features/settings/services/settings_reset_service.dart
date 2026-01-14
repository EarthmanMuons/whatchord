import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/core_preferences_keys.dart';
import 'package:what_chord/core/providers/app_palette_notifier.dart';
import 'package:what_chord/core/providers/app_theme_mode_notifier.dart';
import 'package:what_chord/core/providers/shared_preferences_provider.dart';
import 'package:what_chord/features/midi/providers/midi_connection_notifier.dart';
import 'package:what_chord/features/midi/providers/midi_preferences_notifier.dart';
import 'package:what_chord/features/theory/state/persistence/theory_preferences_keys.dart';
import 'package:what_chord/features/theory/state/providers/theory_preferences_notifier.dart';

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

    // Force rebuilds
    _ref.invalidate(appThemeModeProvider);
    _ref.invalidate(appPaletteProvider);
    _ref.invalidate(chordNotationStyleProvider);

    // Reset MIDI connection state
    final connection = _ref.read(midiConnectionProvider.notifier);
    await connection.stopScanning();
    await connection.disconnect();
    connection.resetToIdle();
  }
}
