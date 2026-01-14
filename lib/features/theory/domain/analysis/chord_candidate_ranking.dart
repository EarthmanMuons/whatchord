import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';

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
    // Primary: higher score wins.
    final delta = b.score - a.score;

    final fa = _CandidateFeatures.from(a);
    final fb = _CandidateFeatures.from(b);

    // Special case: altered dominant7 vs dim7 runs even outside near-tie window
    // because it resolves a fundamental structural ambiguity (e.g., C7#9 vs Eb°7)
    // where the dominant reading is strongly preferred when shell tones are present.
    final hard = _preferAlteredDom7(a, b, fa, fb, tonality);
    if (hard != null && hard != 0) return hard;

    // Normal scoring gate.
    if (delta.abs() > nearTieWindow) {
      return delta > 0 ? 1 : -1;
    }

    for (final rule in _tieBreakerRules) {
      final r = rule.apply(a, b, fa, fb, tonality);
      if (r != null && r != 0) return r;
    }

    // Deterministic final tie-breaker: lower rootPc.
    return a.identity.rootPc.compareTo(b.identity.rootPc);
  }

  /// Same as [compare], but returns detailed information about which rule decided.
  /// Useful for debugging and explaining ranking decisions to users.
  static RankingDecision explain(
    ChordCandidate a,
    ChordCandidate b, {
    required Tonality tonality,
  }) {
    final delta = b.score - a.score;

    if (delta.abs() > nearTieWindow) {
      final result = delta > 0 ? 1 : -1;
      return RankingDecision(
        result: result,
        decidedByRule: 'Score (outside near-tie window)',
        scoreDelta: delta,
      );
    }

    final fa = _CandidateFeatures.from(a);
    final fb = _CandidateFeatures.from(b);

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
      decidedByRule: 'Deterministic fallback: rootPc',
      scoreDelta: delta,
    );
  }

  // ---- Tie-breaker rules (applied in priority order) --------------------
  // These rules resolve near-ties by encoding musical preferences:
  // - Structural clarity (root position, shell tones)
  // - Functional harmony (diatonic, dominant alterations)
  // - Simplicity (fewer extensions/alterations, avoid suspensions)

  static final List<_NamedRule> _tieBreakerRules = <_NamedRule>[
    _NamedRule('Prefer root-position 6th over inverted 7th', _prefer6thInRoot),
    _NamedRule('Prefer altered dominant7 over dim7 slash', _preferAlteredDom7),
    _NamedRule(
      'Prefer upper-structure dominant7 slash',
      _preferUpperStructureDom7,
    ),
    _NamedRule('Prefer root-position diminished7', _preferDim7InRoot),
    _NamedRule('Prefer dominant7 over dim7 slash', _preferDom7Shell),
    _NamedRule('Prefer fewer alterations', _preferFewerAlterations),
    _NamedRule('Prefer diatonic chords', _preferDiatonic),
    _NamedRule('Prefer I chord when bass is tonic', _preferTonicAsI),
    _NamedRule(
      'Prefer natural extensions over adds, then fewer total',
      _preferNaturalExtensions,
    ),
    _NamedRule('Prefer root position', _preferRootPosition),
    _NamedRule('Prefer 1st inversion over 2nd inversion', _prefer1stInversion),
    _NamedRule('Prefer 7th chords over triads', _prefer7thChords),
    _NamedRule('Prefer fewer extensions', _preferFewerExtensions),
    _NamedRule('Avoid suspended chords', _avoidSuspended),
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

    if (fsix.isRootPosition && !fother.isRootPosition && !fother.hasRealExt) {
      return aIs6 ? -1 : 1;
    }

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

  static int? _preferFewerAlterations(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
    Tonality _,
  ) {
    final cmp = fa.extPref.alterationCount.compareTo(
      fb.extPref.alterationCount,
    );
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

  static int? _prefer1stInversion(
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

  final bool isDom7;
  final bool isDom7RootPosition;
  final bool isDom7Slash;
  final bool dom7HasShell;
  final bool dom7SlashHasNonBassAlterations;

  final bool isSlashBass;
  final int bassRoleRank;
  final bool bassIsColorTone;

  final int extensionCount;
  final ExtensionPreference extPref;
  final bool hasRealExt;

  const _CandidateFeatures({
    required this.isRootPosition,
    required this.isSixFamily,
    required this.isSeventhFamily,
    required this.isDim7,
    required this.isDimFamily,
    required this.isSus,
    required this.isDom7,
    required this.isDom7RootPosition,
    required this.isDom7Slash,
    required this.dom7HasShell,
    required this.dom7SlashHasNonBassAlterations,
    required this.isSlashBass,
    required this.bassRoleRank,
    required this.bassIsColorTone,
    required this.extensionCount,
    required this.extPref,
    required this.hasRealExt,
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
    final isDom7RootPosition = isDom7 && rootPos;
    final isDom7Slash = isDom7 && isSlashBass;

    final dom7HasShell = isDom7 && _dom7HasShell(id);
    final dom7SlashHasNonBassAlterations =
        isDom7Slash && _dom7SlashHasNonBassAlterations(id);

    return _CandidateFeatures(
      isRootPosition: rootPos,
      isSixFamily: q.isSixFamily,
      isSeventhFamily: q.isSeventhFamily,
      isDim7: isDim7,
      isDimFamily: isDimFamily,
      isSus: q.isSus,
      isDom7: isDom7,
      isDom7RootPosition: isDom7RootPosition,
      isDom7Slash: isDom7Slash,
      dom7HasShell: dom7HasShell,
      dom7SlashHasNonBassAlterations: dom7SlashHasNonBassAlterations,
      isSlashBass: isSlashBass,
      bassRoleRank: _bassRoleRank(id),
      bassIsColorTone: bassIsColorTone,
      extensionCount: id.extensions.length,
      extPref: pref,
      hasRealExt: realExt,
    );
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
    final bassInterval = _interval(id.bassPc, id.rootPc);
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
    final interval = _interval(id.bassPc, id.rootPc);
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

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  static int _bassRoleRank(ChordIdentity id) {
    final interval = _interval(id.bassPc, id.rootPc);

    // Rank inversions by commonality/stability:
    if (interval == 0) return 0; // Root position
    if (interval == 3 || interval == 4) return 1; // 1st inv (3rd in bass)
    if (interval == 7) return 2; // 2nd inv (5th in bass)
    if (interval == 10 || interval == 11) return 3; // 3rd inv (7th in bass)
    return 4; // Other slash chords
  }
}
