import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/explore/services/explore_chord_options.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';

void main() {
  group('buildExploreExtensionControlGroups', () {
    test('triad-like qualities expose add-tone toggles only', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      );

      expect(groups, hasLength(1));
      expect(groups.single.label, 'Added tones');
      expect(groups.single.allowsMultiple, isTrue);
      expect(groups.single.choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
        ChordExtension.add13,
      ]);
    });

    test('sixth qualities omit redundant add13', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major6,
      );

      expect(groups, hasLength(1));
      expect(groups.single.label, 'Added tones');
      expect(groups.single.choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
      ]);
    });

    test('seventh qualities expose mutually exclusive degree choices', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      );

      expect(groups.map((group) => group.label), ['9', '11', '13']);
      expect(groups.every((group) => !group.allowsMultiple), isTrue);
      expect(groups[0].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.flat9,
        ChordExtension.nine,
        ChordExtension.sharp9,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.eleven,
        ChordExtension.sharp11,
      ]);
      expect(groups[2].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.flat13,
        ChordExtension.thirteen,
      ]);
    });
  });

  group('normalizeExtensionsForQuality', () {
    test('converts triad add tones to natural seventh-family extensions', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.dominant7,
        extensions: const {
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        },
      );

      expect(normalized, {
        ChordExtension.nine,
        ChordExtension.eleven,
        ChordExtension.thirteen,
      });
    });

    test(
      'converts natural extensions to add tones for triad-like qualities',
      () {
        final normalized = normalizeExtensionsForQuality(
          quality: ChordQualityToken.major,
          extensions: const {
            ChordExtension.nine,
            ChordExtension.eleven,
            ChordExtension.thirteen,
            ChordExtension.flat9,
            ChordExtension.sharp11,
          },
        );

        expect(normalized, {
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        });
      },
    );

    test('drops redundant thirteenth for sixth qualities', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major6,
        extensions: const {
          ChordExtension.add9,
          ChordExtension.add13,
          ChordExtension.thirteen,
        },
      );

      expect(normalized, {ChordExtension.add9});
    });

    test('drops alterations for non-seventh qualities', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor,
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
      );

      expect(normalized, isEmpty);
    });
  });

  group('selectExploreExtensionChoice', () {
    test('toggles add tones independently', () {
      final group = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      ).single;

      final withAdd9 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {},
        group: group,
        choice: group.choices[0],
      );

      expect(withAdd9, {ChordExtension.add9});

      final withoutAdd9 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withAdd9,
        group: group,
        choice: group.choices[0],
      );

      expect(withoutAdd9, isEmpty);
    });

    test('replaces selected choices within the same seventh degree', () {
      final ninthGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {ChordExtension.flat9, ChordExtension.sharp11},
        group: ninthGroup,
        choice: ninthGroup.choices[3],
      );

      expect(normalized, {ChordExtension.sharp9, ChordExtension.sharp11});
    });

    test('none clears the selected seventh degree only', () {
      final ninthGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
        group: ninthGroup,
        choice: ninthGroup.choices[0],
      );

      expect(normalized, {ChordExtension.sharp11, ChordExtension.flat13});
    });
  });
}
