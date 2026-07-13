import 'package:meta/meta.dart';

import '../../models/chord_identity.dart';

/// The triad-level foundation of a [ChordSpec].
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

/// The sixth or seventh a [ChordSpec] stacks on its base quality, if any.
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

/// Chromatic adjustment of a [ChordSpec]'s fifth.
enum FifthAlteration { natural, flat, sharp }

/// A chord quality decomposed into independently selectable parts: base
/// quality, sixth/seventh, and fifth alteration.
///
/// Not every combination is a real chord; [normalized] snaps invalid
/// combinations to the nearest valid spec, and [quality] maps the result to
/// its [ChordQuality].
@immutable
class ChordSpec {
  const ChordSpec({
    required this.baseQuality,
    required this.seventhKind,
    required this.fifthAlteration,
  });

  /// Decomposes [quality] into its spec parts.
  factory ChordSpec.fromQuality(ChordQuality quality) {
    return switch (quality) {
      ChordQuality.major => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.majorFlat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQuality.minor => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.minorSharp5 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQuality.diminished => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQuality.augmented => const ChordSpec(
        baseQuality: BaseQuality.augmented,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQuality.sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.sus2sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus2sus4,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.power => const ChordSpec(
        baseQuality: BaseQuality.power,
        seventhKind: SeventhKind.none,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.major6 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.sixth,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.minor6 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.sixth,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.dominant7 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.dominant7sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.dominant7sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.dominant7Flat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQuality.dominant7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.dominant7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQuality.major7 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.major7sus2 => const ChordSpec(
        baseQuality: BaseQuality.sus2,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.major7sus4 => const ChordSpec(
        baseQuality: BaseQuality.sus4,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.major7Flat5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQuality.major7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.major,
        seventhKind: SeventhKind.major7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQuality.minor7 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minor7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.minor7Sharp5 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minor7,
        fifthAlteration: FifthAlteration.sharp,
      ),
      ChordQuality.minorMajor7 => const ChordSpec(
        baseQuality: BaseQuality.minor,
        seventhKind: SeventhKind.minorMajor7,
        fifthAlteration: FifthAlteration.natural,
      ),
      ChordQuality.halfDiminished7 => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.halfDiminished7,
        fifthAlteration: FifthAlteration.flat,
      ),
      ChordQuality.diminished7 => const ChordSpec(
        baseQuality: BaseQuality.diminished,
        seventhKind: SeventhKind.diminished7,
        fifthAlteration: FifthAlteration.flat,
      ),
    };
  }

  /// The triad-level foundation.
  final BaseQuality baseQuality;

  /// The stacked sixth or seventh, if any.
  final SeventhKind seventhKind;

  /// The fifth's chromatic adjustment.
  final FifthAlteration fifthAlteration;

  /// This spec with invalid part combinations snapped to valid ones: an
  /// unavailable seventh drops to none, an unavailable fifth alteration
  /// falls back to the base quality's default.
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

  /// The chord quality this spec names, after normalization.
  ChordQuality get quality {
    final spec = normalized();
    return _qualityFromSpec(
      baseQuality: spec.baseQuality,
      seventhKind: spec.seventhKind,
      fifthAlteration: spec.fifthAlteration,
    );
  }

  /// A normalized copy with the given parts replaced.
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

/// The seventh kinds that form real chords on [baseQuality].
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

/// The fifth alterations that form real chords on the given base quality and
/// seventh kind.
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

/// The fifth alteration implied by [baseQuality] itself (flat for diminished,
/// sharp for augmented, natural otherwise).
FifthAlteration defaultFifthAlterationFor(BaseQuality baseQuality) {
  return switch (baseQuality) {
    BaseQuality.diminished => FifthAlteration.flat,
    BaseQuality.augmented => FifthAlteration.sharp,
    _ => FifthAlteration.natural,
  };
}

ChordQuality _qualityFromSpec({
  required BaseQuality baseQuality,
  required SeventhKind seventhKind,
  required FifthAlteration fifthAlteration,
}) {
  if (seventhKind == SeventhKind.halfDiminished7) {
    return ChordQuality.halfDiminished7;
  }
  if (seventhKind == SeventhKind.diminished7) {
    return ChordQuality.diminished7;
  }
  if (seventhKind == SeventhKind.minor7) {
    return fifthAlteration == FifthAlteration.sharp
        ? ChordQuality.minor7Sharp5
        : ChordQuality.minor7;
  }
  if (seventhKind == SeventhKind.minorMajor7) {
    return ChordQuality.minorMajor7;
  }

  return switch ((baseQuality, seventhKind, fifthAlteration)) {
    (BaseQuality.major, SeventhKind.none, FifthAlteration.flat) =>
      ChordQuality.majorFlat5,
    (BaseQuality.major, SeventhKind.none, _) => ChordQuality.major,
    (BaseQuality.major, SeventhKind.sixth, _) => ChordQuality.major6,
    (BaseQuality.major, SeventhKind.dominant7, FifthAlteration.flat) =>
      ChordQuality.dominant7Flat5,
    (BaseQuality.major, SeventhKind.dominant7, FifthAlteration.sharp) =>
      ChordQuality.dominant7Sharp5,
    (BaseQuality.major, SeventhKind.dominant7, _) => ChordQuality.dominant7,
    (BaseQuality.major, SeventhKind.major7, FifthAlteration.flat) =>
      ChordQuality.major7Flat5,
    (BaseQuality.major, SeventhKind.major7, FifthAlteration.sharp) =>
      ChordQuality.major7Sharp5,
    (BaseQuality.major, SeventhKind.major7, _) => ChordQuality.major7,
    (BaseQuality.minor, SeventhKind.none, FifthAlteration.sharp) =>
      ChordQuality.minorSharp5,
    (BaseQuality.minor, SeventhKind.none, _) => ChordQuality.minor,
    (BaseQuality.minor, SeventhKind.sixth, _) => ChordQuality.minor6,
    (BaseQuality.diminished, SeventhKind.none, _) => ChordQuality.diminished,
    (BaseQuality.augmented, SeventhKind.none, _) => ChordQuality.augmented,
    (BaseQuality.power, _, _) => ChordQuality.power,
    (BaseQuality.sus2, SeventhKind.none, _) => ChordQuality.sus2,
    (BaseQuality.sus2, SeventhKind.dominant7, _) => ChordQuality.dominant7sus2,
    (BaseQuality.sus2, SeventhKind.major7, _) => ChordQuality.major7sus2,
    (BaseQuality.sus4, SeventhKind.none, _) => ChordQuality.sus4,
    (BaseQuality.sus4, SeventhKind.dominant7, _) => ChordQuality.dominant7sus4,
    (BaseQuality.sus4, SeventhKind.major7, _) => ChordQuality.major7sus4,
    (BaseQuality.sus2sus4, SeventhKind.none, _) => ChordQuality.sus2sus4,
    _ => ChordQuality.major,
  };
}
