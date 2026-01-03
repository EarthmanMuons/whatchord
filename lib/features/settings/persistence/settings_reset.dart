import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';
import 'package:what_chord/core/theme/providers/app_palette_provider.dart';
import 'package:what_chord/core/theme/providers/theme_mode_provider.dart';
import 'package:what_chord/features/midi/providers/midi_connection_manager.dart';
import 'package:what_chord/features/midi/providers/midi_prefs_provider.dart';
import 'package:what_chord/features/midi/providers/midi_providers.dart';
import 'package:what_chord/features/theory/providers/chord_symbol_provider.dart';

import 'settings_keys.dart';

final settingsResetProvider = Provider<SettingsResetService>((ref) {
  return SettingsResetService(ref);
});

class SettingsResetService {
  SettingsResetService(this._ref);
  final Ref _ref;

  Future<void> resetAllToDefaults() async {
    final prefs = _ref.read(sharedPreferencesProvider);

    // 1) Clear non-MIDI (general app settings) keys.
    await prefs.remove(SettingsKeys.themeMode);
    await prefs.remove(SettingsKeys.appPalette);
    await prefs.remove(SettingsKeys.chordSymbolStyle);

    // 2) Best-effort: stop scanning + disconnect (runtime state)
    final actions = _ref.read(midiConnectionActionsProvider);
    await actions.stopScanning();
    await actions.disconnect();

    // 3) Clear reconnect backoff / stale connection device/message
    _ref.read(midiConnectionManagerProvider.notifier).resetToIdle();

    // 4) Clear persisted MIDI keys
    await _ref.read(midiPrefsProvider.notifier).clearAllMidiData();

    // 5) Force theme/settings notifiers to rebuild from defaults if desired
    _ref.invalidate(themeModeProvider);
    _ref.invalidate(appPaletteProvider);
    _ref.invalidate(chordSymbolProvider);
  }
}
