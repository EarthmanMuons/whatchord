import 'package:test/test.dart';

import 'package:whatchord/src/construction/services/construction_derivation.dart';
import 'package:whatchord/src/construction/services/extension_rules.dart';
import 'package:whatchord/whatchord.dart';

void main() {
  group('ChordSpec', () {
    test(
      'round-trips analyzer quality seeds through compositional controls',
      () {
        for (final quality in ChordQualityToken.values) {
          final spec = ChordSpec.fromQuality(quality);

          expect(spec.quality, quality, reason: quality.name);
        }
      },
    );

    test(
      'normalizes unavailable seventh choices when base quality changes',
      () {
        final state = ChordConstruction.fromSpec(
          rootPc: 0,
          spec: const ChordSpec(
            baseQuality: BaseQuality.major,
            seventhKind: SeventhKind.dominant7,
            fifthAlteration: FifthAlteration.sharp,
          ),
          extensions: const {},
          bassPc: 0,
        );

        final minor = constructionWithBaseQuality(state, BaseQuality.minor);

        expect(minor.baseQuality, BaseQuality.minor);
        expect(minor.seventhKind, SeventhKind.none);
        expect(minor.fifthAlteration, FifthAlteration.natural);
        expect(minor.quality, ChordQualityToken.minor);
      },
    );

    test('builds altered seventh qualities from separate controls', () {
      final dominantSharpFive = ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.sharp,
      ).quality;
      final majorFlatFive = ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.flat,
      ).quality;

      expect(dominantSharpFive, ChordQualityToken.dominant7Sharp5);
      expect(majorFlatFive, ChordQualityToken.major7Flat5);
    });

    test('allows sharp-five choices for minor and minor seventh qualities', () {
      expect(
        availableFifthAlterationsFor(
          baseQuality: BaseQuality.minor,
          seventhKind: SeventhKind.none,
        ),
        [FifthAlteration.natural, FifthAlteration.sharp],
      );
      expect(
        availableFifthAlterationsFor(
          baseQuality: BaseQuality.minor,
          seventhKind: SeventhKind.minor7,
        ),
        [FifthAlteration.natural, FifthAlteration.sharp],
      );
      expect(
        availableFifthAlterationsFor(
          baseQuality: BaseQuality.minor,
          seventhKind: SeventhKind.minorMajor7,
        ),
        [FifthAlteration.natural],
      );

      final minorSharpFive = ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.sharp,
      ).quality;
      final minor7SharpFive = ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minor7,
        fifthAlteration: FifthAlteration.sharp,
      ).quality;

      expect(minorSharpFive, ChordQualityToken.minorSharp5);
      expect(minor7SharpFive, ChordQualityToken.minor7Sharp5);
    });

    test('keeps augmented quality triad-only', () {
      expect(availableSeventhKindsFor(BaseQuality.augmented), [
        SeventhKind.none,
      ]);

      final dominantSharpFive = ChordSpec.fromQuality(
        ChordQualityToken.dominant7Sharp5,
      );
      final majorSharpFive = ChordSpec.fromQuality(
        ChordQualityToken.major7Sharp5,
      );

      expect(dominantSharpFive.baseQuality, BaseQuality.major);
      expect(dominantSharpFive.seventhKind, SeventhKind.dominant7);
      expect(dominantSharpFive.fifthAlteration, FifthAlteration.sharp);
      expect(majorSharpFive.baseQuality, BaseQuality.major);
      expect(majorSharpFive.seventhKind, SeventhKind.major7);
      expect(majorSharpFive.fifthAlteration, FifthAlteration.sharp);
    });
  });

  group('buildExtensionControlGroups', () {
    test(
      'major qualities expose segmented extensions with sharp-eleventh color',
      () {
        final groups = buildExtensionControlGroups(ChordQualityToken.major);

        expect(groups.map((group) => group.label), [
          'Added tones',
          'Alterations',
        ]);
        expect(groups.map((group) => group.role), [
          ExtensionControlRole.addedTones,
          ExtensionControlRole.alterations,
        ]);
        expect(groups.map((group) => group.allowsMultiple), [true, true]);
        expect(groups[0].choices.map((choice) => choice.extension), [
          ChordExtension.add9,
          ChordExtension.add11,
        ]);
        expect(groups[0].choices.map((choice) => choice.label), [
          'add9',
          'add11',
        ]);
        expect(groups[1].choices.map((choice) => choice.extension), [
          ChordExtension.addFlat9,
          ChordExtension.addSharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ]);
        expect(groups[1].choices.map((choice) => choice.label), [
          '♭9',
          '♯9',
          '♯11',
          '♭13',
        ]);
      },
    );

    test(
      'minor qualities expose segmented add tones with sharp-eleventh color',
      () {
        final groups = buildExtensionControlGroups(ChordQualityToken.minor);

        expect(groups.map((group) => group.label), [
          'Added tones',
          'Alterations',
        ]);
        expect(groups.map((group) => group.role), [
          ExtensionControlRole.addedTones,
          ExtensionControlRole.alterations,
        ]);
        expect(groups.map((group) => group.allowsMultiple), [true, true]);
        expect(groups[0].choices.map((choice) => choice.extension), [
          ChordExtension.add9,
          ChordExtension.add11,
        ]);
        expect(groups[1].choices.map((choice) => choice.extension), [
          ChordExtension.addFlat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ]);
      },
    );

    test('augmented qualities expose sharp-eleventh color', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.augmented);

      expect(groups.map((group) => group.label), [
        'Added tones',
        'Alterations',
      ]);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
        ChordExtension.add13,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.addSharp9,
        ChordExtension.sharp11,
      ]);
    });

    test('sixth qualities omit redundant add13', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.major6);

      expect(groups.map((group) => group.label), [
        'Added tones',
        'Alterations',
      ]);
      expect(groups[0].choices.map((choice) => choice.extension), [
        ChordExtension.add9,
        ChordExtension.add11,
      ]);
      expect(groups[1].choices.map((choice) => choice.extension), [
        ChordExtension.flat9,
        ChordExtension.addSharp9,
        ChordExtension.sharp11,
      ]);
    });

    test('seventh qualities expose a headline tier and color choices', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.dominant7);

      expect(groups.map((group) => group.label), [
        'Stacked extension',
        'Added tones',
        'Alterations',
      ]);
      expect(groups.map((group) => group.role), [
        ExtensionControlRole.highestExtension,
        ExtensionControlRole.addedTones,
        ExtensionControlRole.alterations,
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
      ]);
      expect(groups[1].choices.map((choice) => choice.label), ['add11']);
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
      final groups = buildExtensionControlGroups(ChordQualityToken.diminished7);

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
      final groups = buildExtensionControlGroups(
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
        groups[1].choices.map((choice) => choice.extension),
        contains(ChordExtension.sharp11),
      );
    });

    test(
      'minor seventh qualities expose add-style natural headline labels',
      () {
        final groups = buildExtensionControlGroups(ChordQualityToken.minor7);

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
          ChordExtension.addFlat9,
          ChordExtension.addSharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.minor: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.addFlat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.minorSharp5: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.diminished: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.augmented: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.add13,
          ChordExtension.addSharp9,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.sus2: [
          ChordExtension.add11,
          ChordExtension.add13,
          ChordExtension.flat13,
        ],
        ChordQualityToken.sus4: [
          ChordExtension.add9,
          ChordExtension.add13,
          ChordExtension.addFlat9,
          ChordExtension.flat13,
        ],
        ChordQualityToken.sus2sus4: [
          ChordExtension.add13,
          ChordExtension.flat13,
        ],
        ChordQualityToken.major6: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.addSharp9,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.minor6: [
          ChordExtension.add9,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp11,
        ],
      };

      for (final entry in expectations.entries) {
        final groups = buildExtensionControlGroups(entry.key);
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

    test('all seventh-family qualities have intentional extension choices', () {
      final expectations = {
        ChordQualityToken.dominant7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.dominant7sus2: [
          null,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.dominant7sus4: [
          null,
          ChordExtension.nine,
          ChordExtension.thirteen,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.dominant7Flat5: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.flat13,
        ],
        ChordQualityToken.dominant7Sharp5: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.major7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.major7sus2: [
          null,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.major7sus4: [
          null,
          ChordExtension.nine,
          ChordExtension.thirteen,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.major7Flat5: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.flat13,
        ],
        ChordQualityToken.major7Sharp5: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.minor7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.minor7Sharp5: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp11,
        ],
        ChordQualityToken.minorMajor7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        ],
        ChordQualityToken.halfDiminished7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.thirteen,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.flat13,
        ],
        ChordQualityToken.diminished7: [
          null,
          ChordExtension.nine,
          ChordExtension.eleven,
          ChordExtension.add11,
          ChordExtension.flat9,
          ChordExtension.flat13,
        ],
      };

      for (final entry in expectations.entries) {
        final groups = buildExtensionControlGroups(entry.key);
        final choices = [
          for (final group in groups)
            for (final choice in group.choices) choice.extension,
        ];
        expect(choices, entry.value, reason: entry.key.name);
      }
    });
  });

  group('normalizeExtensionsForQuality', () {
    test('keeps a major sharp-eleventh slash bass valid for page seeding', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );
      final identity = buildConstructionIdentity(
        ChordConstruction(
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

    test('keeps a minor flat thirteenth when normalizing a page seed', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor,
        extensions: const {ChordExtension.flat13},
      );
      final identity = buildConstructionIdentity(
        ChordConstruction(
          rootPc: 9,
          bassPc: 2,
          quality: ChordQualityToken.minor,
          extensions: normalized,
        ),
      );

      expect(identity.rootPc, 9);
      // Bass choices are currently limited to chord members, so the foreign
      // D bass from Amb13/D normalizes to the A root independently of flat13.
      expect(identity.bassPc, 9);
      expect(identity.quality, ChordQualityToken.minor);
      expect(identity.extensions, {ChordExtension.flat13});
    });

    test('promotes seventh-family add ninth and thirteenth, keeping a skipped '
        'add eleventh', () {
      final ninth = normalizeExtensionsForQuality(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.add9},
      );

      expect(ninth, {ChordExtension.nine});

      final skipped = normalizeExtensionsForQuality(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.add11, ChordExtension.add13},
      );

      expect(skipped, {ChordExtension.add11, ChordExtension.thirteen});
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
        });
      },
    );

    test('drops triad add thirteenths that duplicate core-tone choices', () {
      final major = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.add13, ChordExtension.thirteen},
      );
      final minor = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor,
        extensions: const {ChordExtension.add13, ChordExtension.thirteen},
      );
      final diminished = normalizeExtensionsForQuality(
        quality: ChordQualityToken.diminished,
        extensions: const {ChordExtension.add13, ChordExtension.thirteen},
      );

      expect(major, isEmpty);
      expect(minor, isEmpty);
      expect(diminished, isEmpty);
    });

    test('preserves sharp eleventh for supported triad-like qualities', () {
      final major = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );
      final minor = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor,
        extensions: const {ChordExtension.sharp11},
      );
      final major6 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major6,
        extensions: const {ChordExtension.sharp11},
      );
      final minor6 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor6,
        extensions: const {ChordExtension.sharp11},
      );
      final augmented = normalizeExtensionsForQuality(
        quality: ChordQualityToken.augmented,
        extensions: const {ChordExtension.sharp11},
      );

      expect(major, {ChordExtension.sharp11});
      expect(minor, {ChordExtension.sharp11});
      expect(major6, {ChordExtension.sharp11});
      expect(minor6, {ChordExtension.sharp11});
      expect(augmented, {ChordExtension.sharp11});
    });

    test(
      'preserves added sharp ninth for split-third major-family qualities',
      () {
        final major = normalizeExtensionsForQuality(
          quality: ChordQualityToken.major,
          extensions: const {ChordExtension.addSharp9},
        );
        final major6 = normalizeExtensionsForQuality(
          quality: ChordQualityToken.major6,
          extensions: const {ChordExtension.sharp9},
        );
        final minor = normalizeExtensionsForQuality(
          quality: ChordQualityToken.minor,
          extensions: const {ChordExtension.addSharp9},
        );

        expect(major, {ChordExtension.addSharp9});
        expect(major6, {ChordExtension.addSharp9});
        expect(minor, isEmpty);
      },
    );

    test('preserves flat ninth for sixth qualities', () {
      final major6 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major6,
        extensions: const {ChordExtension.flat9},
      );
      final minor6 = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor6,
        extensions: const {ChordExtension.flat9},
      );
      final major = normalizeExtensionsForQuality(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.flat9},
      );

      expect(major6, {ChordExtension.flat9});
      expect(minor6, {ChordExtension.flat9});
      // A plain major triad keeps the flat ninth as an added tone (Cadd♭9),
      // since there is no seventh or sixth to anchor a stacked ♭9.
      expect(major, {ChordExtension.addFlat9});
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

    test('preserves supported alterations for non-seventh qualities', () {
      final normalized = normalizeExtensionsForQuality(
        quality: ChordQualityToken.minor,
        extensions: const {
          ChordExtension.flat9,
          ChordExtension.sharp9,
          ChordExtension.sharp11,
          ChordExtension.flat13,
        },
      );

      expect(normalized, {
        ChordExtension.addFlat9,
        ChordExtension.sharp11,
        ChordExtension.flat13,
      });
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

  group('selectExtensionChoice', () {
    test('selects triad-like added tones independently', () {
      final group = buildExtensionControlGroups(ChordQualityToken.major).first;

      final withAdd9 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {},
        group: group,
        choice: group.choices[0],
      );

      expect(withAdd9, {ChordExtension.add9});

      final withAdd11 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withAdd9,
        group: group,
        choice: group.choices[1],
      );

      expect(withAdd11, {ChordExtension.add9, ChordExtension.add11});
    });

    test('selects flat ninth as an added tone for major qualities', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.major);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withAddFlat9 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {ChordExtension.add9},
        group: colorGroup,
        choice: colorGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.addFlat9,
        ),
      );

      // The ♭9 color replaces the natural ninth: C major has no seventh to
      // anchor a stacked ♭9, so it is an added tone (Cadd♭9).
      expect(withAddFlat9, {ChordExtension.addFlat9});

      final backToAdd9 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withAddFlat9,
        group: addToneGroup,
        choice: addToneGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.add9,
        ),
      );

      expect(backToAdd9, {ChordExtension.add9});
    });

    test('replaces natural and sharp ninth choices for major qualities', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.major);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withSharp9 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {ChordExtension.add9},
        group: colorGroup,
        choice: colorGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.addSharp9,
        ),
      );

      expect(withSharp9, {ChordExtension.addSharp9});

      final withAdd9 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withSharp9,
        group: addToneGroup,
        choice: addToneGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.add9,
        ),
      );

      expect(withAdd9, {ChordExtension.add9});
    });

    test('replaces natural and sharp eleventh choices for major qualities', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.major);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withSharp11 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {ChordExtension.add11},
        group: colorGroup,
        choice: colorGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.sharp11,
        ),
      );

      expect(withSharp11, {ChordExtension.sharp11});

      final withAdd11 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withSharp11,
        group: addToneGroup,
        choice: addToneGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.add11,
        ),
      );

      expect(withAdd11, {ChordExtension.add11});
    });

    test('replaces natural and flat thirteenth choices for sus qualities', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.sus4);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withFlat13 = selectExtensionChoice(
        quality: ChordQualityToken.sus4,
        currentExtensions: const {ChordExtension.add13},
        group: colorGroup,
        choice: colorGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.flat13,
        ),
      );

      expect(withFlat13, {ChordExtension.flat13});

      final withAdd13 = selectExtensionChoice(
        quality: ChordQualityToken.sus4,
        currentExtensions: withFlat13,
        group: addToneGroup,
        choice: addToneGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.add13,
        ),
      );

      expect(withAdd13, {ChordExtension.add13});
    });

    test('toggles triad-like extension choices within their groups', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.major);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withoutAdd11 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: const {
          ChordExtension.add9,
          ChordExtension.sharp11,
          ChordExtension.add11,
        },
        group: addToneGroup,
        choice: addToneGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.add11,
        ),
      );

      expect(withoutAdd11, {ChordExtension.add9, ChordExtension.sharp11});

      final withoutSharp11 = selectExtensionChoice(
        quality: ChordQualityToken.major,
        currentExtensions: withoutAdd11,
        group: colorGroup,
        choice: colorGroup.choices.firstWhere(
          (choice) => choice.extension == ChordExtension.sharp11,
        ),
      );

      expect(withoutSharp11, {ChordExtension.add9});
    });

    test('replaces natural and flat ninth choices for sixth qualities', () {
      final groups = buildExtensionControlGroups(ChordQualityToken.minor6);
      final addToneGroup = groups[0];
      final colorGroup = groups[1];

      final withFlat9 = selectExtensionChoice(
        quality: ChordQualityToken.minor6,
        currentExtensions: const {ChordExtension.add9},
        group: colorGroup,
        choice: colorGroup.choices[0],
      );

      expect(withFlat9, {ChordExtension.flat9});

      final withAdd9 = selectExtensionChoice(
        quality: ChordQualityToken.minor6,
        currentExtensions: withFlat9,
        group: addToneGroup,
        choice: addToneGroup.choices[0],
      );

      expect(withAdd9, {ChordExtension.add9});
    });

    test('replaces the seventh-family headline choice', () {
      final headlineGroup = buildExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExtensionChoice(
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
        final headlineGroup = buildExtensionControlGroups(
          ChordQualityToken.dominant7,
        ).first;

        final withEleven = selectExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {ChordExtension.add11},
          group: headlineGroup,
          choice: headlineGroup.choices[1],
        );

        expect(withEleven, {ChordExtension.eleven});
      },
    );

    test(
      'promotes a seventh-family added eleventh when it completes a stack',
      () {
        final headlineGroup = buildExtensionControlGroups(
          ChordQualityToken.dominant7,
        ).first;
        final addToneGroup = buildExtensionControlGroups(
          ChordQualityToken.dominant7,
        )[1];

        final withNine = selectExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {},
          group: headlineGroup,
          choice: headlineGroup.choices[1],
        );

        expect(withNine, {ChordExtension.nine});

        final withEleven = selectExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: withNine,
          group: addToneGroup,
          choice: addToneGroup.choices[0],
        );

        expect(withEleven, {ChordExtension.eleven});
      },
    );

    test(
      'keeps a seventh-family added eleventh explicit when the ninth is skipped',
      () {
        final addToneGroup = buildExtensionControlGroups(
          ChordQualityToken.dominant7,
        )[1];

        final withAdd11 = selectExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {},
          group: addToneGroup,
          choice: addToneGroup.choices[0],
        );

        expect(withAdd11, {ChordExtension.add11});
      },
    );

    test('promotes a seventh-family added eleventh above an altered ninth', () {
      final addToneGroup = buildExtensionControlGroups(
        ChordQualityToken.dominant7,
      )[1];

      final normalized = selectExtensionChoice(
        quality: ChordQualityToken.dominant7,
        currentExtensions: const {ChordExtension.flat9},
        group: addToneGroup,
        choice: addToneGroup.choices[0],
      );

      expect(normalized, {ChordExtension.flat9, ChordExtension.eleven});
    });

    test('none clears the seventh-family headline only', () {
      final headlineGroup = buildExtensionControlGroups(
        ChordQualityToken.dominant7,
      ).first;

      final normalized = selectExtensionChoice(
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
      final colorGroup = buildExtensionControlGroups(
        ChordQualityToken.dominant7,
      )[2];

      final normalized = selectExtensionChoice(
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

    test(
      'sharp eleventh preserves the lower stack from a selected eleventh',
      () {
        final colorGroup = buildExtensionControlGroups(
          ChordQualityToken.minor7,
        )[2];

        final normalized = selectExtensionChoice(
          quality: ChordQualityToken.minor7,
          currentExtensions: const {ChordExtension.eleven},
          group: colorGroup,
          choice: colorGroup.choices.firstWhere(
            (choice) => choice.extension == ChordExtension.sharp11,
          ),
        );

        expect(normalized, {ChordExtension.nine, ChordExtension.sharp11});
      },
    );

    test(
      'flat thirteenth preserves the lower stack from a selected thirteenth',
      () {
        final colorGroup = buildExtensionControlGroups(
          ChordQualityToken.dominant7,
        )[2];

        final normalized = selectExtensionChoice(
          quality: ChordQualityToken.dominant7,
          currentExtensions: const {ChordExtension.thirteen},
          group: colorGroup,
          choice: colorGroup.choices[3],
        );

        expect(normalized, {ChordExtension.eleven, ChordExtension.flat13});
      },
    );
  });

  group('Tonic root spelling', () {
    test('offers every spelling grouped by letter in wheel order', () {
      expect(Tonic.values.length, 21);
      expect(Tonic.values.map((root) => root.label), [
        'Cb', 'C', 'C#', //
        'Db', 'D', 'D#', //
        'Eb', 'E', 'E#', //
        'Fb', 'F', 'F#', //
        'Gb', 'G', 'G#', //
        'Ab', 'A', 'A#', //
        'Bb', 'B', 'B#', //
      ]);
    });

    test('prefers a matching label, else the plainest spelling', () {
      expect(Tonic.forPitchClass(1, preferredLabel: 'Db'), Tonic.dFlat);
      expect(Tonic.forPitchClass(1, preferredLabel: 'C#'), Tonic.cSharp);
      // No match (Cb is pc 11, not pc 1) falls back to the plainest pc-1
      // spelling: no natural exists, so the sharp wins.
      expect(Tonic.forPitchClass(1, preferredLabel: 'Cb'), Tonic.cSharp);
      expect(Tonic.forPitchClass(8), Tonic.gSharp);
    });

    test('spells the chord from the chosen enharmonic root', () {
      final flat = _example(
        root: Tonic.dFlat,
        quality: ChordQualityToken.major,
      );
      expect(flat.presentation.symbol.toString(), 'Db');
      expect(flat.members, ['Db', 'F', 'Ab']);

      final sharp = _example(
        root: Tonic.cSharp,
        quality: ChordQualityToken.major,
      );
      expect(sharp.presentation.symbol.toString(), 'C#');
      expect(sharp.members, ['C#', 'E#', 'G#']);
    });

    test('labels the diatonic degree only for the in-key root spelling', () {
      const gbMajor = Tonality(Tonic.gFlat, TonalityMode.major);

      final cb = _example(
        root: Tonic.cFlat,
        tonality: gbMajor,
        quality: ChordQualityToken.major,
      );
      expect(cb.presentation.symbol.toString(), 'Cb');
      expect(cb.presentation.scaleDegreeAnalysis?.degree, ScaleDegree.four);
      expect(cb.presentation.scaleDegreeAnalysis?.romanNumeral, 'IV');

      // Same pitch class, off-key spelling: not the diatonic IV of Gb major.
      final b = _example(
        root: Tonic.b,
        tonality: gbMajor,
        quality: ChordQualityToken.major,
      );
      expect(b.presentation.symbol.toString(), 'B');
      expect(b.presentation.scaleDegreeAnalysis, isNull);
    });

    test('degree analysis falls back to the symbol spelling', () {
      const gbMajor = Tonality(Tonic.gFlat, TonalityMode.major);
      final identity = _example(
        root: Tonic.cFlat,
        tonality: gbMajor,
        quality: ChordQualityToken.major,
      ).presentation.identity;

      // No root name: resolves to the diatonic spelling (Cb) and labels IV.
      expect(
        gbMajor.scaleDegreeAnalysisForChord(identity)?.degree,
        ScaleDegree.four,
      );
      // Explicit off-key spelling is rejected.
      expect(
        gbMajor.scaleDegreeAnalysisForChord(identity, rootName: 'B'),
        isNull,
      );
    });
  });

  group('ChordExampleBuilder', () {
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

    test('keeps major sharp-eleventh examples literal', () {
      final example = _example(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.sharp11},
      );

      expect(example.presentation.symbol.toString(), 'C#11');
      expect(example.members, ['C', 'E', 'G', 'F#']);
      expect(example.memberDegrees, ['1', '3', '5', '#11']);
      expect(example.normalizedVoicing, [60, 64, 67, 78]);
    });

    test('builds split-third add sharp-nine examples', () {
      final example = _example(
        quality: ChordQualityToken.major,
        extensions: const {ChordExtension.addSharp9},
      );

      expect(example.presentation.symbol.toString(), 'Cadd#9');
      expect(example.members, ['C', 'Eb', 'E', 'G']);
      expect(example.memberDegrees, ['1', 'b3', '3', '5']);
      expect(example.normalizedVoicing, [60, 63, 64, 67]);
    });

    test('builds minor sharp-eleventh examples', () {
      final example = _example(
        rootPc: 9,
        quality: ChordQualityToken.minor,
        extensions: const {ChordExtension.sharp11},
      );

      expect(example.presentation.symbol.toString(), 'Am#11');
      expect(example.members, ['A', 'C', 'E', 'D#']);
      expect(example.memberDegrees, ['1', 'b3', '5', '#11']);
      expect(example.normalizedVoicing, [57, 60, 64, 75]);
    });

    test('keeps augmented added-thirteenth examples literal', () {
      final example = _example(
        quality: ChordQualityToken.augmented,
        extensions: const {ChordExtension.add13},
      );

      expect(example.presentation.symbol.toString(), 'Caug(add13)');
      expect(example.members, ['C', 'E', 'G#', 'A']);
      expect(example.memberDegrees, ['1', '3', '#5', '13']);
      expect(example.normalizedVoicing, [60, 64, 68, 81]);
    });

    test('keeps minor-six added-eleventh examples literal', () {
      final example = _example(
        quality: ChordQualityToken.minor6,
        extensions: const {ChordExtension.add11},
      );

      expect(example.presentation.symbol.toString(), 'Cm6add11');
      expect(example.members, ['C', 'Eb', 'G', 'A', 'F']);
      expect(example.memberDegrees, ['1', 'b3', '5', '6', '11']);
      expect(example.normalizedVoicing, [60, 63, 67, 69, 77]);
    });

    test('builds sixth flat-ninth examples', () {
      final major = _example(
        quality: ChordQualityToken.major6,
        extensions: const {ChordExtension.flat9},
      );
      final minor = _example(
        quality: ChordQualityToken.minor6,
        extensions: const {ChordExtension.flat9},
      );

      expect(major.presentation.symbol.toString(), 'C6b9');
      expect(major.members, ['C', 'E', 'G', 'A', 'Db']);
      expect(major.memberDegrees, ['1', '3', '5', '6', 'b9']);
      expect(major.normalizedVoicing, [60, 64, 67, 69, 73]);

      expect(minor.presentation.symbol.toString(), 'Cm6b9');
      expect(minor.members, ['C', 'Eb', 'G', 'A', 'Db']);
      expect(minor.memberDegrees, ['1', 'b3', '5', '6', 'b9']);
      expect(minor.normalizedVoicing, [60, 63, 67, 69, 73]);
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

    test('uses only the selected added tone for a dominant add-eleventh', () {
      final example = _example(
        quality: ChordQualityToken.dominant7,
        extensions: const {ChordExtension.add11},
      );

      expect(example.presentation.symbol.toString(), 'C7(add11)');
      expect(example.members, ['C', 'E', 'G', 'Bb', 'F']);
      expect(example.memberDegrees, ['1', '3', '5', 'b7', '11']);
      expect(example.normalizedVoicing, [60, 64, 67, 70, 77]);
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
          tonality: const Tonality(Tonic.c, TonalityMode.major),
          notation: ChordNotationStyle.textual,
        ).toString();

        expect(symbol, entry.key);
      }
    });
  });
}

ChordExample _example({
  int rootPc = 0,
  int? bassPc,
  Tonic? root,
  Tonality tonality = const Tonality(Tonic.c, TonalityMode.major),
  required ChordQualityToken quality,
  Set<ChordExtension> extensions = const {},
}) {
  var state = ChordConstruction(
    rootPc: rootPc,
    bassPc: bassPc ?? rootPc,
    quality: quality,
    extensions: extensions,
  );
  if (root != null) state = state.copyWith(root: root);
  return ChordExampleBuilder.build(
    state: state,
    tonality: tonality,
    notation: ChordNotationStyle.textual,
  );
}

AnalysisContext _context() {
  const tonality = Tonality(Tonic.c, TonalityMode.major);
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
