import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scale_degree.dart';
import 'analysis_context_provider.dart';
import 'analysis_mode_provider.dart';
import 'chord_candidates_providers.dart';

final detectedScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final mode = ref.watch(analysisModeProvider);
  if (mode != AnalysisMode.chord) return null;

  final best = ref.watch(bestChordCandidateProvider);
  if (best == null) return null;

  final context = ref.watch(analysisContextProvider);
  return context.tonality.scaleDegreeForChord(best.identity);
});
