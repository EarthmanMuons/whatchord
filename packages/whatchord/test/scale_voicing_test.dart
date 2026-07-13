import 'package:test/test.dart';

import 'package:whatchord/whatchord.dart';

void main() {
  group('scale voicing', () {
    test('C major chords are anchored from middle C', () {
      const cMajor = Scale(Tonic.c, ScaleKind.major);
      final harmony = ScaleHarmonizer.harmonize(cMajor);

      // Middle C = MIDI 60, so the tonic triad stacks the canonical intervals
      // there.
      final tonicTriad = degreeChordMidi(
        cMajor,
        harmony.degrees[0],
        seventh: false,
      );
      expect(tonicTriad, [60, 64, 67]); // C E G

      final dominantSeventh = degreeChordMidi(
        cMajor,
        harmony.degrees[4],
        seventh: true,
      );
      expect(dominantSeventh, [67, 71, 74, 77]); // G B D F
    });

    test('A and above anchor in the lower (C3) octave', () {
      // A natural minor starts on A3 (MIDI 57), not A4.
      expect(scaleRunMidi(const Scale(Tonic.a, ScaleKind.aeolian)).first, 57);
    });

    test('the scale run ascends to the octave and back down', () {
      expect(scaleRunMidi(const Scale(Tonic.c, ScaleKind.major)), [
        60, 62, 64, 65, 67, 69, 71, 72, // C D E F G A B C
        71, 69, 67, 65, 64, 62, 60, // B A G F E D C
      ]);
    });
  });
}
