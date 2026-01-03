import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/settings/persistence/preferences_keys.dart';

import '../../persistence/shared_preferences_provider.dart';
import '../models/app_palette.dart';

final appPaletteProvider = NotifierProvider<AppPaletteNotifier, AppPalette>(
  AppPaletteNotifier.new,
);

class AppPaletteNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(SettingsKeys.appPalette);

    const fallback = AppPalette.indigo;

    if (stored == null) return fallback;

    return AppPalette.values.firstWhere(
      (p) => p.name == stored,
      orElse: () => fallback,
    );
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(SettingsKeys.appPalette, palette.name);
  }
}
