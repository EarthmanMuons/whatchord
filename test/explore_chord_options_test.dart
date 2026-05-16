import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/features/explore/models/explore_chord_example.dart';
import 'package:whatchord/features/explore/models/explore_chord_state.dart';
import 'package:whatchord/features/explore/services/explore_chord_example_builder.dart';
import 'package:whatchord/features/explore/services/explore_chord_derivation.dart';
import 'package:whatchord/features/explore/services/explore_chord_options.dart';
import 'package:whatchord/features/theory/theory.dart';

void main() {
  group('buildExploreExtensionControlGroups', () {
    test(
      'major qualities expose segmented extensions with sharp-eleventh color',
      () {
        final groups = buildExploreExtensionControlGroups(
          ChordQualityToken.major,
        );

        expect(groups.map((group) => group.label), ['Added tones', 'Colors']);
        expect(groups.map((group) => group.role), [
          ExploreExtensionControlRole.addedTones,
          ExploreExtensionControlRole.colors,
        ]);
        expect(groups.map((group) => group.allowsMultiple), [true, true]);
        expect(groups[0].choices.map((choice) => choice.extension), [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        ]);
        expect(groups[0].choices.map((choice) => choice.label), [
          'add9',
          'add11',
          'add13',
        ]);
        expect(groups[1].choices.map((choice) => choice.extension), [
          ChordExtension.sharp11,
        ]);
        expect(groups[1].choices.map((choice) => choice.label), ['♯11']);
      },
    );

    test(
      'minor triad-like qualities expose segmented natural add tones only',
      () {
        final groups = buildExploreExtensionControlGroups(
          ChordQualityToken.minor,
        );

        expect(groups, hasLength(1));
        expect(groups.single.label, 'Added tones');
        expect(groups.single.role, ExploreExtensionControlRole.addedTones);
        expect(groups.single.allowsMultiple, isTrue);
        expect(groups.single.choices.map((choice) => choice.extension), [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        ]);
      },
    );

    test('augmented qualities expose sharp-eleventh color', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.augmented,
      );

      expect(groups.map((group) => group.label), ['Added tones', 'Colors']);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
        ChordExtension.add13,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.sharp11,
      ]);
    });

    test('sixth qualities omit redundant add13', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major6,
      );

      expect(groups.map((group) => group.label), ['Added tones', 'Colors']);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.sharp11,
      ]);
    });

    test('seventh qualities expose a headline tier and color choices', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      );

      expect(groups.map((group) => group.label), [
        'Highest extension',
        'Added tones',
        'Colors',
      ]);
      expect(groups.map((group) => group.role), [
        ExploreExtensionControlRole.highestExtension,
        ExploreExtensionControlRole.addedTones,
        ExploreExtensionControlRole.colors,
      ]);
      expect(groups.map((group) => group.allowsMultiple), [false, true, true]);
      expect(groups[0].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.nine,
        ChordExtension.eleven,
        ChordExtension.thirteen,
      ]);
      expect(groups[0].choices.map((choice) => choice.label), [
        'None',
        '9',
        '11',
        '13',
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.add11,
        ChordExtension.add13,
      ]);
      expect(groups[1].choices.map((choice) => choice.label), [
        'add11',
        'add13',
      ]);
      expect(groups[2].choices.map((choice) => choice.extension), [
        ChordExtension.flat9,
        ChordExtension.sharp9,
        ChordExtension.sharp11,
        ChordExtension.flat13,
      ]);
      expect(groups[2].choices.map((choice) => choice.label), [
        '♭9',
        '♯9',
        '♯11',
        '♭13',
      ]);
    });

    test('diminished seventh omits extensions already in the chord', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.diminished7,
      );

      expect(groups[0].choices.map((choice) => choice.extension), [
        null,
        ChordExtension.nine,
        ChordExtension.eleven,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.add11,
      ]);
      expect(groups[2].choices.map((choice) => choice.extension), [
        ChordExtension.flat9,
        ChordExtension.flat13,
      ]);
    });

    test('suspended seventh omits the redundant natural eleventh', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7sus4,
      );

      expect(groups.first.choices.map((choice) => choice.extension), [
        null,
        ChordExtension.nine,
        ChordExtension.thirteen,
      ]);
      expect(groups.first.choices.map((choice) => choice.label), [
        'None',
        '9',
        '13',
      ]);
      expect(
        groups[2].choices.map((choice) => choice.extension),
        contains(ChordExtension.sharp11),
      );
    });

    test(
      'minor seventh qualities expose add-style natural headline labels',
      () {
        final groups = buildExploreExtensionControlGroups(
          ChordQualityToken.minor7,
        );

        expect(groups.first.choices.map((choice) => choice.extension), [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
        ]);
        expect(groups.first.choices.map((choice) => choice.label), [
          'None',
          '9',
          '11',
          '13',
        ]);
      },
    );

    test('all non-seventh qualities have intentional extension choices', () {
      final expectations = {
        ChordQualityToken.major: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.minor: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        ],
        ChordQualityToken.diminished: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        ],
        ChordQualityToken.augmented: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.sus2: [ChordExtension.add11, ChordExtension.add13],
        ChordQualityToken.sus4: [ChordExtension.add9, ChordExtension.add13],
        ChordQualityToken.major6: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.minor6: [ChordExtension.add9, ChordExtension.add11],
      };

      for (final entry in expectations.entries) {
        final groups = buildExploreExtensionControlGroups(entry.key);
        final choices = [
          for (final group in groups)
            for (final choice in group.choices) choice.extension,
        ];
        expect(choices, entry.value, reason: entry.key.name);
        expect(
          groups.every((group) => group.allowsMultiple),
          isTrue,
          reason: entry.key.name,
        );
      }
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

    test(
      'promotes seventh-family add ninth while preserving skipped add tones',
      () {
        final ninth = normalizeExtensionsForQuality(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.add9},
        );

        expect(ninth, {ChordExtension.nine});

        final skipped = normalizeExtensionsForQuality(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.add11, ChordExtension.add13},
        );

        expect(skipped, {ChordExtension.add11, ChordExtension.add13});
      },
    );

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

    test('drops add tones that duplicate suspended core tones', () {
      final sus2 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.sus2,
        extensions: const {
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        },
      );
      final sus4 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.sus4,
        extensions: const {
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
        },
      );

      expect(sus2, {ChordExtension.add11, ChordExtension.add13});
      expect(sus4, {ChordExtension.add9, ChordExtension.add13});
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
    test('selects triad-like added tones independently', () {
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

      final withAdd13 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withAdd9,
        group: group,
        choice: group.choices[2],
      );

      expect(withAdd13, {ChordExtension.add9, ChordExtension.add13});
    });

    test('replaces natural and sharp eleventh choices for major qualities', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      );
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withSharp11 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {ChordExtension.add11},
        group: colorGroup,
        choice: colorGroup.choices[0],
      );

      expect(withSharp11, {ChordExtension.sharp11});

      final withAdd11 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withSharp11,
        group: addToneGroup,
        choice: addToneGroup.choices[1],
      );

      expect(withAdd11, {ChordExtension.add11});
    });

    test('toggles triad-like extension choices within their groups', () {
      final groups = buildExploreExtensionControlGroups(
        ChordQualityToken.major,
      );
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withoutAdd13 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {
          ChordExtension.add9,
          ChordExtension.sharp11,
          ChordExtension.add13,
        },
        group: addToneGroup,
        choice: addToneGroup.choices[2],
      );

      expect(withoutAdd13, {ChordExtension.add9, ChordExtension.sharp11});

      final withoutSharp11 = selectExploreExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withoutAdd13,
        group: colorGroup,
        choice: colorGroup.choices[0],
      );

      expect(withoutSharp11, {ChordExtension.add9});
    });

    test('replaces the seventh-family headline choice', () {
      final headlineGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {ChordExtension.flat9, ChordExtension.sharp11},
        group: headlineGroup,
        choice: headlineGroup.choices[3],
      );

      expect(normalized, {
        ChordExtension.flat9,
        ChordExtension.sharp11,
        ChordExtension.thirteen,
      });
    });

    test(
      'promotes skipped added tones when a later headline completes them',
      () {
        final headlineGroup = buildExploreExtensionControlGroups(
          ChordQualityToken.dominant7,
        ).first;

        final withEleven = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {ChordExtension.add11},
          group: headlineGroup,
          choice: headlineGroup.choices[1],
        );

        expect(withEleven, {ChordExtension.eleven});
      },
    );

    test('promotes seventh-family added tones when they complete a stack', () {
      final headlineGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;
      final addToneGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      )[1];

      final withNine = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {},
        group: headlineGroup,
        choice: headlineGroup.choices[1],
      );

      expect(withNine, {ChordExtension.nine});

      final withEleven = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: withNine,
        group: addToneGroup,
        choice: addToneGroup.choices[0],
      );

      expect(withEleven, {ChordExtension.eleven});

      final withThirteen = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: withEleven,
        group: addToneGroup,
        choice: addToneGroup.choices[1],
      );

      expect(withThirteen, {ChordExtension.thirteen});
    });

    test(
      'keeps seventh-family added tones explicit when lower tones are skipped',
      () {
        final addToneGroup = buildExploreExtensionControlGroups(
          ChordQualityToken.dominant7,
        )[1];

        final withAdd11 = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {},
          group: addToneGroup,
          choice: addToneGroup.choices[0],
        );

        expect(withAdd11, {ChordExtension.add11});

        final withAdd13 = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {},
          group: addToneGroup,
          choice: addToneGroup.choices[1],
        );

        expect(withAdd13, {ChordExtension.add13});

        final normalized = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {ChordExtension.thirteen},
          group: addToneGroup,
          choice: addToneGroup.choices[1],
        );

        expect(normalized, {ChordExtension.add13});

        final withNineAndAdd13 = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {ChordExtension.nine},
          group: addToneGroup,
          choice: addToneGroup.choices[1],
        );

        expect(withNineAndAdd13, {ChordExtension.nine, ChordExtension.add13});
      },
    );

    test(
      'promotes seventh-family added tones above complete altered stacks',
      () {
        final addToneGroup = buildExploreExtensionControlGroups(
          ChordQualityToken.dominant7,
        )[1];

        final normalized = selectExploreExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {
            ChordExtension.flat9,
            ChordExtension.eleven,
          },
          group: addToneGroup,
          choice: addToneGroup.choices[1],
        );

        expect(normalized, {ChordExtension.flat9, ChordExtension.thirteen});
      },
    );

    test('none clears the seventh-family headline only', () {
      final headlineGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {
          ChordExtension.thirteen,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
        group: headlineGroup,
        choice: headlineGroup.choices[0],
      );

      expect(normalized, {ChordExtension.sharp11, ChordExtension.flat13});
    });

    test('stacks altered ninth color choices', () {
      final colorGroup = buildExploreExtensionControlGroups(
        ChordQualityToken.dominant7,
      )[2];

      final normalized = selectExploreExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {
          ChordExtension.flat9,
          ChordExtension.thirteen,
        },
        group: colorGroup,
        choice: colorGroup.choices[1],
      );

      expect(normalized, {
        ChordExtension.flat9,
        ChordExtension.sharp9,
        ChordExtension.thirteen,
      });
    });
  });

  group('ExploreChordExampleBuilder', () {
    test('keeps a simple seventh complete', () {
      final example = _example(quality: ChordQualityToken.dominant7);

      expect(example.members, ['C', 'E', 'G', 'Bb']);
      expect(example.memberDegrees, ['1', '3', '5', 'b7']);
      expect(example.normalizedVoicing, [60, 64, 67, 70]);
    });

    test('keeps suspended triads in compact chord-tone order', () {
      final example = _example(quality: ChordQualityToken.sus4);

      expect(example.members, ['C', 'F', 'G']);
      expect(example.memberDegrees, ['1', '4', '5']);
      expect(example.normalizedVoicing, [60, 65, 67]);
    });

    test('uses the lower octave for roots just below middle C', () {
      final aMajor = _example(rootPc: 9, quality: ChordQualityToken.major);
      final bMajor = _example(rootPc: 11, quality: ChordQualityToken.major);

      expect(aMajor.normalizedVoicing, [57, 61, 64]);
      expect(bMajor.normalizedVoicing, [59, 63, 66]);
    });

    test('uses the lower octave for slash bass notes just below middle C', () {
      final example = _example(quality: ChordQualityToken.major7, bassPc: 11);

      expect(example.normalizedVoicing, [59, 60, 64, 67]);
    });

    test('implies added ninth for major sharp-eleventh examples', () {
      final example = _example(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );

      expect(example.presentation.symbol.toString(), 'C#11');
      expect(example.members, ['C', 'E', 'G', 'D', 'F#']);
      expect(example.memberDegrees, ['1', '3', '5', '9', '#11']);
      expect(example.normalizedVoicing, [60, 64, 67, 74, 78]);
    });

    test('implies added ninth for major added-thirteenth examples', () {
      final example = _example(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.add13},
      );

      expect(example.presentation.symbol.toString(), 'Cadd13');
      expect(example.members, ['C', 'E', 'G', 'D', 'A']);
      expect(example.memberDegrees, ['1', '3', '5', '9', '13']);
      expect(example.normalizedVoicing, [60, 64, 67, 74, 81]);
    });

    test('implies added ninth for minor-six added-eleventh examples', () {
      final example = _example(
        quality: ChordQualityToken.minor6,
        extensions: const {ChordExtension.add11},
      );

      expect(example.presentation.symbol.toString(), 'Cm6add11');
      expect(example.members, ['C', 'Eb', 'G', 'A', 'D', 'F']);
      expect(example.memberDegrees, ['1', 'b3', '5', '6', '9', '11']);
      expect(example.normalizedVoicing, [60, 63, 67, 69, 74, 77]);
    });

    test(
      'does not imply redundant added ninth for sus2 add-thirteenth examples',
      () {
        final example = _example(
          quality: ChordQualityToken.sus2,
          extensions: const {ChordExtension.add13},
        );

        expect(example.presentation.symbol.toString(), 'Csus2add13');
        expect(example.members, ['C', 'D', 'G', 'A']);
        expect(example.memberDegrees, ['1', '2', '5', '13']);
        expect(example.normalizedVoicing, [60, 62, 67, 81]);
      },
    );

    test('builds a ninth with the extension above the seventh', () {
      final example = _example(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.nine},
      );

      expect(example.members, ['C', 'E', 'G', 'Bb', 'D']);
      expect(example.memberDegrees, ['1', '3', '5', 'b7', '9']);
      expect(example.normalizedVoicing, [60, 64, 67, 70, 74]);
    });

    test(
      'builds a dominant eleventh with implied ninth and retained fifth',
      () {
        final example = _example(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.eleven},
        );

        expect(example.presentation.symbol.toString(), 'C11');
        expect(example.members, ['C', 'E', 'G', 'Bb', 'D', 'F']);
        expect(example.memberDegrees, ['1', '3', '5', 'b7', '9', '11']);
        expect(example.normalizedVoicing, [60, 64, 67, 70, 74, 77]);
      },
    );

    test(
      'uses implied ninth but no sharp eleventh for a dominant thirteenth example',
      () {
        final example = _example(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.thirteen},
        );

        expect(example.presentation.symbol.toString(), 'C13');
        expect(example.members, ['C', 'E', 'G', 'Bb', 'D', 'A']);
        expect(example.memberDegrees, ['1', '3', '5', 'b7', '9', '13']);
        expect(example.normalizedVoicing, [60, 64, 67, 70, 74, 81]);
      },
    );

    test('uses only the selected added tone for a dominant add-thirteenth', () {
      final example = _example(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.add13},
      );

      expect(example.presentation.symbol.toString(), 'C7(add13)');
      expect(example.members, ['C', 'E', 'G', 'Bb', 'A']);
      expect(example.memberDegrees, ['1', '3', '5', 'b7', '13']);
      expect(example.normalizedVoicing, [60, 64, 67, 70, 81]);
    });

    test(
      'uses explicit sharp-eleventh color for a dominant thirteenth sharp-eleventh',
      () {
        final example = _example(
          quality: ChordQualityToken.dominant7,
          extensions: const {ChordExtension.sharp11, ChordExtension.thirteen},
        );

        expect(example.presentation.symbol.toString(), 'C13#11');
        expect(example.members, ['C', 'E', 'G', 'Bb', 'D', 'F#', 'A']);
        expect(example.memberDegrees, ['1', '3', '5', 'b7', '9', '#11', '13']);
        expect(example.normalizedVoicing, [60, 64, 67, 70, 74, 78, 81]);
      },
    );

    test('uses altered ninth instead of implied natural ninth', () {
      final example = _example(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.flat9, ChordExtension.thirteen},
      );

      expect(example.presentation.symbol.toString(), 'C13b9');
      expect(example.members, ['C', 'E', 'G', 'Bb', 'Db', 'A']);
      expect(example.memberDegrees, ['1', '3', '5', 'b7', 'b9', '13']);
      expect(example.normalizedVoicing, [60, 64, 67, 70, 73, 81]);
    });

    test('round-trips dominant thirteenth examples through the analyzer', () {
      for (final entry in const {
        'C13': {ChordExtension.thirteen},
        'C7(add13)': {ChordExtension.add13},
        'C13#11': {ChordExtension.sharp11, ChordExtension.thirteen},
      }.entries) {
        final example = _example(
          quality: ChordQualityToken.dominant7,
          extensions: entry.value,
        );
        final analyzed = ChordAnalyzer.analyze(
          _inputFromVoicing(example.normalizedVoicing),
          context: _context(),
        );

        expect(analyzed, isNotEmpty, reason: entry.key);
        final symbol = ChordSymbolBuilder.fromIdentity(
          identity: analyzed.first.identity,
          tonality: const Tonality('C', TonalityMode.major),
          notation: ChordNotationStyle.textual,
        ).toString();

        expect(symbol, entry.key);
      }
    });
  });
}

ExploreChordExample _example({
  int rootPc = 0,
  int? bassPc,
  required ChordQualityToken quality,
  Set<ChordExtension> extensions = const {},
}) {
  return ExploreChordExampleBuilder.build(
    state: ExploreChordState(
      rootPc: rootPc,
      bassPc: bassPc ?? rootPc,
      quality: quality,
      extensions: extensions,
    ),
    tonality: const Tonality('C', TonalityMode.major),
    notation: ChordNotationStyle.textual,
  );
}

AnalysisContext _context() {
  const tonality = Tonality('C', TonalityMode.major);
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}

ChordInput _inputFromVoicing(List<int> voicing) {
  var mask = 0;
  for (final note in voicing) {
    mask |= 1 << (note % 12);
  }
  return ChordInput(
    pcMask: mask,
    bassPc: voicing.first % 12,
    noteCount: voicing.length,
  );
}
