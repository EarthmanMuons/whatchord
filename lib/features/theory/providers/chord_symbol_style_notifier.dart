import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';

import '../models/chord_symbol.dart';
import '../persistence/theory_preferences_keys.dart';

final chordSymbolStyleProvider =
    NotifierProvider<ChordSymbolStyleNotifier, ChordSymbolStyle>(
      ChordSymbolStyleNotifier.new,
    );

class ChordSymbolStyleNotifier extends Notifier<ChordSymbolStyle> {
  @override
  ChordSymbolStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(TheoryPreferencesKeys.chordSymbolStyle);

    if (stored == null) return ChordSymbolStyle.leadSheet;

    return ChordSymbolStyle.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => ChordSymbolStyle.leadSheet,
    );
  }

  Future<void> setStyle(ChordSymbolStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(TheoryPreferencesKeys.chordSymbolStyle, style.name);
  }
}
