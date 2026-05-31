import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';
import '../services/chord_quality_intervals.dart';
import '../services/pitch_class.dart';

class RankingDecision {
  final int result;
  final String? decidedByRule;
  final double scoreDelta;

  const RankingDecision({
    required this.result,
    required this.decidedByRule,
    required this.scoreDelta,
  });
}

/// Ranks chord candidates using score-based comparison with tie-breaking rules.
///
/// When scores are within [nearTieWindow], applies heuristics to choose the
/// most musically appropriate interpretation (e.g., preferring root position,
/// diatonic chords, natural extensions, etc.).
///
/// NOTE: docs/site/articles/under-the-hood.html documents the ranking rules in
/// detail. Update the article when rules, their order, or nearTieWindow changes.
abstract final class ChordCandidateRanking {
  /// Score difference threshold for engaging tie-breaker rules.
  /// A value of 0.20 allows rules to resolve ambiguous interpretations
  /// without overriding clear score differences.
  static const double nearTieWindow = 0.20;

  /// Compares two candidates. Returns -1 if a ranks higher, 1 if b ranks higher.
  static int compare(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
  }) {
    return _decide(a, b, tonality: tonality).result;
  }

  /// Same as [compare], but returns detailed information about which rule decided.
  /// Useful for debugging and explaining ranking decisions to users.
  static RankingDecision explain(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
  }) {
    return _decide(a, b, tonality: tonality);
  }

  static RankingDecision _decide(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
  }) {
    final delta = b.score - a.score;
    final fa = _CandidateFeatures.from(a);
    final fb = _CandidateFeatures.from(b);

    for (final rule in _hardRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) {
        return RankingDecision(
          result: r,
          decidedByRule: rule.name,
          scoreDelta: delta,
        );
      }
    }

    if (delta.abs() > nearTieWindow) {
      final result = delta > 0 ? 1 : -1;
      return RankingDecision(
        result: result,
        decidedByRule: 'score outside near-tie window',
        scoreDelta: delta,
      );
    }

    for (final rule in _tieBreakerRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) {
        return RankingDecision(
          result: r,
          decidedByRule: rule.name,
          scoreDelta: delta,
        );
      }
    }

    final finalResult = a.identity.rootPc.compareTo(b.identity.rootPc);
    return RankingDecision(
      result: finalResult,
      decidedByRule: 'deterministic fallback: rootPc',
      scoreDelta: delta,
    );
  }

  // ---- Tie-breaker rules (applied in priority order) --------------------
  // These rules resolve near-ties by encoding musical preferences:
  // - Structural clarity (root position, shell tones)
  // - Functional harmony (diatonic, dominant alterations)
  // - Simplicity (fewer extensions/alterations, avoid suspensions)

  static final List<_NamedRule> _hardRules = <_NamedRule>[
    _NamedRule('prefer altered dominant7 over dim7 slash', _preferAlteredDom7),
    _NamedRule(
      'prefer conventional altered seventh over add11 slash',
      _preferConventionalAlteredSeventhOverAdd11Slash,
    ),
    _NamedRule(
      'prefer complete minor sharp11 over altered maj7sus4',
      _preferCompleteMinorSharp11OverAlteredMaj7Sus4,
    ),
    _NamedRule(
      'prefer close root-position dominant7 over non-dominant slash',
      _preferDom7RootOverNonDomSlash,
    ),
    _NamedRule(
      'prefer ninth-bass seventh chord over altered slash',
      _preferNinthBassSeventhOverAlteredSlash,
    ),
    _NamedRule(
      'prefer minor7 eleventh-bass slash over minor7 sharp-five slash',
      _preferMinor7EleventhBassSlashOverMinor7SharpFiveSlash,
    ),
    _NamedRule(
      'prefer root-position altered-fifth dominant over slash',
      _preferRootAlteredFifthDom7,
    ),
    _NamedRule(
      'prefer root-position add-chord over sus slash',
      _preferRootAddChordOverSusSlash,
    ),
    _NamedRule(
      'prefer complete triad over structurally deficient reading',
      _preferCompleteTriadOverDeficientReading,
    ),
  ];

  static final List<_NamedRule> _tieBreakerRules = <_NamedRule>[
    _NamedRule('prefer root-position 6th over inverted 7th', _prefer6thInRoot),
    _NamedRule(
      'prefer complete triad over incomplete inverted 6th',
      _preferCompleteTriadOverIncompleteInvertedSixth,
    ),
    _NamedRule(
      'prefer upper-structure dominant7 slash',
      _preferUpperStructureDom7,
    ),
    _NamedRule(
      'prefer root-position dominant sus over slash',
      _preferRootDominantSusOverSlash,
    ),
    _NamedRule(
      'prefer root-position extended dominant over altered-fifth slash',
      _preferRootExtendedDom7OverAlteredFifthSlash,
    ),
    _NamedRule(
      'prefer complete major inversion over minor sharp-five',
      _preferCompleteMajorInversionOverMinorSharpFive,
    ),
    _NamedRule(
      'prefer complete major inversion over seventh-family color-bass slash',
      _preferCompleteMajorInversionOverSeventhColorBassSlash,
    ),
    _NamedRule('prefer root-position diminished7', _preferDim7InRoot),
    _NamedRule('prefer dominant7 over dim7 slash', _preferDom7Shell),
    _NamedRule(
      'prefer dominant7 shell slash over non-dominant seventh-family slash',
      _preferDom7ShellSlashOverSeventhFamilySlash,
    ),
    _NamedRule(
      'prefer voicing that names every tone',
      _preferFullyExplainedVoicing,
    ),
    _NamedRule('prefer fewer altered/tension colors', _preferFewerAlterations),
    _NamedRule('prefer diatonic chords', _preferDiatonic),
    _NamedRule('prefer tonic chord', _preferTonicChord),
    _NamedRule('prefer I chord when bass is tonic', _preferTonicAsI),
    _NamedRule(
      'prefer natural extensions over adds, then fewer total',
      _preferNaturalExtensions,
    ),
    _NamedRule(
      'prefer complete triad add-tone over seventh-family add-tone',
      _preferCompleteTriadAddToneOverSeventhFamilyAddTone,
    ),
    _NamedRule('prefer root position', _preferRootPosition),
    _NamedRule(
      'prefer more conventional inversion',
      _preferConventionalInversion,
    ),
    _NamedRule('prefer 7th chords over triads', _prefer7thChords),
    _NamedRule('prefer fewer extensions', _preferFewerExtensions),
    _NamedRule('avoid suspended chords', _avoidSuspended),
  ];

  /// Resolves ambiguity between 6th chords and inverted 7th chords.
  ///
  /// Example: {C, E, G, A} could be C6 or Am7/C. Prefer C6 in root position
  /// when the 7th chord interpretation would be inverted with no extensions.
  static int? _prefer6thInRoot(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (fa.isSixFamily == fb.isSixFamily) return null;

    final aIs6 = fa.isSixFamily;
    final fsix = aIs6 ? fa : fb;
    final fother = aIs6 ? fb : fa;

    if (fsix.isRootPosition &&
        !fother.isRootPosition &&
        fother.extensionCount == 0) {
      return aIs6 ? -1 : 1;
    }

    return null;
  }

  /// Prefers a complete major/minor triad core over an incomplete inverted 6th
  /// chord.
  ///
  /// Example: {B, E, G} with B in the bass can be read as G6/B or Em/B.
  /// The E minor triad is complete, while the G6 reading omits its fifth and
  /// depends on an inversion. Keep this narrow so root-position 6th colors
  /// with an omitted fifth are not demoted to relative-minor slash chords.
  ///
  /// The complete triad may carry simple add-tone color: {A, C, D, E} with E
  /// bass is better read as Amadd11/E than C6/9/E, because the A minor triad is
  /// complete while the C6/9 reading omits the fifth.
  static int? _preferCompleteTriadOverIncompleteInvertedSixth(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsIncompleteSixth = fa.isIncompleteInvertedSixth;
    final bIsIncompleteSixth = fb.isIncompleteInvertedSixth;
    if (aIsIncompleteSixth == bIsIncompleteSixth) return null;

    final aIsCompleteTriad = fa.isCompleteMajorMinorTriad;
    final bIsCompleteTriad = fb.isCompleteMajorMinorTriad;

    if (aIsIncompleteSixth && bIsCompleteTriad) return 1;
    if (bIsIncompleteSixth && aIsCompleteTriad) return -1;

    return null;
  }

  /// Resolves C7#9 vs Eb°7 ambiguity by preferring the dominant reading when:
  /// - Dominant is in root position with shell tones (3rd + b7) present
  /// - Dominant has color tones (extensions/alterations)
  /// - Diminished reading would be a slash chord with color-tone bass
  ///
  /// Example: {C, E, Bb, Eb} → prefer C7b9 over Eb°7/C
  static int? _preferAlteredDom7(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    // Engage only for (dominant7) vs (fully diminished7) comparisons.
    final aIsDom7 = fa.isDom7;
    final bIsDom7 = fb.isDom7;
    final aIsDimFamily = fa.isDimFamily;
    final bIsDimFamily = fb.isDimFamily;

    final domVsDim = (aIsDom7 && bIsDimFamily) || (bIsDom7 && aIsDimFamily);
    if (!domVsDim) return null;

    final fDom = aIsDom7 ? fa : fb;
    final fDim = aIsDom7 ? fb : fa;
    final domIsA = aIsDom7;

    if (!fDom.isDom7RootPosition) return null;
    if (!fDom.dom7HasShell) return null;
    if (!fDim.isSlashBass) return null;
    if (!fDim.bassIsColorTone) return null;

    // Require that the dominant is actually "doing something dominant-ish",
    // i.e. it has at least one real extension/alteration.
    // This is what keeps plain C7 from always beating (say) Cdim7 contexts.
    final domHasColor =
        (fDom.extPref.naturalCount + fDom.extPref.alterationCount) > 0;
    if (!domHasColor) return null;

    // If all of the above holds: prefer dominant7 interpretation.
    return domIsA ? -1 : 1;
  }

  /// Distinguishes upper-structure dominants from inversions.
  ///
  /// When comparing two dominant7 readings (root-position vs slash):
  /// - If slash bass is a color tone (e.g., #11, b9, 13) with no other alterations,
  ///   treat it as an intentional upper-structure voicing → prefer slash
  /// - If slash bass is a core tone (3rd/5th/7th), treat it as an inversion → prefer root
  ///
  /// Example: {Gb, C, E, Bb} → prefer C7/F# over Gb7#11
  static int? _preferUpperStructureDom7(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (!fa.isDom7 || !fb.isDom7) return null;

    // Safety: ensure we really have (slash vs root-position).
    if (fa.isRootPosition == fb.isRootPosition) return null;

    final slashIsA = fa.isDom7Slash;
    final fSlash = slashIsA ? fa : fb;
    final fRoot = slashIsA ? fb : fa;

    // Safety: ensure we really have (slash vs root-position).
    if (!fSlash.isDom7Slash || !fRoot.isDom7RootPosition) return null;

    // Require shell tones to avoid overfitting to sparse voicings.
    if (!fSlash.dom7HasShell || !fRoot.dom7HasShell) return null;

    // If slash bass is color, it *might* be an upper-structure reading,
    // but only if the slash-dominant doesn't have other alterations besides the bass.
    final slashLooksLikeUpperStructure =
        fSlash.bassIsColorTone && !fSlash.dom7SlashHasNonBassAlterations;

    if (slashLooksLikeUpperStructure) {
      // Slash candidate wins.
      return slashIsA ? -1 : 1;
    } else {
      // Otherwise treat it as an inversion-ish/weird slash and prefer root-position.
      return slashIsA ? 1 : -1;
    }
  }

  /// Prefers a conventional root-position extended dominant over a remote
  /// altered-fifth dominant slash spelling in close calls.
  ///
  /// Example: {C, E, G, Bb, D, F#} is better read as C9#11 than D11#5/C.
  /// The D-rooted spelling is possible, but it treats the bass as a seventh and
  /// respells Bb as A#; the C-rooted reading has the bass, shell, and extensions
  /// aligned with the observed voicing.
  static int? _preferRootExtendedDom7OverAlteredFifthSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = _isRootExtendedDom7(a.identity, fa);
    final bIsPreferred = _isRootExtendedDom7(b.identity, fb);
    if (aIsPreferred == bIsPreferred) return null;

    final fOther = aIsPreferred ? fb : fa;
    if (!fOther.isAlteredFifthDom7) return null;
    if (!fOther.isSlashBass) return null;
    if (!fOther.dom7HasShell) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers a bass-rooted suspended dominant over remote slash spellings.
  ///
  /// Example: {D, G, A, C, E} with D in the bass is normally read as D9sus4,
  /// not Em7#5(add11)/D. The latter is pitch-class valid, but it respells C as
  /// B# and turns a straightforward dominant sus voicing into a remote altered
  /// seventh slash chord.
  static int? _preferRootDominantSusOverSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = fa.isRootDominantSus;
    final bIsPreferred = fb.isRootDominantSus;
    if (aIsPreferred == bIsPreferred) return null;

    final fPreferred = aIsPreferred ? fa : fb;
    if (fPreferred.extPref.alterationCount > 0) return null;

    final fOther = aIsPreferred ? fb : fa;
    if (!fOther.isSlashBass) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers the ordinary inverted major triad reading over the
  /// enharmonically equivalent minor-sharp-five reading.
  ///
  /// Example: {C, Eb, Ab} with C or Eb in the bass is normally heard and written
  /// as Ab/C or Ab/Eb, not Cm#5. The latter is pitch-class valid, but it depends
  /// on spelling Ab as G# and treats a complete consonant triad as an altered
  /// minor color.
  static int? _preferCompleteMajorInversionOverMinorSharpFive(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsMajorInversion = fa.isCompleteMajorTriadInversion;
    final bIsMajorInversion = fb.isCompleteMajorTriadInversion;
    if (aIsMajorInversion == bIsMajorInversion) return null;

    final fOther = aIsMajorInversion ? fb : fa;
    if (!fOther.isMinorSharpFive) return null;

    return aIsMajorInversion ? -1 : 1;
  }

  /// Prefers a complete major triad inversion over a seventh-family slash chord
  /// where the bass note only appears as a color-tone add-extension.
  ///
  /// Example: {A, B, C, F} with A in the bass reads naturally as F(#11)/A
  /// (first inversion, bass=M3), not Cmaj7sus4(add13)/A where the bass A is
  /// merely an add13 extension on an unrelated root. The inversion reading keeps
  /// all four tones in a single coherent chord name without borrowing the bass
  /// as an ornament.
  static int? _preferCompleteMajorInversionOverSeventhColorBassSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsMajorInversion = fa.isCompleteMajorTriadInversion;
    final bIsMajorInversion = fb.isCompleteMajorTriadInversion;
    if (aIsMajorInversion == bIsMajorInversion) return null;

    final fOther = aIsMajorInversion ? fb : fa;
    if (!fOther.isSeventhFamily || !fOther.bassIsColorTone) return null;

    return aIsMajorInversion ? -1 : 1;
  }

  static bool _isRootExtendedDom7(
    ChordIdentity id,
    _CandidateFeatures features,
  ) {
    if (!features.isDom7RootPosition) return false;
    if (!features.dom7HasShell) return false;
    if (!id.extensions.contains(ChordExtension.nine)) return false;
    return id.extensions.contains(ChordExtension.sharp11);
  }

  /// Prefers root-position diminished7 even though they're symmetrical.
  ///
  /// Fully diminished 7th chords have identical interval structure in all inversions
  /// (stacked minor 3rds), but the bass note often indicates functional intent:
  /// - Leading-tone dim7: bass = tendency tone resolving up
  /// - Passing/neighbor dim7: bass = dissonant approach to target chord
  ///
  /// When scores are tied, prefer the interpretation where the bass note
  /// is named as the root for notational clarity and functional analysis.
  ///
  /// Example: {B, D, F, Ab} → prefer B°7 over D°7/B when bass is B
  static int? _preferDim7InRoot(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (!fa.isDim7 && !fb.isDim7) return null;

    if (fa.isDim7 && fb.isDim7) {
      if (fa.isRootPosition == fb.isRootPosition) return null;
      return fb.isRootPosition ? 1 : -1;
    }

    final aIsPreferredDim7 = fa.isDim7 && fa.isRootPosition;
    final bIsPreferredDim7 = fb.isDim7 && fb.isRootPosition;

    if (aIsPreferredDim7 == bIsPreferredDim7) return null;

    final otherIsSlash = aIsPreferredDim7
        ? !fb.isRootPosition
        : !fa.isRootPosition;
    if (!otherIsSlash) return null;

    return bIsPreferredDim7 ? 1 : -1;
  }

  /// Prefers dominant7 shell (3+b7) over dim7 slash reinterpretation.
  ///
  /// When the same notes can be read as either a dominant7 with shell tones
  /// or a diminished7 slash with color-tone bass, prefer the dominant reading
  /// (matches musician expectation for altered dominant voicings).
  static int? _preferDom7Shell(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsDom = fa.isDom7;
    final bIsDom = fb.isDom7;
    final aIsDim7 = fa.isDim7;
    final bIsDim7 = fb.isDim7;

    // Only engage on dominant7 vs diminished7 comparisons.
    final domVsDim = (aIsDom && bIsDim7) || (bIsDom && aIsDim7);
    if (!domVsDim) return null;

    final domIsA = aIsDom;
    final fDom = domIsA ? fa : fb;
    final fDim = domIsA ? fb : fa;

    // Require strong dominant evidence (shell).
    if (!fDom.dom7HasShell) return null;

    // If the diminished7 candidate is a slash reading and its bass is a color tone,
    // prefer the dominant reading (musician expectation for altered dominants).
    final dimIsSlash = fDim.isSlashBass;
    if (!dimIsSlash) return null;

    // Use the same "color bass" classifier you already built (it works beyond dom7),
    // or add a generic one. If you don't have a generic one yet, treat any non-core
    // bass role as "color".
    if (!fDim.bassIsColorTone) return null;

    // Dominant wins.
    return domIsA ? -1 : 1;
  }

  /// Prefers a root-position dominant7 (with shell) over a non-dominant slash
  /// interpretation in near-ties.
  ///
  /// This catches cases like:
  ///   {C, E, Bb, Db, F#, Ab, G} -> prefer C7(b9,#11,b13)
  /// over remote minor-major / extended slash readings.
  static int? _preferDom7RootOverNonDomSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = fa.isDom7RootPosition && fa.dom7HasShell;
    final bIsPreferred = fb.isDom7RootPosition && fb.dom7HasShell;
    if (aIsPreferred == bIsPreferred) return null;

    final fDom = aIsPreferred ? fa : fb;
    final fOther = aIsPreferred ? fb : fa;
    final domCandidate = aIsPreferred ? a : b;
    final otherCandidate = aIsPreferred ? b : a;

    // Only when the competing interpretation is a slash and not itself dominant7.
    if (!fOther.isSlashBass) return null;
    if (fOther.isDom7) return null;
    if (fOther.isAlteredFifthDom7) return null;

    // Ensure the dominant reading is not "plain"; it should have some color.
    final domHasColor =
        (fDom.extPref.naturalCount + fDom.extPref.alterationCount) > 0;
    if (!domHasColor) return null;

    if (domCandidate.score + 0.25 < otherCandidate.score) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers a complete seventh chord with the ninth in the bass over a remote
  /// altered slash spelling.
  ///
  /// Example: {C, D, E, G, Bb} with D in the bass is normally understood as
  /// C9/D (often written C7/D), not Em7#5#11/D. The E-rooted spelling is
  /// pitch-class valid, but it respells C as B# and treats a plain C dominant
  /// stack as a remote altered minor seventh chord.
  static int? _preferNinthBassSeventhOverAlteredSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = fa.isCompleteNinthBassSeventhChord;
    final bIsPreferred = fb.isCompleteNinthBassSeventhChord;
    if (aIsPreferred == bIsPreferred) return null;

    final fOther = aIsPreferred ? fb : fa;
    final preferredCandidate = aIsPreferred ? a : b;
    final otherCandidate = aIsPreferred ? b : a;

    if (!fOther.isSlashBass) return null;
    if (fOther.extensionTensionCount == 0) return null;
    if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers the complete minor seventh upper-structure slash reading over a
  /// remote minor-seven-sharp-five slash spelling.
  ///
  /// Example: {D, A, C, E, G} with D in the bass has D9sus4 as the strongest
  /// root-position sus reading, but if comparing slash alternatives, Am7/D is
  /// clearer than Em7#5(add11)/D. The latter respells C as B# and turns a
  /// complete minor seventh chord into a remote altered-fifth chord.
  static int? _preferMinor7EleventhBassSlashOverMinor7SharpFiveSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = fa.isCompleteMinor7EleventhBassSlash;
    final bIsPreferred = fb.isCompleteMinor7EleventhBassSlash;
    if (aIsPreferred == bIsPreferred) return null;

    final fOther = aIsPreferred ? fb : fa;
    final preferredCandidate = aIsPreferred ? a : b;
    final otherCandidate = aIsPreferred ? b : a;
    if (!fOther.isSlashBass) return null;
    if (otherCandidate.identity.quality != ChordQualityToken.minor7Sharp5) {
      return null;
    }

    if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers root-position altered-fifth dominants over close slash readings.
  ///
  /// Flat-five and sharp-five dominant sevenths are tritone-symmetric, so a
  /// slash interpretation can score competitively even when the root-position
  /// name is clearer. Prefer the root-position reading when it has a real
  /// alteration and the slash reading only has added or natural color tones.
  static int? _preferRootAlteredFifthDom7(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (!fa.isAlteredFifthDom7 || !fb.isAlteredFifthDom7) return null;
    if (fa.isRootPosition == fb.isRootPosition) return null;

    final rootIsA = fa.isRootPosition;
    final fRoot = rootIsA ? fa : fb;
    final fSlash = rootIsA ? fb : fa;
    final rootCandidate = rootIsA ? a : b;
    final slashCandidate = rootIsA ? b : a;

    if (!fRoot.dom7HasShell || !fSlash.dom7HasShell) return null;

    final rootHasAlteration = fRoot.extPref.alterationCount > 0;
    final slashHasOnlyAddOrNaturalColor = fSlash.extPref.alterationCount == 0;
    if (!rootHasAlteration || !slashHasOnlyAddOrNaturalColor) return null;

    if (rootCandidate.score + 0.50 < slashCandidate.score) return null;

    return rootIsA ? -1 : 1;
  }

  /// Avoids promoting remote, non-dominant slash readings whose "simple" color
  /// is a natural 11 against a major third.
  ///
  /// Example: {Ab, B, C, E, F} is better read as Fm(maj7)#11/Ab than as
  /// Cmaj7#5(add11)/G#, because the F-rooted reading is a normal inversion of
  /// a complete altered seventh chord while the C-rooted reading depends on a
  /// non-dominant add11 clash and a less stable slash bass.
  static int? _preferConventionalAlteredSeventhOverAdd11Slash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsQuestionableSlash = fa.isQuestionableAdd11Slash;
    final bIsQuestionableSlash = fb.isQuestionableAdd11Slash;
    if (aIsQuestionableSlash == bIsQuestionableSlash) return null;

    final questionable = aIsQuestionableSlash ? a : b;
    final conventional = aIsQuestionableSlash ? b : a;
    final fq = aIsQuestionableSlash ? fa : fb;
    final fc = aIsQuestionableSlash ? fb : fa;

    if (!fc.isSeventhFamily) return null;
    if (fc.extensionTensionCount == 0) return null;
    if (fc.bassRoleRank >= fq.bassRoleRank) return null;

    // Keep this rule bounded to close structural ambiguities. Wider gaps should
    // still be decided by the raw template fit.
    if (conventional.score + 0.55 < questionable.score) return null;

    return aIsQuestionableSlash ? 1 : -1;
  }

  /// Prefers a complete minor triad with a single sharp-eleventh color over a
  /// root-position major-7-sus4 reading that needs an altered thirteenth.
  ///
  /// Example: {E, A, C, D#} is more defensibly Am#11/E than Emaj7sus4(b13):
  /// the A-rooted reading preserves a complete minor triad, while the E-rooted
  /// reading has neither a third nor fifth and depends on b13 color.
  static int? _preferCompleteMinorSharp11OverAlteredMaj7Sus4(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsMinorSharp11 = fa.isCompleteMinorSharp11;
    final bIsMinorSharp11 = fb.isCompleteMinorSharp11;
    if (aIsMinorSharp11 == bIsMinorSharp11) return null;

    final fMinor = aIsMinorSharp11 ? fa : fb;
    final fSus = aIsMinorSharp11 ? fb : fa;
    final minorCandidate = aIsMinorSharp11 ? a : b;
    final susCandidate = aIsMinorSharp11 ? b : a;

    if (!fMinor.isSecondInversion) return null;
    if (!fSus.isAlteredMajor7Sus4) return null;

    // Keep the override narrow: if the template score strongly favors the sus
    // reading, let score win.
    if (minorCandidate.score + 0.35 < susCandidate.score) return null;

    return aIsMinorSharp11 ? -1 : 1;
  }

  /// Prefers a root-position major/minor add-chord over a sus-family slash
  /// interpretation of the same notes.
  ///
  /// Example: {C, E, G, F} is naturally read as Cadd11, not Fmaj7sus2/C.
  /// The F-rooted sus reading fits the template cleanly (no extra tones), so it
  /// earns a higher raw score. But the score advantage is a structural artifact:
  /// the major7sus2 template has three required tones, which accumulates more
  /// reward than the two-required-tone major template, even though musicians
  /// universally hear the simpler root-position reading.
  ///
  /// The 1.50-point guard lets the sus reading win when the score difference is
  /// decisive rather than merely a template-complexity artifact.
  static int? _preferRootAddChordOverSusSlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsPreferred = fa.isRootPositionNaturalAddChord;
    final bIsPreferred = fb.isRootPositionNaturalAddChord;
    if (aIsPreferred == bIsPreferred) return null;

    final fSus = aIsPreferred ? fb : fa;
    if (!fSus.isSus || !fSus.isSlashBass) return null;

    final preferredCandidate = aIsPreferred ? a : b;
    final susCandidate = aIsPreferred ? b : a;

    if (preferredCandidate.score + 1.50 < susCandidate.score) return null;

    return aIsPreferred ? -1 : 1;
  }

  /// Prefers a complete major/minor triad with add-tone extensions over a
  /// seventh-family chord whose extensions are all add-tones in a near-tie.
  ///
  /// A complete triad with simple color tones (e.g., Bbmadd9/Db) is a more
  /// conventional and stable structure than forcing the same pitches into a
  /// seventh-family framework with unusual extension pairings (e.g.,
  /// Dbmaj7(add13) where a maj7(add13) is rare in practice).
  static int? _preferCompleteTriadAddToneOverSeventhFamilyAddTone(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    // One candidate must be a complete major/minor triad carrying only
    // add-tone extensions (no alterations or stacked natural extensions).
    final aIsTriadAddTone =
        fa.isCompleteMajorMinorTriad &&
        fa.extPref.alterationCount == 0 &&
        fa.extPref.naturalCount == 0;
    final bIsTriadAddTone =
        fb.isCompleteMajorMinorTriad &&
        fb.extPref.alterationCount == 0 &&
        fb.extPref.naturalCount == 0;
    if (aIsTriadAddTone == bIsTriadAddTone) return null;

    // The other must be a seventh-family chord carrying only add-tone
    // extensions, indicating the same pitch set is being forced into an
    // unconventional seventh-family framework.
    final fOther = aIsTriadAddTone ? fb : fa;
    if (!fOther.isSeventhFamily) return null;
    if (fOther.extPref.alterationCount > 0) return null;
    if (fOther.extPref.naturalCount > 0) return null;

    return aIsTriadAddTone ? -1 : 1;
  }

  /// Prefers a complete major/minor triad carrying only natural/add color over
  /// a structurally deficient reading that omits a core tone.
  ///
  /// A complete triad (root + 3rd + 5th) with simple add color is a strong,
  /// stable gestalt. The raw scorer can rank it below a larger template that
  /// books more "required" tones, even when that larger reading omits a core
  /// tone of its own. This prefers the complete triad over:
  /// - a seventh-family slash that omits every fifth (e.g. D♭maj7(add13)/F), and
  /// - a plain suspended triad with no seventh (e.g. Fsus4♭13).
  ///
  /// Example: {F, B♭, C, D♭} with F in the bass is B♭m(add9)/F, not
  /// D♭maj7(add13)/F (fifthless) or Fsus4♭13 (no third, no seventh).
  ///
  /// The deficient side is deliberately narrow so that complete seventh chords,
  /// altered-fifth chords (which keep a flat/sharp fifth), six chords, and
  /// dominant/major suspended chords (which keep a seventh) are never demoted.
  /// A score guard keeps a decisively higher-scoring reading in front.
  static int? _preferCompleteTriadOverDeficientReading(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsTriad = fa.isCompleteMajorMinorTriad;
    final bIsTriad = fb.isCompleteMajorMinorTriad;
    if (aIsTriad == bIsTriad) return null;

    final fOther = aIsTriad ? fb : fa;
    if (!fOther.isStructurallyDeficient) return null;

    final triadCandidate = aIsTriad ? a : b;
    final otherCandidate = aIsTriad ? b : a;
    if (triadCandidate.score + 0.55 < otherCandidate.score) return null;

    return aIsTriad ? -1 : 1;
  }

  /// Prefers a dominant7 slash with shell tones and a color-tone bass over a
  /// non-dominant seventh-family slash of similar score.
  ///
  /// When the same notes can be read as either a strongly-voiced dominant7
  /// (major 3rd + flat 7th present, bass is a color extension rather than a
  /// core inversion tone) or as a non-dominant seventh-family slash, the
  /// dominant reading is the one musicians expect.
  ///
  /// Example: {C, D♭, E♭, F, A♭, A} with A♭ bass reads as F7(♯9,♭13)/A♭,
  /// not as C♯maj9♭13/A♭. The F dominant interpretation has shell tones (A +
  /// E♭) and a color-tone bass (A♭ = ♯9 of F), while the C♯ reading requires
  /// an unusual root and treats the same A♭ as a structural fifth inversion.
  static int? _preferDom7ShellSlashOverSeventhFamilySlash(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aIsDom7Slash = fa.isDom7Slash;
    final bIsDom7Slash = fb.isDom7Slash;
    if (aIsDom7Slash == bIsDom7Slash) return null;

    final domIsA = aIsDom7Slash;
    final fDom = domIsA ? fa : fb;
    final fOther = domIsA ? fb : fa;

    if (!fDom.dom7HasShell) return null;
    if (!fDom.bassIsColorTone) return null;
    if (!fOther.isSeventhFamily) return null;
    if (fOther.isDom7) return null;
    if (!fOther.isSlashBass) return null;

    return domIsA ? -1 : 1;
  }

  /// Prefers a reading that names every sounding tone over one that drops a
  /// tone as an unexplained extra.
  ///
  /// Example: {C, D♭, E, G} with G in the bass reads as Cadd♭9/G, not C♯dim/G
  /// (which silently drops the C natural). Runs before [_preferFewerAlterations]
  /// so the note-dropping reading is not rewarded for its apparent simplicity.
  static int? _preferFullyExplainedVoicing(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final aDropsTone = fa.unnamedToneCount > 0;
    final bDropsTone = fb.unnamedToneCount > 0;
    if (aDropsTone == bDropsTone) return null;
    return aDropsTone ? 1 : -1;
  }

  static int? _preferFewerAlterations(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final cmp = fa.extensionTensionCount.compareTo(fb.extensionTensionCount);
    if (cmp == 0) return null;
    return cmp;
  }

  static int? _preferDiatonic(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality tonality,
  ) {
    final da = tonality.scaleDegreeForChord(a.identity);
    final db = tonality.scaleDegreeForChord(b.identity);

    final aOk = da != null;
    final bOk = db != null;

    if (aOk == bOk) return null;
    return bOk ? 1 : -1;
  }

  /// Prefers the selected key's tonic chord in otherwise ambiguous near-ties.
  ///
  /// This lets context resolve relative major/minor sonorities without overriding
  /// stronger structural evidence.
  static int? _preferTonicChord(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality tonality,
  ) {
    final da = tonality.scaleDegreeForChord(a.identity);
    final db = tonality.scaleDegreeForChord(b.identity);
    if (da == null || db == null) return null;

    final aIsI = da == ScaleDegree.one;
    final bIsI = db == ScaleDegree.one;

    if (aIsI == bIsI) return null;

    return bIsI ? 1 : -1;
  }

  /// Prefers the I chord when the bass is the tonic pitch class.
  ///
  /// When multiple diatonic interpretations are possible with tonic in bass,
  /// favor the most stable/expected reading (the I chord itself) over other
  /// scale degrees that happen to have tonic as a chord tone.
  ///
  /// Example in C major with bass = C:
  /// - Prefer "C" (I) over "Am/C" (vi/I) or "Fmaj7/C" (IV/I)
  /// - Tonic bass + tonic chord = strongest harmonic stability
  ///
  /// Only applies when both candidates are diatonic to the key.
  static int? _preferTonicAsI(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality tonality,
  ) {
    final tonic = tonality.tonicPitchClass;

    final da = tonality.scaleDegreeForChord(a.identity);
    final db = tonality.scaleDegreeForChord(b.identity);
    if (da == null || db == null) return null;

    final bassIsTonic = a.identity.bassPc == tonic;
    if (!bassIsTonic) return null;

    final aIsI = da == ScaleDegree.one;
    final bIsI = db == ScaleDegree.one;

    if (aIsI == bIsI) return null;

    return bIsI ? 1 : -1;
  }

  /// Prefers stacked natural extensions (9, 11, 13) over "add" extensions,
  /// then prefers fewer total extensions for simpler interpretations.
  static int? _preferNaturalExtensions(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final natural = fb.extPref.naturalCount.compareTo(fa.extPref.naturalCount);
    if (natural != 0) return natural;

    final add = fa.extPref.addCount.compareTo(fb.extPref.addCount);
    if (add != 0) return add;

    final total = fa.extPref.totalCount.compareTo(fb.extPref.totalCount);
    if (total != 0) return total;

    return null;
  }

  static int? _preferRootPosition(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (fa.isRootPosition == fb.isRootPosition) return null;
    return fb.isRootPosition ? 1 : -1;
  }

  static int? _preferConventionalInversion(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final cmp = fa.bassRoleRank.compareTo(fb.bassRoleRank);
    if (cmp == 0) return null;
    return cmp;
  }

  static int? _prefer7thChords(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (fa.isSeventhFamily == fb.isSeventhFamily) return null;
    return fb.isSeventhFamily ? 1 : -1;
  }

  static int? _preferFewerExtensions(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final cmp = fa.extensionCount.compareTo(fb.extensionCount);
    if (cmp == 0) return null;
    return cmp;
  }

  static int? _avoidSuspended(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    if (fa.isSus == fb.isSus) return null;
    return fa.isSus ? 1 : -1;
  }
}

