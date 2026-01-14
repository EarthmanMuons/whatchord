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
/// above the assumed root (N = 0-11 semitones).
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

// ---- Interval constants -----------------------------------------------
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
// 8  = m6  (enharmonic: A5; functional alias: b13; also "#5" in augmented context)
// 9  = M6  (functional alias: 13; enharmonic: d7 is rare; avoid as primary name)
// 10 = m7  (functional alias: b7 / "dominant 7")
// 11 = M7

// Note: P0 is always enforced by the analyzer, not templates.
// const int _unison = 0;
// Note: m2 is handled as an extension, not in base templates.
// const int _minor2 = 1;
const int _major2 = 2;
const int _minor3 = 3;
const int _major3 = 4;
const int _perfect4 = 5;
const int _tritone = 6;
const int _diminished5 = _tritone; // b5
// const int _sharp11 = _tritone; // #11
const int _perfect5 = 7;
const int _minor6 = 8;
const int _augmented5 = _minor6; // #5 / b13
const int _major6 = 9;
const int _minor7 = 10;
const int _major7 = 11;

/// Template list (ordered for clarity, not scoring priority).
///
/// The analyzer tests all templates; order doesn't affect results.
/// Organized by complexity: triads -> power -> 6ths -> 7ths
const chordTemplates = <ChordTemplate>[
  // Major triad: R + M3 + (P5)
  // - M3 defines major quality
  // - P5 optional for sparse voicings
  // - Penalty: m3, b7, M7 (would suggest minor/seventh chords)
  ChordTemplate(
    quality: ChordQualityToken.major,
    requiredMask: (1 << _major3),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _minor3) | (1 << _minor7) | (1 << _major7),
  ),

  // Minor triad: R + m3 + (P5)
  // - m3 defines minor quality
  // - Penalty: M3, b7, M7 (would suggest major/seventh chords)
  ChordTemplate(
    quality: ChordQualityToken.minor,
    requiredMask: (1 << _minor3),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _major3) | (1 << _minor7) | (1 << _major7),
  ),

  // Diminished triad: R + m3 + b5
  // - m3 + b5 define diminished quality
  // - No optional tones (tight structure)
  // - Penalty: M3, P5 (would contradict diminished quality)
  ChordTemplate(
    quality: ChordQualityToken.diminished,
    requiredMask: (1 << _minor3) | (1 << _diminished5),
    optionalMask: 0,
    penaltyMask: (1 << _major3) | (1 << _perfect5),
  ),

  // Augmented triad: R + M3 + #5
  // - M3 + #5 define augmented quality
  // - No optional tones (symmetric structure)
  // - Penalty: m3, P5 (would contradict augmented quality)
  ChordTemplate(
    quality: ChordQualityToken.augmented,
    requiredMask: (1 << _major3) | (1 << _augmented5),
    optionalMask: 0,
    penaltyMask: (1 << _minor3) | (1 << _perfect5),
  ),

  // Sus2: R + M2 + P5
  // - Replaces third with major second (suspended harmony)
  // - P5 required (standard triad definition; prevents ambiguous two-note matches)
  // - Penalty: any third (would resolve the suspension) or seventh (would suggest 7sus2)
  ChordTemplate(
    quality: ChordQualityToken.sus2,
    requiredMask: (1 << _major2) | (1 << _perfect5),
    optionalMask: 0,
    penaltyMask:
        (1 << _minor3) | (1 << _major3) | (1 << _minor7) | (1 << _major7),
  ),

  // Sus4: R + P4 + P5
  // - Replaces third with perfect fourth (suspended harmony)
  // - P5 required (standard triad definition)
  // - Penalty: any third (would resolve the suspension) or seventh (would suggest 7sus4)
  ChordTemplate(
    quality: ChordQualityToken.sus4,
    requiredMask: (1 << _perfect4) | (1 << _perfect5),
    optionalMask: 0,
    penaltyMask:
        (1 << _minor3) | (1 << _major3) | (1 << _minor7) | (1 << _major7),
  ),

  // Power chord (5): R + P5
  // - No third (tonally ambiguous / distortion-friendly)
  // - Penalty: thirds prevent stealing major/minor triad candidates
  ChordTemplate(
    quality: ChordQualityToken.power5,
    requiredMask: (1 << _perfect5),
    optionalMask: 0,
    penaltyMask: (1 << _minor3) | (1 << _major3),
  ),

  // Major 6th: R + M3 + (P5) + 6
  // - Major third + major sixth
  // - P5 optional (like other major-family chords)
  // - Penalty: b7/M7 (ambiguous with inverted minor7/major7)
  //            m3 (would suggest minor6)
  ChordTemplate(
    quality: ChordQualityToken.major6,
    requiredMask: (1 << _major3) | (1 << _major6),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _minor7) | (1 << _major7) | (1 << _minor3),
  ),

  // Minor 6th: R + m3 + (P5) + 6
  // - Minor third + major sixth
  // - P5 optional
  // - Penalty: b7/M7 (ambiguous with seventh chords)
  //            M3 (would suggest major6)
  ChordTemplate(
    quality: ChordQualityToken.minor6,
    requiredMask: (1 << _minor3) | (1 << _major6),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _minor7) | (1 << _major7) | (1 << _major3),
  ),

  // Dominant 7th: R + M3 + (P5) + b7
  // - Major third + minor seventh (dominant function)
  // - P5 optional (shell voicing: R-3-b7)
  // - Penalty: M7 (would suggest major7), m3 (would suggest minor7)
  ChordTemplate(
    quality: ChordQualityToken.dominant7,
    requiredMask: (1 << _major3) | (1 << _minor7),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _major7) | (1 << _minor3),
  ),

  // Major 7th: R + M3 + (P5) + M7
  // - Major third + major seventh (stable, color chord)
  // - P5 optional
  // - Penalty: b7 (would suggest dominant7), m3 (would suggest minor-major7)
  ChordTemplate(
    quality: ChordQualityToken.major7,
    requiredMask: (1 << _major3) | (1 << _major7),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _minor7) | (1 << _minor3),
  ),

  // Minor 7th: R + m3 + (P5) + b7
  // - Minor third + minor seventh (subdominant/tonic function)
  // - P5 optional
  // - Penalty: M7 (would suggest minor-major7), M3 (would suggest dominant7)
  ChordTemplate(
    quality: ChordQualityToken.minor7,
    requiredMask: (1 << _minor3) | (1 << _minor7),
    optionalMask: (1 << _perfect5),
    penaltyMask: (1 << _major7) | (1 << _major3),
  ),

  // Half-diminished 7th: R + m3 + b5 + b7
  // - Minor third + diminished fifth + minor seventh
  // - No optional tones (all intervals define the quality)
  // - Penalty: P5 (contradicts b5), M3 (contradicts m3), M7 (contradicts b7)
  ChordTemplate(
    quality: ChordQualityToken.halfDiminished7,
    requiredMask: (1 << _minor3) | (1 << _diminished5) | (1 << _minor7),
    optionalMask: 0,
    penaltyMask: (1 << _perfect5) | (1 << _major3) | (1 << _major7),
  ),

  // Fully diminished 7th: R + m3 + b5 + d7 (enharmonic M6)
  // - Symmetrical: stacked minor thirds (R - m3 - b5 - d7)
  // - The top tone is spelled as diminished 7th in theory, but is pitch-class = M6 (9 semitones)
  // - No optional tones (tight, symmetrical structure)
  // - Penalty: b7 (would suggest half-diminished), P5/M3/M7 (contradict structure)
  ChordTemplate(
    quality: ChordQualityToken.diminished7,
    requiredMask: (1 << _minor3) | (1 << _diminished5) | (1 << _major6),
    optionalMask: 0,
    penaltyMask:
        (1 << _minor7) | (1 << _perfect5) | (1 << _major3) | (1 << _major7),
  ),
];
