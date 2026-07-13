import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/lookup/lookup_voicing.dart';

void main() {
  group('LookupVoicing.midiFromPitchClasses', () {
    test('returns empty for no notes', () {
      expect(LookupVoicing.midiFromPitchClasses(const []), isEmpty);
    });

    test('places the first note as the bass in octave 3', () {
      expect(LookupVoicing.midiFromPitchClasses(const [0]), [48]);
    });

    test('stacks a close triad ascending above the bass', () {
      // C E G -> C3 E3 G3.
      expect(LookupVoicing.midiFromPitchClasses(const [0, 4, 7]), [48, 52, 55]);
    });

    test('preserves press order, spreading upward', () {
      // C G E -> C3 G3 E4 (E lands above G, not below).
      expect(LookupVoicing.midiFromPitchClasses(const [0, 7, 4]), [48, 55, 64]);
    });

    test('repeats climb to the next octave', () {
      // C C C -> C3 C4 C5.
      expect(LookupVoicing.midiFromPitchClasses(const [0, 0, 0]), [48, 60, 72]);
    });

    test('result is strictly ascending so MIDI order tracks press order', () {
      final midi = LookupVoicing.midiFromPitchClasses(const [11, 0, 4, 0]);
      for (var i = 1; i < midi.length; i++) {
        expect(midi[i], greaterThan(midi[i - 1]));
      }
    });

    test('normalizes pitch classes modulo 12', () {
      expect(LookupVoicing.midiFromPitchClasses(const [12, 16]), [48, 52]);
    });

    test('does not climb past the top of the keyboard', () {
      final midi = LookupVoicing.midiFromPitchClasses(List<int>.filled(12, 0));
      expect(midi.every((m) => m <= 108), isTrue);
    });
  });
}
