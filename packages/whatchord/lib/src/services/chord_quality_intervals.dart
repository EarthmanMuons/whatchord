import '../models/chord_identity.dart';
import 'interval_constants.dart';

/// The interval content that defines one [ChordQualityToken].
class ChordQualityIntervals {
  const ChordQualityIntervals({
    required this.quality,
    required this.canonicalMask,
    this.omittableMask = 0,
  });

  /// The quality these intervals define.
  final ChordQualityToken quality;

  /// 12-bit mask of the quality's canonical tones, root included.
  final int canonicalMask;

  /// Tones a voicing may omit while still reading as this quality
  /// (typically the perfect fifth).
  final int omittableMask;

  /// [canonicalMask] without the root bit.
  int get templateBaseMask => canonicalMask & ~chordRootBit;

  /// The tones a voicing must contain to claim this quality.
  int get templateRequiredMask => templateBaseMask & ~omittableMask;

  /// [canonicalMask] as a set of semitone intervals above the root.
  Set<int> get canonicalIntervals => _intervalsFromMask(canonicalMask);
}

/// The interval definitions for every supported [ChordQualityToken].
const chordQualityIntervalSets = <ChordQualityIntervals>[
  ChordQualityIntervals(
    quality: ChordQualityToken.major,
    canonicalMask:
        chordRootBit | (1 << majorThirdInterval) | (1 << perfectFifthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.majorFlat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minor,
    canonicalMask:
        chordRootBit | (1 << minorThirdInterval) | (1 << perfectFifthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minorSharp5,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << augmentedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.diminished,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.augmented,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.power,
    canonicalMask: chordRootBit | (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.sus2,
    canonicalMask:
        chordRootBit | (1 << majorSecondInterval) | (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.sus2sus4,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major6,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSixthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minor6,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSixthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.dominant7,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.dominant7sus2,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.dominant7sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.dominant7Flat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.dominant7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major7,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major7sus2,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major7sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major7Flat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << majorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.major7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << majorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minor7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minor7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.minorMajor7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.halfDiminished7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQualityToken.diminished7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << majorSixthInterval),
  ),
];

/// [chordQualityIntervalSets] indexed by quality.
final Map<ChordQualityToken, ChordQualityIntervals>
chordQualityIntervalsByQuality = {
  for (final intervals in chordQualityIntervalSets)
    intervals.quality: intervals,
};

/// Interval lookups on [ChordQualityToken].
extension ChordQualityTokenIntervals on ChordQualityToken {
  /// The interval definition for this quality.
  ChordQualityIntervals get intervals {
    return chordQualityIntervalsByQuality[this]!;
  }

  /// Shorthand for `intervals.canonicalIntervals`.
  Set<int> get canonicalIntervals => intervals.canonicalIntervals;

  /// Shorthand for `intervals.canonicalMask`.
  int get canonicalMask => intervals.canonicalMask;
}

Set<int> _intervalsFromMask(int mask) {
  return {
    for (var interval = 0; interval < 12; interval++)
      if ((mask & (1 << interval)) != 0) interval,
  };
}
