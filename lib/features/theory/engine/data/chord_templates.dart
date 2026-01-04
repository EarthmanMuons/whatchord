import 'package:meta/meta.dart';

import '../models/chord_identity.dart';

@immutable
class ChordTemplate {
  /// Quality token for this template.
  final ChordQualityToken quality;

  /// Required intervals (as a 12-bit mask relative to root).
  final int requiredMask;

  /// Optional intervals (often omitted in real voicings).
  final int optionalMask;

  /// Intervals that strongly contradict this quality (penalty, not hard forbid).
  final int penaltyMask;

  const ChordTemplate({
    required this.quality,
    required this.requiredMask,
    this.optionalMask = 0,
    this.penaltyMask = 0,
  });

  int get baseMask => requiredMask | optionalMask;
}

/// 12-bit mask helper: set these intervals relative to root.
int m(List<int> intervals) {
  var mask = 0;
  for (final i in intervals) {
    mask |= (1 << (i % 12));
  }
  return mask;
}

/// Initial template set.
/// Notes:
/// - Fifths are often optional.
/// - Penalty masks discourage ambiguous thirds, etc.
const chordTemplates = <ChordTemplate>[
  // Triads
  ChordTemplate(
    quality: ChordQualityToken.major,
    requiredMask: 0 /*root*/ | (1 << 4),
    optionalMask: (1 << 7),
    penaltyMask: (1 << 3),
  ),
  ChordTemplate(
    quality: ChordQualityToken.minor,
    requiredMask: 0 /*root*/ | (1 << 3),
    optionalMask: (1 << 7),
    penaltyMask: (1 << 4),
  ),
  ChordTemplate(
    quality: ChordQualityToken.diminished,
    requiredMask: 0 /*root*/ | (1 << 3) | (1 << 6),
    optionalMask: 0,
    penaltyMask: (1 << 4) | (1 << 7),
  ),
  ChordTemplate(
    quality: ChordQualityToken.augmented,
    requiredMask: 0 /*root*/ | (1 << 4) | (1 << 8),
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 7),
  ),
  ChordTemplate(
    quality: ChordQualityToken.sus2,
    requiredMask: 0 /*root*/ | (1 << 2) | (1 << 7),
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 4),
  ),
  ChordTemplate(
    quality: ChordQualityToken.sus4,
    requiredMask: 0 /*root*/ | (1 << 5) | (1 << 7),
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 4),
  ),

  // 7th chords (5th optional)
  ChordTemplate(
    quality: ChordQualityToken.dominant7,
    requiredMask: 0 /*root*/ | (1 << 4) | (1 << 10),
    optionalMask: (1 << 7),
    penaltyMask: (1 << 11) | (1 << 3),
  ),
  ChordTemplate(
    quality: ChordQualityToken.major7,
    requiredMask: 0 /*root*/ | (1 << 4) | (1 << 11),
    optionalMask: (1 << 7),
    penaltyMask: (1 << 10) | (1 << 3),
  ),
  ChordTemplate(
    quality: ChordQualityToken.minor7,
    requiredMask: 0 /*root*/ | (1 << 3) | (1 << 10),
    optionalMask: (1 << 7),
    penaltyMask: (1 << 11) | (1 << 4),
  ),
  ChordTemplate(
    quality: ChordQualityToken.halfDiminished7,
    requiredMask: 0 /*root*/ | (1 << 3) | (1 << 6) | (1 << 10),
    optionalMask: 0,
    penaltyMask: (1 << 7) | (1 << 4) | (1 << 11),
  ),
  ChordTemplate(
    quality: ChordQualityToken.diminished7,
    requiredMask: 0 /*root*/ | (1 << 3) | (1 << 6) | (1 << 9),
    optionalMask: 0,
    penaltyMask: (1 << 10) | (1 << 7) | (1 << 4) | (1 << 11),
  ),
];
