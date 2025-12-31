import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chord_analysis.dart';
import '../models/chord_symbol.dart';
import '../models/scale_degree.dart';
import '../providers/tonality_provider.dart';

final chordAnalysisProvider = Provider<ChordAnalysis>((ref) {
  return const ChordAnalysis(
    symbol: ChordSymbol(root: 'C', quality: 'maj', bass: 'E'),
    inversion: '1st inversion',
  );
});

final activeScaleDegreeProvider = Provider<ScaleDegree?>((ref) {
  final tonality = ref.watch(selectedTonalityProvider);
  final analysis = ref.watch(chordAnalysisProvider);

  // Stub logic
  if (analysis.symbol.format().startsWith(tonality.label)) {
    return ScaleDegree.one;
  }
  return null;
});
