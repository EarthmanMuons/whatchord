import 'package:meta/meta.dart';

import '../../domain/theory_domain.dart';
import 'chord_symbol.dart';

@immutable
class ChordPresentation {
  const ChordPresentation({
    required this.identity,
    required this.symbol,
    required this.longLabel,
    required this.members,
    required this.memberDegrees,
    required this.memberPitchClasses,
    required this.scaleDegree,
    required this.normalizedVoicing,
  });

  final ChordIdentity identity;
  final ChordSymbol symbol;
  final String longLabel;
  final List<String> members;
  final List<String> memberDegrees;
  final Set<int> memberPitchClasses;
  final ScaleDegree? scaleDegree;
  final List<int> normalizedVoicing;
}
