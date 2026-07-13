import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord/whatchord.dart';

import 'selected_tonality_notifier.dart';

/// 12 pitch-class display names (0..11) based on the current tonality.
/// Recomputes only when tonality/key signature changes.
final pitchClassNamesProvider = Provider<List<String>>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);

  return List<String>.generate(
    12,
    (pc) => noteNameForPitchClass(pc, tonality: tonality),
    growable: false,
  );
});