class _NamedRule {
  final String name;
  final int? Function(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality tonality,
  )
  apply;

  const _NamedRule(this.name, this.apply);
}

/// Cached features extracted from a ChordCandidate for efficient rule evaluation.
///
/// Pre-computes properties like position, quality family, extension types,
/// and dominant7-specific characteristics to avoid repeated calculations
/// during rule application.
class _CandidateFeatures {
  final bool isRootPosition;
  final bool isSixFamily;
  final bool isSeventhFamily;
  final bool isDim7;
  final bool isDimFamily;
  final bool isSus;
  final bool isCompleteMinorSharp11;
  final bool isCompleteMajorMinorTriad;
  final bool isCompleteMajorTriadInversion;
  final bool isMinorSharpFive;
  final bool isIncompleteInvertedSixth;
  final bool isCompleteNinthBassSeventhChord;
  final bool isCompleteMinor7EleventhBassSlash;
  final bool isSecondInversion;
  final bool isAlteredMajor7Sus4;
  final bool isRootDominantSus;
  final bool isRootPositionNaturalAddChord;
  final bool isStructurallyDeficient;

  final bool isDom7;
  final bool isAlteredFifthDom7;
  final bool isFlatFiveDom7;
  final bool isDom7RootPosition;
  final bool isDom7Slash;
  final bool dom7HasShell;
  final bool dom7SlashHasNonBassAlterations;

