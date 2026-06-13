import 'package:flutter_test/flutter_test.dart';

import '../tool/src/chord_id_engine.dart';

void main() {
  test('includes academic names in candidate output', () {
    final result = identifyChord('C E G');

    expect(result.candidates.first.academicName, 'C major');
    expect(result.candidates.first.toJson()['academicName'], 'C major');
  });

  test('separates chord tones and also-played input tones', () {
    final result = identifyChord('C E G Bb D');
    final suspended = result.candidates.firstWhere(
      (candidate) => candidate.symbol == 'C7sus2',
    );

    expect(suspended.chordTones, 'C D G B♭');
    expect(suspended.alsoPlayedNotes, 'E');
    expect(suspended.toJson()['chordTones'], 'C D G B♭');
    expect(suspended.toJson()['alsoPlayedNotes'], 'E');
  });

  test('orders recognized tones by chord degree', () {
    final result = identifyChord('C E G Bb D');
    final suspended = result.candidates.firstWhere(
      (candidate) => candidate.symbol == 'D9sus4(♭13) / C',
    );

    expect(suspended.chordTones, 'D G C E B♭');
  });

  test('accepts hyphen-delimited note lists', () {
    final result = identifyChord('B-F#-D#-E#-G#-C#');

    expect(result.ok, isTrue);
    expect(result.notes, ['B', 'F♯', 'D♯', 'E♯', 'G♯', 'C♯']);
  });

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
