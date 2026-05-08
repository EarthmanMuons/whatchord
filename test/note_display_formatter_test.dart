import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('noteDisplayLabel', () {
    test('converts canonical ASCII note accidentals for UI', () {
      expect(noteDisplayLabel('Bb'), 'B♭');
      expect(noteDisplayLabel('F#'), 'F♯');
      expect(noteDisplayLabel('Abb'), 'A𝄫');
      expect(noteDisplayLabel('Fx'), 'F𝄪');
    });
  });

  group('theoryTokenDisplayLabel', () {
    test('converts canonical ASCII role and quality tokens for UI', () {
      expect(theoryTokenDisplayLabel('b9'), '♭9');
      expect(theoryTokenDisplayLabel('#11'), '♯11');
      expect(theoryTokenDisplayLabel('bb7'), '𝄫7');
      expect(theoryTokenDisplayLabel('m7(b5)'), 'm7(♭5)');
    });
  });
}
