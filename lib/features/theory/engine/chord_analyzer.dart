import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'chord_candidate_ranking.dart';
import 'data/chord_templates.dart';
import 'models/analysis_context.dart';
import 'models/chord_candidate.dart';
import 'models/chord_extension.dart';
import 'models/chord_identity.dart';
import 'models/chord_input.dart';
import 'services/chord_tone_roles.dart';
import 'utils/bit_ops.dart';

@immutable
class ScoreReason {
  final String label;
  final double delta;
  final String? detail;

  const ScoreReason(this.label, this.delta, {this.detail});

  @override
  String toString() {
    final d = delta >= 0
        ? '+${delta.toStringAsFixed(2)}'
        : delta.toStringAsFixed(2);
    return detail == null ? '$label $d' : '$label $d ($detail)';
  }
}

@immutable
class RankedCandidateDebug {
  final ChordCandidate candidate;

  /// High-signal scoring deltas; intended for CLI explanation.
  final List<ScoreReason> scoreReasons;

  /// Why this candidate is ordered where it is relative to the previous one.
  /// (Null for the first result.)
  final RankingDecision? vsPrevious;

  /// The template that generated this candidate (useful for diagnostics).
  final ChordTemplate template;

  const RankedCandidateDebug({
    required this.candidate,
    required this.scoreReasons,
    required this.vsPrevious,
    required this.template,
  });
}

abstract final class ChordAnalyzer {
  static final Map<int, List<ChordCandidate>> _cache =
      <int, List<ChordCandidate>>{};

  static List<ChordCandidate> analyze(
    ChordInput input, {
    required AnalysisContext context,
    int take = 8,
  }) {
    // Cache must include all bias sources (context) because it affects ranking.
    final key = Object.hash(input.cacheKey, context, take);
    final cached = _cache[key];
    if (cached != null) return cached;

    final eval = _evaluateAll(input, context: context, debug: false);

    final result = eval
        .take(take)
        .map((e) => e.candidate)
        .toList(growable: false);

    _cache[key] = result;
    return result;
  }

  static void clearCache() => _cache.clear();

