import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/theory_domain.dart';
import 'analysis_mode_provider.dart';
import 'chord_presentation_provider.dart';

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return null;

  return ref.watch(chordPresentationProvider)?.scaleDegree;
});
