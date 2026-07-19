import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

void main() {
  test('popCount counts set bits in a mask', () {
    expect(popCount(0), 0);
    expect(popCount(0xaaa), 6);
    expect(popCount(0xfff), 12);
  });

  test('intervalsFromMask lists set bit positions ascending', () {
    expect(intervalsFromMask(0), isEmpty);
    expect(intervalsFromMask(0x091), [0, 4, 7]);
    expect(intervalsFromMask(0xfff), List.generate(12, (i) => i));
  });
}
