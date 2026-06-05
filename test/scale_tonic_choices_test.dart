import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

List<String> _labels(ScaleKind kind) =>
    tonicChoicesForKind(kind).map((tonic) => tonic.label).toList();

void main() {
  group('tonicChoicesForKind', () {
    test(
      'major offers the 15 standard signatures, ordered sharp-then-flat',
      () {
        expect(_labels(ScaleKind.major), [
          'C',
          'C#',
          'Db',
          'D',
          'Eb',
          'E',
          'F',
          'F#',
          'Gb',
          'G',
          'Ab',
          'A',
          'Bb',
          'B',
          'Cb',
        ]);
      },
    );

    test('natural minor offers its own 15 signatures', () {
      expect(_labels(ScaleKind.aeolian), [
        'C',
        'C#',
        'D',
        'D#',
        'Eb',
        'E',
        'F',
        'F#',
        'G',
        'G#',
        'Ab',
        'A',
        'A#',
        'Bb',
        'B',
      ]);
    });

    test(
      'the three boundary pitch classes carry both enharmonic spellings',
      () {
        final major = _labels(ScaleKind.major);
        expect(major, containsAll(['Gb', 'F#'])); // pitch class 6
        expect(major, containsAll(['Db', 'C#'])); // pitch class 1
        expect(major, containsAll(['Cb', 'B'])); // pitch class 11
      },
    );

    test('nonsense roots requiring double accidentals are excluded', () {
      // D# major would need F##/C##; A# and G# major are likewise unwritable.
      expect(_labels(ScaleKind.major), isNot(contains('D#')));
      expect(_labels(ScaleKind.major), isNot(contains('A#')));
      expect(_labels(ScaleKind.major), isNot(contains('G#')));
    });

    test('a root can be valid in one mode but not another', () {
      // D# minor is a real key (6 sharps); D# major is not.
      expect(_labels(ScaleKind.aeolian), contains('D#'));
      expect(_labels(ScaleKind.major), isNot(contains('D#')));
    });

    test('every offered tonic spells with single accidentals in its mode', () {
      for (final kind in ScaleKind.values) {
        for (final tonic in tonicChoicesForKind(kind)) {
          final scale = Scale(tonic, kind);
          final names = spellScaleTones(
            pitchClasses: scale.pitchClasses,
            tonicLetter: tonic.letter,
            letterOffsets: kind.spellingLetterOffsets,
          );
          for (final name in names) {
            expect(
              name.contains('x') || name.contains('bb'),
              isFalse,
              reason:
                  '$tonic ${kind.label} spells $name with a double '
                  'accidental',
            );
          }
        }
      }
    });
  });
}
