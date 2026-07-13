import 'package:meta/meta.dart';

import '../../models/chord_identity.dart';

enum ExploreBaseQuality {
  major,
  minor,
  power,
  diminished,
  augmented,
  sus2,
  sus4,
  sus2sus4,
}

enum ExploreSeventhKind {
  none,
  sixth,
  dominant7,
  major7,
  minor7,
  minorMajor7,
  halfDiminished7,
  diminished7,
}

enum ExploreFifthAlteration { natural, flat, sharp }

@immutable
class ExploreChordSpec {
  const ExploreChordSpec({
    required this.baseQuality,
    required this.seventhKind,
    required this.fifthAlteration,
  });

  factory ExploreChordSpec.fromQuality(ChordQualityToken quality) {
    return switch (quality) {
      ChordQualityToken.major => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.majorFlat5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
      ChordQualityToken.minor => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.minorSharp5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.sharp,
      ),
      ChordQualityToken.diminished => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.diminished,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
      ChordQualityToken.augmented => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.augmented,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.sharp,
      ),
      ChordQualityToken.sus2 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus2,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.sus4 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus4,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.sus2sus4 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus2sus4,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.power => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.power,
        seventhKind: ExploreSeventhKind.none,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.major6 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.sixth,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.minor6 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.sixth,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.dominant7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.dominant7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.dominant7sus2 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus2,
        seventhKind: ExploreSeventhKind.dominant7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.dominant7sus4 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus4,
        seventhKind: ExploreSeventhKind.dominant7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.dominant7Flat5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.dominant7,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
      ChordQualityToken.dominant7Sharp5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.dominant7,
        fifthAlteration: ExploreFifthAlteration.sharp,
      ),
      ChordQualityToken.major7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.major7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.major7sus2 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus2,
        seventhKind: ExploreSeventhKind.major7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.major7sus4 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.sus4,
        seventhKind: ExploreSeventhKind.major7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.major7Flat5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.major7,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
      ChordQualityToken.major7Sharp5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.major,
        seventhKind: ExploreSeventhKind.major7,
        fifthAlteration: ExploreFifthAlteration.sharp,
      ),
      ChordQualityToken.minor7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.minor7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.minor7Sharp5 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.minor7,
        fifthAlteration: ExploreFifthAlteration.sharp,
      ),
      ChordQualityToken.minorMajor7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.minor,
        seventhKind: ExploreSeventhKind.minorMajor7,
        fifthAlteration: ExploreFifthAlteration.natural,
      ),
      ChordQualityToken.halfDiminished7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.diminished,
        seventhKind: ExploreSeventhKind.halfDiminished7,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
      ChordQualityToken.diminished7 => const ExploreChordSpec(
        baseQuality: ExploreBaseQuality.diminished,
        seventhKind: ExploreSeventhKind.diminished7,
        fifthAlteration: ExploreFifthAlteration.flat,
      ),
    };
  }

  final ExploreBaseQuality baseQuality;
  final ExploreSeventhKind seventhKind;
  final ExploreFifthAlteration fifthAlteration;

  ExploreChordSpec normalized() {
    final seventh = availableSeventhKindsFor(baseQuality).contains(seventhKind)
        ? seventhKind
        : ExploreSeventhKind.none;

    final fifth =
        availableFifthAlterationsFor(
          baseQuality: baseQuality,
          seventhKind: seventh,
        ).contains(fifthAlteration)
        ? fifthAlteration
        : defaultFifthAlterationFor(baseQuality);

    return ExploreChordSpec(
      baseQuality: baseQuality,
      seventhKind: seventh,
      fifthAlteration: fifth,
    );
  }

  ChordQualityToken get quality {
    final spec = normalized();
    return _qualityFromSpec(
      baseQuality: spec.baseQuality,
      seventhKind: spec.seventhKind,
      fifthAlteration: spec.fifthAlteration,
    );
  }

  ExploreChordSpec copyWith({
    ExploreBaseQuality? baseQuality,
    ExploreSeventhKind? seventhKind,
    ExploreFifthAlteration? fifthAlteration,
  }) {
    return ExploreChordSpec(
      baseQuality: baseQuality ?? this.baseQuality,
      seventhKind: seventhKind ?? this.seventhKind,
      fifthAlteration: fifthAlteration ?? this.fifthAlteration,
    ).normalized();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreChordSpec &&
          other.baseQuality == baseQuality &&
          other.seventhKind == seventhKind &&
          other.fifthAlteration == fifthAlteration;

  @override
  int get hashCode => Object.hash(baseQuality, seventhKind, fifthAlteration);
}

