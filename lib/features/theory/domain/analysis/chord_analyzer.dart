import 'dart:collection';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../models/analysis_context.dart';
import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_input.dart';
import '../models/observed_voicing.dart';
import '../services/chord_quality_intervals.dart';
import '../services/chord_tone_roles.dart';
import '../services/pitch_class.dart';
import 'chord_candidate_ranking.dart';
import 'chord_templates.dart';

@immutable
class ScoreReason {
  final String label;
  final double delta;
  final String? detail;

  /// Root-relative interval mask for the notes in this category, when the
  /// reason describes a tone set (required, optional, penalty, extras,
  /// missing). Null for contextual modifiers that have no note set.
  final int? intervals;

  const ScoreReason(this.label, this.delta, {this.detail, this.intervals});

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
/// - Penalize missing tones, contradictory tones, and added complexity
/// - Normalize by chord complexity to allow fair comparison
///
/// NOTE: docs/site/articles/under-the-hood.html documents this pipeline in
/// detail. Update the article when scoring weights or algorithm structure changes.
abstract final class ChordAnalyzer {
  @visibleForTesting
  static const int cacheCapacity = 512;

  static final LinkedHashMap<int, List<ChordCandidate>> _cache =
      LinkedHashMap<int, List<ChordCandidate>>();

  // ---- Scoring weights (tuned empirically) ----------------------------------
  // See docs/site/articles/under-the-hood.html for the full scoring model.

  // Core per-tone weights (positive magnitude; sign applied at use site).
  static const _reqWeight = 4.0; // required tone present
  static const _missWeight = 6.0; // required tone missing
  static const _optWeight = 1.5; // optional tone present
  static const _penWeight = 3.0; // penalty (contradicting) tone present
  static const _extraWeight = 0.5; // complexity cost per extra-template tone

  // Bass fit scores.
  static const _bassBase = 1.00; // bass is a required/optional tone
  static const _bassColor =
      0.75; // bass is a color/extension tone on 7th-family chord
  static const _bassAdd = 0.25; // bass is an add/extension tone on a triad
  static const _bassMiss = -0.25; // bass pitch not accounted for by template

  // One-off structural penalties (applied as raw -= constant).
  static const _minorSharp5BassPenalty = 3.0; // m#5/m7#5 with the #5 in bass
  static const _susToneBassPenalty =
      2.0; // sus chord with suspended tone in bass
  static const _sixChordNo5Penalty =
      0.60; // 6th chord omitting the 5th in a 3-note voicing
  static const _altPenalty = 0.60; // alteration spelling preference
  static const _altPenaltyDim7 = 0.30; // softened for symmetric dim7
  static const _altPenaltyTriad =
      0.30; // softened for non-seventh-family chords
  static const _splitNinthPenalty = 0.05; // simultaneous b9 and natural 9 color

  // Dominant-stack coherence bonuses.
  static const _domStackPartial = 0.70; // dom7 + 9 + #11 partial stack
  static const _domStackFull = 2.1; // dom7 + 9 + #11 + 13/b13 coherent stack
  static const _fifthlessExtensionStackBonus =
      2.4; // root-position fifthless natural 9 + #11/13 stacks
  static const _fifthlessMajorThirteenthStackBonus =
      1.9; // root-position fifthless maj7 + 9 + #11 + 13 stacks
  static const _completeDominantFlatThirteenthBonus =
      0.15; // complete dom7 shell + b13 should compete with enharmonic maj7#5
  static const _completeDominantNineFlatThirteenthBonus =
      0.70; // complete dom7 shell + natural 9 + b13 stack
  static const _completeDominantFlatNineFlatThirteenthBonus =
      0.70; // complete dom7 shell + b9 + b13 altered stack

  // Upper-structure slash-triad bonus.
  static const _add9BassUpperTriadBonus = 3.2; // e.g. D/E, C#/D#

