import 'dart:math' as math;

import 'data/chord_templates.dart';
import 'models/chord_candidate.dart';
import 'models/chord_extension.dart';
import 'models/chord_identity.dart';
import 'models/chord_input.dart';
import 'utils/bit_ops.dart';

abstract final class ChordAnalyzer {
  static final Map<int, List<ChordCandidate>> _cache =
      <int, List<ChordCandidate>>{};

  static List<ChordCandidate> analyze(ChordInput input) {
    final key = input.cacheKey;
    final cached = _cache[key];
    if (cached != null) return cached;

    final result = _analyzeUncached(input);
    _cache[key] = result;
    return result;
  }

  static void clearCache() => _cache.clear();

  static List<ChordCandidate> _analyzeUncached(ChordInput input) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <ChordCandidate>[];

    final candidates = <ChordCandidate>[];

    // Phase 2 assumption: root pitch class is present in the voicing.
    // (We will relax this later for shell voicings / missing-root patterns.)
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

        candidates.add(
          ChordCandidate(
            identity: ChordIdentity(
              rootPc: rootPc,
              bassPc: input.bassPc,
              quality: tmpl.quality,
              extensions: scored.extensions,
            ),
            score: scored.score,
          ),
        );
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(8).toList(growable: false);
  }

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

    final required = template.requiredMask | 0x1; // enforce root as required
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

    // Extras are tones that are neither base nor penalty.
    final base = required | optional;
    final extrasMask = relMask & ~(base | penalty);
    final extrasCount = popCount(extrasMask);

    // If we are missing more than one required tone, treat as too weak for now.
    // This keeps early behavior stable; we can relax later for omissions.
    if (missingCount > 1) return null;

    // Scoring weights (tune in Phase 2/3):
    // - Missing required is heavy penalty.
    // - Required present is strong evidence.
    // - Optional present is mild bonus.
    // - Penalty present is moderate penalty.
    // - Extras are mild penalty (until we interpret them as extensions).
    var score = 0.0;
    score += reqCount * 4.0;
    score -= missingCount * 6.0;
    score += optCount * 1.5;
    score -= penCount * 3.0;
    score -= extrasCount * 0.5;

    // Bass bonus: prefer bass as a chord tone (required/optional).
    // Penalize slightly if bass is a "non-chord tone" relative to this root.
    final bassBit = 1 << bassInterval;
    if ((base & bassBit) != 0) {
      score += 1.0;
    } else if ((extrasMask & bassBit) != 0) {
      // bass is an extension: slightly positive (slash chords like Cadd9/E are real)
      score += 0.25;
    } else {
      score -= 0.25;
    }

    // Normalize lightly so scores are comparable across templates of different sizes.
    // This is not a strict probability—just stabilizes ranking.
    final denom = math.max(1, popCount(required) + popCount(optional));
    final normalized = score / denom;

    // Compute extensions as intervals beyond the base chord (excluding penalties).
    final has7 = _qualityHasSeventh(template.quality);
    final extensions = _extensionsFromExtras(extrasMask, has7: has7);

    return _ScoredTemplate(score: normalized, extensions: extensions);
  }
}

class _ScoredTemplate {
  final double score;
  final Set<ChordExtension> extensions;
  const _ScoredTemplate({required this.score, required this.extensions});
}

bool _qualityHasSeventh(ChordQualityToken q) {
  switch (q) {
    case ChordQualityToken.dominant7:
    case ChordQualityToken.major7:
    case ChordQualityToken.minor7:
    case ChordQualityToken.halfDiminished7:
    case ChordQualityToken.diminished7:
      return true;
    default:
      return false;
  }
}

Set<ChordExtension> _extensionsFromExtras(
  int extrasMask, {
  required bool has7,
}) {
  final out = <ChordExtension>{};

  // Interval semitones relative to root:
  // 1=b9, 2=9, 3=#9 (also m3, but if it's in extras it's not part of the base quality),
  // 5=11, 6=#11, 8=b13, 9=13

  if ((extrasMask & (1 << 1)) != 0) out.add(ChordExtension.flat9);
  if ((extrasMask & (1 << 3)) != 0) out.add(ChordExtension.sharp9);
  if ((extrasMask & (1 << 6)) != 0) out.add(ChordExtension.sharp11);
  if ((extrasMask & (1 << 8)) != 0) out.add(ChordExtension.flat13);

  final has9 = (extrasMask & (1 << 2)) != 0;
  final has11 = (extrasMask & (1 << 5)) != 0;
  final has13 = (extrasMask & (1 << 9)) != 0;

  if (has9) out.add(has7 ? ChordExtension.nine : ChordExtension.add9);
  if (has11) out.add(has7 ? ChordExtension.eleven : ChordExtension.add11);
  if (has13) out.add(has7 ? ChordExtension.thirteen : ChordExtension.add13);

  return out;
}
