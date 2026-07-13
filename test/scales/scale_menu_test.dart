import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/features/scales/scales.dart';
import 'package:whatchord_app/features/theory/theory.dart';

void main() {
  group('Scale menu catalog', () {
    test('covers every scale kind at least once', () {
      final kinds = scaleMenuEntries.map((entry) => entry.kind).toSet();
      expect(kinds, ScaleKind.values.toSet());
    });

    test('essential section contains the practical names', () {
      final essential = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.essential)
          .toList();
      expect(
        essential.map((entry) => entry.label),
        unorderedEquals([
          'Major',
          'Natural minor',
          'Harmonic minor',
          'Jazz melodic minor',
        ]),
      );
    });

    test('diatonic modes contains the seven major-scale rotations', () {
      final modes = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.diatonicModes)
          .toList();
      expect(
        modes.map((entry) => entry.label),
        unorderedEquals([
          'Ionian',
          'Dorian',
          'Phrygian',
          'Lydian',
          'Mixolydian',
          'Aeolian',
          'Locrian',
        ]),
      );
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

    test('dominant and altered section lists focused chord scales', () {
      final dominantAndAltered = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.dominantAndAltered)
          .toList();
      expect(
        dominantAndAltered.map((entry) => entry.label),
        unorderedEquals(['Phrygian dominant', 'Lydian dominant', 'Altered']),
      );
    });

    test('harmonic major section lists both related scales', () {
      final harmonicMajor = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.harmonicMajor)
          .toList();
      expect(
        harmonicMajor.map((entry) => entry.label),
        unorderedEquals(['Harmonic major', 'Double harmonic major']),
      );
    });

    test('symmetric section lists both augmented modes', () {
      final symmetric = scaleMenuEntries
          .where((entry) => entry.section == ScaleSection.symmetric)
          .map((entry) => entry.label);
      expect(symmetric, containsAll(['Augmented', 'Augmented inverse']));
    });

    test(
      'header labels lowercase qualities but keep mode names capitalized',
      () {
        String headerFor(String label) =>
            scaleMenuEntries.firstWhere((e) => e.label == label).headerLabel;

        expect(headerFor('Major'), 'major');
        expect(headerFor('Natural minor'), 'natural minor');
        expect(headerFor('Harmonic minor'), 'harmonic minor');
        expect(headerFor('Jazz melodic minor'), 'jazz melodic minor');
        expect(headerFor('Ionian'), 'Ionian');
        expect(headerFor('Dorian'), 'Dorian');
        expect(headerFor('Locrian'), 'Locrian');
      },
    );

    test('seedScaleEntry resolves the practical-name row', () {
      final major = seedScaleEntry(ScaleKind.major);
      expect(major.label, 'Major');
      expect(major.section, ScaleSection.essential);

      final minor = seedScaleEntry(ScaleKind.aeolian);
      expect(minor.label, 'Natural minor');
      expect(minor.section, ScaleSection.essential);
    });

    test('seedScaleEntry rejects kinds without an essential row', () {
      expect(() => seedScaleEntry(ScaleKind.lydian), throwsArgumentError);
    });
  });
}