  static List<ChordCandidate> analyze(
    ChordInput input, {
    required AnalysisContext context,
    ObservedVoicing? voicing,
    int take = 8,
  }) {
    // Cache includes context because tonality affects ranking tie-breakers
    // (e.g., diatonic preference, tonic-as-I rule), and the voicing signature
    // because register evidence nudges the ranking.
    final key = Object.hash(
      input.cacheKey,
      voicing?.signature ?? 0,
      context,
      take,
    );
    final cached = _cache[key];
    if (cached != null) {
      // Promote cache hits so eviction removes the least recently used entry,
      // not merely the oldest inserted entry.
      _cache
        ..remove(key)
        ..[key] = cached;
      return cached;
    }

    final eval = _evaluateAll(
      input,
      context: context,
      voicing: voicing,
      debug: false,
    );

    final result = eval
        .take(take)
        .map((e) => e.candidate)
        .toList(growable: false);

    _cache[key] = result;
    if (_cache.length > cacheCapacity) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  static void clearCache() => _cache.clear();

  @visibleForTesting
  static int get cacheSize => _cache.length;

  /// Debug entrypoint for CLI tooling.
  ///
  /// Uses the exact same evaluation + ranking logic as [analyze], but also
  /// returns human-readable score reasons and tie-break explanations.
  static List<RankedCandidateDebug> analyzeDebug(
    ChordInput input, {
    required AnalysisContext context,
    ObservedVoicing? voicing,
    int take = 8,
  }) {
    final eval = _evaluateAll(
      input,
      context: context,
      voicing: voicing,
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
                  voicing: voicing,
                ),
        ),
      );
    }
    return out;
  }

  static List<_Evaluated> _evaluateAll(
    ChordInput input, {
    required AnalysisContext context,
    required ObservedVoicing? voicing,
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
      final bassInterval = intervalAboveRoot(input.bassPc, rootPc);

      for (final tmpl in chordTemplates) {
        final reasons = debug ? <ScoreReason>[] : null;

        final scored = _scoreTemplate(
          relMask: relMask,
          bassInterval: bassInterval,
          template: tmpl,
          rootPc: rootPc,
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
            presentIntervalsMask: relMask,
          ),
          score: scored.score,
        );

        out.add(
          _Evaluated(candidate: candidate, template: tmpl, reasons: reasons),
        );
      }
    }

    // `compare` is intentionally non-transitive (hard rules and the near-tie
    // window override raw score), so a plain sort would be undefined and could
    // bury a strong candidate. `rank` linearizes the relation deterministically.
    return ChordCandidateRanking.rank(
      out,
      (e) => e.candidate,
      tonality: context.tonality,
      voicing: voicing,
    );
  }

  // ---- Template scoring: fit voicing to chord structure -----------------
  //
  // Weights are tuned empirically to balance:
  // - Structural integrity (required > optional)
  // - Penalty for ambiguity and complexity (missing tones, extras)
  // - Bass role appropriateness

  static _ScoredTemplate? _scoreTemplate({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
    required int rootPc,
    required AnalysisContext context,
    List<ScoreReason>? reasons,
  }) {
    void add(String label, double delta, {String? detail, int? intervals}) {
      reasons?.add(
        ScoreReason(label, delta, detail: detail, intervals: intervals),
      );
    }

    if ((relMask & 0x1) == 0) return null;

    // Root must always be required for stability.
    final required = template.requiredMask | 0x1;
    final optional = template.optionalMask;
    final penalty = template.penaltyMask;

    if (template.requiresExactMatch && relMask != (required | optional)) {
      return null;
    }

    final missingRequiredMask = required & ~relMask;
    final presentRequiredMask = required & relMask;
    final presentOptionalMask = optional & relMask;
    final functionalPenaltyExtensionsMask = _functionalPenaltyExtensionsMask(
      template: template,
      relMask: relMask,
      bassInterval: bassInterval,
    );
    final presentPenaltyMask =
        (penalty & relMask) & ~functionalPenaltyExtensionsMask;

    final missCount = popCount(missingRequiredMask);

    // Allow up to 1 missing required tone for sparse voicings.
    // Example: dominant7 without the 5th (shell voicing) is still valid.
    // More than 1 missing tone suggests wrong template entirely.
    if (missCount > 1) return null;

    final reqCount = popCount(presentRequiredMask);
    final optCount = popCount(presentOptionalMask);
    final penCount = popCount(presentPenaltyMask);

    // Extras: tones outside the base template. These may become named
    // extensions in the final chord identity.
    final base = required | optional;
    final extrasMask =
        (relMask & ~(base | penalty)) | functionalPenaltyExtensionsMask;

    // Extract extensions before counting extras so the alt-penalty check below
    // can inform which extra tones are already covered by that penalty.
    final has7 = template.quality.isSeventhFamily;
    final extensions = _extensionsFromExtras(
      extrasMask,
      has7: has7,
      quality: template.quality,
    );

    // The flat alt penalty below covers the cost of having any alteration
    // extension outside the base template — so the first such extra should not
    // also incur the per-tone complexity cost. Additional alteration extras
    // beyond the first still incur that cost because the flat penalty doesn't
    // scale with count.
    const alterationIntervalBits = (1 << 1) | (1 << 3) | (1 << 6) | (1 << 8);
    final hasAltExtras =
        _hasAlterations(extensions, template.quality) &&
        (extrasMask & alterationIntervalBits) != 0;
    final extraCount = popCount(extrasMask) - (hasAltExtras ? 1 : 0);

    if (_flatFiveConflictsWithNaturalThirteenth(
      quality: template.quality,
      extensions: extensions,
    )) {
      return null;
    }

    // Raw scoring components (single source of truth).
    var raw = 0.0;

    final reqDelta = reqCount * _reqWeight;
    raw += reqDelta;
    add(
      'required tones',
      reqDelta,
      detail: 'count=$reqCount',
      intervals: presentRequiredMask,
    );

    final missDelta = -missCount * _missWeight;
    raw += missDelta;
    add(
      'missing required',
      missDelta,
      detail: 'count=$missCount',
      intervals: missingRequiredMask,
    );

    final optDelta = optCount * _optWeight;
    raw += optDelta;
    add(
      'optional tones',
      optDelta,
      detail: 'count=$optCount',
      intervals: presentOptionalMask,
    );

    final penDelta = -penCount * _penWeight;
    raw += penDelta;
    add(
      'penalty tones',
      penDelta,
      detail: 'count=$penCount',
      intervals: presentPenaltyMask,
    );

    final extraDelta = -extraCount * _extraWeight;
    raw += extraDelta;
    add(
      'extras',
      extraDelta,
      detail: 'count=$extraCount',
      intervals: extrasMask,
    );

    // Bass scoring priority (reflects common voicing practices):
    // base tone > color/extension tone on 7th chord > add tone on triad > not in template
    final bassBit = 1 << bassInterval;
    final double bassDelta;
    if ((base & bassBit) != 0) {
      bassDelta = _bassBase;
    } else if ((extrasMask & bassBit) != 0) {
      // If the bass is being interpreted as an extension/alteration tone on a
      // seventh-family chord, treat it as a legitimate "color bass" rather than
      // an arbitrary extra tone.
      final isColorBass =
          template.quality.isSeventhFamily && extensions.isNotEmpty;
      bassDelta = isColorBass ? _bassColor : _bassAdd;
    } else {
      bassDelta = _bassMiss;
    }
    raw += bassDelta;
    add('bass fit', bassDelta, detail: 'interval=$bassInterval');

    // Minor sharp-five sonorities are real but uncommon. When the bass is the
    // altered fifth, common add-chord voicings can otherwise be overread as a
    // remote slash minor-sharp-five chord (for example Cadd9 as Em7#5/C).
    if (_hasMinorSharpFiveAlteredFifthBass(
      quality: template.quality,
      bassInterval: bassInterval,
    )) {
      raw -= _minorSharp5BassPenalty;
      add('m#5 bass', -_minorSharp5BassPenalty);
    }

    // Sus chords with the suspended tone itself in the bass are rare and
    // awkward to read. Musicians almost never write "D7sus2/E" (the suspension
    // in the bass); instead they hear the voicing from a different root where
    // the bass is a normal core tone. Penalize enough that a competing
    // add-chord or triad reading can win through the diatonic and
    // root-position tie-breakers when one exists.
    //
    // Root-position sus chords (bassInterval == 0) are unaffected because the
    // root is always a core tone. Inversions with the 5th or 7th in bass are
    // also unaffected; only the suspended tone itself triggers the penalty.
    if (_hasSusToneInBass(
      quality: template.quality,
      bassInterval: bassInterval,
    )) {
      raw -= _susToneBassPenalty;
      add('sus-tone bass', -_susToneBassPenalty);
    }

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
    final altPenalty = switch (template.quality) {
      ChordQualityToken.diminished7 => _altPenaltyDim7,
      _
          when !template.quality.isSeventhFamily &&
              !template.quality.isSixFamily =>
        _altPenaltyTriad,
      _ => _altPenalty,
    };

    if (_hasAlterations(extensions, template.quality)) {
      raw -= altPenalty;
      add(
        'alterations penalty',
        -altPenalty,
        detail: switch (template.quality) {
          ChordQualityToken.diminished7 => 'dim7 softened',
          _
              when !template.quality.isSeventhFamily &&
                  !template.quality.isSixFamily =>
            'triad softened',
          _ => null,
        },
      );
    }

    if (_hasSplitNinthColor(extensions)) {
      raw -= _splitNinthPenalty;
      add('split ninth', -_splitNinthPenalty);
    }

    final dominantStackDelta = _dominantStackCoherenceBonus(
      quality: template.quality,
      extensions: extensions,
      relMask: relMask,
      bassInterval: bassInterval,
    );
    if (dominantStackDelta != 0) {
      raw += dominantStackDelta;
      add('dominant stack', dominantStackDelta);
    }

    final fifthlessExtensionStackDelta = _fifthlessExtensionStackBonusFor(
      quality: template.quality,
      extensions: extensions,
      relMask: relMask,
      bassInterval: bassInterval,
    );
    if (fifthlessExtensionStackDelta != 0) {
      raw += fifthlessExtensionStackDelta;
      add('fifthless extension stack', fifthlessExtensionStackDelta);
    }

    final completeDominantFlatThirteenthDelta =
        _completeDominantFlatThirteenthBonusFor(
          quality: template.quality,
          extensions: extensions,
          relMask: relMask,
        );
    if (completeDominantFlatThirteenthDelta != 0) {
      raw += completeDominantFlatThirteenthDelta;
      add('complete b13 dominant', completeDominantFlatThirteenthDelta);
    }

    final add9BassUpperTriadDelta = _add9BassUpperTriadBonusFor(
      quality: template.quality,
      extensions: extensions,
      relMask: relMask,
      bassInterval: bassInterval,
    );
    if (add9BassUpperTriadDelta != 0) {
      raw += add9BassUpperTriadDelta;
      add('add9 bass triad', add9BassUpperTriadDelta);
    }

    // Penalize sparse 6-chord interpretations that omit the 5th. Doubling a
    // tone does not make the pitch-class structure more complete.
    // Helps avoid "root-3-6" ambiguity by disfavoring incomplete 6th chords.
    //
    // Example: {C, E, A} could be C6(no5) or Am7/C → prefer Am7/C
    if (_has6ChordWithout5(quality: template.quality, relMask: relMask)) {
      raw -= _sixChordNo5Penalty;
      add(
        'sixNo5',
        -_sixChordNo5Penalty,
        detail: 'pitchClasses=${popCount(relMask)}',
      );
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

  static bool _hasAlterations(
    Set<ChordExtension> extensions,
    ChordQualityToken quality,
  ) {
    return extensions.contains(ChordExtension.flat9) ||
        extensions.contains(ChordExtension.sharp9) ||
        (extensions.contains(ChordExtension.sharp11) &&
            !quality.sharp11IsNaturalColor) ||
        extensions.contains(ChordExtension.flat13);
  }

  static bool _hasSplitNinthColor(Set<ChordExtension> extensions) {
    return extensions.contains(ChordExtension.flat9) &&
        extensions.contains(ChordExtension.nine);
  }

  static int _functionalPenaltyExtensionsMask({
    required ChordTemplate template,
    required int relMask,
    required int bassInterval,
  }) {
    final quality = template.quality;
    if (_supportsSplitThirdMajorFamilyVoicing(bassInterval, relMask) &&
        _isSplitThirdMajorQuality(quality, relMask)) {
      return 1 << minorThirdInterval;
    }

    final isSharpNineDominantQuality =
        quality == ChordQualityToken.dominant7 ||
        quality == ChordQualityToken.dominant7Flat5 ||
        quality == ChordQualityToken.dominant7Sharp5;
    if (!isSharpNineDominantQuality) return 0;

    final hasDominantShell =
        (relMask & (1 << majorThirdInterval)) != 0 &&
        (relMask & (1 << minorSeventhInterval)) != 0;
    if (!hasDominantShell) return 0;

    // In dominant context, interval 3 is the altered ninth rather than a
    // contradictory minor third: G-B-D-F-A# is G7#9, not plain G7 with a penalty.
    const sharpNineBit =
        1 << minorThirdInterval; // same interval, dominant function
    if ((relMask & sharpNineBit) == 0) return 0;
    return sharpNineBit;
  }

  static bool _supportsSplitThirdMajorFamilyVoicing(
    int bassInterval,
    int relMask,
  ) {
    if (bassInterval == 0) return true;

    final isConventionalInversion =
        bassInterval == majorThirdInterval ||
        bassInterval == perfectFifthInterval;
    final hasPerfectFifth = (relMask & (1 << perfectFifthInterval)) != 0;
    return isConventionalInversion && hasPerfectFifth;
  }

  static bool _allowsAddSharpNine(ChordQualityToken quality) {
    return quality == ChordQualityToken.major ||
        quality == ChordQualityToken.major6 ||
        quality == ChordQualityToken.augmented;
  }

  static bool _isSplitThirdMajorQuality(
    ChordQualityToken quality,
    int relMask,
  ) {
    if (!_allowsAddSharpNine(quality)) return false;
    const majorThirdBit = 1 << majorThirdInterval;
    const minorThirdBit = 1 << minorThirdInterval;
    return (relMask & majorThirdBit) != 0 && (relMask & minorThirdBit) != 0;
  }

  static bool _has6ChordWithout5({
    required ChordQualityToken quality,
    required int relMask,
  }) {
    if (popCount(relMask) != 3) return false;

    final isSixChord =
        quality == ChordQualityToken.major6 ||
        quality == ChordQualityToken.minor6;
    if (!isSixChord) return false;

    final hasFifth = (relMask & (1 << perfectFifthInterval)) != 0;

    return !hasFifth;
  }

  static bool _hasMinorSharpFiveAlteredFifthBass({
    required ChordQualityToken quality,
    required int bassInterval,
  }) {
    final isMinorSharpFiveQuality =
        quality == ChordQualityToken.minorSharp5 ||
        quality == ChordQualityToken.minor7Sharp5;
    return isMinorSharpFiveQuality && bassInterval == 8;
  }

  /// Returns true when a sus chord has its suspended tone (not the root) in
  /// the bass. The sus2 interval is 2 (M2); the sus4 interval is 5 (P4).
  static bool _hasSusToneInBass({
    required ChordQualityToken quality,
    required int bassInterval,
  }) {
    switch (quality) {
      case ChordQualityToken.sus2:
      case ChordQualityToken.dominant7sus2:
      case ChordQualityToken.major7sus2:
        return bassInterval == 2;
      case ChordQualityToken.sus4:
      case ChordQualityToken.dominant7sus4:
      case ChordQualityToken.major7sus4:
        return bassInterval == 5;
      default:
        return false;
    }
  }

  static bool _flatFiveConflictsWithNaturalThirteenth({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
  }) {
    final isFlatFiveQuality =
        quality == ChordQualityToken.dominant7Flat5 ||
        quality == ChordQualityToken.major7Flat5;
    if (!isFlatFiveQuality) return false;

    // With a natural thirteenth present, the tritone usually functions as #11
    // color rather than a literal b5 core tone: C-E-Bb-D-F#-A -> C13#11.
    return extensions.contains(ChordExtension.thirteen) ||
        extensions.contains(ChordExtension.add13);
  }

  static double _dominantStackCoherenceBonus({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int relMask,
    required int bassInterval,
  }) {
    // Lydian and altered dominant stacks are commonly voiced as dominant chords
    // with 9/#11 or b9/#11/b13 color. Without this structural bonus, the scorer
    // overvalues remote altered-fifth slash readings that happen to reinterpret
    // one color tone as a required chord tone.
    if (quality != ChordQualityToken.dominant7) return 0;
    if (!extensions.contains(ChordExtension.sharp11)) return 0;

    final hasNaturalNinth = extensions.contains(ChordExtension.nine);
    final hasFlatNinth = extensions.contains(ChordExtension.flat9);
    final hasNaturalThirteenth = extensions.contains(ChordExtension.thirteen);
    final hasFlatThirteenth = extensions.contains(ChordExtension.flat13);
    if (hasFlatNinth && hasFlatThirteenth) {
      final hasRealFifth = (relMask & (1 << perfectFifthInterval)) != 0;
      return hasRealFifth ? _domStackFull : 0;
    }

    if (!hasNaturalNinth) return 0;
    if (!hasNaturalThirteenth && !hasFlatThirteenth) {
      return bassInterval == 0 ? _domStackPartial : 0;
    }

    if (hasNaturalThirteenth && !hasFlatThirteenth) {
      final hasRealFifth = (relMask & (1 << perfectFifthInterval)) != 0;
      if (!hasRealFifth) return 0;
      return bassInterval == 0 ? _domStackFull : _domStackPartial;
    }

    if (hasFlatThirteenth && (relMask & (1 << perfectFifthInterval)) == 0) {
      return 0;
    }

    return _domStackFull;
  }

  static double _fifthlessExtensionStackBonusFor({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int relMask,
    required int bassInterval,
  }) {
    // Root-position fifthless extended chords are conventional when their upper
    // colors form a natural extension stack. Reward that coherence directly,
    // rather than relying on a later hard ranking override. Major-family stacks
    // still need Lydian #11 color; a natural 11 against the major third is too
    // tense to justify this structural bonus. For dominant sevenths, require a
    // natural thirteenth: with only 9 + #11 and no fifth, the tritone is usually
    // clearer as a chord-defining b5.
    if (bassInterval != 0) return 0;
    if (quality != ChordQualityToken.major7 &&
        quality != ChordQualityToken.dominant7) {
      return 0;
    }
    if (!extensions.contains(ChordExtension.nine)) return 0;
    if (extensions.contains(ChordExtension.flat13)) return 0;
    final hasSharpEleventh = extensions.contains(ChordExtension.sharp11);
    final hasThirteenth = extensions.contains(ChordExtension.thirteen);
    if (!hasSharpEleventh && !hasThirteenth) return 0;
    if (quality == ChordQualityToken.major7 &&
        extensions.contains(ChordExtension.eleven)) {
      return 0;
    }
    if (quality == ChordQualityToken.dominant7 && !hasThirteenth) return 0;
    if ((relMask & (1 << perfectFifthInterval)) != 0) return 0;

    if (quality == ChordQualityToken.major7 && hasThirteenth) {
      return _fifthlessMajorThirteenthStackBonus;
    }
    return _fifthlessExtensionStackBonus;
  }

  static double _completeDominantFlatThirteenthBonusFor({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int relMask,
  }) {
    if (quality != ChordQualityToken.dominant7) return 0;
    if (!extensions.contains(ChordExtension.flat13)) return 0;
    if (extensions.any(
      (extension) =>
          extension != ChordExtension.flat13 &&
          extension != ChordExtension.flat9 &&
          extension != ChordExtension.nine,
    )) {
      return 0;
    }

    final hasCompleteShell =
        (relMask & 1) != 0 &&
        (relMask & (1 << majorThirdInterval)) != 0 &&
        (relMask & (1 << perfectFifthInterval)) != 0 &&
        (relMask & (1 << minorSeventhInterval)) != 0;
    if (!hasCompleteShell) return 0;

    final hasNinthColor =
        extensions.contains(ChordExtension.nine) ||
        extensions.contains(ChordExtension.flat9);
    if (extensions.contains(ChordExtension.flat9)) {
      return _completeDominantFlatNineFlatThirteenthBonus;
    }
    if (hasNinthColor) return _completeDominantNineFlatThirteenthBonus;
    return _completeDominantFlatThirteenthBonus;
  }

  static double _add9BassUpperTriadBonusFor({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int relMask,
    required int bassInterval,
  }) {
    // A complete major/minor triad over a bass a whole step above the root is
    // commonly heard as an upper-structure slash chord (D/E, C#/D#), not as a
    // remote altered seventh or incomplete sus reinterpretation.
    final isPlainMajorMinor =
        quality == ChordQualityToken.major ||
        quality == ChordQualityToken.minor;
    if (!isPlainMajorMinor) return 0;
    if (bassInterval != majorSecondInterval) return 0;
    if (extensions.length != 1 || !extensions.contains(ChordExtension.add9)) {
      return 0;
    }

    final thirdInterval = quality == ChordQualityToken.major
        ? majorThirdInterval
        : minorThirdInterval;
    final hasThird = (relMask & (1 << thirdInterval)) != 0;
    final hasFifth = (relMask & (1 << perfectFifthInterval)) != 0;
    if (!hasThird || !hasFifth) return 0;

    return _add9BassUpperTriadBonus;
  }

  /// Rotates a 12-bit pitch-class mask to be relative to the given root.
  /// Example: {C, E, G} with root=C → bitmask 100010001 (intervals 0, 4, 7)
  static int _rotateMaskToRoot(int pcMask, int rootPc) {
    var rel = 0;
    for (var pc = 0; pc < 12; pc++) {
      if ((pcMask & (1 << pc)) == 0) continue;
      final interval = intervalAboveRoot(pc, rootPc);
      rel |= (1 << interval);
    }
    return rel;
  }

  /// Extracts extension tokens from the "extra" tone mask.
  ///
  /// Maps interval positions to ChordExtension enums:
  /// - Alterations: b9(1), #9(3), #11(6), b13(8)
  /// - Natural extensions: 9(2), 11(5), 13(9)
  ///
  /// Natural extensions become "add9/add11/add13" for triads,
  /// or stacked "9/11/13" for 7th-family chords (where they're more idiomatic).
  static Set<ChordExtension> _extensionsFromExtras(
    int extrasMask, {
    required bool has7,
    required ChordQualityToken quality,
  }) {
    final out = <ChordExtension>{};

    // Alterations.
    if ((extrasMask & (1 << 1)) != 0) {
      // Without a seventh (or sixth) to anchor a stacked ♭9, the flat ninth is
      // an added tone: C-E-G-D♭ is Cadd♭9, not C♭9. Mirrors add9/add#9.
      out.add(
        has7 || quality.isSixFamily
            ? ChordExtension.flat9
            : ChordExtension.addFlat9,
      );
    }
    if ((extrasMask & (1 << 3)) != 0) {
      out.add(
        has7 || !_allowsAddSharpNine(quality)
            ? ChordExtension.sharp9
            : ChordExtension.addSharp9,
      );
    }
    if ((extrasMask & (1 << 6)) != 0) out.add(ChordExtension.sharp11);
    if ((extrasMask & (1 << 8)) != 0) out.add(ChordExtension.flat13);

    // Natural extensions/add tones. A natural 9, 11, or 13 reads as a stacked
    // upper extension (eligible to headline) whenever the chord has a seventh;
    // the lower stack members are optional, so C-E-G-B♭-A is C13 and
    // C-E-G-B♭-F is C11, not C7(addN). Without a seventh the tone is an added
    // color (and a plain triad plus a sixth is a sixth chord).
    final has9 = (extrasMask & (1 << 2)) != 0;
    final has11 = (extrasMask & (1 << 5)) != 0;
    final has13 = (extrasMask & (1 << 9)) != 0;

    if (has9) out.add(has7 ? ChordExtension.nine : ChordExtension.add9);
    if (has11) out.add(has7 ? ChordExtension.eleven : ChordExtension.add11);
    if (has13) out.add(has7 ? ChordExtension.thirteen : ChordExtension.add13);

    return out;
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
