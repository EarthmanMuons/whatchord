import 'dart:math' as math;

import 'package:whatchord/features/history/history_domain.dart';
import 'package:whatchord/features/theory/domain/theory_domain.dart';

import '../models/key_estimate.dart';
import 'key_detector.dart';
import 'key_space.dart';

/// Progression-pattern key detection (design plan section 2e): scores chord
/// _transitions_ instead of chord contents, because motion between functions
/// carries far more key information than any single sonority.
///
/// Per event, each of the 24 keys is scored for the patterns the latest
/// transition completes under that key's functional reading (function is
/// key-relative, so the same transition reads differently under each tonic
/// hypothesis):
///
/// - Authentic cadence: dominant-family on the fifth degree resolving to a
///   tonic-quality chord, the strongest single signal. A plain major triad on
///   V scores less (no tritone); a root-position resolution scores a bonus.
///   The tonic quality set includes dominant7 in major, so a blues I7 counts
///   as home rather than as V-of-IV.
/// - Leading-tone diminished resolving to the tonic.
/// - ii to V motion, plus a completion bonus when it lands as ii-V-I.
/// - Deceptive cadence (V to vi, major keys).
/// - Secondary-dominant resolution onto any diatonic degree.
/// - Bass falling a fifth onto the tonic, quality-independent.
///
/// - Plagal return (IV to I, including the blues IV7 to I7), the signal that
///   breaks the blues symmetry: I7 to IV7 reads as a cadence into the
///   subdominant key, and only the return home distinguishes the true tonic.
///
/// Scores decay on elapsed time; contributions are weighted by the resolving
/// event's hold duration and recognizer confidence, like the other detectors.
/// Unlike the per-event-normalized evidence model, confidence here is the
/// decayed weighted sum of pattern points: patterns are sparse, and a recent
/// cadence must keep its full vote until decay fades it rather than being
/// diluted by pattern-less transitions.
class ProgressionKeyDetector implements KeyDetector {
  final double cadencePoints;
  final double cadenceTriadPoints;
  final double rootPositionBonusPoints;
  final double leadingTonePoints;
  final double iiToVPoints;
  final double iiVICompletionPoints;
  final double deceptivePoints;
  final double plagalPoints;
  final double secondaryResolutionPoints;
  final double bassFifthPoints;

  final bool confidenceWeighted;
  final bool durationWeighted;

  /// Score half-life; null disables decay.
  final Duration? decayHalfLife;
  final int minEvents;
  final double marginFloor;

  final List<double> _scores = List.filled(24, 0);
  int _eventCount = 0;
  DateTime? _lastTimestamp;
  ChordIdentity? _previous;
  ChordIdentity? _previous2;

  ProgressionKeyDetector({
    this.cadencePoints = 5,
    this.cadenceTriadPoints = 3,
    this.rootPositionBonusPoints = 1,
    this.leadingTonePoints = 4,
    this.iiToVPoints = 2,
    this.iiVICompletionPoints = 3,
    this.deceptivePoints = 2,
    this.plagalPoints = 2,
    this.secondaryResolutionPoints = 1,
    this.bassFifthPoints = 1,
    this.confidenceWeighted = true,
    this.durationWeighted = true,
    this.decayHalfLife = const Duration(seconds: 30),
    this.minEvents = 3,
    this.marginFloor = 0.5,
  });

  @override
  String get name => 'progression';

  @override
  String get configuration =>
      'points=$cadencePoints/$cadenceTriadPoints/+$rootPositionBonusPoints/'
      '$leadingTonePoints/$iiToVPoints/$iiVICompletionPoints/'
      '$deceptivePoints/$plagalPoints/$secondaryResolutionPoints/'
      '$bassFifthPoints '
      'confidenceWeighted=$confidenceWeighted '
      'durationWeighted=$durationWeighted '
      'decayHalfLifeMs=${decayHalfLife?.inMilliseconds} '
      'minEvents=$minEvents marginFloor=$marginFloor';

  @override
  void reset() {
    _scores.fillRange(0, 24, 0);
    _eventCount = 0;
    _lastTimestamp = null;
    _previous = null;
    _previous2 = null;
  }

  @override
  KeyEstimateFrame onEvent(ChordEvent event) {
    _decayTo(event.timestamp);
    _eventCount += 1;

    final current = event.identity;
    final previous = _previous;
    final weight = _eventWeight(event);
    if (previous != null && weight > 0 && previous != current) {
      for (var k = 0; k < 24; k++) {
        _scores[k] +=
            weight *
            _transitionPoints(
              KeySpace.canonicalTonalities[k],
              _previous2,
              previous,
              current,
            );
      }
    }
    _previous2 = previous;
    _previous = current;

    final ranked = _rankKeys();
    if (ranked.isEmpty || _eventCount < minEvents) {
      return KeyEstimateFrame.abstain(ranked);
    }
    final margin = ranked.length < 2
        ? double.infinity
        : ranked[0].confidence - ranked[1].confidence;
    if (ranked[0].confidence <= 0 || margin < marginFloor) {
      return KeyEstimateFrame.abstain(ranked);
    }
    return KeyEstimateFrame(ranked: ranked, claim: ranked.first);
  }