  final bool isSlashBass;
  final int bassRoleRank;
  final bool bassIsColorTone;

  final int extensionCount;
  final int extensionTensionCount;
  final bool isQuestionableAdd11Slash;
  final ExtensionPreference extPref;
  final bool hasRealExt;
  final int unnamedToneCount;

  const _CandidateFeatures({
    required this.isRootPosition,
    required this.isSixFamily,
    required this.isSeventhFamily,
    required this.isDim7,
    required this.isDimFamily,
    required this.isSus,
    required this.isCompleteMinorSharp11,
    required this.isCompleteMajorMinorTriad,
    required this.isCompleteMajorTriadInversion,
    required this.isMinorSharpFive,
    required this.isIncompleteInvertedSixth,
    required this.isCompleteNinthBassSeventhChord,
    required this.isCompleteMinor7EleventhBassSlash,
    required this.isSecondInversion,
    required this.isAlteredMajor7Sus4,
    required this.isRootDominantSus,
    required this.isRootPositionNaturalAddChord,
    required this.isStructurallyDeficient,
    required this.isDom7,
    required this.isAlteredFifthDom7,
    required this.isFlatFiveDom7,
    required this.isDom7RootPosition,
    required this.isDom7Slash,
    required this.dom7HasShell,
    required this.dom7SlashHasNonBassAlterations,
    required this.isSlashBass,
    required this.bassRoleRank,
    required this.bassIsColorTone,
    required this.extensionCount,
    required this.extensionTensionCount,
    required this.isQuestionableAdd11Slash,
    required this.extPref,
    required this.hasRealExt,
    required this.unnamedToneCount,
  });

