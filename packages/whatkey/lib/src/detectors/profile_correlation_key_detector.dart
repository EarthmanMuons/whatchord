import 'dart:math' as math;

import 'package:whatchord/whatchord.dart';

import '../models/key_estimate.dart';
import 'key_detector.dart';
import 'key_profiles.dart';
import 'key_space.dart';

/// Profile-correlation key detection (Krumhansl-Schmuckler family): the floor
/// every later model must beat.
///
/// Maintains a 12-bin pitch-class histogram over the event stream and ranks
/// all 24 keys by Pearson correlation against a rotated key profile.
/// Weighting options follow the design plan: each event's pitch classes
/// contribute its hold duration (or a flat count), and the histogram decays
/// exponentially on elapsed time so older evidence fades regardless of
/// engagement boundaries.
///
/// Abstains until [minEvents] events have arrived, and whenever the
/// correlation margin between the best and second-best key falls below
/// [marginFloor]. Estimate confidence is the correlation coefficient.
class ProfileCorrelationKeyDetector implements KeyDetector {
  final KeyProfilePair profiles;
  final bool durationWeighted;

  /// Histogram half-life; null disables decay.
  final Duration? decayHalfLife;

  /// Event-count half-life: when set, the histogram decays by a fixed factor
  /// per event instead of on elapsed wall-clock time, normalizing the memory
  /// dial across corpora with different event rates (log entry
  /// 2026-07-07-15).
  final double? decayHalfLifeEvents;
  final int minEvents;
  final double marginFloor;

  final List<double> _histogram = List.filled(12, 0);
  int _eventCount = 0;
  DateTime? _lastTimestamp;

  ProfileCorrelationKeyDetector({
    this.profiles = KeyProfilePair.albrechtShanahan,
    this.durationWeighted = true,
    this.decayHalfLife = const Duration(seconds: 30),
    this.decayHalfLifeEvents,
    this.minEvents = 3,
    this.marginFloor = 0.05,
  });

  @override
  String get name => 'profile-correlation';

  @override
  String get configuration =>
      'profiles=${profiles.name} durationWeighted=$durationWeighted '
      'decayHalfLifeMs=${decayHalfLife?.inMilliseconds} '
      'decayHalfLifeEvents=$decayHalfLifeEvents '
      'minEvents=$minEvents marginFloor=$marginFloor';

  @override
  void reset() {
    _histogram.fillRange(0, 12, 0);
    _eventCount = 0;
    _lastTimestamp = null;
  }

  @override
  KeyEstimateFrame onEvent(ChordEvent event) {
    _decayTo(event.timestamp);
    _accumulate(event);
    _eventCount += 1;

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

  void _decayTo(DateTime timestamp) {
    final last = _lastTimestamp;
    _lastTimestamp = timestamp;
    if (last == null) return;
    final eventHalfLife = decayHalfLifeEvents;
    if (eventHalfLife != null) {
      _applyDecay(math.pow(0.5, 1 / eventHalfLife) as double);
      return;
    }
    final halfLife = decayHalfLife;
    if (halfLife == null) return;
    final elapsedMs = timestamp.difference(last).inMilliseconds;
    if (elapsedMs <= 0) return;
    _applyDecay(math.pow(0.5, elapsedMs / halfLife.inMilliseconds) as double);
  }

  void _applyDecay(double factor) {
    for (var pc = 0; pc < 12; pc++) {
      _histogram[pc] *= factor;
    }
  }

  void _accumulate(ChordEvent event) {
    final weight = durationWeighted
        ? event.duration.inMilliseconds / 1000.0
        : 1.0;
    if (weight <= 0) return;
    final mask = event.input.pcMask;
    for (var pc = 0; pc < 12; pc++) {
      if ((mask & (1 << pc)) != 0) _histogram[pc] += weight;
    }
  }

  List<KeyEstimate> _rankKeys() {
    final stats = _VectorStats.of(_histogram);
    if (stats.deviation == 0) return const [];

    final estimates = <KeyEstimate>[];
    for (final tonality in canonicalTonalities) {
      final profile = tonality.isMajor ? profiles.major : profiles.minor;
      estimates.add(
        KeyEstimate(
          tonality: tonality,
          confidence: _rotatedCorrelation(
            stats,
            profile,
            tonality.tonicPitchClass,
          ),
        ),
      );
    }
    estimates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return estimates;
  }

  /// Pearson correlation between the histogram and [profile] rotated so its
  /// index 0 lands on [tonicPc].
  double _rotatedCorrelation(
    _VectorStats histogram,
    List<double> profile,
    int tonicPc,
  ) {
    final profileStats = _VectorStats.of(profile);
    if (profileStats.deviation == 0) return 0;
    var covariance = 0.0;
    for (var pc = 0; pc < 12; pc++) {
      final profileValue = profile[(pc - tonicPc + 12) % 12];
      covariance +=
          (histogram.values[pc] - histogram.mean) *
          (profileValue - profileStats.mean);
    }
    return covariance / (histogram.deviation * profileStats.deviation);
  }

  /// See [KeySpace.canonicalTonalities]; kept here as the historical access
  /// point.
  static List<Tonality> get canonicalTonalities => KeySpace.canonicalTonalities;
}

class _VectorStats {
  final List<double> values;
  final double mean;

  /// Root of the summed squared deviations (not the standard deviation; the
  /// 1/n factors cancel in Pearson correlation).
  final double deviation;

  _VectorStats._(this.values, this.mean, this.deviation);

  factory _VectorStats.of(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSquares = 0.0;
    for (final value in values) {
      sumSquares += (value - mean) * (value - mean);
    }
    return _VectorStats._(values, mean, math.sqrt(sumSquares));
  }
}
