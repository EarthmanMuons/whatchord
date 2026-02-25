import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'selected_tonality_notifier.dart';

final diatonicPitchClassesProvider = Provider<Set<int>>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final out = <int>{};

  for (int pc = 0; pc < 12; pc++) {
    if (tonality.containsPitchClass(pc)) out.add(pc);
  }

  return out;
});
