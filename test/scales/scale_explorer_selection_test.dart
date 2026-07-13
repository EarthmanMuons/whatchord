import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/scales/services/scale_explorer_selection.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('scale explorer selection helpers', () {
    test('resolves exact tonic when the scale offers it', () {
      expect(
        resolveScaleExplorerTonic(
          choices: const [Tonic.fSharp, Tonic.gFlat],
          pitchClass: 6,
          exact: Tonic.gFlat,
          preferFlat: false,
        ),
        Tonic.gFlat,
      );
    });

    test('uses spelling preference for enharmonic tonic choices', () {
      expect(
        resolveScaleExplorerTonic(
          choices: const [Tonic.fSharp, Tonic.gFlat],
          pitchClass: 6,
          preferFlat: true,
        ),
        Tonic.gFlat,
      );
      expect(
        resolveScaleExplorerTonic(
          choices: const [Tonic.fSharp, Tonic.gFlat],
          pitchClass: 6,
          preferFlat: false,
        ),
        Tonic.fSharp,
      );
    });

    test('keeps selected degree only for compatible harmonized scales', () {
      expect(
        keepsSelectedOrdinalForScaleChange(
          current: ScaleKind.major,
          next: ScaleKind.dorian,
        ),
        isTrue,
      );
      expect(
        keepsSelectedOrdinalForScaleChange(
          current: ScaleKind.major,
          next: ScaleKind.majorPentatonic,
        ),
        isFalse,
      );
    });

    test('formats selected degree function label', () {
      expect(
        selectedScaleDegreeFunctionLabel(
          scale: const Scale(Tonic.c, ScaleKind.major),
          selectedOrdinal: 5,
          supportsChordHarmony: true,
        ),
        'Dominant, pulls toward I',
      );
      expect(
        selectedScaleDegreeFunctionLabel(
          scale: const Scale(Tonic.c, ScaleKind.major),
          selectedOrdinal: null,
          supportsChordHarmony: true,
        ),
        isNull,
      );
    });
  });
}
