import 'models/chord_candidate.dart';
import 'models/chord_extension.dart';
import 'models/chord_identity.dart';

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

abstract final class ChordCandidateRanking {
  static const double nearTieWindow = 0.20;

  /// Comparator suitable for `List.sort`.
  ///
  /// Returns:
  /// - < 0 if [a] should sort before [b]
  /// - > 0 if [a] should sort after [b]
  /// - 0 only if fully equivalent (should not happen due to deterministic tail)
  static int compare(ChordCandidate a, ChordCandidate b) {
    // Primary: higher score wins.
    final delta = b.score - a.score;

    // Treat near-equal scores as effectively tied so musical tie-breakers
    // apply deterministically.
    if (delta.abs() > nearTieWindow) {
      return delta > 0 ? 1 : -1;
    }

    final fa = _CandidateFeatures.from(a);
    final fb = _CandidateFeatures.from(b);

    for (final rule in _tieBreakerRules) {
      final r = rule.apply(a, b, fa, fb);
      if (r != null && r != 0) return r;
    }

    // Deterministic final tie-breaker: lower rootPc.
    return a.identity.rootPc.compareTo(b.identity.rootPc);
  }

  static RankingDecision explain(ChordCandidate a, ChordCandidate b) {
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
      final r = rule.apply(a, b, fa, fb);
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

  // ---- Rules framework ------------------------------------------------------

  static final List<_NamedRule> _tieBreakerRules = <_NamedRule>[
    _NamedRule(
      'Prefer root-position 6th over inverted 7th (when no extensions)',
      _rule6RootVsSlash7,
    ),
    _NamedRule(
      'Prefer root-position dominant7 in upper-structure cases',
      _ruleDom7RootPosition,
    ),
    _NamedRule('Prefer fewer alterations', _ruleFewerAlterations),
    _NamedRule(
      'Natural extensions over adds, then simpler',
      _ruleNaturalExtensions,
    ),
    _NamedRule('Prefer root position', _ruleRootPosition),
    _NamedRule('Prefer 1st inversion over 2nd inversion', _ruleBass3rdOver5th),
    _NamedRule('Prefer 7th chords over triads', _rule7thOverTriad),
    _NamedRule('Prefer fewer extensions', _ruleFewerExtensions),
    _NamedRule('Avoid suspended chords', _ruleAvoidSus),
  ];

  // Prefer 6-family in root position over slash 7-family when effectively tied,
  // but only when the non-6 chord has no “real” natural/alteration extensions.
  static int? _rule6RootVsSlash7(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    if (fa.isSixFamily == fb.isSixFamily) return null;

    // Identify which side is the 6-family candidate (preserving original logic).
    final aIs6 = fa.isSixFamily;
    final fsix = aIs6 ? fa : fb;
    final fother = aIs6 ? fb : fa;

    // Only privilege 6-family if:
    // - six is root position AND other is NOT root position
    // - other has no "real" extensions/alterations (9/11/13/b9/#11/etc)
    if (fsix.isRootPosition && !fother.isRootPosition && !fother.hasRealExt) {
      // six wins (preserve original return direction)
      return aIs6 ? -1 : 1;
    }

    // Also preserve original behavior where we do not promote 6-family in other cases.
    return null;
  }

  // Prefer root-position dominant7 chords in ambiguous upper-structure situations.
  static int? _ruleDom7RootPosition(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    if (fa.isDom7RootPosition == fb.isDom7RootPosition) return null;
    return fb.isDom7RootPosition ? 1 : -1;
  }

  // Prefer fewer alterations (b9/#11/b13 etc.).
  static int? _ruleFewerAlterations(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    final cmp = fa.extPref.alterationCount.compareTo(
      fb.extPref.alterationCount,
    );
    if (cmp == 0) return null;
    return cmp; // lower alteration count wins
  }

  // Prefer:
  // - more natural extensions (9/11/13),
  // - then fewer add-tones,
  // - then fewer total extension tokens.
  static int? _ruleNaturalExtensions(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    final natural = fb.extPref.naturalCount.compareTo(fa.extPref.naturalCount);
    if (natural != 0) return natural;

    final add = fa.extPref.addCount.compareTo(fb.extPref.addCount);
    if (add != 0) return add;

    final total = fa.extPref.totalCount.compareTo(fb.extPref.totalCount);
    if (total != 0) return total;

    return null;
  }

  // Prefer root position (bass == root).
  static int? _ruleRootPosition(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    if (fa.isRootPosition == fb.isRootPosition) return null;
    return fb.isRootPosition ? 1 : -1;
  }

  // Prefer inversions where bass is the 3rd over those where bass is the 5th.
  // Kept before seventh-family to preserve cases like C6/E beating Am7/E.
  static int? _ruleBass3rdOver5th(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    final cmp = fa.bassRoleRank.compareTo(fb.bassRoleRank);
    if (cmp == 0) return null;
    return cmp; // lower is better
  }

  // Prefer seventh-family over triad-family.
  static int? _rule7thOverTriad(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    if (fa.isSeventhFamily == fb.isSeventhFamily) return null;
    return fb.isSeventhFamily ? 1 : -1;
  }

  // Prefer fewer extensions (simpler explanation).
  static int? _ruleFewerExtensions(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    final cmp = fa.extensionCount.compareTo(fb.extensionCount);
    if (cmp == 0) return null;
    return cmp;
  }

  // Prefer non-sus over sus.
  static int? _ruleAvoidSus(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  ) {
    if (fa.isSus == fb.isSus) return null;
    return fa.isSus ? 1 : -1; // non-sus wins
  }
}

class _NamedRule {
  final String name;
  final int? Function(
    ChordCandidate a,
    ChordCandidate b,
    _CandidateFeatures fa,
    _CandidateFeatures fb,
  )
  apply;

  const _NamedRule(this.name, this.apply);
}

class _CandidateFeatures {
  final bool isRootPosition;
  final bool isSixFamily;
  final bool isSeventhFamily;
  final bool isSus;

  final bool isDom7RootPosition;

  final int bassRoleRank;
  final int extensionCount;

  final ExtensionPreference extPref;
  final bool hasRealExt;

  const _CandidateFeatures({
    required this.isRootPosition,
    required this.isSixFamily,
    required this.isSeventhFamily,
    required this.isSus,
    required this.isDom7RootPosition,
    required this.bassRoleRank,
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

    return _CandidateFeatures(
      isRootPosition: rootPos,
      isSixFamily: q.isSixFamily,
      isSeventhFamily: q.isSeventhFamily,
      isSus: q.isSus,
      isDom7RootPosition: q == ChordQualityToken.dominant7 && rootPos,
      bassRoleRank: _bassRoleRank(id),
      extensionCount: id.extensions.length,
      extPref: pref,
      hasRealExt: realExt,
    );
  }

  static int _bassRoleRank(ChordIdentity id) {
    // Lower is better.
    final interval = (id.bassPc - id.rootPc) % 12;

    // Root position already handled earlier, but keep it best anyway.
    if (interval == 0) return 0;

    // Thirds (major/minor)
    if (interval == 3 || interval == 4) return 1;

    // Fifth
    if (interval == 7) return 2;

    // Sevenths
    if (interval == 10 || interval == 11) return 3;

    // Seconds / fourths / sixths etc.
    return 4;
  }
}
