import 'package:meta/meta.dart';

import '../models/chord_identity.dart';

/// Chord structure templates for pitch-class matching.
///
/// Each template defines the expected interval structure for a chord quality:
/// - Required: tones that define the quality (e.g., M3 + P5 for major)
/// - Optional: tones often omitted in real voicings (typically the 5th)
/// - Penalty: tones that contradict the quality (e.g., m3 in a major chord)
///
/// Intervals are encoded as 12-bit masks where bit N represents interval N
/// above the root (N = 0-11 semitones).
///
/// Design philosophy:
/// - Fifths are usually optional (shell voicing support)
/// - Penalties are soft (scoring penalty, not hard rejection)
/// - Third quality defines major/minor family membership
/// - Seventh presence/type defines extended chord categories
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

// ---- Interval constants (semitones above root) ------------------------
// Pitch-class offsets (mod 12) above the assumed root.
// Interval identity is canonical; chord-function aliases are contextual.
//
// 0  = P1  unison / root
// 1  = m2  (functional alias: b9; enharmonic spelling: A1)
// 2  = M2  (functional alias: 9)
// 3  = m3  (functional alias: #9 in dominant context)
// 4  = M3
// 5  = P4  (functional alias: 11)
// 6  = tritone (A4 / d5; functional aliases: #11 or b5)
// 7  = P5
// 8  = m6  (enharmonic: A5; functional alias: b13; also “#5” in augmented context)
// 9  = M6  (functional alias: 13; enharmonic: d7 is rare; avoid as primary name)
// 10 = m7  (functional alias: b7 / “dominant 7”)
// 11 = M7

