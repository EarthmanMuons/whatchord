import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chord_symbol.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';
import 'package:what_chord/features/settings/persistence/preferences_keys.dart';

final chordSymbolProvider =
    NotifierProvider<ChordSymbolNotifier, ChordSymbolStyle>(
      ChordSymbolNotifier.new,
    );

class ChordSymbolNotifier extends Notifier<ChordSymbolStyle> {
  @override
  ChordSymbolStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(SettingsKeys.chordSymbolStyle);

    if (stored == null) return ChordSymbolStyle.standard;

    return ChordSymbolStyle.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => ChordSymbolStyle.standard,
    );
  }

  Future<void> setStyle(ChordSymbolStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(SettingsKeys.chordSymbolStyle, style.name);
  }
}
