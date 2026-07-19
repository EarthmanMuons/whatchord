import 'dart:math' as math;

/// Mean and deviation of a 12-bin vector, precomputed for Pearson
/// correlation.
class VectorStats {
  final List<double> values;
  final double mean;

  /// Root of the summed squared deviations (not the standard deviation; the
  /// 1/n factors cancel in Pearson correlation).
  final double deviation;

  VectorStats._(this.values, this.mean, this.deviation);

  factory VectorStats.of(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSquares = 0.0;
    for (final value in values) {
      sumSquares += (value - mean) * (value - mean);
    }
    return VectorStats._(values, mean, math.sqrt(sumSquares));
  }

  static final Map<List<double>, VectorStats> _profileCache = Map.identity();

  /// Stats for a constant key profile, computed once per profile list.
  factory VectorStats.ofProfile(List<double> profile) =>
      _profileCache.putIfAbsent(profile, () => VectorStats.of(profile));
}

/// Pearson correlation between [histogram] and [profile] rotated so the
/// profile's index 0 lands on [tonicPc]. Returns 0 when either side has no
/// variance.
double rotatedCorrelation(
  VectorStats histogram,
  VectorStats profile,
  int tonicPc,
) {
  if (histogram.deviation == 0 || profile.deviation == 0) return 0;
  var covariance = 0.0;
  for (var pc = 0; pc < 12; pc++) {
    covariance +=
        (histogram.values[pc] - histogram.mean) *
        (profile.values[(pc - tonicPc + 12) % 12] - profile.mean);
  }
  return covariance / (histogram.deviation * profile.deviation);
}
