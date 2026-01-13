import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/core_preferences_keys.dart';
import '../providers/shared_preferences_provider.dart';
import '../models/app_palette.dart';

final appPaletteProvider = NotifierProvider<AppPaletteNotifier, AppPalette>(
  AppPaletteNotifier.new,
);

class AppPaletteNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(CorePreferencesKeys.appPalette);

    if (stored == null) return AppPalette.blue;

    return AppPalettePersistence.fromPrefsKey(stored);
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(CorePreferencesKeys.appPalette, palette.prefsKey);
  }
}