  factory _CandidateFeatures.from(ChordCandidate c) {
    final id = c.identity;
    final q = id.quality;

    final rootPos = id.rootPc == id.bassPc;
    final pref = extensionPreference(id.extensions);
    final realExt = (pref.naturalCount + pref.alterationCount) > 0;

    final isDim7 = q == ChordQualityToken.diminished7;
    final isDimFamily = isDim7 || q == ChordQualityToken.halfDiminished7;
    final isSlashBass = !rootPos;
    final bassIsColorTone = isSlashBass ? _bassIsColorTone(id) : false;

    final isDom7 = q == ChordQualityToken.dominant7;
    final isFlatFiveDom7 = q == ChordQualityToken.dominant7Flat5;
    final isAlteredFifthDom7 =
        isFlatFiveDom7 || q == ChordQualityToken.dominant7Sharp5;
    final isDom7RootPosition = isDom7 && rootPos;
    final isDom7Slash = isDom7 && isSlashBass;

    final dom7HasShell = (isDom7 || isAlteredFifthDom7) && _dom7HasShell(id);
    final dom7SlashHasNonBassAlterations =
        isDom7Slash && _dom7SlashHasNonBassAlterations(id);

    final hasMaj3Nat11 = _hasMajorThirdNaturalEleventh(id);

    return _CandidateFeatures(
      isRootPosition: rootPos,
      isSixFamily: q.isSixFamily,
      isSeventhFamily: q.isSeventhFamily,
      isDim7: isDim7,
      isDimFamily: isDimFamily,
      isSus: q.isSus,
      isCompleteMinorSharp11: _isCompleteMinorSharp11(id),
      isCompleteMajorMinorTriad: _isCompleteMajorMinorTriadCore(id),
      isCompleteMajorTriadInversion: _isCompleteMajorTriadInversion(
        id,
        rootPos,
      ),
      isMinorSharpFive: q == ChordQualityToken.minorSharp5,
      isIncompleteInvertedSixth: _isIncompleteInvertedSixth(id, rootPos),
      isCompleteNinthBassSeventhChord: _isCompleteNinthBassSeventhChord(id),
      isCompleteMinor7EleventhBassSlash: _isCompleteMinor7EleventhBassSlash(id),
      isSecondInversion: _bassRoleRank(id) == 2,
      isAlteredMajor7Sus4: _isAlteredMajor7Sus4(id, rootPos),
      isRootDominantSus: _isRootDominantSus(id, rootPos),
      isRootPositionNaturalAddChord:
          rootPos &&
          (q == ChordQualityToken.major ||
              q == ChordQualityToken.minor ||
              q == ChordQualityToken.major6 ||
              q == ChordQualityToken.minor6) &&
          pref.alterationCount == 0 &&
          pref.naturalCount == 0,
      isStructurallyDeficient: _isStructurallyDeficient(id, rootPos),
      isDom7: isDom7,
      isAlteredFifthDom7: isAlteredFifthDom7,
      isFlatFiveDom7: isFlatFiveDom7,
      isDom7RootPosition: isDom7RootPosition,
      isDom7Slash: isDom7Slash,
      dom7HasShell: dom7HasShell,
      dom7SlashHasNonBassAlterations: dom7SlashHasNonBassAlterations,
      isSlashBass: isSlashBass,
      bassRoleRank: _bassRoleRank(id),
      bassIsColorTone: bassIsColorTone,
      extensionCount: id.extensions.length,
      extensionTensionCount: _extensionTensionCount(pref, hasMaj3Nat11),
      isQuestionableAdd11Slash: _isQuestionableAdd11Slash(
        id,
        rootPos,
        hasMaj3Nat11,
      ),
      extPref: pref,
      hasRealExt: realExt,
      unnamedToneCount:
          popCount(id.presentIntervalsMask) - id.toneRolesByInterval.length,
    );
  }

