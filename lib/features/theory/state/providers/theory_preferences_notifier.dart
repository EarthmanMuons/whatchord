import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../../presentation/models/chord_symbol.dart';
import '../persistence/theory_preferences_keys.dart';

final chordNotationStyleProvider =
    NotifierProvider<ChordNotationStyleNotifier, ChordNotationStyle>(
      ChordNotationStyleNotifier.new,
    );

final noteNameSystemProvider =
    NotifierProvider<NoteNameSystemNotifier, NoteNameSystem>(
      NoteNameSystemNotifier.new,
    );

class ChordNotationStyleNotifier extends Notifier<ChordNotationStyle> {
  @override
  ChordNotationStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(TheoryPreferencesKeys.chordNotationStyle);

    if (stored == null) return ChordNotationStyle.textual;

    return switch (stored) {
      TheoryPreferencesValues.chordNotationStyleSymbolic =>
        ChordNotationStyle.symbolic,
      TheoryPreferencesValues.chordNotationStyleTextual =>
        ChordNotationStyle.textual,
      _ => ChordNotationStyle.textual,
    };
  }

  Future<void> setStyle(ChordNotationStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    final serialized = switch (style) {
      ChordNotationStyle.symbolic =>
        TheoryPreferencesValues.chordNotationStyleSymbolic,
      ChordNotationStyle.textual =>
        TheoryPreferencesValues.chordNotationStyleTextual,
    };
    await prefs.setString(TheoryPreferencesKeys.chordNotationStyle, serialized);
  }
}

class NoteNameSystemNotifier extends Notifier<NoteNameSystem> {
  @override
  NoteNameSystem build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(TheoryPreferencesKeys.noteNameSystem);

    if (stored == null) return NoteNameSystem.international;

    return switch (stored) {
      TheoryPreferencesValues.noteNameSystemGerman => NoteNameSystem.german,
      TheoryPreferencesValues.noteNameSystemFixedDo => NoteNameSystem.fixedDo,
      TheoryPreferencesValues.noteNameSystemInternational =>
        NoteNameSystem.international,
      _ => NoteNameSystem.international,
    };
  }

  Future<void> setSystem(NoteNameSystem system) async {
    state = system;
    final prefs = ref.read(sharedPreferencesProvider);
    final serialized = switch (system) {
      NoteNameSystem.international =>
        TheoryPreferencesValues.noteNameSystemInternational,
      NoteNameSystem.german => TheoryPreferencesValues.noteNameSystemGerman,
      NoteNameSystem.fixedDo => TheoryPreferencesValues.noteNameSystemFixedDo,
    };
    await prefs.setString(TheoryPreferencesKeys.noteNameSystem, serialized);
  }
}
