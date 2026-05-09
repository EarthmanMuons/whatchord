import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/explore/models/explore_chord_state.dart';
import 'package:whatchord/features/explore/services/explore_chord_derivation.dart';
import 'package:whatchord/features/explore/services/explore_chord_options.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('buildExploreExtensionControlGroups', () {
    test('major qualities group exclusive eleventh choices separately', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      );

      expect(groups.map((group) => group.label), ['Add tones', '11']);
      expect(groups.map((group) => group.allowsMultiple), [true, false]);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add13,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.add11,
        ChordExtension.sharp11,
      ]);
      expect(groups[1].choices.map((choice) => choice.label), [
        'None',
        'add11',
        '♯11',
      ]);
    });

    test('minor triad-like qualities expose natural add-tone toggles only', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.minor,
      );

      expect(groups, hasLength(1));
      expect(groups.single.label, 'Extensions');
      expect(groups.single.allowsMultiple, isTrue);
      expect(groups.single.choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
        ChordExtension.add13,
      ]);
    });

    test('augmented qualities expose sharp-eleventh color', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.augmented,
      );

      expect(groups.map((group) => group.label), ['Add tones', '11']);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add13,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.add11,
        ChordExtension.sharp11,
      ]);
    });

    test('sixth qualities omit redundant add13', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major6,
      );

      expect(groups.map((group) => group.label), ['Add tones', '11']);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.add11,
        ChordExtension.sharp11,
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
      expect(groups[0].choices.map((choice) => choice.label), [
        'None',
        '♭9',
        '9',
        '♯9',
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.eleven,
        ChordExtension.sharp11,
      ]);
      expect(groups[1].choices.map((choice) => choice.label), [
        'None',
        '11',
        '♯11',
      ]);
      expect(groups[2].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.flat13,
        ChordExtension.thirteen,
      ]);
      expect(groups[2].choices.map((choice) => choice.label), [
        'None',
        '♭13',
        '13',
      ]);
    });

    test('diminished seventh omits extensions already in the chord', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.diminished7,
      );

      expect(groups[0].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.flat9,
        ChordExtension.nine,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.eleven,
      ]);
      expect(groups[2].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.flat13,
      ]);
    });

    test('suspended seventh omits the redundant natural eleventh', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7sus4,
      );

      expect(groups[1].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.sharp11,
      ]);
    });
  });

  group('extensionSetLabel', () {
    test('uses glyph accidentals for UI labels', () {
      expect(
        extensionSetLabel(const {
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        }),
        '♭9, ♯11, ♭13',
      );
    });
  });

  group('normalizeExtensionsForQuality', () {
    test('keeps a major sharp-eleventh slash bass valid for page seeding', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );
      final identity = buildExploreChordIdentity(
        ExploreChordState(
          rootPc: 8,
          bassPc: 2,
          quality: ChordQualityToken.major,
          extensions: normalized,
        ),
      );

      expect(identity.rootPc, 8);
      expect(identity.bassPc, 2);
      expect(identity.quality, ChordQualityToken.major);
      expect(identity.extensions, {ChordExtension.sharp11});
    });

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
            ChordExtension.sharp11,
          },
        );

        expect(normalized, {
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.sharp11,
          ChordExtension.add13,
        });
      },
    );

    test('preserves sharp eleventh for supported triad-like qualities', () {
      final major = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );
      final major6 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major6,
        extensions: const {ChordExtension.sharp11},
      );
      final augmented = normalizeExtensionsForQuality(
        quality: ChordQualityToken.augmented,
        extensions: const {ChordExtension.sharp11},
      );

      expect(major, {ChordExtension.sharp11});
      expect(major6, {ChordExtension.sharp11});
      expect(augmented, {ChordExtension.sharp11});
    });

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

    test('drops seventh-family extensions that duplicate core chord tones', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.diminished7,
        extensions: const {
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.thirteen,
          ChordExtension.flat9,
          ChordExtension.eleven,
        },
      );

      expect(normalized, {ChordExtension.flat9, ChordExtension.eleven});
    });
  });

  group('selectExploreExtensionChoice', () {
    test('toggles add tones independently', () {
      final group = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      ).first;

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

    test('replaces natural and sharp eleventh choices for major qualities', () {
      final group = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      )[1];

      final withSharp11 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {ChordExtension.add11},
        group: group,
        choice: group.choices[2],
      );

      expect(withSharp11, {ChordExtension.sharp11});

      final withAdd11 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withSharp11,
        group: group,
        choice: group.choices[1],
      );

      expect(withAdd11, {ChordExtension.add11});
    });

    test('none clears triad-like eleventh choices only', () {
      final group = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      )[1];

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {
          ChordExtension.add9,
          ChordExtension.sharp11,
          ChordExtension.add13,
        },
        group: group,
        choice: group.choices[0],
      );

      expect(normalized, {ChordExtension.add9, ChordExtension.add13});
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
