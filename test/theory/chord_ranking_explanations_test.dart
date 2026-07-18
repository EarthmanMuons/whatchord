import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/theory/theory.dart';

void main() {
  test('covers every analyzer ranking decision', () {
    expect(
      ChordRankingExplanations.decisionRuleNames,
      ChordCandidateRanking.decisionRuleNames,
    );
  });

  test('covers every analyzer cost-reason label', () {
    expect(ChordRankingExplanations.costReasonLabels, CostReasonLabel.values);
  });
}
