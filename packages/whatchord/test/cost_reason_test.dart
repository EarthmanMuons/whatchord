import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

import 'package:whatchord/testing.dart';

void main() {
  setUp(ChordAnalyzer.clearCache);

  test('tone-set reasons expose their count as structured data', () {
    final results = ChordAnalyzer.explain(
      chordInputFromNames(names: ['C', 'E', 'G'], bass: 'C'),
      context: makeAnalysisContext(),
    );
    final required = results.first.costReasons.firstWhere(
      (reason) => reason.label == CostReasonLabel.requiredTones,
    );

    expect(required.count, 2);
  });
}
