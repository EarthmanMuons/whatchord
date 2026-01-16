import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../../presentation/models/chord_symbol.dart';
import '../persistence/theory_preferences_keys.dart';

final chordNotationStyleProvider =
    NotifierProvider<ChordNotationStyleNotifier, ChordNotationStyle>(
      ChordNotationStyleNotifier.new,
    );

class ChordNotationStyleNotifier extends Notifier<ChordNotationStyle> {
  @override
  ChordNotationStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(TheoryPreferencesKeys.chordNotationStyle);

    if (stored == null) return ChordNotationStyle.textual;

    return ChordNotationStyle.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => ChordNotationStyle.textual,
    );
  }

  Future<void> setStyle(ChordNotationStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(TheoryPreferencesKeys.chordNotationStyle, style.name);
  }
}
