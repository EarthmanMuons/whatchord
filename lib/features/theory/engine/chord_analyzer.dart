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

    // Sort by score, then apply deterministic musical tie-breakers to reduce
    // "weird but equivalent" picks (e.g. choosing Gsus4add13/C over Cadd9).
    candidates.sort(_compareCandidates);

    return candidates.take(8).toList(growable: false);
  }

  /// Debug entrypoint:
  /// - Returns the ranked candidates along with score breakdown and masks.
  /// - Mirrors [analyze] ranking exactly (including normalization).
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

        // IMPORTANT: use the same score basis as production (normalized).
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
            normalizationDenom: scored.normalizationDenom,
            rawScore: scored.rawScore,
            normalizedScore: scored.normalizedScore,
          ),
        );
      }
    }

    // Sort using the same tie-breakers as production.
    out.sort((a, b) => _compareCandidates(a.candidate, b.candidate));

    return out.take(take).toList(growable: false);
  }

  static int _compareCandidates(ChordCandidate a, ChordCandidate b) {
    // 1) Primary: highest score wins.
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;

    // 2) Prefer root position when tied (bass == root).
    final aRootPos = a.identity.rootPc == a.identity.bassPc;
    final bRootPos = b.identity.rootPc == b.identity.bassPc;
    if (aRootPos != bRootPos) return bRootPos ? 1 : -1;

    // 3) Prefer fewer extensions (simpler explanation) when tied.
    final e = a.identity.extensions.length.compareTo(
      b.identity.extensions.length,
    );
    if (e != 0) return e;

    // 4) Prefer non-sus over sus when tied (common default expectation).
    final aSus = _isSus(a.identity.quality);
    final bSus = _isSus(b.identity.quality);
    if (aSus != bSus) return aSus ? 1 : -1;

    // 5) Deterministic final tie-breaker: lower rootPc.
    return a.identity.rootPc.compareTo(b.identity.rootPc);
  }

  static bool _isSus(ChordQualityToken q) =>
      q == ChordQualityToken.sus2 || q == ChordQualityToken.sus4;

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  /// Rotates an absolute pitch-class mask into root-relative intervals.
  ///
  /// Example: if rootPc=4 (E), then absolute pitch class 4 becomes interval 0,
  /// pitch class 7 (G) becomes interval 3, etc.
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

    // Force root to be required for stability in Phase 2/3.
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

    // Extras are tones that are neither base (required/optional) nor penalty.
    // We'll interpret many of these as extensions (9/11/13) rather than "noise".
    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = popCount(extrasMask);

    // If missing too many required tones, treat as too weak for now.
    // We can relax later for omissions and shell voicings.
    if (missingCount > 1) return null;

    // Scoring model (tuned for stability, not strict probability):
    // - Missing required: heavy penalty.
    // - Required present: strong evidence.
    // - Optional present: mild bonus.
    // - Penalty present: moderate penalty.
    // - Extras: mild penalty (offset by interpreting them as extensions).
    var score = 0.0;
    score += reqCount * 4.0;
    score -= missingCount * 6.0;
    score += optCount * 1.5;
    score -= penCount * 3.0;
    score -= extrasCount * 0.5;

    // Bass handling:
    // - Prefer bass as a chord tone.
    // - Slightly positive if bass is an extension tone (slash chords are real).
    // - Slightly negative if bass is unrelated to this root/template.
    final bassBit = 1 << bassInterval;
    if ((base & bassBit) != 0) {
      score += 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      score += 0.25;
    } else {
      score -= 0.25;
    }

    // Strong preference for root position when bass == root.
    // This helps resolve ambiguous pitch-class sets toward the musically expected root.
    if (bassInterval == 0) {
      score += 1.25; // tune: ~1.0–1.5
    }

    // Compute extensions from extras so we can apply additional heuristics.
    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    // Complexity heuristic: penalize altered interpretations slightly.
    // This helps avoid cases like Em7(b5)(b13)/C when C9 fits cleanly.
    if (_hasAlterations(extensions)) {
      score -= 0.60; // tune: ~0.4–0.9
    }

    // Normalize so scores are comparable across templates.
    // IMPORTANT: normalize by required-count only. Optional tones are optional and
    // should not dilute a correct interpretation that legitimately includes them.
    final denom = math.max(1, popCount(required));
    final normalized = score / denom;

    return _ScoredTemplate(score: normalized, extensions: extensions);
  }

  static _ScoredTemplateDebug? _scoreTemplateDebug({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
  }) {
    // Ensure root exists (interval 0) for this candidate root.
    if ((relMask & 0x1) == 0) return null;

    // Force root to be required for stability in Phase 2/3.
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

    // Score components (mirror _scoreTemplate exactly)
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

    var scoreRootPos = 0.0;
    if (bassInterval == 0) {
      scoreRootPos = 1.25;
    }

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

    final denom = math.max(1, popCount(required));
    final normalized = rawScore / denom;

    return _ScoredTemplateDebug(
      score: normalized, // IMPORTANT: matches production score basis.
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
  final int normalizationDenom;

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

  // Interval semitones relative to root:
  // 1=b9, 2=9, 3=#9, 5=11, 6=#11, 8=b13, 9=13
  if ((extrasMask & (1 << 1)) != 0) out.add(ChordExtension.flat9);
  if ((extrasMask & (1 << 3)) != 0) out.add(ChordExtension.sharp9);
  if ((extrasMask & (1 << 6)) != 0) out.add(ChordExtension.sharp11);
  if ((extrasMask & (1 << 8)) != 0) out.add(ChordExtension.flat13);

  final has9 = (extrasMask & (1 << 2)) != 0;
  final has11 = (extrasMask & (1 << 5)) != 0;
  final has13 = (extrasMask & (1 << 9)) != 0;

  // Distinguish add-tones vs true extensions based on whether a 7th is present.
  if (has9) out.add(has7 ? ChordExtension.nine : ChordExtension.add9);
  if (has11) out.add(has7 ? ChordExtension.eleven : ChordExtension.add11);
  if (has13) out.add(has7 ? ChordExtension.thirteen : ChordExtension.add13);

  return out;
}

double _tonalityBonus(int rootPc, Tonality tonality) {
  final isDiatonic = tonality.containsPitchClass(rootPc);
  return isDiatonic ? 0.10 : -0.02;
}
