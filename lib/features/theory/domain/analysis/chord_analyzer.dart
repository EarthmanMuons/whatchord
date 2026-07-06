import 'dart:collection';

import 'package:meta/meta.dart';

import '../models/analysis_context.dart';
import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_input.dart';
import '../models/chord_tone_role.dart';
import '../models/observed_voicing.dart';
import '../services/chord_quality_intervals.dart';
import '../services/chord_tone_roles.dart';
import '../services/pitch_class.dart';
import 'chord_candidate_ranking.dart';
import 'chord_templates.dart';
import 'engine_counters.dart';

@immutable
class CostReason {
  final String label;
  final double cost;
  final String? detail;

  /// Root-relative interval mask for the notes in this category, when the
  /// reason describes a tone set (required, optional, penalty, extras,
  /// missing). Null for contextual modifiers that have no note set.
  final int? intervals;

  const CostReason(this.label, this.cost, {this.detail, this.intervals});

  @override
  String toString() {
    final d = cost >= 0
        ? '+${cost.toStringAsFixed(2)}'
        : cost.toStringAsFixed(2);
    return detail == null ? '$label $d' : '$label $d ($detail)';
  }
}

@immutable
class RankedCandidateDebug {
  final ChordCandidate candidate;

  /// Rank in the full list returned by the ranking pass. Debug tools can
  /// filter candidates while still showing where each row originally landed.
  final int? originalRank;

  /// High-signal cost deltas; intended for CLI explanation.
  final List<CostReason> costReasons;

  /// Why this candidate is ordered where it is relative to the previous one.
  /// (Null for the first result.)
  final RankingDecision? vsPrevious;

  /// The template that generated this candidate (useful for diagnostics).
  final ChordTemplate template;

  const RankedCandidateDebug({
    required this.candidate,
    this.originalRank,
    required this.costReasons,
    required this.vsPrevious,
    required this.template,
  });
}

/// Analyzes pitch-class sets to generate and rank chord interpretations.
///
/// Core pipeline:
/// 1. Generate candidates from all possible roots present in the voicing
/// 2. Price each candidate against chord templates using fit metrics
/// 3. Rank candidates using cost + tie-breaking heuristics
/// 4. Cache results keyed by input + context
///
/// Pricing philosophy: a candidate's cost is the price of explaining the input
/// under that name; lower is better. Core chord tones are free, and the name
/// pays for its rarity, appended colors, missing essentials, unexplained tones,
/// and awkward bass placement.
///
/// NOTE: docs/site/articles/chord-recognition-algorithm.html documents this
/// pipeline in detail. Update the article when prices or algorithm structure
/// change.
abstract final class ChordAnalyzer {
  @visibleForTesting
  static const int cacheCapacity = 512;

  static final LinkedHashMap<int, List<ChordCandidate>> _cache =
      LinkedHashMap<int, List<ChordCandidate>>();

  // ---- Explanation-cost prices -----------------------------------------
  // A candidate's cost is the price of explaining every sounding pitch under
  // that name: core chord tones are free, and the name pays for its own
  // rarity, each color tone it appends, essential tones it lacks, tones it
  // cannot account for, and awkward bass placement. Lower is better. Prices are
  // musician-judged priors calibrated against the reviewed oracle pool.
  // See docs/site/articles/chord-recognition-algorithm.html.

  // Vocabulary rarity: how readily a musician reaches for the quality name.
  static const _vocabularyMarked = 0.1; // dim, aug, sus2, dim7, m7b5, ...
  static const _vocabularyUncommon = 0.4; // 7b5, 7#5, maj7sus4, maj7#5
  static const _vocabularyRare = 1.0; // m#5, m7#5, majb5, maj7b5, sus2 7ths

  // Natural color tones. Upper extensions are idiomatic on everyday hosts
  // (a 13 on a dominant, an 11 on a minor seventh); on marked-vocabulary
  // hosts (a 13 on a half-diminished or minor-major seventh) they are far
  // rarer and cost proportionally more.
  static const _priceNine = 0.35;
  static const _priceEleven = 0.3;
  static const _priceThirteen = 0.3;
  static const _priceAdd9 = 0.4;
  static const _priceAdd11 = 0.3;
  static const _priceAdd13 = 0.3;
  static const _markedHostExtensionMultiplier = 1.75;

  // Altered color tones. The alt palette lives on dominant chords; hosting
  // one of these on another quality doubles its price (#11 stays unmultiplied
  // on the qualities where it is idiomatic Lydian color).
  static const _priceFlat9 = 0.45;
  static const _priceSharp9 = 0.5;
  static const _priceSharp11 = 0.55;
  static const _priceFlat13 = 0.5;
  static const _priceSplitThird = 0.4;
  static const _offDominantAlterationMultiplier = 2.0;

