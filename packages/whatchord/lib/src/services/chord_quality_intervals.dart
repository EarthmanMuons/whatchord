import '../models/chord_identity.dart';
import 'bit_masks.dart';
import 'interval_constants.dart';

/// The interval content that defines one [ChordQuality].
class ChordQualityIntervals {
  const ChordQualityIntervals({
    required this.quality,
    required this.canonicalMask,
    this.omittableMask = 0,
  });

  /// The quality these intervals define.
  final ChordQuality quality;

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
  Set<int> get canonicalIntervals => intervalsFromMask(canonicalMask).toSet();
}

/// The interval definitions for every supported [ChordQuality].
const chordQualityIntervalSets = <ChordQualityIntervals>[
  ChordQualityIntervals(
    quality: ChordQuality.major,
    canonicalMask:
        chordRootBit | (1 << majorThirdInterval) | (1 << perfectFifthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.majorFlat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minor,
    canonicalMask:
        chordRootBit | (1 << minorThirdInterval) | (1 << perfectFifthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minorSharp5,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << augmentedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.diminished,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.augmented,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.power,
    canonicalMask: chordRootBit | (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.sus2,
    canonicalMask:
        chordRootBit | (1 << majorSecondInterval) | (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.sus2sus4,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major6,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSixthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minor6,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSixthInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.dominant7,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.dominant7sus2,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.dominant7sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.dominant7Flat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.dominant7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major7,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major7sus2,
    canonicalMask:
        chordRootBit |
        (1 << majorSecondInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major7sus4,
    canonicalMask:
        chordRootBit |
        (1 << perfectFourthInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major7Flat5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << majorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.major7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << majorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << majorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minor7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minor7Sharp5,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << augmentedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.minorMajor7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << majorSeventhInterval),
    omittableMask: 1 << perfectFifthInterval,
  ),
  ChordQualityIntervals(
    quality: ChordQuality.halfDiminished7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << minorSeventhInterval),
  ),
  ChordQualityIntervals(
    quality: ChordQuality.diminished7,
    canonicalMask:
        chordRootBit |
        (1 << minorThirdInterval) |
        (1 << diminishedFifthInterval) |
        (1 << majorSixthInterval),
  ),
];

/// [chordQualityIntervalSets] indexed by quality.
final Map<ChordQuality, ChordQualityIntervals> chordQualityIntervalsByQuality =
    {
      for (final intervals in chordQualityIntervalSets)
        intervals.quality: intervals,
    };

/// Interval lookups on [ChordQuality].
extension ChordQualityIntervalLookup on ChordQuality {
  /// The interval definition for this quality.
  ChordQualityIntervals get intervals {
    return chordQualityIntervalsByQuality[this]!;
  }

  /// Shorthand for `intervals.canonicalIntervals`.
  Set<int> get canonicalIntervals => intervals.canonicalIntervals;

  /// Shorthand for `intervals.canonicalMask`.
  int get canonicalMask => intervals.canonicalMask;
}
