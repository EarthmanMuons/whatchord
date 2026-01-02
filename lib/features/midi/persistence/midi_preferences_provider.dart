import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/core/persistence/shared_preferences_provider.dart';

import 'midi_preferences.dart';

final midiPreferencesProvider = Provider<MidiPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MidiPreferences(prefs);
});
