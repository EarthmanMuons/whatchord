import 'dart:math' as math;

import 'package:whatchord/features/history/history_domain.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';

import '../models/key_estimate.dart';
import 'hybrid_key_detector.dart';
import 'key_detector.dart';
import 'key_profiles.dart';
import 'key_space.dart';

/// Hidden Markov key detection (design plan section 2c): the key is a hidden
/// state over the 24-key space, observed through the hybrid detector's
/// per-key scores.
///
/// Per event, the filtered posterior is updated with the causal forward
/// algorithm (never Viterbi, which needs the future the task definition
/// forbids): predict through the transition matrix, then weigh by an
/// emission distribution obtained as a softmax of the hybrid's scores at
/// [emissionTemperature]. The claim is the posterior's top key; confidence is
/// its actual posterior probability, and abstention triggers when the
/// posterior margin between the top two keys falls below [marginFloor].
///
/// The transition matrix is built from three parameters: [selfTransition] is
/// the probability mass of staying in the current key (the principled form of
/// the persistence that decay tuning and claim hysteresis approximated, log
/// entry 2026-07-07-07); the remaining mass goes to other keys weighted by
/// [fifthsDecay] per step of key-signature distance on the circle of fifths
/// (relative keys are at distance zero) and discounted by [modeSwitchFactor]
/// when the mode changes.
class HmmKeyDetector implements KeyDetector {
  /// The emission memory selects which timescale of key structure the
  /// detector reports (log entry 2026-07-07-16): one-second, effectively
  /// per-event emissions win on tonicization-scale labels (When in Rome),
  /// while long memory wins accuracy and stability on section-scale labels
  /// (Isophonics, ASAP). WhatChord's key indicator means the settled,
  /// section-level key (product decision, log entry 2026-07-07-17), so the
  /// shipped default is long memory; pass one second to evaluate against
  /// tonicization-scale ground truth. The harness references this constant
  /// so the CLI default cannot silently diverge.
  static const int defaultEmissionHalfLifeSeconds = 30;

  /// Shipped operating point on the calibration curve (log entries
  /// 2026-07-07-12 and -17): clean behavioral suite at the section-scale
  /// default.
  static const double defaultMarginFloor = 0.3;

  /// Emission blends for the shipped section-scale configuration (log entry
  /// 2026-07-07-18): the ablation factorial showed the functional and
  /// progression terms vote for exactly the tonicization-scale excursions
  /// the product absorbs, and removing them is a significant paired win on
  /// section-scale labels (and what finally fixed blues). The hybrid
  /// detector keeps its own nonzero blend defaults for tonicization-scale
  /// work; these constants configure only the HMM's emissions.
  static const double defaultEmissionFunctionalBlend = 0;
  static const double defaultEmissionProgressionBlend = 0;
  static const bool defaultEmissionConfidenceWeighted = false;

  final HybridKeyDetector _emissions;
  final double selfTransition;
  final double fifthsDecay;
  final double modeSwitchFactor;
  final double emissionTemperature;
  final int minEvents;
  final double marginFloor;

  late final List<List<double>> _transition = _buildTransitionMatrix();
  final List<double> _posterior = List.filled(24, 1 / 24);
  int _eventCount = 0;

  HmmKeyDetector({
    KeyProfilePair profiles = KeyProfilePair.albrechtShanahan,
    bool durationWeighted = true,
    Duration? decayHalfLife = const Duration(
      seconds: defaultEmissionHalfLifeSeconds,
    ),
    double? decayHalfLifeEvents,
    bool confidenceWeighted = defaultEmissionConfidenceWeighted,
    double functionalBlend = defaultEmissionFunctionalBlend,
    double progressionBlend = defaultEmissionProgressionBlend,
    this.selfTransition = 0.9,
    this.fifthsDecay = 0.5,
    this.modeSwitchFactor = 0.5,
    this.emissionTemperature = 0.25,
    this.minEvents = 3,
    this.marginFloor = defaultMarginFloor,
  }) : assert(selfTransition > 0 && selfTransition < 1),
       _emissions = HybridKeyDetector(
         profiles: profiles,
         durationWeighted: durationWeighted,
         decayHalfLife: decayHalfLife,
         decayHalfLifeEvents: decayHalfLifeEvents,
         confidenceWeighted: confidenceWeighted,
         functionalBlend: functionalBlend,
         progressionBlend: progressionBlend,
         minEvents: 1,
         marginFloor: 0,
       );

  @override
  String get name => 'hmm';