  double _transitionPoints(
    Tonality key,
    ChordIdentity? older,
    ChordIdentity from,
    ChordIdentity to,
  ) {
    final tonic = key.tonicPitchClass;
    int interval(int pc) => (pc - tonic + 12) % 12;
    final fromInterval = interval(from.rootPc);
    final toInterval = interval(to.rootPc);
    var points = 0.0;

    final toIsTonic =
        toInterval == 0 && KeySpace.tonicQualities(key).contains(to.quality);

    if (toIsTonic && fromInterval == 7) {
      if (_dominantFamily.contains(from.quality)) {
        points += cadencePoints;
      } else if (from.quality == ChordQualityToken.major) {
        points += cadenceTriadPoints;
      }
      if (points > 0 && !from.hasSlashBass && !to.hasSlashBass) {
        points += rootPositionBonusPoints;
      }
      // ii-V-I completion: the chord before the dominant sat on the second
      // degree with pre-dominant quality.
      if (older != null &&
          interval(older.rootPc) == 2 &&
          _predominantFamily.contains(older.quality)) {
        points += iiVICompletionPoints;
      }
    }

    if (toIsTonic &&
        fromInterval == 11 &&
        _leadingToneFamily.contains(from.quality)) {
      points += leadingTonePoints;
    }

    if (fromInterval == 2 &&
        toInterval == 7 &&
        _predominantFamily.contains(from.quality) &&
        (_dominantFamily.contains(to.quality) ||
            to.quality == ChordQualityToken.major)) {
      points += iiToVPoints;
    }

    if (toIsTonic &&
        fromInterval == 5 &&
        (from.quality == ChordQualityToken.major ||
            from.quality == ChordQualityToken.dominant7 ||
            from.quality == ChordQualityToken.minor)) {
      points += plagalPoints;
    }

    if (key.isMajor &&
        fromInterval == 7 &&
        toInterval == 9 &&
        _dominantFamily.contains(from.quality) &&
        (to.quality == ChordQualityToken.minor ||
            to.quality == ChordQualityToken.minor7)) {
      points += deceptivePoints;
    }

    // Any dominant falling a fifth onto a diatonic degree confirms the key's
    // functional fabric (secondary dominants resolving); the tonic landing is
    // already covered by the cadence rule above.
    if (!toIsTonic &&
        _dominantFamily.contains(from.quality) &&
        (from.rootPc - to.rootPc + 12) % 12 == 7 &&
        (KeySpace.scaleMask(key) & (1 << to.rootPc)) != 0) {
      points += secondaryResolutionPoints;
    }

    if (interval(from.bassPc) == 7 && interval(to.bassPc) == 0) {
      points += bassFifthPoints;
    }

    return points;
  }

  double _eventWeight(ChordEvent event) {
    var weight = durationWeighted
        ? event.duration.inMilliseconds / 1000.0
        : 1.0;
    if (confidenceWeighted) weight *= _identityConfidence(event);
    return weight;
  }

  static double _identityConfidence(ChordEvent event) {
    if (event.candidates.length < 2) return 1.0;
    final gap = event.candidates[1].cost - event.candidates.first.cost;
    return (gap / ChordCandidateRanking.nearTieWindow).clamp(0.0, 1.0);
  }

  void _decayTo(DateTime timestamp) {
    final halfLife = decayHalfLife;
    final last = _lastTimestamp;
    _lastTimestamp = timestamp;
    if (halfLife == null || last == null) return;
    final elapsedMs = timestamp.difference(last).inMilliseconds;
    if (elapsedMs <= 0) return;
    final factor = math.pow(0.5, elapsedMs / halfLife.inMilliseconds) as double;
    for (var k = 0; k < 24; k++) {
      _scores[k] *= factor;
    }
  }

  List<KeyEstimate> _rankKeys() {
    if (_scores.every((score) => score == 0)) return const [];
    final estimates = <KeyEstimate>[
      for (var k = 0; k < 24; k++)
        KeyEstimate(
          tonality: KeySpace.canonicalTonalities[k],
          confidence: _scores[k],
        ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    return estimates;
  }

  static const Set<ChordQualityToken> _dominantFamily = {
    ChordQualityToken.dominant7,
    ChordQualityToken.dominant7sus2,
    ChordQualityToken.dominant7sus4,
    ChordQualityToken.dominant7Flat5,
    ChordQualityToken.dominant7Sharp5,
  };

  /// Pre-dominant qualities on the second degree: ii/ii7 in major, ii°/ii-7b5
  /// in minor.
  static const Set<ChordQualityToken> _predominantFamily = {
    ChordQualityToken.minor,
    ChordQualityToken.minor7,
    ChordQualityToken.diminished,
    ChordQualityToken.halfDiminished7,
  };

  static const Set<ChordQualityToken> _leadingToneFamily = {
    ChordQualityToken.diminished,
    ChordQualityToken.diminished7,
    ChordQualityToken.halfDiminished7,
  };
}
