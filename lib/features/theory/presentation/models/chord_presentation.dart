import 'package:meta/meta.dart';

import '../../domain/theory_domain.dart';
import 'chord_symbol.dart';

@immutable
class ChordPresentation {
  const ChordPresentation({
    required this.identity,
    required this.symbol,
    required this.longLabel,
    required this.semanticLongLabel,
    required this.members,
    required this.memberDegrees,
    required this.memberPitchClasses,
    required this.scaleDegreeAnalysis,
    required this.normalizedVoicing,
  });

  final ChordIdentity identity;
  final ChordSymbol symbol;
  final String longLabel;
  final String semanticLongLabel;
  final List<String> members;
  final List<String> memberDegrees;
  final Set<int> memberPitchClasses;
  final ScaleDegreeAnalysis? scaleDegreeAnalysis;
  final List<int> normalizedVoicing;

  ScaleDegree? get scaleDegree => scaleDegreeAnalysis?.degree;
}
