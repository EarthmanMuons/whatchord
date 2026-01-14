import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../models/analysis_context.dart';
import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_input.dart';
import '../services/chord_tone_roles.dart';
import 'chord_candidate_ranking.dart';
import 'data/chord_templates.dart';

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

/// Analyzes pitch-class sets to generate and rank chord interpretations.
///
/// Core pipeline:
/// 1. Generate candidates from all possible roots present in the voicing
/// 2. Score each candidate against chord templates using fit metrics
/// 3. Rank candidates using score + tie-breaking heuristics
/// 4. Cache results keyed by input + context
///
/// Scoring philosophy:
/// - Reward structural completeness (required tones present)
/// - Penalize missing tones, penalty tones, and unexplained extras
/// - Normalize by chord complexity to allow fair comparison
abstract final class ChordAnalyzer {
  static final Map<int, List<ChordCandidate>> _cache =
      <int, List<ChordCandidate>>{};

  static List<ChordCandidate> analyze(
    ChordInput input, {
    required AnalysisContext context,
    int take = 8,
  }) {
    // Cache includes context because tonality affects ranking tie-breakers
    // (e.g., diatonic preference, tonic-as-I rule).
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

  static List<_Evaluated> _evaluateAll(
    ChordInput input, {
    required AnalysisContext context,
    required bool debug,
  }) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <_Evaluated>[];

    final out = <_Evaluated>[];

    // Assumption: chord roots must be spelled on notes actually present in the voicing.
    // This prevents generating "ghost root" interpretations.
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
          rootPc: rootPc,
          inputNoteCount: input.noteCount,
          context: context,
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

  // ---- Template scoring: fit voicing to chord structure -----------------
  //
  // Weights are tuned empirically to balance:
  // - Structural integrity (required > optional)
  // - Penalty for ambiguity (missing tones, extras)
  // - Bass role appropriateness

  static _ScoredTemplate? _scoreTemplate({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
    required int rootPc,
    required int inputNoteCount,
    required AnalysisContext context,
    List<ScoreReason>? reasons,
  }) {
    void add(String label, double delta, {String? detail}) {
      reasons?.add(ScoreReason(label, delta, detail: detail));
    }

    if ((relMask & 0x1) == 0) return null;

    // Root must always be required for stability.
    final required = template.requiredMask | 0x1;
    final optional = template.optionalMask;
    final penalty = template.penaltyMask;

    final missingRequiredMask = required & ~relMask;
    final presentRequiredMask = required & relMask;
    final presentOptionalMask = optional & relMask;
    final presentPenaltyMask = penalty & relMask;

    final missingCount = _popCount(missingRequiredMask);

    // Allow up to 1 missing required tone for sparse voicings.
    // Example: dominant7 without the 5th (shell voicing) is still valid.
    // More than 1 missing tone suggests wrong template entirely.
    if (missingCount > 1) return null;

    final reqCount = _popCount(presentRequiredMask);
    final optCount = _popCount(presentOptionalMask);
    final penCount = _popCount(presentPenaltyMask);

    // Extras: tones that are neither base (required/optional) nor penalty.
    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = _popCount(extrasMask);

    // Extract extensions first so bass scoring can recognize extension-bass as legitimate.
    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    // Raw scoring components (single source of truth).
    var raw = 0.0;

    // Scoring weights (tuned empirically):
    // - Required tones: +4.0 each (structural foundation)
    // - Missing required: -6.0 each (dealbreaker for incomplete chords)
    // - Optional tones: +1.5 each (adds color without being essential)
    // - Penalty tones: -3.0 each (contradicts chord quality)
    // - Extras: -0.5 each (unexplained complexity)

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

    // Bass scoring priority (reflects common voicing practices):
    // 1. Bass is a base tone (required/optional): +1.0 (inversions/root position)
    // 2. Bass is an extension on 7th-family chord: +0.75 (upper-structure voicing)
    // 3. Bass is an extension on triad: +0.25 (add-chord slash notation)
    // 4. Bass is missing from template: -0.25 (arbitrary slash bass)
    final bassBit = 1 << bassInterval;
    final double bassDelta;
    if ((base & bassBit) != 0) {
      bassDelta = 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      // If the bass is being interpreted as an extension/alteration tone on a
      // seventh-family chord, treat it as a legitimate "color bass" rather than
      // an arbitrary extra tone.
      final isColorBass =
          template.quality.isSeventhFamily && extensions.isNotEmpty;
      bassDelta = isColorBass ? 0.75 : 0.25;
    } else {
      bassDelta = -0.25;
    }
    raw += bassDelta;
    add('bass fit', bassDelta, detail: 'interval=$bassInterval');

    // Alteration penalty: prefer simpler spellings over altered interpretations.
    //
    // Special case: Fully diminished seventh chords are symmetric (minor-third stacks).
    // With one extra pitch, the same pitch-class set can be explained either as:
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

    // Penalize 6-chord interpretations for 3-note voicings that omit the 5th.
    // Helps avoid "root-3-6" ambiguity by disfavoring incomplete 6th chords.
    //
    // Example: {C, E, A} could be C6(no5) or Am7/C → prefer Am7/C
    const sixChordNo5PenaltyRaw = 0.60;
    if (_has6ChordWithout5(
      quality: template.quality,
      relMask: relMask,
      inputNoteCount: inputNoteCount,
    )) {
      raw -= sixChordNo5PenaltyRaw;
      add('sixNo5', -sixChordNo5PenaltyRaw, detail: 'n=$inputNoteCount');
    }

    // Normalize by sqrt(required_tone_count) to allow fair comparison across
    // chord complexities. Without normalization, 7th chords would always outscore
    // triads simply due to having more required tones to match.
    //
    // Square root (vs linear) preserves meaningful score separation while
    // preventing over-penalization of complex chords.
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

  static bool _has6ChordWithout5({
    required ChordQualityToken quality,
    required int relMask,
    required int inputNoteCount,
  }) {
    if (inputNoteCount != 3) return false;

    final isSixChord =
        quality == ChordQualityToken.major6 ||
        quality == ChordQualityToken.minor6;
    if (!isSixChord) return false;

    // Perfect fifth is interval 7 above the root.
    const fifthBit = 1 << 7;
    final hasFifth = (relMask & fifthBit) != 0;

    return !hasFifth;
  }

  /// Calculates the interval (in semitones, 0-11) from rootPc to pc.
  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  /// Rotates a 12-bit pitch-class mask to be relative to the given root.
  /// Example: {C, E, G} with root=C → bitmask 100010001 (intervals 0, 4, 7)
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

/// Extracts extension tokens from the "extra" tone mask.
///
/// Maps interval positions to ChordExtension enums:
/// - Alterations: b9(1), #9(3), #11(6), b13(8)
/// - Natural extensions: 9(2), 11(5), 13(9)
///
/// Natural extensions become "add9/add11/add13" for triads,
/// or stacked "9/11/13" for 7th-family chords (where they're more idiomatic).
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

/// Bitwise popcount utility for small integer masks using the standard
/// Kernighan algorithm.
int _popCount(int v) {
  var c = 0;
  while (v != 0) {
    v &= v - 1; // clear lowest set bit
    c++;
  }
  return c;
}