  /// Debug entrypoint for CLI tooling.
  ///
  /// Uses the exact same evaluation + ranking logic as [analyze], but also
  /// returns human-readable score reasons and tie-break explanations.
  static List<RankedCandidateDebug> analyzeDebug(
    ChordInput input, {
    required AnalysisContext context,
    int take = 8,
  }) {
    final eval = _evaluateAll(
      input,
      context: context,
      debug: true,
    ).take(take).toList(growable: false);

    final out = <RankedCandidateDebug>[];
    for (var i = 0; i < eval.length; i++) {
      final current = eval[i];
      final prev = i == 0 ? null : eval[i - 1];

      out.add(
        RankedCandidateDebug(
          candidate: current.candidate,
          template: current.template,
          scoreReasons: current.reasons ?? const <ScoreReason>[],
          vsPrevious: prev == null
              ? null
              : ChordCandidateRanking.explain(
                  prev.candidate,
                  current.candidate,
                  tonality: context.tonality,
                ),
        ),
      );
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Centralized evaluation pipeline (single source of truth)
  // ---------------------------------------------------------------------------

  static List<_Evaluated> _evaluateAll(
    ChordInput input, {
    required AnalysisContext context,
    required bool debug,
  }) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <_Evaluated>[];

    final out = <_Evaluated>[];

    // Assumption: candidate roots must be present in the voicing.
    for (var rootPc = 0; rootPc < 12; rootPc++) {
      if ((pcMask & (1 << rootPc)) == 0) continue;

      final relMask = _rotateMaskToRoot(pcMask, rootPc);
      final bassInterval = _interval(input.bassPc, rootPc);

      for (final tmpl in chordTemplates) {
        final reasons = debug ? <ScoreReason>[] : null;

        final scored = _scoreTemplate(
          relMask: relMask,
          bassInterval: bassInterval,
          template: tmpl,
          reasons: reasons,
        );
        if (scored == null) continue;

        final roles = ChordToneRoles.build(
          quality: tmpl.quality,
          extensions: scored.extensions,
          relMask: relMask,
        );

        final candidate = ChordCandidate(
          identity: ChordIdentity(
            rootPc: rootPc,
            bassPc: input.bassPc,
            quality: tmpl.quality,
            extensions: scored.extensions,
            toneRolesByInterval: roles,
          ),
          score: scored.score,
        );

        out.add(
          _Evaluated(candidate: candidate, template: tmpl, reasons: reasons),
        );
      }
    }

    out.sort(
      (a, b) => ChordCandidateRanking.compare(
        a.candidate,
        b.candidate,
        tonality: context.tonality,
      ),
    );

    return out;
  }

  // ---------------------------------------------------------------------------
  // Scoring (single implementation). Debug is optional "reasons", not a fork.
  // ---------------------------------------------------------------------------

  static _ScoredTemplate? _scoreTemplate({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
    List<ScoreReason>? reasons,
  }) {
    void add(String label, double delta, {String? detail}) {
      reasons?.add(ScoreReason(label, delta, detail: detail));
    }

    // Root interval must be present for this rootPc.
    if ((relMask & 0x1) == 0) return null;

    // Root must always be required for stability.
    final required = template.requiredMask | 0x1;
    final optional = template.optionalMask;
    final penalty = template.penaltyMask;

    final missingRequiredMask = required & ~relMask;
    final presentRequiredMask = required & relMask;
    final presentOptionalMask = optional & relMask;
    final presentPenaltyMask = penalty & relMask;

    final missingCount = popCount(missingRequiredMask);

    // Current rule: allow up to 1 missing required tone.
    if (missingCount > 1) return null;

    final reqCount = popCount(presentRequiredMask);
    final optCount = popCount(presentOptionalMask);
    final penCount = popCount(presentPenaltyMask);

    // Extras: tones that are neither base (required/optional) nor penalty.
    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = popCount(extrasMask);

    // Raw scoring components (single source of truth).
    var raw = 0.0;

    final reqDelta = reqCount * 4.0;
    raw += reqDelta;
    add('required tones', reqDelta, detail: 'count=$reqCount');

    final missDelta = -missingCount * 6.0;
    raw += missDelta;
    add('missing required', missDelta, detail: 'count=$missingCount');

    final optDelta = optCount * 1.5;
    raw += optDelta;
    add('optional tones', optDelta, detail: 'count=$optCount');

    final penDelta = -penCount * 3.0;
    raw += penDelta;
    add('penalty tones', penDelta, detail: 'count=$penCount');

    final extraDelta = -extrasCount * 0.5;
    raw += extraDelta;
    add('extras', extraDelta, detail: 'count=$extrasCount');

    // Bass handling.
    final bassBit = 1 << bassInterval;
    final double bassDelta;
    if ((base & bassBit) != 0) {
      bassDelta = 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      bassDelta = 0.25;
    } else {
      bassDelta = -0.25;
    }
    raw += bassDelta;
    add('bass fit', bassDelta, detail: 'interval=$bassInterval');

    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    // Slight penalty for altered interpretations (keeps "simpler" spellings ahead).
    //
    // Fully diminished seventh chords are symmetric (minor-third stacks). With one
    // extra pitch, the same pitch-class set can be explained either as:
    //   - dim7 rooted on the bass with an "altered" color tone (e.g. Cdim7(b13)), or
    //   - a different dim7 root that reinterprets that same pitch as a "natural/add"
    //     extension, often forcing a slash bass (e.g. D#dim7(add11)/C).
    //
    // Musicians typically expect the bass-root reading for symmetric dim7 chords in
    // ambiguous contexts, so we soften the alteration penalty specifically for dim7
    // to avoid over-favoring slash-root reinterpretations.
    final altPenalty = (template.quality == ChordQualityToken.diminished7)
        ? 0.30
        : 0.60;

    if (_hasAlterations(extensions)) {
      raw -= altPenalty;
      add(
        'alterations penalty',
        -altPenalty,
        detail: template.quality == ChordQualityToken.diminished7
            ? 'dim7 softened'
            : null,
      );
    }

    // Soft normalization by the number of required tones present.
    final denom = reqCount > 0 ? math.sqrt(reqCount.toDouble()) : 1.0;
    final normalized = raw / denom;

    if (reasons != null) {
      add(
        'normalize',
        0.0,
        detail:
            'raw=${raw.toStringAsFixed(2)} denom=${denom.toStringAsFixed(2)} => ${normalized.toStringAsFixed(2)}',
      );
    }

    return _ScoredTemplate(score: normalized, extensions: extensions);
  }

  static bool _hasAlterations(Set<ChordExtension> extensions) {
    return extensions.contains(ChordExtension.flat9) ||
        extensions.contains(ChordExtension.sharp9) ||
        extensions.contains(ChordExtension.sharp11) ||
        extensions.contains(ChordExtension.flat13);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

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
}

class _Evaluated {
  final ChordCandidate candidate;
  final ChordTemplate template;
  final List<ScoreReason>? reasons;

  const _Evaluated({
    required this.candidate,
    required this.template,
    required this.reasons,
  });
}

class _ScoredTemplate {
  final double score;
  final Set<ChordExtension> extensions;

  const _ScoredTemplate({required this.score, required this.extensions});
}

Set<ChordExtension> _extensionsFromExtras(
  int extrasMask, {
  required bool has7,
}) {
  final out = <ChordExtension>{};

  // Alterations.
  if ((extrasMask & (1 << 1)) != 0) out.add(ChordExtension.flat9);
  if ((extrasMask & (1 << 3)) != 0) out.add(ChordExtension.sharp9);
  if ((extrasMask & (1 << 6)) != 0) out.add(ChordExtension.sharp11);
  if ((extrasMask & (1 << 8)) != 0) out.add(ChordExtension.flat13);

  // Natural extensions/add tones.
  final has9 = (extrasMask & (1 << 2)) != 0;
  final has11 = (extrasMask & (1 << 5)) != 0;
  final has13 = (extrasMask & (1 << 9)) != 0;

  if (has9) out.add(has7 ? ChordExtension.nine : ChordExtension.add9);
  if (has11) out.add(has7 ? ChordExtension.eleven : ChordExtension.add11);
  if (has13) out.add(has7 ? ChordExtension.thirteen : ChordExtension.add13);

  return out;
}
