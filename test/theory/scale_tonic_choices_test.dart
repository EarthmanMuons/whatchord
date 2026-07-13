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

    test('conventional-key kinds offer only single-accidental spellings', () {
      // Blues scales inherit the parent major/minor root list but carry a
      // chromatic passing tone, so an extreme root like Cb major blues spells
      // one tone with a double accidental (Ebb). That is accepted, so the clean
      // guarantee only covers the conventional-key kinds themselves.
      for (final kind in ScaleKind.values) {
        if (kind.tonicPolicy != TonicPolicy.conventionalKeys) continue;
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

    test('pentatonic and blues inherit their parent key roots', () {
      expect(_labels(ScaleKind.majorPentatonic), _labels(ScaleKind.major));
      expect(_labels(ScaleKind.majorBlues), _labels(ScaleKind.major));
      expect(_labels(ScaleKind.minorPentatonic), _labels(ScaleKind.aeolian));
      expect(_labels(ScaleKind.minorBlues), _labels(ScaleKind.aeolian));
    });

    test('inherited roots drop the extra enharmonic spellings', () {
      // The sparser pentatonic set would spell G#/D#/Cb cleanly on its own, but
      // inheriting the parent key keeps the conventional root vocabulary.
      expect(_labels(ScaleKind.majorPentatonic), isNot(contains('G#')));
      expect(_labels(ScaleKind.minorPentatonic), isNot(contains('Cb')));
    });

    test(
      'symmetric scales offer every spelled root, chromatically ordered',
      () {
        final wholeTone = _labels(ScaleKind.wholeTone);
        expect(wholeTone.length, 21);
        expect(wholeTone.first, 'C'); // pitch class 0: natural before B#
        expect(wholeTone, containsAll(['Cb', 'B#', 'E#', 'Fb']));
        // No filtering: roots whose scale needs double accidentals are kept.
        final scale = Scale(Tonic.bSharp, ScaleKind.wholeTone);
        final names = spellScaleTones(
          pitchClasses: scale.pitchClasses,
          tonicLetter: Tonic.bSharp.letter,
          letterOffsets: ScaleKind.wholeTone.spellingLetterOffsets,
        );
        expect(names.any((n) => n.contains('x')), isTrue);
      },
    );
  });
}