  static bool _isCompleteMinorSharp11(ChordIdentity id) {
    if (id.quality != ChordQualityToken.minor) return false;
    if (id.extensions.length != 1) return false;
    if (!id.extensions.contains(ChordExtension.sharp11)) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.minor3) &&
        roles.contains(ChordToneRole.perfect5) &&
        roles.contains(ChordToneRole.sharp11);
  }

  static bool _isCompleteMajorMinorTriadCore(ChordIdentity id) {
    final q = id.quality;
    if (q != ChordQualityToken.major && q != ChordQualityToken.minor) {
      return false;
    }
    if (id.extensions.any(
      (extension) => _isTriadCoreDestabilizingExtension(extension, quality: q),
    )) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    final hasThird = q == ChordQualityToken.major
        ? roles.contains(ChordToneRole.major3)
        : roles.contains(ChordToneRole.minor3);

    return roles.contains(ChordToneRole.root) &&
        hasThird &&
        roles.contains(ChordToneRole.perfect5);
  }

  static bool _isCompleteMajorTriadInversion(ChordIdentity id, bool rootPos) {
    if (rootPos) return false;
    if (id.quality != ChordQualityToken.major) return false;
    if (_bassRoleRank(id) > 2) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.major3) &&
        roles.contains(ChordToneRole.perfect5);
  }

  static bool _isTriadCoreDestabilizingExtension(
    ChordExtension extension, {
    required ChordQualityToken quality,
  }) {
    if (quality == ChordQualityToken.major &&
        extension == ChordExtension.add11) {
      return true;
    }

    return extension == ChordExtension.flat9 ||
        extension == ChordExtension.sharp9 ||
        extension == ChordExtension.addSharp9 ||
        extension == ChordExtension.sharp11 ||
        extension == ChordExtension.flat13;
  }

  static bool _isIncompleteInvertedSixth(ChordIdentity id, bool rootPos) {
    if (!id.quality.isSixFamily) return false;
    if (rootPos) return false;

    final roles = id.toneRolesByInterval.values;
    return !roles.contains(ChordToneRole.perfect5);
  }

  static bool _isCompleteNinthBassSeventhChord(ChordIdentity id) {
    if (!id.quality.isSeventhFamily) return false;
    if (id.rootPc == id.bassPc) return false;
    if (id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.nine)) {
      return false;
    }

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    if (bassInterval != majorSecondInterval) return false;

    final roles = id.toneRolesByInterval.values;
    final hasThird =
        roles.contains(ChordToneRole.major3) ||
        roles.contains(ChordToneRole.minor3) ||
        roles.contains(ChordToneRole.sus2) ||
        roles.contains(ChordToneRole.sus4);
    final hasSeventh =
        roles.contains(ChordToneRole.flat7) ||
        roles.contains(ChordToneRole.major7);

    return roles.contains(ChordToneRole.root) &&
        hasThird &&
        roles.contains(ChordToneRole.perfect5) &&
        hasSeventh;
  }

  static bool _isCompleteMinor7EleventhBassSlash(ChordIdentity id) {
    if (id.quality != ChordQualityToken.minor7) return false;
    if (id.rootPc == id.bassPc) return false;
    if (id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.add11)) {
      return false;
    }

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    if (bassInterval != perfectFourthInterval) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.minor3) &&
        roles.contains(ChordToneRole.perfect5) &&
        roles.contains(ChordToneRole.flat7);
  }

  static bool _isAlteredMajor7Sus4(ChordIdentity id, bool rootPos) {
    if (!rootPos) return false;
    if (id.quality != ChordQualityToken.major7sus4) return false;
    return id.extensions.contains(ChordExtension.flat13);
  }

  static bool _isRootDominantSus(ChordIdentity id, bool rootPos) {
    if (!rootPos) return false;
    final q = id.quality;
    if (q != ChordQualityToken.dominant7sus2 &&
        q != ChordQualityToken.dominant7sus4) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    final hasSuspension = q == ChordQualityToken.dominant7sus2
        ? roles.contains(ChordToneRole.sus2)
        : roles.contains(ChordToneRole.sus4);
    return hasSuspension && roles.contains(ChordToneRole.flat7);
  }

  /// A reading that omits a core triad tone in a way that makes it weaker than
  /// a competing complete major/minor triad: a plain suspended triad (no third
  /// and no seventh) or a seventh-family slash that omits every fifth.
  static bool _isStructurallyDeficient(ChordIdentity id, bool rootPos) {
    final q = id.quality;

    // Plain suspended triad: no third, and no seventh that would make it a real
    // dominant/major sus. Dominant7sus/major7sus keep their seventh and are not
    // deficient.
    if (q == ChordQualityToken.sus2 || q == ChordQualityToken.sus4) {
      return true;
    }

    // Seventh-family slash that omits every fifth (perfect, diminished, or
    // augmented). Root-position fifthless sevenths are common and intentional,
    // so only the inverted/slash form counts as deficient here.
    if (q.isSeventhFamily && !rootPos) {
      final roles = id.toneRolesByInterval.values;
      final hasFifth =
          roles.contains(ChordToneRole.perfect5) ||
          roles.contains(ChordToneRole.flat5) ||
          roles.contains(ChordToneRole.sharp5);
      if (!hasFifth) return true;
    }

    return false;
  }

  static bool _isQuestionableAdd11Slash(
    ChordIdentity id,
    bool rootPos,
    bool hasMaj3Nat11,
  ) {
    if (rootPos) return false;
    if (id.quality == ChordQualityToken.dominant7 ||
        id.quality == ChordQualityToken.dominant7Flat5 ||
        id.quality == ChordQualityToken.dominant7Sharp5) {
      return false;
    }
    return hasMaj3Nat11;
  }

  static int _extensionTensionCount(
    ExtensionPreference pref,
    bool hasMaj3Nat11,
  ) {
    var count = pref.alterationCount;

    // A natural 11 against a major third is at least as harmonically loaded as
    // an altered color. Do not let the "fewer alterations" tie-breaker prefer
    // this spelling over an otherwise stronger #11/rooted interpretation.
    if (hasMaj3Nat11) count++;

    return count;
  }

  static bool _hasMajorThirdNaturalEleventh(ChordIdentity id) {
    final roles = id.toneRolesByInterval.values;
    final hasMajorThird = roles.contains(ChordToneRole.major3);
    final hasNaturalEleventh =
        id.extensions.contains(ChordExtension.add11) ||
        id.extensions.contains(ChordExtension.eleven);
    return hasMajorThird && hasNaturalEleventh;
  }

  /// Returns true if the voicing contains the dominant7 "shell" (major 3rd + flat 7th).
  /// Shell tones are the minimal chord tones that define dominant function.
  static bool _dom7HasShell(ChordIdentity id) {
    final roles = id.toneRolesByInterval.values;
    final has3 = roles.contains(ChordToneRole.major3);
    final has7 = roles.contains(ChordToneRole.flat7);
    return has3 && has7;
  }

  static bool _dom7SlashHasNonBassAlterations(ChordIdentity id) {
    if (id.quality != ChordQualityToken.dominant7) return false;
    if (id.rootPc == id.bassPc) return false;

    // Identify which extension token corresponds to the bass role (if any),
    // so we can ignore it when deciding if the chord has "extra" alterations.
    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    final bassRole = id.toneRolesByInterval[bassInterval];
    final bassExt = _extensionFromRole(bassRole);

    // Look for any alteration extensions other than the one explained by bass.
    for (final e in id.extensions) {
      if (e == bassExt) continue;
      if (_isAlterationExtension(e)) return true;
    }
    return false;
  }

  static bool _isAlterationExtension(ChordExtension e) {
    return e == ChordExtension.flat9 ||
        e == ChordExtension.sharp9 ||
        e == ChordExtension.sharp11 ||
        e == ChordExtension.flat13;
  }

  static ChordExtension? _extensionFromRole(ChordToneRole? role) {
    // Only roles that map cleanly to ChordExtension tokens.
    return switch (role) {
      ChordToneRole.flat9 => ChordExtension.flat9,
      ChordToneRole.sharp9 => ChordExtension.sharp9,
      ChordToneRole.sharp11 => ChordExtension.sharp11,
      ChordToneRole.flat13 => ChordExtension.flat13,
      ChordToneRole.nine => ChordExtension.nine,
      ChordToneRole.eleven => ChordExtension.eleven,
      ChordToneRole.thirteenth => ChordExtension.thirteen,
      ChordToneRole.add9 => ChordExtension.add9,
      ChordToneRole.addSharp9 => ChordExtension.addSharp9,
      ChordToneRole.splitMinor3 => ChordExtension.addSharp9,
      ChordToneRole.add11 => ChordExtension.add11,
      ChordToneRole.add13 => ChordExtension.add13,
      _ => null,
    };
  }

  /// Returns true when the bass is acting as a color tone (extension/alteration)
  /// rather than a core inversion tone (3rd/5th/7th).
  ///
  /// This distinction helps identify upper-structure voicings vs traditional inversions.
  static bool _bassIsColorTone(ChordIdentity id) {
    final interval = intervalAboveRoot(id.bassPc, id.rootPc);
    final role = id.toneRolesByInterval[interval];

    if (role == null) {
      // Conservative: don't treat unknown bass-role as "color"
      // (prevents over-promoting slash interpretations).
      return false;
    }

    return !_isCoreInversionBassRole(role);
  }

  static bool _isCoreInversionBassRole(ChordToneRole role) {
    return role == ChordToneRole.root ||
        role == ChordToneRole.major3 ||
        role == ChordToneRole.minor3 ||
        role == ChordToneRole.perfect5 ||
        role == ChordToneRole.flat5 ||
        role == ChordToneRole.sharp5 ||
        role == ChordToneRole.sixth ||
        role == ChordToneRole.flat7 ||
        role == ChordToneRole.major7 ||
        role == ChordToneRole.dim7;
  }

  static int _bassRoleRank(ChordIdentity id) {
    final interval = intervalAboveRoot(id.bassPc, id.rootPc);

    // Rank inversions by commonality/stability:
    if (interval == 0) return 0; // Root position
    if (interval == 3 || interval == 4) return 1; // 1st inv (3rd in bass)
    if (interval == 7) return 2; // 2nd inv (5th in bass)
    if (interval == 10 || interval == 11) return 3; // 3rd inv (7th in bass)
    return 4; // Other slash chords
  }
}
