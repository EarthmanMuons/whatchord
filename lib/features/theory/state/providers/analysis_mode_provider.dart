import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chord_input_provider.dart';

enum AnalysisMode { none, single, dyad, chord }

final analysisModeProvider = Provider<AnalysisMode>((ref) {
  final input = ref.watch(chordInputProvider);
  if (input == null || input.noteCount == 0) return AnalysisMode.none;
  if (input.noteCount == 1) return AnalysisMode.single;
  if (input.noteCount == 2) return AnalysisMode.dyad;
  return AnalysisMode.chord;
});