List<ExploreSeventhKind> availableSeventhKindsFor(
  ExploreBaseQuality baseQuality,
) {
  return switch (baseQuality) {
    ExploreBaseQuality.major => const [
      ExploreSeventhKind.none,
      ExploreSeventhKind.sixth,
      ExploreSeventhKind.dominant7,
      ExploreSeventhKind.major7,
    ],
    ExploreBaseQuality.minor => const [
      ExploreSeventhKind.none,
      ExploreSeventhKind.sixth,
      ExploreSeventhKind.minor7,
      ExploreSeventhKind.minorMajor7,
    ],
    ExploreBaseQuality.diminished => const [
      ExploreSeventhKind.none,
      ExploreSeventhKind.diminished7,
      ExploreSeventhKind.halfDiminished7,
    ],
    ExploreBaseQuality.augmented => const [ExploreSeventhKind.none],
    ExploreBaseQuality.power => const [ExploreSeventhKind.none],
    ExploreBaseQuality.sus2 || ExploreBaseQuality.sus4 => const [
      ExploreSeventhKind.none,
      ExploreSeventhKind.dominant7,
      ExploreSeventhKind.major7,
    ],
    ExploreBaseQuality.sus2sus4 => const [ExploreSeventhKind.none],
  };
}

List<ExploreFifthAlteration> availableFifthAlterationsFor({
  required ExploreBaseQuality baseQuality,
  required ExploreSeventhKind seventhKind,
}) {
  return switch (baseQuality) {
    ExploreBaseQuality.major
        when seventhKind == ExploreSeventhKind.dominant7 ||
            seventhKind == ExploreSeventhKind.major7 =>
      const [
        ExploreFifthAlteration.natural,
        ExploreFifthAlteration.flat,
        ExploreFifthAlteration.sharp,
      ],
    ExploreBaseQuality.major when seventhKind == ExploreSeventhKind.none =>
      const [ExploreFifthAlteration.natural, ExploreFifthAlteration.flat],
    ExploreBaseQuality.major => const [ExploreFifthAlteration.natural],
    ExploreBaseQuality.minor
        when seventhKind == ExploreSeventhKind.none ||
            seventhKind == ExploreSeventhKind.minor7 =>
      const [ExploreFifthAlteration.natural, ExploreFifthAlteration.sharp],
    ExploreBaseQuality.minor => const [ExploreFifthAlteration.natural],
    ExploreBaseQuality.diminished => const [ExploreFifthAlteration.flat],
    ExploreBaseQuality.augmented => const [ExploreFifthAlteration.sharp],
    ExploreBaseQuality.power ||
    ExploreBaseQuality.sus2 ||
    ExploreBaseQuality.sus4 ||
    ExploreBaseQuality.sus2sus4 => const [ExploreFifthAlteration.natural],
  };
}

ExploreFifthAlteration defaultFifthAlterationFor(
  ExploreBaseQuality baseQuality,
) {
  return switch (baseQuality) {
    ExploreBaseQuality.diminished => ExploreFifthAlteration.flat,
    ExploreBaseQuality.augmented => ExploreFifthAlteration.sharp,
    _ => ExploreFifthAlteration.natural,
  };
}

