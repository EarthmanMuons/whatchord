import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/piano/piano.dart';

void main() {
  group('PianoGeometry', () {
    const a0 = 21;
    const c4 = 60;
    const c8 = 108;

    test('white midis span the full 88-key keyboard from A0 to C8', () {
      final geometry = PianoGeometry(
        firstWhiteMidi: PianoGeometry.fullKeyboardLowestMidi,
        whiteKeyCount: PianoGeometry.fullKeyboardWhiteKeyCount,
      );
      expect(geometry.whiteMidis, hasLength(52));
      expect(geometry.whiteMidis.first, a0);
      expect(geometry.whiteMidis.last, c8);
      expect(geometry.whiteMidis.any(PianoGeometry.isBlackMidi), isFalse);
    });

    test('white midis step by whole tones except E-F and B-C', () {
      final geometry = PianoGeometry(firstWhiteMidi: c4, whiteKeyCount: 8);
      expect(geometry.whiteMidis, [60, 62, 64, 65, 67, 69, 71, 72]);
    });

    test('white pitch classes follow the octave cycle from the start key', () {
      final geometry = PianoGeometry(firstWhiteMidi: a0, whiteKeyCount: 10);
      expect(geometry.whitePitchClassForIndex(0), 9, reason: 'A');
      expect(geometry.whitePitchClassForIndex(1), 11, reason: 'B');
      expect(geometry.whitePitchClassForIndex(2), 0, reason: 'C');
      expect(geometry.whiteMidiForIndex(2), 24);
    });

    test('a black-key start falls back to a C-position cycle', () {
      final geometry = PianoGeometry(firstWhiteMidi: 61, whiteKeyCount: 3);
      expect(geometry.whitePitchClassForIndex(0), 0);
      expect(geometry.whiteMidis, [61, 63, 65]);
    });

    test('black keys sit after C, D, F, G, and A only', () {
      const blackAfter = {0, 2, 5, 7, 9};
      for (final pc in const [0, 2, 4, 5, 7, 9, 11]) {
        expect(
          PianoGeometry.hasBlackAfterWhitePc(pc),
          blackAfter.contains(pc),
          reason: 'pc $pc',
        );
      }
    });

    test(
      'isBlackMidi matches the five black pitch classes in every octave',
      () {
        const blackPcs = {1, 3, 6, 8, 10};
        for (var midi = 21; midi <= 108; midi++) {
          expect(
            PianoGeometry.isBlackMidi(midi),
            blackPcs.contains(midi % 12),
            reason: 'midi $midi',
          );
        }
      },
    );

    test(
      'black-key center bias leans C#/F# left, D#/A# right, G# centered',
      () {
        const w = 100.0;
        expect(PianoGeometry.blackCenterBiasForPc(1, w), -10, reason: 'C#');
        expect(PianoGeometry.blackCenterBiasForPc(3, w), 10, reason: 'D#');
        expect(PianoGeometry.blackCenterBiasForPc(6, w), -15, reason: 'F#');
        expect(PianoGeometry.blackCenterBiasForPc(8, w), 0, reason: 'G#');
        expect(PianoGeometry.blackCenterBiasForPc(10, w), 15, reason: 'A#');
      },
    );

    group('keyRectForMidi', () {
      const w = 100.0;
      final geometry = PianoGeometry(firstWhiteMidi: c4, whiteKeyCount: 7);
      final totalWidth = 7 * w;

      PianoKeyRect rect(int midi) => geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: w,
        totalWidth: totalWidth,
      );

      test('white keys occupy one width at their index', () {
        expect(rect(c4).left, 0);
        expect(rect(c4).right, w);
        final g4 = rect(67);
        expect(g4.left, 4 * w);
        expect(g4.width, w);
      });

      test('black keys center on the boundary plus their bias', () {
        final cSharp = rect(61);
        expect(cSharp.width, closeTo(62, 0.001));
        // Boundary at 100, bias -10, so center 90 and left 90 - 31.
        expect(cSharp.left, closeTo(59, 0.001));

        final gSharp = rect(68);
        // Boundary between G and A at 500, no bias for G#.
        expect(gSharp.left, closeTo(500 - 31, 0.001));
      });

      test('a black key hanging off the span end clamps flush to the edge', () {
        final narrow = PianoGeometry(firstWhiteMidi: c4, whiteKeyCount: 2);
        final dSharp = narrow.keyRectForMidi(
          midi: 63,
          whiteKeyWidth: w,
          totalWidth: 2 * w,
        );
        // Unclamped left would be 200 + 10 - 31 = 179; clamped to 200 - 62.
        expect(dSharp.left, closeTo(138, 0.001));
        expect(dSharp.right, closeTo(200, 0.001));
      });

      test('an out-of-span note falls back to the nearest white rect', () {
        final dSharp5 = rect(75);
        expect(dSharp5.left, 6 * w);
        expect(dSharp5.width, w);
      });
    });

    group('whiteIndexForMidi', () {
      final geometry = PianoGeometry(firstWhiteMidi: c4, whiteKeyCount: 7);

      test('maps black notes to the preceding white index', () {
        expect(geometry.whiteIndexForMidi(61), 0, reason: 'C# after C');
        expect(geometry.whiteIndexForMidi(66), 3, reason: 'F# after F');
      });

      test('clamps notes outside the span to the keyboard ends', () {
        expect(geometry.whiteIndexForMidi(21), 0);
        expect(geometry.whiteIndexForMidi(108), 6);
      });
    });

    group('viewport helpers', () {
      test('white key width divides the viewport evenly', () {
        expect(
          PianoGeometry.whiteKeyWidthForViewport(
            viewportWidth: 350,
            visibleWhiteKeyCount: 7,
          ),
          50,
        );
      });

      test('visible count floors the fit and clamps to the given range', () {
        expect(
          PianoGeometry.visibleWhiteKeyCountForViewport(
            viewportWidth: 359,
            minWhiteKeyWidth: 24,
          ),
          14,
        );
        expect(
          PianoGeometry.visibleWhiteKeyCountForViewport(
            viewportWidth: 10,
            minWhiteKeyWidth: 24,
          ),
          1,
        );
        expect(
          PianoGeometry.visibleWhiteKeyCountForViewport(
            viewportWidth: 10000,
            minWhiteKeyWidth: 24,
          ),
          PianoGeometry.fullKeyboardWhiteKeyCount,
        );
      });
    });
  });
}
