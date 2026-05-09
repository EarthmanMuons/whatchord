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

  group('NoteLongFormFormatter', () {
    test('spells notes in plain English', () {
      expect(NoteLongFormFormatter.format('C'), 'C natural');
      expect(NoteLongFormFormatter.format('Bb'), 'B flat');
      expect(NoteLongFormFormatter.format('F#'), 'F sharp');
      expect(NoteLongFormFormatter.format('Abb'), 'A double flat');
      expect(NoteLongFormFormatter.format('Fx'), 'F double sharp');
    });
  });

  group('chordSymbolDisplayLabel', () {
    test('converts root, quality, and slash bass accidentals for UI', () {
      final symbol = ChordSymbol(root: 'Bb', quality: '7(#11)', bass: 'F#');

      expect(chordSymbolDisplayLabel(symbol), 'B♭7(♯11) / F♯');
    });
  });
}
