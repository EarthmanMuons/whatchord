import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/theory_domain.dart';
import 'selected_tonality_notifier.dart';

final selectedKeySignatureProvider = Provider<KeySignature>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);

  for (final ks in keySignatureRows) {
    if (tonality.mode == TonalityMode.major && ks.relativeMajor == tonality) {
      return ks;
    }
    if (tonality.mode == TonalityMode.minor && ks.relativeMinor == tonality) {
      return ks;
    }
  }

  // Fallback: if tonality isn't represented exactly (e.g., user chose "F#"
  // but list uses "F♯"), try a normalized compare.
  final normalized = _normalizeTonalityLabel(tonality.tonic);

  for (final ks in keySignatureRows) {
    final maj = _normalizeTonalityLabel(ks.relativeMajor.tonic);
    final min = _normalizeTonalityLabel(ks.relativeMinor.tonic);

    if (tonality.mode == TonalityMode.major && maj == normalized) return ks;
    if (tonality.mode == TonalityMode.minor && min == normalized) return ks;
  }

  // Final fallback: default to C major / no sharps/flats.
  return keySignatureRows.firstWhere((k) => k.accidentalCount == 0);
});

String _normalizeTonalityLabel(String tonic) {
  return tonic.trim().replaceAll('♯', '#').replaceAll('♭', 'b').toUpperCase();
}
