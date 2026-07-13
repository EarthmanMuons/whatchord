import 'package:meta/meta.dart';

import '../../models/chord_identity.dart';

enum BaseQuality {
  major,
  minor,
  power,
  diminished,
  augmented,
  sus2,
  sus4,
  sus2sus4,
}

enum SeventhKind {
  none,
  sixth,
  dominant7,
  major7,
  minor7,
  minorMajor7,
  halfDiminished7,
  diminished7,
}

enum FifthAlteration { natural, flat, sharp }

@immutable
class ChordSpec {
  const ChordSpec({
    required this.baseQuality,
    required this.seventhKind,
    required this.fifthAlteration,
  });

  factory ChordSpec.fromQuality(ChordQualityToken quality) {
    return switch (quality) {
      ChordQualityToken.major => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.majorFlat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQualityToken.minor => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.minorSharp5 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQualityToken.diminished => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQualityToken.augmented => const ChordSpec(
        baseQuality: BaseQuality.augmented,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQualityToken.sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.sus2sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus2sus4,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.power => const ChordSpec(
        baseQuality: BaseQuality.power,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.major6 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.sixth,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.minor6 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.sixth,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.dominant7 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.dominant7sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.dominant7sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.dominant7Flat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQualityToken.dominant7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQualityToken.major7 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.major7sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.major7sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.major7Flat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQualityToken.major7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQualityToken.minor7 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minor7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.minor7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minor7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQualityToken.minorMajor7 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minorMajor7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQualityToken.halfDiminished7 => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.halfDiminished7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQualityToken.diminished7 => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.diminished7,
        fifthAlteration: FifthAlteration.flat,
      ),
    };
  }

  final BaseQuality baseQuality;
  final SeventhKind seventhKind;
  final FifthAlteration fifthAlteration;

  ChordSpec normalized() {
    final seventh = availableSeventhKindsFor(baseQuality).contains(seventhKind)
        ? seventhKind
        : SeventhKind.none;

    final fifth =
        availableFifthAlterationsFor(
          baseQuality: baseQuality,
          seventhKind: seventh,
        ).contains(fifthAlteration)
        ? fifthAlteration
        : defaultFifthAlterationFor(baseQuality);

    return ChordSpec(
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

  ChordSpec copyWith({
    BaseQuality? baseQuality,
    SeventhKind? seventhKind,
    FifthAlteration? fifthAlteration,
  }) {
    return ChordSpec(
      baseQuality: baseQuality ?? this.baseQuality,
      seventhKind: seventhKind ?? this.seventhKind,
      fifthAlteration: fifthAlteration ?? this.fifthAlteration,
    ).normalized();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordSpec &&
          other.baseQuality == baseQuality &&
          other.seventhKind == seventhKind &&
          other.fifthAlteration == fifthAlteration;

  @override
  int get hashCode => Object.hash(baseQuality, seventhKind, fifthAlteration);
}

List<SeventhKind> availableSeventhKindsFor(BaseQuality baseQuality) {
  return switch (baseQuality) {
    BaseQuality.major => const [
      SeventhKind.none,
      SeventhKind.sixth,
      SeventhKind.dominant7,
      SeventhKind.major7,
    ],
    BaseQuality.minor => const [
      SeventhKind.none,
      SeventhKind.sixth,
      SeventhKind.minor7,
      SeventhKind.minorMajor7,
    ],
    BaseQuality.diminished => const [
      SeventhKind.none,
      SeventhKind.diminished7,
      SeventhKind.halfDiminished7,
    ],
    BaseQuality.augmented => const [SeventhKind.none],
    BaseQuality.power => const [SeventhKind.none],
    BaseQuality.sus2 || BaseQuality.sus4 => const [
      SeventhKind.none,
      SeventhKind.dominant7,
      SeventhKind.major7,
    ],
    BaseQuality.sus2sus4 => const [SeventhKind.none],
  };
}

List<FifthAlteration> availableFifthAlterationsFor({
  required BaseQuality baseQuality,
  required SeventhKind seventhKind,
}) {
  return switch (baseQuality) {
    BaseQuality.major
        when seventhKind == SeventhKind.dominant7 ||
            seventhKind == SeventhKind.major7 =>
      const [
        FifthAlteration.natural,
        FifthAlteration.flat,
        FifthAlteration.sharp,
      ],
    BaseQuality.major when seventhKind == SeventhKind.none => const [
      FifthAlteration.natural,
      FifthAlteration.flat,
    ],
    BaseQuality.major => const [FifthAlteration.natural],
    BaseQuality.minor
        when seventhKind == SeventhKind.none ||
            seventhKind == SeventhKind.minor7 =>
      const [FifthAlteration.natural, FifthAlteration.sharp],
    BaseQuality.minor => const [FifthAlteration.natural],
    BaseQuality.diminished => const [FifthAlteration.flat],
    BaseQuality.augmented => const [FifthAlteration.sharp],
    BaseQuality.power ||
    BaseQuality.sus2 ||
    BaseQuality.sus4 ||
    BaseQuality.sus2sus4 => const [FifthAlteration.natural],
  };
}

FifthAlteration defaultFifthAlterationFor(BaseQuality baseQuality) {
  return switch (baseQuality) {
    BaseQuality.diminished => FifthAlteration.flat,
    BaseQuality.augmented => FifthAlteration.sharp,
    _ => FifthAlteration.natural,
  };
}

ChordQualityToken _qualityFromSpec({
  required BaseQuality baseQuality,
  required SeventhKind seventhKind,
  required FifthAlteration fifthAlteration,
}) {
  if (seventhKind == SeventhKind.halfDiminished7) {
    return ChordQualityToken.halfDiminished7;
  }
  if (seventhKind == SeventhKind.diminished7) {
    return ChordQualityToken.diminished7;
  }
  if (seventhKind == SeventhKind.minor7) {
    return fifthAlteration == FifthAlteration.sharp
        ? ChordQualityToken.minor7Sharp5
        : ChordQualityToken.minor7;
  }
  if (seventhKind == SeventhKind.minorMajor7) {
    return ChordQualityToken.minorMajor7;
  }

  return switch ((baseQuality, seventhKind, fifthAlteration)) {
    (BaseQuality.major, SeventhKind.none, FifthAlteration.flat) =>
      ChordQualityToken.majorFlat5,
    (BaseQuality.major, SeventhKind.none, _) => ChordQualityToken.major,
    (BaseQuality.major, SeventhKind.sixth, _) => ChordQualityToken.major6,
    (BaseQuality.major, SeventhKind.dominant7, FifthAlteration.flat) =>
      ChordQualityToken.dominant7Flat5,
    (BaseQuality.major, SeventhKind.dominant7, FifthAlteration.sharp) =>
      ChordQualityToken.dominant7Sharp5,
    (BaseQuality.major, SeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7,
    (BaseQuality.major, SeventhKind.major7, FifthAlteration.flat) =>
      ChordQualityToken.major7Flat5,
    (BaseQuality.major, SeventhKind.major7, FifthAlteration.sharp) =>
      ChordQualityToken.major7Sharp5,
    (BaseQuality.major, SeventhKind.major7, _) => ChordQualityToken.major7,
    (BaseQuality.minor, SeventhKind.none, FifthAlteration.sharp) =>
      ChordQualityToken.minorSharp5,
    (BaseQuality.minor, SeventhKind.none, _) => ChordQualityToken.minor,
    (BaseQuality.minor, SeventhKind.sixth, _) => ChordQualityToken.minor6,
    (BaseQuality.diminished, SeventhKind.none, _) =>
      ChordQualityToken.diminished,
    (BaseQuality.augmented, SeventhKind.none, _) => ChordQualityToken.augmented,
    (BaseQuality.power, _, _) => ChordQualityToken.power,
    (BaseQuality.sus2, SeventhKind.none, _) => ChordQualityToken.sus2,
    (BaseQuality.sus2, SeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7sus2,
    (BaseQuality.sus2, SeventhKind.major7, _) => ChordQualityToken.major7sus2,
    (BaseQuality.sus4, SeventhKind.none, _) => ChordQualityToken.sus4,
    (BaseQuality.sus4, SeventhKind.dominant7, _) =>
      ChordQualityToken.dominant7sus4,
    (BaseQuality.sus4, SeventhKind.major7, _) => ChordQualityToken.major7sus4,
    (BaseQuality.sus2sus4, SeventhKind.none, _) => ChordQualityToken.sus2sus4,
    _ => ChordQualityToken.major,
  };
}
