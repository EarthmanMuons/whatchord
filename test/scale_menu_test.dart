import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/scales/scales.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('Scale menu catalog', () {
    test('covers every scale kind at least once', () {
      final kinds = scaleMenuEntries.map((entry) => entry.kind).toSet();
      expect(kinds, ScaleKind.values.toSet());
    });

    test('common section lists the practical names in order', () {
      final common = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.common)
          .toList();
      expect(common.map((entry) => entry.label), [
        'Major',
        'Natural minor',
        'Harmonic minor',
        'Melodic minor',
      ]);
    });

    test('diatonic modes list the seven major-scale rotations in order', () {
      final modes = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.diatonicModes)
          .toList();
      expect(modes.map((entry) => entry.label), [
        'Ionian',
        'Dorian',
        'Phrygian',
        'Lydian',
        'Mixolydian',
        'Aeolian',
        'Locrian',
      ]);
    });

    test('major and natural minor surface under both lenses', () {
      final majorEntries = scaleMenuEntries
          .where((entry) => entry.kind == ScaleKind.major)
          .map((entry) => entry.label);
      expect(majorEntries, containsAll(['Major', 'Ionian']));

      final minorEntries = scaleMenuEntries
          .where((entry) => entry.kind == ScaleKind.aeolian)
          .map((entry) => entry.label);
      expect(minorEntries, containsAll(['Natural minor', 'Aeolian']));
    });

    test('commonScaleEntry resolves the practical-name row', () {
      final major = commonScaleEntry(ScaleKind.major);
      expect(major.label, 'Major');
      expect(major.section, ScaleSection.common);

      final minor = commonScaleEntry(ScaleKind.aeolian);
      expect(minor.label, 'Natural minor');
      expect(minor.section, ScaleSection.common);
    });
  });
}
