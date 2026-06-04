import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('scaleDegreeFunction', () {
    test('names every degree in a major key', () {
      const scale = Scale(Tonic.c, ScaleKind.major);
      expect(
        [for (var i = 1; i <= 7; i++) scaleDegreeFunction(scale, i).name],
        [
          'tonic',
          'supertonic',
          'mediant',
          'subdominant',
          'dominant',
          'submediant',
          'leading tone',
        ],
      );
    });

    test('major degrees carry a resolution tendency', () {
      const scale = Scale(Tonic.c, ScaleKind.major);
      expect(scaleDegreeFunction(scale, 5).tendency, 'pulls toward I');
      expect(scaleDegreeFunction(scale, 2).tendency, 'leads to V');
      expect(scaleDegreeFunction(scale, 7).tendency, 'resolves to I');
    });

    test('the mediant resolves in major and natural minor', () {
      expect(
        scaleDegreeFunction(const Scale(Tonic.c, ScaleKind.major), 3).tendency,
        'passes toward IV or vi',
      );
      expect(
        scaleDegreeFunction(
          const Scale(Tonic.a, ScaleKind.aeolian),
          3,
        ).tendency,
        'leans toward ♭VI',
      );
    });

    test('the augmented harmonic-minor mediant has no tendency', () {
      final mediant = scaleDegreeFunction(
        const Scale(Tonic.a, ScaleKind.harmonicMinor),
        3,
      );
      expect(mediant.name, 'mediant');
      expect(mediant.tendency, isNull);
    });

    test('melodic minor names degrees without tendencies', () {
      const scale = Scale(Tonic.a, ScaleKind.melodicMinor);
      expect(scaleDegreeFunction(scale, 5).name, 'dominant');
      expect(scaleDegreeFunction(scale, 5).tendency, isNull);
      expect(scaleDegreeFunction(scale, 7).name, 'leading tone');
      expect(scaleDegreeFunction(scale, 7).tendency, isNull);
    });

    test('natural minor degree 7 is a subtonic that leads to the mediant', () {
      const scale = Scale(Tonic.a, ScaleKind.aeolian);
      final seventh = scaleDegreeFunction(scale, 7);
      expect(seventh.name, 'subtonic');
      expect(seventh.tendency, 'leads to ♭III');
      expect(scaleDegreeFunction(scale, 5).tendency, 'pulls toward i');
      // The dominant triad is minor here, so it is referenced as a lowercase v.
      expect(scaleDegreeFunction(scale, 4).tendency, 'pulls toward v or i');
    });

    test('harmonic minor raises degree 7 to a leading tone', () {
      const scale = Scale(Tonic.a, ScaleKind.harmonicMinor);
      final seventh = scaleDegreeFunction(scale, 7);
      expect(seventh.name, 'leading tone');
      expect(seventh.tendency, 'resolves to i');
      // A leading tone makes the dominant major, so it is referenced as V.
      expect(scaleDegreeFunction(scale, 4).tendency, 'pulls toward V or i');
    });

    test('church modes name the degree but drop the tendency', () {
      const scale = Scale(Tonic.d, ScaleKind.dorian);
      final submediant = scaleDegreeFunction(scale, 6);
      expect(submediant.name, 'submediant');
      expect(submediant.tendency, isNull);
    });
  });
}
