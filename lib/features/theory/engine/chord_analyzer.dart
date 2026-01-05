import 'dart:math' as math;

import '../models/tonality.dart';
import 'data/chord_templates.dart';
import 'models/analysis_context.dart';
import 'models/chord_candidate.dart';
import 'models/chord_candidate_debug.dart';
import 'models/chord_extension.dart';
import 'models/chord_identity.dart';
import 'models/chord_input.dart';
import 'utils/bit_ops.dart';

abstract final class ChordAnalyzer {
  static final Map<int, List<ChordCandidate>> _cache =
      <int, List<ChordCandidate>>{};

  static List<ChordCandidate> analyze(
    ChordInput input, {
    AnalysisContext? context,
  }) {
    // Cache must incorporate all bias sources (context) because it affects ranking.
    final key = Object.hash(input.cacheKey, context);
    final cached = _cache[key];
    if (cached != null) return cached;

    final result = _analyzeUncached(input, context: context);

    _cache[key] = result;
    return result;
  }

  static void clearCache() => _cache.clear();

  static List<ChordCandidate> _analyzeUncached(
    ChordInput input, {
    AnalysisContext? context,
  }) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <ChordCandidate>[];

    final candidates = <ChordCandidate>[];

    // Phase 2/3 assumption: root pitch class is present in the voicing.
    // (We can relax later for missing-root shells, e.g. 3-7 voicings.)
    for (var rootPc = 0; rootPc < 12; rootPc++) {
      if ((pcMask & (1 << rootPc)) == 0) continue;

      final relMask = _rotateMaskToRoot(pcMask, rootPc);
      final bassInterval = _interval(input.bassPc, rootPc);

      for (final tmpl in chordTemplates) {
        final scored = _scoreTemplate(
          relMask: relMask,
          bassInterval: bassInterval,
          template: tmpl,
        );

        if (scored == null) continue;

        // Tonality prior: small bias only (never dominates note-evidence).
        final baseScore = scored.score;
        final score = context == null
            ? baseScore
            : baseScore + _tonalityBonus(rootPc, context.tonality);

        candidates.add(
          ChordCandidate(
            identity: ChordIdentity(
              rootPc: rootPc,
              bassPc: input.bassPc,
              quality: tmpl.quality,
              extensions: scored.extensions,
            ),
            score: score,
          ),
        );
      }
    }

    // Sort by score, then apply deterministic musical tie-breakers.
    candidates.sort(_compareCandidates);

