import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  test('orders chord members by stack degree before chromatic interval', () {
    const identity = ChordIdentity(
      rootPc: 1,
      bassPc: 7,
      quality: ChordQualityToken.minorMajor7,
      toneRolesByInterval: {
        0: ChordToneRole.root,
        2: ChordToneRole.nine,
        3: ChordToneRole.minor3,
        6: ChordToneRole.sharp11,
        7: ChordToneRole.perfect5,
        11: ChordToneRole.major7,
      },
      presentIntervalsMask:
          (1 << 0) | (1 << 2) | (1 << 3) | (1 << 6) | (1 << 7) | (1 << 11),
    );

    expect(
      ChordToneOrdering.byDegree(const [0, 2, 3, 6, 7, 11], identity: identity),
      const [0, 3, 7, 11, 2, 6],
    );
  });
}
