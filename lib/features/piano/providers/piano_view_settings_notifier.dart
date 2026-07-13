import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord_app/core/providers/shared_preferences_provider.dart';

import '../models/piano_view_settings.dart';
import '../persistence/piano_preferences_keys.dart';

final pianoViewSettingsProvider =
    NotifierProvider<PianoViewSettingsNotifier, PianoViewSettings>(
      PianoViewSettingsNotifier.new,
    );

class PianoViewSettingsNotifier extends Notifier<PianoViewSettings> {
  @override
  PianoViewSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const defaults = PianoViewSettings.defaults();

    return PianoViewSettings(
      widthScale: PianoViewSettings.clampScale(
        prefs.getDouble(PianoPreferencesKeys.widthScale) ?? defaults.widthScale,
      ),
      heightScale: PianoViewSettings.clampScale(
        prefs.getDouble(PianoPreferencesKeys.heightScale) ??
            defaults.heightScale,
      ),
    );
  }

  Future<void> setWidthScale(double widthScale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final clamped = PianoViewSettings.clampScale(widthScale);

    state = state.copyWith(widthScale: clamped);
    await prefs.setDouble(PianoPreferencesKeys.widthScale, clamped);
  }

  Future<void> setHeightScale(double heightScale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final clamped = PianoViewSettings.clampScale(heightScale);

    state = state.copyWith(heightScale: clamped);
    await prefs.setDouble(PianoPreferencesKeys.heightScale, clamped);
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);

    state = const PianoViewSettings.defaults();
    await prefs.remove(PianoPreferencesKeys.widthScale);
    await prefs.remove(PianoPreferencesKeys.heightScale);
  }

  /// Alias for [reset] used by the global settings-reset flow.
  Future<void> clearAllPianoData() => reset();
}