    return candidates.take(8).toList(growable: false);
  }

  /// Debug entrypoint:
  /// - Returns ranked candidates with score breakdown and masks.
  /// - Mirrors [analyze] ranking exactly.
  static List<ChordCandidateDebug> analyzeDebug(
    ChordInput input, {
    AnalysisContext? context,
    int take = 8,
  }) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <ChordCandidateDebug>[];

    final out = <ChordCandidateDebug>[];

    for (var rootPc = 0; rootPc < 12; rootPc++) {
      if ((pcMask & (1 << rootPc)) == 0) continue;

      final relMask = _rotateMaskToRoot(pcMask, rootPc);
      final bassInterval = _interval(input.bassPc, rootPc);

      for (final tmpl in chordTemplates) {
        final scored = _scoreTemplateDebug(
          relMask: relMask,
          bassInterval: bassInterval,
          template: tmpl,
        );
        if (scored == null) continue;

        final baseScore = scored.score; // normalized (same as analyze)
        final score = context == null
            ? baseScore
            : baseScore + _tonalityBonus(rootPc, context.tonality);

        final candidate = ChordCandidate(
          identity: ChordIdentity(
            rootPc: rootPc,
            bassPc: input.bassPc,
            quality: tmpl.quality,
            extensions: scored.extensions,
          ),
          score: score,
        );

        out.add(
          ChordCandidateDebug(
            candidate: candidate,
            template: tmpl,
            relMask: relMask,
            requiredMask: scored.requiredMask,
            optionalMask: scored.optionalMask,
            penaltyMask: scored.penaltyMask,
            extrasMask: scored.extrasMask,
            missingRequiredMask: scored.missingRequiredMask,
            presentRequiredMask: scored.presentRequiredMask,
            presentOptionalMask: scored.presentOptionalMask,
            presentPenaltyMask: scored.presentPenaltyMask,
            missingCount: scored.missingCount,
            reqCount: scored.reqCount,
            optCount: scored.optCount,
            penCount: scored.penCount,
            extrasCount: scored.extrasCount,
            scoreRequired: scored.scoreRequired,
            scoreMissing: scored.scoreMissing,
            scoreOptional: scored.scoreOptional,
            scorePenalty: scored.scorePenalty,
            scoreExtras: scored.scoreExtras,
            scoreBass: scored.scoreBass,
            scoreRootPos: scored.scoreRootPos,
            scoreAlterations: scored.scoreAlterations,
            rawScore: scored.rawScore,
            normalizedScore: scored.normalizedScore,
            normalizationDenom: scored.normalizationDenom,
          ),
        );
      }
    }

    out.sort((a, b) => _compareCandidates(a.candidate, b.candidate));
    return out.take(take).toList(growable: false);
  }

  static const double _nearTieWindow = 0.20;

  static int _compareCandidates(ChordCandidate a, ChordCandidate b) {
    // 1) Primary: higher score wins.
    final delta = b.score - a.score;

    // Treat near-equal scores as effectively tied, so we can apply musical
    // preferences deterministically. This stabilizes cases like:
    // - C E G D where Cadd9 vs Gsus/C are very close numerically
    // - C E G Bb Db where C7(b9) vs dim7/upper-structure are very close
    if (delta.abs() > _nearTieWindow) {
      return delta > 0 ? 1 : -1;
    }

    // 2) Prefer seventh-family over triad-family when effectively tied.
    final a7 = a.identity.quality.isSeventhFamily;
    final b7 = b.identity.quality.isSeventhFamily;
    if (a7 != b7) return b7 ? 1 : -1;

    // 3) Prefer root position when effectively tied (bass == root).
    final aRootPos = a.identity.rootPc == a.identity.bassPc;
    final bRootPos = b.identity.rootPc == b.identity.bassPc;
    if (aRootPos != bRootPos) return bRootPos ? 1 : -1;

    // 4) Prefer fewer extensions (simpler explanation).
    final e = a.identity.extensions.length.compareTo(
      b.identity.extensions.length,
    );
    if (e != 0) return e;

    // 5) Prefer non-sus over sus.
    final aSus = _isSus(a.identity.quality);
    final bSus = _isSus(b.identity.quality);
    if (aSus != bSus) return aSus ? 1 : -1;

    // 6) Deterministic final tie-breaker: lower rootPc.
    return a.identity.rootPc.compareTo(b.identity.rootPc);
  }

  static bool _isSus(ChordQualityToken q) =>
      q == ChordQualityToken.sus2 || q == ChordQualityToken.sus4;

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  static int _rotateMaskToRoot(int pcMask, int rootPc) {
    var rel = 0;
    for (var pc = 0; pc < 12; pc++) {
      if ((pcMask & (1 << pc)) == 0) continue;
      final interval = _interval(pc, rootPc);
      rel |= (1 << interval);
    }
    return rel;
  }

  static _ScoredTemplate? _scoreTemplate({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
  }) {
    // Ensure root exists (interval 0) for this candidate root.
    if ((relMask & 0x1) == 0) return null;

    // Force root to be required for stability.
    final required = template.requiredMask | 0x1;
    final optional = template.optionalMask;
    final penalty = template.penaltyMask;

    final missingRequired = required & ~relMask;
    final presentRequired = required & relMask;
    final presentOptional = optional & relMask;
    final presentPenalty = penalty & relMask;

    final missingCount = popCount(missingRequired);
    final reqCount = popCount(presentRequired);
    final optCount = popCount(presentOptional);
    final penCount = popCount(presentPenalty);

    // Extras: tones that are neither base (required/optional) nor penalty.
    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = popCount(extrasMask);

    if (missingCount > 1) return null;

    // Scoring model
    var score = 0.0;
    score += reqCount * 4.0;
    score -= missingCount * 6.0;
    score += optCount * 1.5;
    score -= penCount * 3.0;
    score -= extrasCount * 0.5;

    // Bass handling
    final bassBit = 1 << bassInterval;
    if ((base & bassBit) != 0) {
      score += 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      score += 0.25;
    } else {
      score -= 0.25;
    }

    // No numeric root-position bonus; root position is handled in tie-breakers.

    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    // Slight penalty for altered interpretations
    if (_hasAlterations(extensions)) {
      score -= 0.60;
    }

    // Soft-normalize by required tones present.
    final denom = reqCount > 0 ? math.sqrt(reqCount.toDouble()) : 1.0;
    final normalized = score / denom;

    return _ScoredTemplate(score: normalized, extensions: extensions);
  }

  static _ScoredTemplateDebug? _scoreTemplateDebug({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
  }) {
    if ((relMask & 0x1) == 0) return null;

    final required = template.requiredMask | 0x1;
    final optional = template.optionalMask;
    final penalty = template.penaltyMask;

    final missingRequired = required & ~relMask;
    final presentRequired = required & relMask;
    final presentOptional = optional & relMask;
    final presentPenalty = penalty & relMask;

    final missingCount = popCount(missingRequired);
    final reqCount = popCount(presentRequired);
    final optCount = popCount(presentOptional);
    final penCount = popCount(presentPenalty);

    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = popCount(extrasMask);

    if (missingCount > 1) return null;

    final scoreRequired = reqCount * 4.0;
    final scoreMissing = -missingCount * 6.0;
    final scoreOptional = optCount * 1.5;
    final scorePenalty = -penCount * 3.0;
    final scoreExtras = -extrasCount * 0.5;

    var scoreBass = 0.0;
    final bassBit = 1 << bassInterval;
    if ((base & bassBit) != 0) {
      scoreBass = 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      scoreBass = 0.25;
    } else {
      scoreBass = -0.25;
    }

    // Root-position preference is intentionally not part of numeric score.
    const scoreRootPos = 0.0;

    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    var scoreAlterations = 0.0;
    if (_hasAlterations(extensions)) {
      scoreAlterations = -0.60;
    }

    final rawScore =
        scoreRequired +
        scoreMissing +
        scoreOptional +
        scorePenalty +
        scoreExtras +
        scoreBass +
        scoreRootPos +
        scoreAlterations;

    final denom = reqCount > 0 ? math.sqrt(reqCount.toDouble()) : 1.0;
    final normalized = rawScore / denom;

    return _ScoredTemplateDebug(
      score: normalized,
      extensions: extensions,
      rawScore: rawScore,
      normalizedScore: normalized,
      normalizationDenom: denom,
      requiredMask: required,
      optionalMask: optional,
      penaltyMask: penalty,
      extrasMask: extrasMask,
      missingRequiredMask: missingRequired,
      presentRequiredMask: presentRequired,
      presentOptionalMask: presentOptional,
      presentPenaltyMask: presentPenalty,
      missingCount: missingCount,
      reqCount: reqCount,
      optCount: optCount,
      penCount: penCount,
      extrasCount: extrasCount,
      scoreRequired: scoreRequired,
      scoreMissing: scoreMissing,
      scoreOptional: scoreOptional,
      scorePenalty: scorePenalty,
      scoreExtras: scoreExtras,
      scoreBass: scoreBass,
      scoreRootPos: scoreRootPos,
      scoreAlterations: scoreAlterations,
    );
  }

  static bool _hasAlterations(Set<ChordExtension> extensions) {
    return extensions.contains(ChordExtension.flat9) ||
        extensions.contains(ChordExtension.sharp9) ||
        extensions.contains(ChordExtension.sharp11) ||
        extensions.contains(ChordExtension.flat13);
  }
}

