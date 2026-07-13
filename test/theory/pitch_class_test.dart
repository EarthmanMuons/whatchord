import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('normalizeNoteNameToAscii', () {
    test('canonicalizes ASCII and Unicode accidentals', () {
      expect(normalizeNoteNameToAscii(' f♯ '), 'F#');
      expect(normalizeNoteNameToAscii('b♭'), 'Bb');
      expect(normalizeNoteNameToAscii('G𝄪'), 'Gx');
      expect(normalizeNoteNameToAscii('A𝄫'), 'Abb');
      expect(normalizeNoteNameToAscii('C##'), 'Cx');
    });

    test('rejects a lone accidental with no note letter', () {
      // The flat glyphs normalize to an ASCII "b"; guard against mistaking
      // them for the note letter B.
      for (final glyph in const ['𝄫', '♭', '♯', '𝄪', '#', 'x']) {
        expect(
          () => normalizeNoteNameToAscii(glyph),
          throwsArgumentError,
          reason: 'lone "$glyph" is not a note name',
        );
      }
    });
  });

  group('pitchClassFromNoteName', () {
    test('resolves double accidentals', () {
      expect(pitchClassFromNoteName('C𝄫'), 10); // C double-flat = Bb
      expect(pitchClassFromNoteName('G𝄪'), 9); // G double-sharp = A
      expect(pitchClassFromNoteName('Abb'), 7); // A double-flat = G
    });

    test('rejects a lone double-flat glyph', () {
      expect(() => pitchClassFromNoteName('𝄫'), throwsArgumentError);
    });
  });
}
