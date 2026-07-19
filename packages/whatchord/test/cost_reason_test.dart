import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

import 'package:whatchord/testing.dart';

final _analyzer = ChordAnalyzer();

void main() {
  test('tone-set reasons expose their count as structured data', () {
    final results = _analyzer.explain(
      chordInputFromNames(names: ['C', 'E', 'G'], bass: 'C'),
      context: makeAnalysisContext(),
    );
    final required = results.first.costReasons.firstWhere(
      (reason) => reason.label == CostReasonLabel.requiredTones,
    );

    expect(required.count, 2);
  });
}
