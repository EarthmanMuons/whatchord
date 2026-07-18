import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

void main() {
  test('popCount counts set bits in a mask', () {
    expect(popCount(0), 0);
    expect(popCount(0xaaa), 6);
    expect(popCount(0xfff), 12);
  });
}