class _ScoredTemplate {
  final double score;
  final Set<ChordExtension> extensions;
  const _ScoredTemplate({required this.score, required this.extensions});
}

class _ScoredTemplateDebug extends _ScoredTemplate {
  final double rawScore;
  final double normalizedScore;
  final double normalizationDenom;

  final int requiredMask;
  final int optionalMask;
  final int penaltyMask;
  final int extrasMask;

  final int missingRequiredMask;
  final int presentRequiredMask;
  final int presentOptionalMask;
  final int presentPenaltyMask;

  final int missingCount;
  final int reqCount;
  final int optCount;
  final int penCount;
  final int extrasCount;

  final double scoreRequired;
  final double scoreMissing;
  final double scoreOptional;
  final double scorePenalty;
  final double scoreExtras;
  final double scoreBass;
  final double scoreRootPos;
  final double scoreAlterations;

  const _ScoredTemplateDebug({
    required super.score,
    required super.extensions,
    required this.rawScore,
    required this.normalizedScore,
    required this.normalizationDenom,
    required this.requiredMask,
    required this.optionalMask,
    required this.penaltyMask,
    required this.extrasMask,
    required this.missingRequiredMask,
    required this.presentRequiredMask,
    required this.presentOptionalMask,
    required this.presentPenaltyMask,
    required this.missingCount,
    required this.reqCount,
    required this.optCount,
    required this.penCount,
    required this.extrasCount,
    required this.scoreRequired,
    required this.scoreMissing,
    required this.scoreOptional,
    required this.scorePenalty,
    required this.scoreExtras,
    required this.scoreBass,
    required this.scoreRootPos,
    required this.scoreAlterations,
  });
}

Set<ChordExtension> _extensionsFromExtras(
  int extrasMask, {
  required bool has7,
}) {
  final out = <ChordExtension>{};

  // Alterations
  if ((extrasMask & (1 << 1)) != 0) out.add(ChordExtension.flat9);
  if ((extrasMask & (1 << 3)) != 0) out.add(ChordExtension.sharp9);
  if ((extrasMask & (1 << 6)) != 0) out.add(ChordExtension.sharp11);
  if ((extrasMask & (1 << 8)) != 0) out.add(ChordExtension.flat13);

  // Natural extensions/add tones
  final has9 = (extrasMask & (1 << 2)) != 0;
  final has11 = (extrasMask & (1 << 5)) != 0;
  final has13 = (extrasMask & (1 << 9)) != 0;

  if (has9) out.add(has7 ? ChordExtension.nine : ChordExtension.add9);
  if (has11) out.add(has7 ? ChordExtension.eleven : ChordExtension.add11);
  if (has13) out.add(has7 ? ChordExtension.thirteen : ChordExtension.add13);

  return out;
}

double _tonalityBonus(int rootPc, Tonality tonality) {
  final isDiatonic = tonality.containsPitchClass(rootPc);
  return isDiatonic ? 0.10 : -0.02;
}