/// Template list (ordered for clarity, not scoring priority).
///
/// The analyzer tests all templates; order doesn't affect results.
/// Organized by complexity: triads → power → 6ths → 7ths
const chordTemplates = <ChordTemplate>[
  // Major triad: R + M3 + (P5)
  // - M3 defines major quality
  // - P5 optional for sparse voicings
  // - Penalty: m3, b7, M7 (would suggest minor/seventh chords)
  ChordTemplate(
    quality: ChordQualityToken.major,
    requiredMask: (1 << 4), // M3
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 3) | (1 << 10) | (1 << 11), // m3, b7, M7
  ),

  // Minor triad: R + m3 + (P5)
  // - m3 defines minor quality
  // - Penalty: M3, b7, M7 (would suggest major/seventh chords)
  ChordTemplate(
    quality: ChordQualityToken.minor,
    requiredMask: (1 << 3), // m3
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 4) | (1 << 10) | (1 << 11), // M3, b7, M7
  ),

  // Diminished triad: R + m3 + b5
  // - m3 + b5 define diminished quality
  // - No optional tones (tight structure)
  // - Penalty: M3, P5 (would contradict diminished quality)
  ChordTemplate(
    quality: ChordQualityToken.diminished,
    requiredMask: (1 << 3) | (1 << 6), // m3, b5
    optionalMask: 0,
    penaltyMask: (1 << 4) | (1 << 7), // M3, P5
  ),

  // Augmented triad: R + M3 + #5
  // - M3 + #5 define augmented quality
  // - No optional tones (symmetric structure)
  // - Penalty: m3, P5 (would contradict augmented quality)
  ChordTemplate(
    quality: ChordQualityToken.augmented,
    requiredMask: (1 << 4) | (1 << 8), // M3, #5
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 7), // m3, P5
  ),

  // Sus2: R + 9 + P5
  // - Replaces third with major second (suspended harmony)
  // - P5 required for stability (unlike major/minor triads)
  // - Penalty: any third or seventh (would resolve the suspension)
  ChordTemplate(
    quality: ChordQualityToken.sus2,
    requiredMask: (1 << 2) | (1 << 7), // 9, P5
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 4) | (1 << 10) | (1 << 11), // m3, M3, b7, M7
  ),

  // Sus4: R + 11 + P5
  // - Replaces third with perfect fourth (suspended harmony)
  // - P5 required for stability
  // - Penalty: any third or seventh (would resolve the suspension)
  ChordTemplate(
    quality: ChordQualityToken.sus4,
    requiredMask: (1 << 5) | (1 << 7), // 11, P5
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 4) | (1 << 10) | (1 << 11), // m3, M3, b7, M7
  ),

  // Power chord (5): R + P5
  // - No third (tonally ambiguous / distortion-friendly)
  // - Penalty: thirds prevent stealing major/minor triad candidates
  ChordTemplate(
    quality: ChordQualityToken.power5,
    requiredMask: (1 << 7), // P5
    optionalMask: 0,
    penaltyMask: (1 << 3) | (1 << 4), // m3, M3
  ),

  // Major 6th: R + M3 + (P5) + 6
  // - Major third + major sixth
  // - P5 optional (like other major-family chords)
  // - Penalty: b7/M7 (ambiguous with inverted minor7/major7)
  //            m3 (would suggest minor6)
  ChordTemplate(
    quality: ChordQualityToken.major6,
    requiredMask: (1 << 4) | (1 << 9), // M3, 6
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 10) | (1 << 11) | (1 << 3), // b7, M7, m3
  ),

  // Minor 6th: R + m3 + (P5) + 6
  // - Minor third + major sixth
  // - P5 optional
  // - Penalty: b7/M7 (ambiguous with seventh chords)
  //            M3 (would suggest major6)
  ChordTemplate(
    quality: ChordQualityToken.minor6,
    requiredMask: (1 << 3) | (1 << 9), // m3, 6
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 10) | (1 << 11) | (1 << 4), // b7, M7, M3
  ),

  // Dominant 7th: R + M3 + (P5) + b7
  // - Major third + minor seventh (dominant function)
  // - P5 optional (shell voicing: R-3-b7)
  // - Penalty: M7 (would suggest major7), m3 (would suggest minor7)
  ChordTemplate(
    quality: ChordQualityToken.dominant7,
    requiredMask: (1 << 4) | (1 << 10), // M3, b7
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 11) | (1 << 3), // M7, m3
  ),

  // Major 7th: R + M3 + (P5) + M7
  // - Major third + major seventh (stable, color chord)
  // - P5 optional
  // - Penalty: b7 (would suggest dominant7), m3 (would suggest minor-major7)
  ChordTemplate(
    quality: ChordQualityToken.major7,
    requiredMask: (1 << 4) | (1 << 11), // M3, M7
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 10) | (1 << 3), // b7, m3
  ),

  // Minor 7th: R + m3 + (P5) + b7
  // - Minor third + minor seventh (subdominant/tonic function)
  // - P5 optional
  // - Penalty: M7 (would suggest minor-major7), M3 (would suggest dominant7)
  ChordTemplate(
    quality: ChordQualityToken.minor7,
    requiredMask: (1 << 3) | (1 << 10), // m3, b7
    optionalMask: (1 << 7), // P5
    penaltyMask: (1 << 11) | (1 << 4), // M7, M3
  ),

  // Half-diminished 7th (ø7): R + m3 + b5 + b7
  // - Minor third + diminished fifth + minor seventh
  // - No optional tones (all intervals define the quality)
  // - Penalty: P5 (contradicts b5), M3 (contradicts m3), M7 (contradicts b7)
  ChordTemplate(
    quality: ChordQualityToken.halfDiminished7,
    requiredMask: (1 << 3) | (1 << 6) | (1 << 10), // m3, b5, b7
    optionalMask: 0,
    penaltyMask: (1 << 7) | (1 << 4) | (1 << 11), // P5, M3, M7
  ),

  // Fully diminished 7th (°7): R + m3 + b5 + bb7
  // - Symmetrical: stacked minor thirds (R - m3 - b5 - bb7/6)
  // - No optional tones (tight, symmetrical structure)
  // - Penalty: b7 (would suggest half-diminished), P5/M3/M7 (contradict structure)
  ChordTemplate(
    quality: ChordQualityToken.diminished7,
    requiredMask: (1 << 3) | (1 << 6) | (1 << 9), // m3, b5, bb7(6)
    optionalMask: 0,
    penaltyMask: (1 << 10) | (1 << 7) | (1 << 4) | (1 << 11), // b7, P5, M3, M7
  ),
];
