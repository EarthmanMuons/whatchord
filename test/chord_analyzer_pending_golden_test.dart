import 'package:whatchord/features/theory/theory.dart';

import 'helpers/chord_analyzer_golden_helpers.dart';

void main() {
  final cases = <GoldenCase>[
    golden(
      description: 'minor and major third contradiction',
      expectedSymbol: 'Cm',
      pcs: ['C', 'Eb', 'E', 'G'],
      expectedRoot: 'C',
      expectedQuality: ChordQualityToken.minor,
      skipReason:
          'Pending UX/scoring decision for simultaneous minor and major thirds.',
    ),
  ];

  runChordAnalyzerGoldenCases(cases);
}
