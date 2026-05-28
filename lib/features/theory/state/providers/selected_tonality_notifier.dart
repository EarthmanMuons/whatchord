import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/core/providers/shared_preferences_provider.dart';

import '../../domain/theory_domain.dart';
import '../persistence/theory_preferences_keys.dart';

final selectedTonalityProvider =
    NotifierProvider<SelectedTonalityNotifier, Tonality>(
      SelectedTonalityNotifier.new,
    );

class SelectedTonalityNotifier extends Notifier<Tonality> {
  static const _defaultTonality = Tonality(Tonic.c, TonalityMode.major);

  @override
  Tonality build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(TheoryPreferencesKeys.selectedTonality);
    if (stored == null) return _defaultTonality;

    return _deserializeTonality(stored) ?? _defaultTonality;
  }

  Future<void> setTonality(Tonality tonality) async {
    state = tonality;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      TheoryPreferencesKeys.selectedTonality,
      _serializeTonality(tonality),
    );
  }

  String _serializeTonality(Tonality tonality) {
    final mode = switch (tonality.mode) {
      TonalityMode.major => TheoryPreferencesValues.tonalityModeMajor,
      TonalityMode.minor => TheoryPreferencesValues.tonalityModeMinor,
    };
    return '${tonality.tonic.label}|$mode';
  }

  Tonality? _deserializeTonality(String value) {
    final parts = value.split('|');
    if (parts.length != 2) return null;

    final tonicLabel = parts[0].trim();
    if (tonicLabel.isEmpty) return null;

    final mode = switch (parts[1]) {
      TheoryPreferencesValues.tonalityModeMajor => TonalityMode.major,
      TheoryPreferencesValues.tonalityModeMinor => TonalityMode.minor,
      _ => null,
    };
    if (mode == null) return null;

    final tonic = Tonic.tryFromLabel(tonicLabel);
    if (tonic == null) return null;

    return Tonality(tonic, mode);
  }
}