  // Structural surcharges on individual color tones.
  static const _unsupportedElevenSurcharge = 0.15; // 11 with no 9 below it
  static const _unsupportedThirteenSurcharge = 0.25; // 13 with no 9 below it
  static const _elevenOverMajorThirdSurcharge = 0.5; // avoid-tone clash
  static const _splitFourthSurcharge = 0.6; // natural 4 and #11 at once
  static const _splitSecondSurcharge = 0.4; // natural 2 and b9/#9 at once
  static const _splitSixthSurcharge = 0.4; // natural 6/13 and b13 at once
  static const _splitSharpFiveThirteenSurcharge = 0.8; // #5 and 13 at once
  static const _sharpElevenEmptyFifthSurcharge = 0.75; // #11 with no 5th tone
  static const _flatThirteenEmptyFifthSurcharge = 0.5; // b13 with no 5th
  static const _sixChordNoFifthSurcharge = 0.45; // bare R-3-6 set as a 6th
  static const _flatNineMajorHostSurcharge = 0.3; // b9 on a major 6th/7th
  static const _minorMajorFlatNineElevenSurcharge = 0.9;
  static const _stackedChromaticAddSurcharge = 0.15; // addb9/add#9 in a pile
  static const _upperTriadNinthBassCost = 0.15; // D/E idiom: add9 as pedal

  // Missing essential tones (candidate generation allows at most one).
  static const _missingThirdCost = 1.7;
  static const _missingSusToneCost = 1.4;
  static const _missingAlteredFifthCost = 0.9;
  static const _missingSeventhCost = 0.75;
  static const _missingFifthCost = 0.5;

  // A sounding tone the name cannot account for at all.
  static const _unexplainedToneCost = 2.0;

  // Bass placement: root is free, conventional inversions are cheap, color
  // tones and especially suspended tones in the bass read awkwardly. An
  // integrated extension in the bass (the 11 of a m7) reads smoother than a
  // bare add tone (the add9 under a 6/9), which reads like a pedal the name
  // fails to acknowledge.
  static const _bassCoreToneCost = 0.15;
  static const _bassSusToneCost = 0.7;
  static const _bassAlteredFifthCost = 0.3;
  static const _bassNaturalColorCost = 0.3;
  static const _bassAddToneCost = 0.65;
  static const _bassAlteredColorCost = 0.5;
  static const _bassUnexplainedCost = 1.0;

  // Candidates priced more than this above the cheapest reading are dropped
  // before the O(n^2) ranking. A reading this far down can never surface as
  // the #1 pick or an alternative; chord_ranking_prune_guard_test measures
  // the widest surfaced gap and asserts it stays under this margin.
  // Not const so that guard test can disable pruning (raise to infinity) and
  // measure the unpruned surfaced gap.
  @visibleForTesting
  static double rankingPruneMargin = 2.0;