ChordQualityToken _qualityFromSpec({
  required ExploreBaseQuality baseQuality,
  required ExploreSeventhKind seventhKind,
  required ExploreFifthAlteration fifthAlteration,
}) {
  if (seventhKind == ExploreSeventhKind.halfDiminished7) {
    return ChordQualityToken.halfDiminished7;
  }
  if (seventhKind == ExploreSeventhKind.diminished7) {
    return ChordQualityToken.diminished7;
  }
  if (seventhKind == ExploreSeventhKind.minor7) {
    return fifthAlteration == ExploreFifthAlteration.sharp
        ? ChordQualityToken.minor7Sharp5
        : ChordQualityToken.minor7;
  }
  if (seventhKind == ExploreSeventhKind.minorMajor7) {
    return ChordQualityToken.minorMajor7;
  }

  return switch ((baseQuality, seventhKind, fifthAlteration)) {
    (
      ExploreBaseQuality.major,
      ExploreSeventhKind.none,
      ExploreFifthAlteration.flat,
    ) =>
      ChordQualityToken.majorFlat5,
    (ExploreBaseQuality.major, ExploreSeventhKind.none, _) =>
      ChordQualityToken.major,
    (ExploreBaseQuality.major, ExploreSeventhKind.sixth, _) =>
      ChordQualityToken.major6,
    (
      ExploreBaseQuality.major,
      ExploreSeventhKind.dominant7,
      ExploreFifthAlteration.flat,
    ) =>
      ChordQualityToken.dominant7Flat5,
    (
      ExploreBaseQuality.major,
      ExploreSeventhKind.dominant7,
      ExploreFifthAlteration.sharp,
    ) =>
      ChordQualityToken.dominant7Sharp5,
    (ExploreBaseQuality.major, ExploreSeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7,
    (
      ExploreBaseQuality.major,
      ExploreSeventhKind.major7,
      ExploreFifthAlteration.flat,
    ) =>
      ChordQualityToken.major7Flat5,
    (
      ExploreBaseQuality.major,
      ExploreSeventhKind.major7,
      ExploreFifthAlteration.sharp,
    ) =>
      ChordQualityToken.major7Sharp5,
    (ExploreBaseQuality.major, ExploreSeventhKind.major7, _) =>
      ChordQualityToken.major7,
    (
      ExploreBaseQuality.minor,
      ExploreSeventhKind.none,
      ExploreFifthAlteration.sharp,
    ) =>
      ChordQualityToken.minorSharp5,
    (ExploreBaseQuality.minor, ExploreSeventhKind.none, _) =>
      ChordQualityToken.minor,
    (ExploreBaseQuality.minor, ExploreSeventhKind.sixth, _) =>
      ChordQualityToken.minor6,
    (ExploreBaseQuality.diminished, ExploreSeventhKind.none, _) =>
      ChordQualityToken.diminished,
    (ExploreBaseQuality.augmented, ExploreSeventhKind.none, _) =>
      ChordQualityToken.augmented,
    (ExploreBaseQuality.power, _, _) => ChordQualityToken.power,
    (ExploreBaseQuality.sus2, ExploreSeventhKind.none, _) =>
      ChordQualityToken.sus2,
    (ExploreBaseQuality.sus2, ExploreSeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7sus2,
    (ExploreBaseQuality.sus2, ExploreSeventhKind.major7, _) =>
      ChordQualityToken.major7sus2,
    (ExploreBaseQuality.sus4, ExploreSeventhKind.none, _) =>
      ChordQualityToken.sus4,
    (ExploreBaseQuality.sus4, ExploreSeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7sus4,
    (ExploreBaseQuality.sus4, ExploreSeventhKind.major7, _) =>
      ChordQualityToken.major7sus4,
    (ExploreBaseQuality.sus2sus4, ExploreSeventhKind.none, _) =>
      ChordQualityToken.sus2sus4,
    _ => ChordQualityToken.major,
  };
}
