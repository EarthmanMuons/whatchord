import '../models/chord_identity.dart';

const int chordRootInterval = 0;
const int minorSecondInterval = 1;
const int majorSecondInterval = 2;
const int minorThirdInterval = 3;
const int majorThirdInterval = 4;
const int perfectFourthInterval = 5;
const int tritoneInterval = 6;
const int diminishedFifthInterval = tritoneInterval;
const int sharpEleventhInterval = tritoneInterval;
const int perfectFifthInterval = 7;
const int minorSixthInterval = 8;
const int augmentedFifthInterval = minorSixthInterval;
const int majorSixthInterval = 9;
const int minorSeventhInterval = 10;
const int majorSeventhInterval = 11;

const int chordRootBit = 1 << chordRootInterval;

class ChordQualityIntervals {
  const ChordQualityIntervals({
    required this.quality,
    required this.canonicalMask,
    this.omittableMask = 0,
  });

  final ChordQualityToken quality;
  final int canonicalMask;
  final int omittableMask;

  int get templateBaseMask => canonicalMask & ~chordRootBit;

  int get templateRequiredMask => templateBaseMask & ~omittableMask;

  Set<int> get canonicalIntervals => _intervalsFromMask(canonicalMask);
}

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

final Map<ChordQualityToken, ChordQualityIntervals>
chordQualityIntervalsByQuality = {
  for (final intervals in chordQualityIntervalSets)
    intervals.quality: intervals,
};

extension ChordQualityTokenIntervals on ChordQualityToken {
  ChordQualityIntervals get intervals {
    return chordQualityIntervalsByQuality[this]!;
  }

  Set<int> get canonicalIntervals => intervals.canonicalIntervals;

  int get canonicalMask => intervals.canonicalMask;
}

Set<int> _intervalsFromMask(int mask) {
  return {
    for (var interval = 0; interval < 12; interval++)
      if ((mask & (1 << interval)) != 0) interval,
  };
}
