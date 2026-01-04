import 'package:flutter_test/flutter_test.dart';
import 'package:what_chord/features/theory/engine/engine.dart';

int maskOf(List<int> pcs) {
  var m = 0;
  for (final pc in pcs) {
    m |= (1 << (pc % 12));
  }
  return m;
}

void main() {
  test('C E G Bb D prefers a 7th-family identity over major triad', () {
    final input = ChordInput(
      pcMask: maskOf([0, 4, 7, 10, 2]),
      bassPc: 0,
      noteCount: 5,
    );

    final top = ChordAnalyzer.analyze(input).first.identity;
    expect(top.quality.isSeventhFamily, isTrue);
  });
}
