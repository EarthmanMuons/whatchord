import 'dart:math' as math;

/// Summary statistics for a set of timing samples (microseconds per unit).
class Stats {
  Stats(List<double> samples) : samples = List.unmodifiable(samples..sort());

  final List<double> samples;

  int get n => samples.length;

  double get mean => samples.reduce((a, b) => a + b) / n;

  double get median {
    final mid = n ~/ 2;
    return n.isOdd ? samples[mid] : (samples[mid - 1] + samples[mid]) / 2;
  }

  double get min => samples.first;
  double get max => samples.last;

  /// Sample standard deviation (Bessel-corrected).
  double get stddev {
    if (n < 2) return 0;
    final m = mean;
    final ss = samples.fold(0.0, (acc, x) => acc + (x - m) * (x - m));
    return math.sqrt(ss / (n - 1));
  }

  /// Half-width of the 95% confidence interval on the mean, relative to the
  /// mean. This is the convergence signal: it shrinks as samples accumulate and
  /// as variance settles. (1.96 = normal approximation, adequate at the n >= 30
  /// sample floor, where the exact Student-t multiplier is 2.045.)
  double get relCi95 {
    if (n < 2 || mean == 0) return double.infinity;
    return 1.96 * stddev / math.sqrt(n) / mean;
  }

  /// When [targetRelCi] is given, emits `converged`: whether the interval met
  /// the target rather than stopping on a run cap or time budget.
  Map<String, Object?> toJson({double? targetRelCi}) => <String, Object?>{
    'mean': mean,
    'median': median,
    'stddev': stddev,
    'min': min,
    'max': max,
    'n': n,
    'relCi95': relCi95,
    if (targetRelCi != null) 'converged': relCi95 <= targetRelCi,
  };
}

/// Collects samples of [sampleUs] adaptively, like hyperfine/Criterion: run a
/// few warmups, then keep sampling until the mean's 95% CI is within
/// [targetRelCi] (default 1.5%), bounded by [minRuns]/[maxRuns] and a wall-clock
/// [budget] so an expensive workload still terminates. The returned [Stats]
/// carries the spread so callers can report stddev and whether it converged.
Stats collect(
  double Function() sampleUs, {
  int warmup = 5,
  int minRuns = 30,
  int maxRuns = 300,
  double targetRelCi = 0.015,
  Duration budget = const Duration(seconds: 20),
}) {
  for (var i = 0; i < warmup; i++) {
    sampleUs();
  }
  final samples = <double>[];
  final sw = Stopwatch()..start();
  while (true) {
    samples.add(sampleUs());
    if (samples.length >= minRuns &&
        Stats(samples.toList()).relCi95 <= targetRelCi) {
      break;
    }
    if (samples.length >= maxRuns || sw.elapsed >= budget) break;
  }
  return Stats(samples);
}
