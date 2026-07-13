import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord/whatchord.dart';

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

  return keySignatureRows.firstWhere((k) => k.accidentalCount == 0);
});
