import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord_theory/whatchord_theory.dart';

import 'analysis_mode_provider.dart';
import 'chord_presentation_provider.dart';

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  return ref.watch(detectedScaleDegreeAnalysisProvider)?.degree;
});

final detectedScaleDegreeAnalysisProvider = Provider<ScaleDegreeAnalysis?>((
  ref,
) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return null;

  return ref.watch(chordPresentationProvider)?.scaleDegreeAnalysis;
});
