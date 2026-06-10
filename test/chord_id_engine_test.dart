import 'package:flutter_test/flutter_test.dart';

import '../tool/src/chord_id_engine.dart';

void main() {
  group('identifyChord input limits', () {
    test('accepts up to 128 note tokens', () {
      final notes = List<String>.filled(maxChordIdNoteTokens, 'C').join(' ');

      final result = identifyChord(notes);

      expect(result.ok, isTrue);
    });

    test('rejects more than 128 note tokens', () {
      final notes = List<String>.filled(
        maxChordIdNoteTokens + 1,
        'C',
      ).join(' ');

      final result = identifyChord(notes);

      expect(result.ok, isFalse);
      expect(
        result.errors,
        contains(
          'Too many notes. Enter no more than 128 note names or MIDI numbers.',
        ),
      );
    });
  });
}