  @override
  String get configuration =>
      'selfTransition=$selfTransition fifthsDecay=$fifthsDecay '
      'modeSwitchFactor=$modeSwitchFactor '
      'emissionTemperature=$emissionTemperature '
      'minEvents=$minEvents marginFloor=$marginFloor '
      '| emissions: ${_emissions.configuration}';

  @override
  void reset() {
    _emissions.reset();
    _posterior.fillRange(0, 24, 1 / 24);
    _eventCount = 0;
  }

  @override
  KeyEstimateFrame onEvent(ChordEvent event) {
    final emissionFrame = _emissions.onEvent(event);
    _eventCount += 1;

    // Predict: posterior through the transition matrix.
    final predicted = List<double>.filled(24, 0);
    for (var from = 0; from < 24; from++) {
      final mass = _posterior[from];
      if (mass == 0) continue;
      final row = _transition[from];
      for (var to = 0; to < 24; to++) {
        predicted[to] += mass * row[to];
      }
    }

    // Update: weigh by the emission distribution and renormalize. An empty
    // emission frame (hybrid warming up) carries no information; the
    // prediction stands.
    if (emissionFrame.ranked.isNotEmpty) {
      final emission = _emissionDistribution(emissionFrame.ranked);
      var total = 0.0;
      for (var k = 0; k < 24; k++) {
        predicted[k] *= emission[k];
        total += predicted[k];
      }
      if (total > 0) {
        for (var k = 0; k < 24; k++) {
          predicted[k] /= total;
        }
      } else {
        predicted.setAll(0, _posterior);
      }
    }
    _posterior.setAll(0, predicted);

    final ranked = [
      for (var k = 0; k < 24; k++)
        KeyEstimate(
          tonality: KeySpace.canonicalTonalities[k],
          confidence: _posterior[k],
        ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));

    if (_eventCount < minEvents) return KeyEstimateFrame.abstain(ranked);
    final margin = ranked[0].confidence - ranked[1].confidence;
    if (margin < marginFloor) return KeyEstimateFrame.abstain(ranked);
    return KeyEstimateFrame(ranked: ranked, claim: ranked.first);
  }

  /// Softmax of the hybrid's scores at [emissionTemperature], as a 24-vector
  /// indexed by [KeySpace.index].
  List<double> _emissionDistribution(List<KeyEstimate> ranked) {
    final scores = List<double>.filled(24, double.negativeInfinity);
    for (final estimate in ranked) {
      scores[KeySpace.index(estimate.tonality)] = estimate.confidence;
    }
    final top = scores.reduce(math.max);
    final emission = List<double>.filled(24, 0);
    var total = 0.0;
    for (var k = 0; k < 24; k++) {
      if (scores[k] == double.negativeInfinity) continue;
      final value = math.exp((scores[k] - top) / emissionTemperature);
      emission[k] = value;
      total += value;
    }
    for (var k = 0; k < 24; k++) {
      emission[k] /= total;
    }
    return emission;
  }

  List<List<double>> _buildTransitionMatrix() {
    final tonalities = KeySpace.canonicalTonalities;
    final matrix = <List<double>>[];
    for (var from = 0; from < 24; from++) {
      final row = List<double>.filled(24, 0);
      var switchTotal = 0.0;
      for (var to = 0; to < 24; to++) {
        if (to == from) continue;
        var weight = math
            .pow(
              fifthsDecay,
              _signatureDistance(tonalities[from], tonalities[to]),
            )
            .toDouble();
        if (tonalities[from].isMajor != tonalities[to].isMajor) {
          weight *= modeSwitchFactor;
        }
        row[to] = weight;
        switchTotal += weight;
      }
      for (var to = 0; to < 24; to++) {
        row[to] = to == from
            ? selfTransition
            : (1 - selfTransition) * row[to] / switchTotal;
      }
      matrix.add(row);
    }
    return matrix;
  }

  /// Steps around the circle of fifths between two keys' signatures
  /// (0..6); relative major/minor pairs are at distance zero.
  static int _signatureDistance(Tonality a, Tonality b) {
    final delta = (_signaturePosition(a) - _signaturePosition(b)).abs() % 12;
    return math.min(delta, 12 - delta);
  }

  /// Position of the key's signature on the circle of fifths: the relative
  /// major's tonic mapped through pc * 7 mod 12 (7 fifths span the octave).
  static int _signaturePosition(Tonality tonality) {
    final relativeMajorPc = tonality.isMajor
        ? tonality.tonicPitchClass
        : (tonality.tonicPitchClass + 3) % 12;
    return (relativeMajorPc * 7) % 12;
  }
}