  static List<ChordCandidate> analyze(
    ChordInput input, {
    required AnalysisContext context,
    ObservedVoicing? voicing,
    int take = 5,
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
      if (kEngineCountersEnabled) EngineCounters.cacheHits++;
      // Promote cache hits so eviction removes the least recently used entry,
      // not merely the oldest inserted entry.
      _cache
        ..remove(key)
        ..[key] = cached;
      return cached;
    }
    if (kEngineCountersEnabled) EngineCounters.cacheMisses++;

    final eval = _evaluateAll(
      input,
      context: context,
      voicing: voicing,
      debug: false,
      take: take,
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
  /// returns human-readable cost reasons and tie-break explanations.
  static List<RankedCandidateDebug> analyzeDebug(
    ChordInput input, {
    required AnalysisContext context,
    ObservedVoicing? voicing,
    int take = 5,
  }) {
    final eval = _evaluateAll(
      input,
      context: context,
      voicing: voicing,
      debug: true,
      take: take,
    ).take(take).toList(growable: false);

    final out = <RankedCandidateDebug>[];
    for (var i = 0; i < eval.length; i++) {
      final current = eval[i];
      final prev = i == 0 ? null : eval[i - 1];

      out.add(
        RankedCandidateDebug(
          candidate: current.candidate,
          originalRank: i + 1,
          template: current.template,
          costReasons: current.reasons ?? const <CostReason>[],
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
    required int take,
  }) {
    final pcMask = input.pcMask;
    if (pcMask == 0) return const <_Evaluated>[];

    final out = <_Evaluated>[];

    // Assumption: chord roots must be spelled on notes actually present in the voicing.
    // This prevents generating "ghost root" interpretations.
    for (var rootPc = 0; rootPc < 12; rootPc++) {
      if ((pcMask & (1 << rootPc)) == 0) continue;
      if (kEngineCountersEnabled) EngineCounters.rootsConsidered++;

      final relMask = _rotateMaskToRoot(pcMask, rootPc);
      final bassInterval = intervalAboveRoot(input.bassPc, rootPc);

      for (final tmpl in chordTemplates) {
        if (kEngineCountersEnabled) EngineCounters.templatesEvaluated++;
        final reasons = debug ? <CostReason>[] : null;

        final priced = _priceTemplate(
          relMask: relMask,
          bassInterval: bassInterval,
          template: tmpl,
          rootPc: rootPc,
          context: context,
          reasons: reasons,
        );
        if (priced == null) continue;

        final candidate = ChordCandidate(
          identity: ChordIdentity(
            rootPc: rootPc,
            bassPc: input.bassPc,
            quality: tmpl.quality,
            extensions: priced.extensions,
            toneRolesByInterval: priced.roles,
            presentIntervalsMask: relMask,
          ),
          cost: priced.cost,
        );

        if (kEngineCountersEnabled) EngineCounters.candidatesProduced++;
        out.add(
          _Evaluated(candidate: candidate, template: tmpl, reasons: reasons),
        );
      }
    }

    // Drop the long tail of high-cost readings before the O(n^2) ranking.
    // Costs are a pure function of the input, so this is transposition-invariant
    // (both a chord and its transposition prune to the same set).
    final toRank = _pruneForRanking(out, take);
    if (kEngineCountersEnabled) {
      EngineCounters.candidatesRanked += toRank.length;
    }

    // `compare` is intentionally non-transitive (hard rules and the near-tie
    // window override raw cost), so a plain sort would be undefined and could
    // bury a strong candidate. `rank` linearizes the relation deterministically.
    return ChordCandidateRanking.rank(
      toRank,
      (e) => e.candidate,
      tonality: context.tonality,
      voicing: voicing,
    );
  }

  /// Trims the candidate set before the O(n^2) ranking, keeping whichever is
  /// larger of: every candidate within [rankingPruneMargin] of the cheapest raw
  /// cost (which preserves the #1 pick and the surfaced alternatives set, see
  /// [rankingPruneMargin]), or the cheapest [take] by cost.
  ///
  /// The [take] floor keeps the requested result count honest: a caller asking
  /// for N ranked candidates gets up to N even on a strong voicing where only
  /// the winner is within the margin (e.g. C E G as Cmaj, or the top-5/top-12
  /// lists the try page and the Why This Chord modal show regardless of cost).
  /// Tooling that wants the full list passes a large [take]. The floor only
  /// engages when the margin set is smaller than [take], i.e. on clear voicings
  /// with few near-top readings, which are cheap to rank anyway; ambiguous and
  /// dense voicings keep the (larger) margin set, so the prune's win is intact.
  static List<_Evaluated> _pruneForRanking(List<_Evaluated> out, int take) {
    if (out.length <= take) return out;
    var minCost = double.infinity;
    for (final e in out) {
      if (e.candidate.cost < minCost) minCost = e.candidate.cost;
    }
    final threshold = minCost + rankingPruneMargin;
    final within = [
      for (final e in out)
        if (e.candidate.cost <= threshold) e,
    ];
    if (within.length >= take) return within;
    // Margin set is smaller than the requested count. Keep the cheapest [take]
    // by cost; beyond the surfaced set the ranking is essentially cost order, so
    // these fill the lower positions. The margin set is a subset (the cheapest
    // readings), so the #1 pick and surfaced alternatives are still preserved.
    final sorted = [...out]
      ..sort((a, b) => a.candidate.cost.compareTo(b.candidate.cost));
    return sorted.sublist(0, take);
  }

  // ---- Template pricing: fit voicing to chord structure -----------------
  //
  // Weights are tuned empirically to balance:
  // - Structural integrity (required > optional)
  // - Penalty for ambiguity and complexity (missing tones, extras)
  // - Bass role appropriateness

  static _PricedTemplate? _priceTemplate({
    required int relMask,
    required int bassInterval,
    required ChordTemplate template,
    required int rootPc,
    required AnalysisContext context,
    List<CostReason>? reasons,
  }) {
    void add(
      String label,
      double costContribution, {
      String? detail,
      int? intervals,
    }) {
      reasons?.add(
        CostReason(
          label,
          costContribution,
          detail: detail,
          intervals: intervals,
        ),
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

    final missCount = popCount(missingRequiredMask);

    // Allow up to 1 missing required tone for sparse voicings.
    // Example: dominant7 without the 5th (shell voicing) is still valid.
    // More than 1 missing tone suggests wrong template entirely. A power
    // chord is nothing but its fifth, so it gets no such allowance.
    if (missCount > 1) return null;
    if (missCount > 0 && template.quality == ChordQualityToken.power) {
      return null;
    }

    // Extras: tones outside the base template. These may become named
    // extensions in the final chord identity.
    final base = required | optional;
    final extrasMask =
        (relMask & ~(base | penalty)) | functionalPenaltyExtensionsMask;

    // A bare triad plus the major sixth is a sixth chord (C6, Cm6); the add13
    // labeling of the same tones would duplicate the six-family template
    // under a name the symbol guide reserves for seventh chords. When the
    // sixth is the bass, the add13 label compresses into the slash and the
    // reading survives as the conventional triad-over-sixth symbol (A-C-E as
    // C/A), so only tones above the bass trigger the rejection.
    final isBareTriad =
        template.quality == ChordQualityToken.major ||
        template.quality == ChordQualityToken.minor;
    if (isBareTriad &&
        (extrasMask & (1 << majorSixthInterval)) != 0 &&
        bassInterval != majorSixthInterval) {
      return null;
    }

    final extensions = _extensionsFromExtras(
      extrasMask,
      has7: template.quality.isSeventhFamily,
      quality: template.quality,
    );

    // The seventh is what makes a chord a ninth, eleventh, or thirteenth.
    // Without that required seventh sounding, the same tones should be named
    // as add tones or sixth chords, not as a stacked seventh-family extension.
    if (_missesSeventhUnderStackedExtensions(
      template: template,
      missingRequiredMask: missingRequiredMask,
      extensions: extensions,
    )) {
      return null;
    }

    if (_flatFiveConflictsWithNaturalThirteenth(
      quality: template.quality,
      extensions: extensions,
      relMask: relMask,
      bassInterval: bassInterval,
    )) {
      return null;
    }

    final roles = ChordToneRoles.build(
      quality: template.quality,
      extensions: extensions,
      relMask: relMask,
    );

    var cost = 0.0;

    final vocabulary = _vocabularyCost(template.quality);
    if (vocabulary != 0) {
      cost += vocabulary;
      add('vocabulary rarity', vocabulary);
    }

    // Core tones are free; report them so downstream tone ledgers can show
    // what the name accounts for.
    add(
      'required tones',
      0,
      detail: 'count=${popCount(presentRequiredMask)}',
      intervals: presentRequiredMask,
    );
    if (presentOptionalMask != 0) {
      add(
        'optional tones',
        0,
        detail: 'count=${popCount(presentOptionalMask)}',
        intervals: presentOptionalMask,
      );
    }

    // A complete plain triad voiced over its added ninth in the bass is the
    // upper-structure slash idiom (D/E, C#/D#): the bass reads as an
    // independent pedal, not as chord color the name must justify.
    final isUpperTriadOverNinthBass =
        (template.quality == ChordQualityToken.major ||
            template.quality == ChordQualityToken.minor) &&
        bassInterval == majorSecondInterval &&
        extensions.length == 1 &&
        extensions.contains(ChordExtension.add9) &&
        (relMask & (1 << perfectFifthInterval)) != 0;

    final isStackedColor = extensions.length > 1;
    final isStackedChromaticAdd =
        isStackedColor &&
        (extensions.contains(ChordExtension.addFlat9) ||
            extensions.contains(ChordExtension.addSharp9));

    // Each color tone the name appends is priced by its role; tones with no
    // role are contradictions the name cannot account for.
    var colorCost = 0.0;
    var colorMask = 0;
    var unexplainedMask = 0;
    final colorDetails = reasons == null ? null : <String>[];
    for (var interval = 1; interval < 12; interval++) {
      if ((relMask & (1 << interval)) == 0) continue;
      final role = roles[interval];
      if (role == null) {
        unexplainedMask |= 1 << interval;
        continue;
      }
      final price = role == ChordToneRole.add9 && isUpperTriadOverNinthBass
          ? _upperTriadNinthBassCost
          : _tonePrice(
              role: role,
              quality: template.quality,
              relMask: relMask,
              roles: roles,
              isBassTone: interval == bassInterval,
              isStackedColor: isStackedColor,
              isStackedChromaticAdd: isStackedChromaticAdd,
            );
      if (price == 0) continue;
      colorCost += price;
      colorMask |= 1 << interval;
      colorDetails?.add('${role.name}=${price.toStringAsFixed(2)}');
    }
    if (colorCost != 0) {
      cost += colorCost;
      add(
        'color tones',
        colorCost,
        detail: colorDetails?.join(' '),
        intervals: colorMask,
      );
    }

    // A bare root-third-sixth set is better read as the relative minor's
    // triad; a sixth chord needs its fifth to anchor the sixth as color.
    final isBareFifthlessSixChord =
        template.quality.isSixFamily &&
        (relMask & (1 << perfectFifthInterval)) == 0 &&
        popCount(relMask) == 3;
    if (isBareFifthlessSixChord) {
      cost += _sixChordNoFifthSurcharge;
      add('fifthless sixth', _sixChordNoFifthSurcharge);
    }

    // A power chord is only a credible reading when the bare fifth plus its
    // named colors account for every sounding tone; a leftover tone means
    // some other harmony is in play.
    if (unexplainedMask != 0 && template.quality == ChordQualityToken.power) {
      return null;
    }

    if (unexplainedMask != 0) {
      final unexplainedCost = popCount(unexplainedMask) * _unexplainedToneCost;
      cost += unexplainedCost;
      add(
        'penalty tones',
        unexplainedCost,
        detail: 'count=${popCount(unexplainedMask)}',
        intervals: unexplainedMask,
      );
    }

    if (missingRequiredMask != 0) {
      var missingCost = 0.0;
      for (var interval = 1; interval < 12; interval++) {
        if ((missingRequiredMask & (1 << interval)) != 0) {
          missingCost += _missingEssentialCost(interval);
        }
      }
      cost += missingCost;
      add(
        'missing required',
        missingCost,
        detail: 'count=$missCount',
        intervals: missingRequiredMask,
      );
    }

    final bassCost = isUpperTriadOverNinthBass
        ? 0.0
        : _bassPlacementCost(roles[bassInterval], template.quality);
    if (bassCost != 0) {
      cost += bassCost;
      add('bass fit', bassCost, detail: 'interval=$bassInterval');
    }

    return _PricedTemplate(cost: cost, extensions: extensions, roles: roles);
  }

  /// How readily a musician reaches for this quality name. Everyday names
  /// (major, minor, 7, m7, maj7, sus4, 6ths) are free; a rare name has to be
  /// much cheaper at explaining the tones than a common one to win.
  static double _vocabularyCost(ChordQualityToken quality) {
    return switch (quality) {
      ChordQualityToken.sus2 ||
      ChordQualityToken.sus2sus4 ||
      ChordQualityToken.diminished ||
      ChordQualityToken.augmented ||
      ChordQualityToken.diminished7 ||
      ChordQualityToken.halfDiminished7 ||
      ChordQualityToken.minorMajor7 ||
      ChordQualityToken.dominant7sus4 => _vocabularyMarked,
      ChordQualityToken.dominant7Flat5 ||
      ChordQualityToken.dominant7Sharp5 ||
      ChordQualityToken.major7sus4 ||
      ChordQualityToken.major7Sharp5 => _vocabularyUncommon,
      _ when quality.isRareVocabulary => _vocabularyRare,
      _ => 0,
    };
  }

  static bool _isDominantFamily(ChordQualityToken quality) {
    return switch (quality) {
      ChordQualityToken.dominant7 ||
      ChordQualityToken.dominant7sus2 ||
      ChordQualityToken.dominant7sus4 ||
      ChordQualityToken.dominant7Flat5 ||
      ChordQualityToken.dominant7Sharp5 => true,
      _ => false,
    };
  }

  /// Hosts where a sharp eleven is idiomatic color rather than a marked
  /// alteration: Lydian majors, dominants, minor family (Dorian #11), and
  /// sus4 frames (where the split-fourth surcharge prices the clash
  /// separately). On diminished and sus2 hosts it stays multiplied.
  static bool _isSharpElevenFriendly(ChordQualityToken quality) {
    return _isDominantFamily(quality) ||
        switch (quality) {
          ChordQualityToken.major ||
          ChordQualityToken.major6 ||
          ChordQualityToken.major7 ||
          ChordQualityToken.minor ||
          ChordQualityToken.minor6 ||
          ChordQualityToken.minor7 ||
          ChordQualityToken.minorMajor7 ||
          ChordQualityToken.sus4 ||
          ChordQualityToken.major7sus4 ||
          ChordQualityToken.sus2sus4 => true,
          _ => false,
        };
  }

  static double _tonePrice({
    required ChordToneRole role,
    required ChordQualityToken quality,
    required int relMask,
    required Map<int, ChordToneRole> roles,
    required bool isBassTone,
    required bool isStackedColor,
    required bool isStackedChromaticAdd,
  }) {
    final hasNinth = (relMask & (1 << majorSecondInterval)) != 0;
    final hasMajorThirdRole = roles[majorThirdInterval] == ChordToneRole.major3;

    switch (role) {
      case ChordToneRole.root:
      case ChordToneRole.sus2:
      case ChordToneRole.minor3:
      case ChordToneRole.major3:
      case ChordToneRole.sus4:
      case ChordToneRole.flat5:
      case ChordToneRole.perfect5:
      case ChordToneRole.sharp5:
      case ChordToneRole.sixth:
      case ChordToneRole.dim7:
      case ChordToneRole.flat7:
      case ChordToneRole.major7:
        return 0;

      case ChordToneRole.nine:
        return _naturalExtensionPrice(_priceNine, quality);
      case ChordToneRole.add9:
        return _naturalExtensionPrice(_priceAdd9, quality);
      case ChordToneRole.eleven:
        // An 11 with no 9 below it is really an add-tone wearing a stack
        // name, unless the 11 is the bass itself (the sus-pedal idiom, e.g.
        // Am7/D, needs no stack support); an 11 against a major third is the
        // classic avoid-tone clash.
        return _naturalExtensionPrice(_priceEleven, quality) +
            (hasNinth || isBassTone ? 0 : _unsupportedElevenSurcharge) +
            (hasMajorThirdRole ? _elevenOverMajorThirdSurcharge : 0);
      case ChordToneRole.add11:
        return _naturalExtensionPrice(_priceAdd11, quality) +
            (hasMajorThirdRole ? _elevenOverMajorThirdSurcharge : 0);
      case ChordToneRole.thirteen:
        return _naturalExtensionPrice(_priceThirteen, quality) +
            (hasNinth ? 0 : _unsupportedThirteenSurcharge) +
            (_hasSharpFifthRole(roles) ? _splitSharpFiveThirteenSurcharge : 0);
      case ChordToneRole.add13:
        return _naturalExtensionPrice(_priceAdd13, quality);

      case ChordToneRole.flat9:
      case ChordToneRole.sharp9:
      case ChordToneRole.sharp11:
      case ChordToneRole.flat13:
      case ChordToneRole.splitMinor3:
      case ChordToneRole.addSharp9:
        return _alteredTonePrice(
          role: role,
          quality: quality,
          relMask: relMask,
          roles: roles,
          isStackedColor: isStackedColor,
          isStackedChromaticAdd: isStackedChromaticAdd,
        );
    }
  }

  static double _alteredTonePrice({
    required ChordToneRole role,
    required ChordQualityToken quality,
    required int relMask,
    required Map<int, ChordToneRole> roles,
    required bool isStackedColor,
    required bool isStackedChromaticAdd,
  }) {
    bool has(int interval) => (relMask & (1 << interval)) != 0;

    var price = switch (role) {
      ChordToneRole.flat9 => _priceFlat9,
      ChordToneRole.sharp9 => _priceSharp9,
      ChordToneRole.sharp11 => _priceSharp11,
      ChordToneRole.flat13 => _priceFlat13,
      _ => _priceSplitThird,
    };
    if (role == ChordToneRole.sharp11 && _hasNaturalFourthRole(roles)) {
      price += _splitFourthSurcharge;
    }
    // A #11 is color above an occupied fifth slot; with no fifth-slot tone
    // sounding at all, the tritone reads as the altered fifth instead
    // (C-E-Gb is C(b5), not a fifthless Cadd#11). A natural 13 keeps the
    // #11 reading (C13#11 shells; the b5-plus-13 template is rejected
    // outright), as do fifthless major-family Lydian stacks with a
    // supporting ninth (Dbmaj9#11).
    final majorFamilyLydianStack =
        has(majorSecondInterval) &&
        switch (quality) {
          ChordQualityToken.major ||
          ChordQualityToken.major6 ||
          ChordQualityToken.major7 => true,
          _ => false,
        };
    if (role == ChordToneRole.sharp11 &&
        !has(perfectFifthInterval) &&
        !has(minorSixthInterval) &&
        !has(majorSixthInterval) &&
        !majorFamilyLydianStack) {
      price += _sharpElevenEmptyFifthSurcharge;
    }
    // Same fifth-slot logic for the flat thirteen: with no fifth-slot tone
    // sounding, the m6 interval reads as a sharp five (G-B-F-A-D# is G7#5(9),
    // not a fifthless G9b13). On a minor-third flat-five host (m7b5, dim) the
    // flat five occupies the slot and the sharp-five re-reading would respell
    // the whole chord, so Em7(b5,b13) keeps its plain name; major-third
    // flat-five hosts keep the surcharge because the #5/#11 reading stays
    // available (whole-tone sets prefer C9(#5,#11) over C9(b5,b13)).
    // Minor-major sevenths are exempt: the fifthless m(maj7)b13 is the
    // harmonic-minor tonic idiom and has no competing sharp-five reading.
    final flatFiveMinorHost =
        roles[tritoneInterval] == ChordToneRole.flat5 &&
        roles[minorThirdInterval] == ChordToneRole.minor3;
    if (role == ChordToneRole.flat13 &&
        !has(perfectFifthInterval) &&
        !flatFiveMinorHost &&
        quality != ChordQualityToken.minorMajor7) {
      price += _flatThirteenEmptyFifthSurcharge;
    }
    if ((role == ChordToneRole.flat9 || role == ChordToneRole.sharp9) &&
        _hasNaturalSecondRole(roles)) {
      price += _splitSecondSurcharge;
    }
    if (role == ChordToneRole.flat13 && _hasNaturalSixthRole(roles)) {
      price += _splitSixthSurcharge;
    }
    // A b9 stacked among other colors on a major sixth or seventh chord is
    // the alt sound without its dominant context; musicians do not write
    // F#6(b9,#11). As the single color it stays the harmonic-minor gesture
    // (C6b9, Cmaddb9), like the add-b9 Phrygian color on a bare triad.
    if (role == ChordToneRole.flat9 &&
        isStackedColor &&
        switch (quality) {
          ChordQualityToken.major6 ||
          ChordQualityToken.major7 ||
          ChordQualityToken.major7Flat5 ||
          ChordQualityToken.major7Sharp5 => true,
          _ => false,
        }) {
      price += _flatNineMajorHostSurcharge;
    }
    if (role == ChordToneRole.flat9 &&
        quality == ChordQualityToken.minorMajor7 &&
        roles[perfectFifthInterval] != ChordToneRole.perfect5 &&
        roles.containsValue(ChordToneRole.eleven)) {
      price += _minorMajorFlatNineElevenSurcharge;
    }
    // A lone chromatic add is the Phrygian gesture (Cmaddb9); stacked among
    // other colors it reads as alt tension the name fails to integrate
    // (F#(addb9,#11,add13)).
    if (isStackedChromaticAdd &&
        (role == ChordToneRole.flat9 || role == ChordToneRole.splitMinor3)) {
      price += _stackedChromaticAddSurcharge;
    }
    // The alt-palette discount belongs to sounding dominants; a dominant name
    // whose flat seventh is missing is a phantom host, and its alterations
    // pay the off-dominant rate like any other quality's.
    final soundingDominant =
        _isDominantFamily(quality) && has(minorSeventhInterval);
    final multiplied =
        !soundingDominant &&
        !(role == ChordToneRole.sharp11 && _isSharpElevenFriendly(quality));
    return multiplied ? price * _offDominantAlterationMultiplier : price;
  }

  static double _naturalExtensionPrice(double base, ChordQualityToken quality) {
    return _isMarkedExtensionHost(quality)
        ? base * _markedHostExtensionMultiplier
        : base;
  }

  /// Qualities on which upper extensions are rare enough that a stacked or
  /// added color tone reads as a stretch rather than everyday vocabulary.
  /// Dominants (including sus dominants), plain major/minor sevenths, and
  /// sixth chords keep flat extension prices.
  static bool _isMarkedExtensionHost(ChordQualityToken quality) {
    return switch (quality) {
      ChordQualityToken.diminished ||
      ChordQualityToken.augmented ||
      ChordQualityToken.diminished7 ||
      ChordQualityToken.halfDiminished7 ||
      ChordQualityToken.minorMajor7 ||
      ChordQualityToken.minorSharp5 ||
      ChordQualityToken.minor7Sharp5 ||
      ChordQualityToken.majorFlat5 ||
      ChordQualityToken.major7Flat5 ||
      ChordQualityToken.major7Sharp5 ||
      ChordQualityToken.major7sus2 ||
      ChordQualityToken.sus2 ||
      ChordQualityToken.sus2sus4 ||
      ChordQualityToken.dominant7sus2 => true,
      _ => false,
    };
  }

  static bool _hasNaturalFourthRole(Map<int, ChordToneRole> roles) {
    return roles.containsValue(ChordToneRole.sus4) ||
        roles.containsValue(ChordToneRole.eleven) ||
        roles.containsValue(ChordToneRole.add11);
  }

  static bool _hasNaturalSecondRole(Map<int, ChordToneRole> roles) {
    return roles.containsValue(ChordToneRole.sus2) ||
        roles.containsValue(ChordToneRole.nine) ||
        roles.containsValue(ChordToneRole.add9);
  }

  static bool _hasNaturalSixthRole(Map<int, ChordToneRole> roles) {
    return roles.containsValue(ChordToneRole.sixth) ||
        roles.containsValue(ChordToneRole.thirteen) ||
        roles.containsValue(ChordToneRole.add13);
  }

  static bool _hasSharpFifthRole(Map<int, ChordToneRole> roles) {
    return roles.containsValue(ChordToneRole.sharp5);
  }

  /// True when a seventh-family name is missing its seventh while promoting
  /// stacked natural extensions (a 9, 11, or 13 in the symbol). Under the
  /// [isSeventhFamily] guard, interval 9 can only be a required diminished
  /// seventh, never a sixth.
  static bool _missesSeventhUnderStackedExtensions({
    required ChordTemplate template,
    required int missingRequiredMask,
    required Set<ChordExtension> extensions,
  }) {
    if (!template.quality.isSeventhFamily) return false;
    const seventhMask =
        (1 << majorSixthInterval) |
        (1 << minorSeventhInterval) |
        (1 << majorSeventhInterval);
    if ((missingRequiredMask & seventhMask) == 0) return false;
    return extensions.contains(ChordExtension.nine) ||
        extensions.contains(ChordExtension.eleven) ||
        extensions.contains(ChordExtension.thirteen);
  }

  /// Price of a required tone the voicing omits, by the degree it would fill.
  /// A perfect fifth is routinely dropped; a third, seventh, or the tone that
  /// defines a suspension or altered fifth is the name's identity.
  static double _missingEssentialCost(int interval) {
    return switch (interval) {
      2 || 5 => _missingSusToneCost,
      3 || 4 => _missingThirdCost,
      6 || 8 => _missingAlteredFifthCost,
      7 => _missingFifthCost,
      _ => _missingSeventhCost,
    };
  }

  static double _bassPlacementCost(
    ChordToneRole? bassRole,
    ChordQualityToken quality,
  ) {
    // Diminished and augmented chords invert freely; their fifth in the bass
    // is a plain core tone, unlike the altered fifth of a m#5 or 7#5.
    final fifthIsDefinitional = switch (quality) {
      ChordQualityToken.diminished ||
      ChordQualityToken.diminished7 ||
      ChordQualityToken.halfDiminished7 ||
      ChordQualityToken.augmented => true,
      _ => false,
    };
    if (bassRole == null) return _bassUnexplainedCost;
    return switch (bassRole) {
      ChordToneRole.root => 0,
      ChordToneRole.sus2 || ChordToneRole.sus4 => _bassSusToneCost,
      ChordToneRole.flat5 || ChordToneRole.sharp5 =>
        fifthIsDefinitional ? _bassCoreToneCost : _bassAlteredFifthCost,
      ChordToneRole.minor3 ||
      ChordToneRole.major3 ||
      ChordToneRole.perfect5 ||
      ChordToneRole.sixth ||
      ChordToneRole.dim7 ||
      ChordToneRole.flat7 ||
      ChordToneRole.major7 => _bassCoreToneCost,
      ChordToneRole.nine ||
      ChordToneRole.eleven ||
      ChordToneRole.thirteen => _bassNaturalColorCost,
      ChordToneRole.add9 ||
      ChordToneRole.add11 ||
      ChordToneRole.add13 => _bassAddToneCost,
      ChordToneRole.flat9 ||
      ChordToneRole.sharp9 ||
      ChordToneRole.sharp11 ||
      ChordToneRole.flat13 ||
      ChordToneRole.splitMinor3 ||
      ChordToneRole.addSharp9 => _bassAlteredColorCost,
    };
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

    if (quality == ChordQualityToken.major7 &&
        _hasMajorSeventhSharpNineColor(relMask)) {
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

  static bool _hasMajorSeventhSharpNineColor(int relMask) {
    const majorThirdBit = 1 << majorThirdInterval;
    const sharpNineBit = 1 << minorThirdInterval;
    const majorSeventhBit = 1 << majorSeventhInterval;

    return (relMask & majorThirdBit) != 0 &&
        (relMask & sharpNineBit) != 0 &&
        (relMask & majorSeventhBit) != 0;
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

  static bool _flatFiveConflictsWithNaturalThirteenth({
    required ChordQualityToken quality,
    required Set<ChordExtension> extensions,
    required int relMask,
    required int bassInterval,
  }) {
    final isFlatFiveQuality =
        quality == ChordQualityToken.dominant7Flat5 ||
        quality == ChordQualityToken.major7Flat5;
    if (!isFlatFiveQuality) return false;

    // With a natural thirteenth present, the tritone usually functions as #11
    // color rather than a literal b5 core tone: C-E-Bb-D-F#-A -> C13#11.
    // If the perfect fifth is absent, the flat seventh is in the bass, and the
    // extension stack is the clean 9 + 13 color, the same tritone can be the
    // defining altered fifth: Eb-G-Db-F-A-C -> Eb13b5/Db. Keep altered/split
    // ninth stacks on the sharper #11 side.
    if ((relMask & (1 << perfectFifthInterval)) == 0 &&
        bassInterval == minorSeventhInterval &&
        extensions.length == 2 &&
        extensions.contains(ChordExtension.nine) &&
        extensions.contains(ChordExtension.thirteen)) {
      return false;
    }
    return extensions.contains(ChordExtension.thirteen) ||
        extensions.contains(ChordExtension.add13);
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
  final List<CostReason>? reasons;

  const _Evaluated({
    required this.candidate,
    required this.template,
    required this.reasons,
  });
}

class _PricedTemplate {
  final double cost;
  final Set<ChordExtension> extensions;
  final Map<int, ChordToneRole> roles;

  const _PricedTemplate({
    required this.cost,
    required this.extensions,
    required this.roles,
  });
}
