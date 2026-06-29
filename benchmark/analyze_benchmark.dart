// Offline performance baseline for the chord analysis engine.
//
// Measures, by replaying chord corpora through ChordAnalyzer.analyze():
//
//   1. Time, normalized to a fixed CPU reference workload (hardware-stable),
//      for two corpora: the adversarial reviewed-oracle corpus and the common
//      voicing pool (real-playing structures). Sampled adaptively until the
//      mean's 95% CI is tight; stddev reported.
//   2. Memory: allocation churn and retained heap delta (deterministic).
//   3. Algorithmic operation counters (deterministic; require the counters
//      compile-time define to be set).
//
// Memory and counters are measured on the oracle corpus only -- it is the
// adversarial stress case, so it is the most sensitive regression signal.
//
// Run from the repo root:
//
//   dart run --enable-vm-service --define=whatchord.counters=true \
//     benchmark/analyze_benchmark.dart
//
// Writes full results as JSON to benchmark/last_run.json and prints a summary.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:whatchord/features/theory/domain/theory_domain.dart';

import 'src/allocation_probe.dart';
import 'src/common_voicings.dart';
import 'src/corpus.dart';
import 'src/reference.dart';
import 'src/stats.dart';

// Convergence target for adaptive sampling: stop once the mean's 95% CI is
// within this fraction of the mean (or a budget/run cap is hit).
const double _targetRelCi = 0.015;

// The fast warm (cache-hit) pass is far below timer resolution per call, so each
// sample runs the whole corpus this many times and divides, lifting the timed
// region well above the microsecond clock granularity.
const int _warmBatch = 200;

const String _defaultOutPath = 'benchmark/last_run.json';
const String _baselinePath = 'benchmark/baseline.json';

// Accumulates the reference workload result so the compiler cannot elide it.
int _sink = 0;

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    _printUsage();
    return;
  }
  final outPath = _argValue(args, '--out=') ?? _defaultOutPath;

  final context = buildContext();
  final oracle = loadCorpus();
  final common = [for (final v in commonVoicings()) v.input];

  // Reference: one fixed CPU unit, measured once. Used only to normalize out
  // hardware speed; a slower machine inflates the engine and reference alike.
  final reference = collect(
    () => _timeMicros(() => _sink ^= referenceWork(referenceIterations)),
    budget: const Duration(seconds: 8),
    targetRelCi: _targetRelCi,
  );

  // --- Time, per corpus -----------------------------------------------------
  final (oracleCold, oracleWarm) = _measureCorpusTime(oracle, context);
  final (commonCold, commonWarm) = _measureCorpusTime(common, context);

  // --- Memory + counters: oracle corpus (the adversarial stress case) -------
  void oraclePass() {
    for (final input in oracle) {
      ChordAnalyzer.analyze(input, context: context);
    }
  }

  final probe = await AllocationProbe.connect();
  ChordAnalyzer.clearCache();
  // Baseline heap with an empty cache, then reset the accumulator so churn
  // covers only the pass. Retained-by-engine is the heap growth from caching
  // the corpus (the after/before heapUsage delta), not the whole isolate heap.
  final baselineHeap = (await probe.sample()).heapUsage;
  await probe.resetAndGc();
  oraclePass();
  final memory = await probe.sample();
  final retainedBytes = memory.heapUsage - baselineHeap;
  await probe.dispose();

  EngineCounters.reset();
  ChordAnalyzer.clearCache();
  oraclePass();
  final counters = EngineCounters.snapshot();

  if (_sink == 1) stderr.writeln(); // keep _sink observable; effectively never.

  final result = <String, Object?>{
    'meta': {
      'oracleSize': oracle.length,
      'commonSize': common.length,
      'dartVersion': Platform.version,
      'targetRelCi95': _targetRelCi,
      'referenceIterations': referenceIterations,
      'countersEnabled': kEngineCountersEnabled,
    },
    'referenceUs': reference.toJson(),
    // Compare normalized values across runs, not raw microseconds.
    'time': {
      'oracle': _timeJson(oracleCold, oracleWarm, reference),
      'common': _timeJson(commonCold, commonWarm, reference),
    },
    'memory': {
      'churnBytes': memory.churnBytes,
      'churnObjects': memory.churnObjects,
      'churnBytesPerCall': memory.churnBytes / oracle.length,
      'retainedBytes': retainedBytes,
      'liveHeapBytes': memory.heapUsage,
    },
    'counters': counters,
  };

  File(
    outPath,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  _printSummary(
    oracleSize: oracle.length,
    commonSize: common.length,
    reference: reference,
    oracleCold: oracleCold,
    oracleWarm: oracleWarm,
    commonCold: commonCold,
    commonWarm: commonWarm,
    memory: result['memory'] as Map<String, Object?>,
    counters: counters,
    countersEnabled: kEngineCountersEnabled,
  );
  _maybePrintComparison(outPath, result);
  stdout.writeln('Wrote $outPath');
}

/// Adaptively samples cold (cache-miss) and warm (cache-hit) per-call time for
/// [corpus]. Cold clears the cache outside the timed region; warm batches the
/// pass for timer resolution.
(Stats, Stats) _measureCorpusTime(
  List<ChordInput> corpus,
  AnalysisContext context,
) {
  final n = corpus.length;
  void pass() {
    for (final input in corpus) {
      ChordAnalyzer.analyze(input, context: context);
    }
  }

  final cold = collect(
    () {
      ChordAnalyzer.clearCache();
      return _timeMicros(pass) / n;
    },
    budget: const Duration(seconds: 30),
    targetRelCi: _targetRelCi,
  );

  ChordAnalyzer.clearCache();
  pass();
  final warm = collect(
    () {
      final us = _timeMicros(() {
        for (var b = 0; b < _warmBatch; b++) {
          pass();
        }
      });
      return us / (_warmBatch * n);
    },
    budget: const Duration(seconds: 8),
    targetRelCi: _targetRelCi,
  );

  return (cold, warm);
}

Map<String, Object?> _timeJson(Stats cold, Stats warm, Stats reference) => {
  'coldNormalized': cold.mean / reference.mean,
  'warmNormalized': warm.mean / reference.mean,
  // CI of a ratio of independent means, propagated in quadrature.
  'coldNormalizedRelCi95': _hypot(cold.relCi95, reference.relCi95),
  'warmNormalizedRelCi95': _hypot(warm.relCi95, reference.relCi95),
  'coldUsPerCall': cold.toJson(),
  'warmUsPerCall': warm.toJson(),
};

/// Prints a delta against the committed baseline, unless this run *is* the
/// baseline. Counters and churn are deterministic, so any change on the same
/// corpus is a real signal; normalized time changes beyond its CI are too.
void _maybePrintComparison(String outPath, Map<String, Object?> current) {
  if (outPath == _baselinePath) return;
  final file = File(_baselinePath);
  if (!file.existsSync()) return;
  final base = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  stdout.writeln('  vs baseline ($_baselinePath):');
  for (final key in ['oracleSize', 'commonSize']) {
    final b = _at(base, ['meta', key]);
    final c = _at(current, ['meta', key]);
    if (b != c) {
      stdout.writeln(
        '    $key differs ($b -> $c): per-call values are not comparable.'
        ' Regenerate the baseline.',
      );
    }
  }

  void cmp(String label, List<String> path, {int frac = 3, bool pct = true}) {
    final b = _at(base, path);
    final c = _at(current, path);
    if (b is! num || c is! num) return;
    final arrow = '${b.toStringAsFixed(frac)} -> ${c.toStringAsFixed(frac)}';
    final String change;
    if (c == b) {
      change = 'unchanged';
    } else if (pct && b != 0) {
      final p = (c - b) / b * 100;
      change = '${p >= 0 ? '+' : ''}${p.toStringAsFixed(1)}%';
    } else {
      final d = c - b;
      change = '${d >= 0 ? '+' : ''}$d';
    }
    stdout.writeln('    $label $arrow  ($change)');
  }

  cmp('oracle cold norm: ', ['time', 'oracle', 'coldNormalized'], frac: 5);
  cmp('oracle warm norm: ', ['time', 'oracle', 'warmNormalized'], frac: 5);
  cmp('common cold norm: ', ['time', 'common', 'coldNormalized'], frac: 5);
  cmp('common warm norm: ', ['time', 'common', 'warmNormalized'], frac: 5);
  cmp('churn bytes/call: ', ['memory', 'churnBytesPerCall'], frac: 0);
  cmp('retained bytes:   ', ['memory', 'retainedBytes'], frac: 0);
  for (final key in (current['counters'] as Map<String, Object?>).keys) {
    cmp('$key:'.padRight(18), ['counters', key], frac: 0, pct: false);
  }
}

Object? _at(Map<String, Object?> map, List<String> path) {
  Object? node = map;
  for (final key in path) {
    if (node is Map && node.containsKey(key)) {
      node = node[key];
    } else {
      return null;
    }
  }
  return node;
}

void _printUsage() {
  stdout.writeln('''
Chord engine performance benchmark.

Replays two corpora through ChordAnalyzer.analyze and reports normalized time
for each: the adversarial reviewed-oracle corpus and the common voicing pool.
Allocation memory and operation counters are reported for the oracle corpus.

Usage:
  tool/benchmark.sh [options]
  dart run --enable-vm-service --define=whatchord.counters=true \\
    benchmark/analyze_benchmark.dart [options]

Options:
  --out=PATH   Write results JSON to PATH (default: $_defaultOutPath).
               Use --out=$_baselinePath to update the committed baseline.
  -h, --help   Show this help and exit.

Unless --out points at the baseline, the run prints a delta against
$_baselinePath when it exists. Compare runs on the same corpora only;
regenerate the baseline after changing a corpus.

Memory measurement needs the VM service (--enable-vm-service) and the
operation counters need the whatchord.counters define; tool/benchmark.sh
sets both.''');
}

void _printSummary({
  required int oracleSize,
  required int commonSize,
  required Stats reference,
  required Stats oracleCold,
  required Stats oracleWarm,
  required Stats commonCold,
  required Stats commonWarm,
  required Map<String, Object?> memory,
  required Map<String, Object?> counters,
  required bool countersEnabled,
}) {
  String f(Object? v, int frac) => (v as num).toStringAsFixed(frac);

  void timeLine(String label, Stats s) {
    final norm = s.mean / reference.mean;
    final normRelCi = _hypot(s.relCi95, reference.relCi95);
    final conv = s.relCi95 <= _targetRelCi ? 'converged' : 'budget-capped';
    stdout.writeln(
      '      $label ${f(norm, 5)} norm +/-${f(normRelCi * 100, 1)}%'
      '  |  ${f(s.mean, 3)} +/- ${f(s.stddev, 3)} us/call'
      '  [n=${s.n}, +/-${f(s.relCi95 * 100, 1)}% CI95, $conv]',
    );
  }

  stdout.writeln('Chord engine benchmark');
  stdout.writeln('  time (normalized to reference workload):');
  stdout.writeln('    oracle corpus ($oracleSize voicings):');
  timeLine('cold (cache miss):', oracleCold);
  timeLine('warm (cache hit): ', oracleWarm);
  stdout.writeln('    common voicings ($commonSize):');
  timeLine('cold (cache miss):', commonCold);
  timeLine('warm (cache hit): ', commonWarm);
  stdout.writeln('  memory (oracle corpus, cold pass):');
  stdout.writeln(
    '    churn:    ${f(memory['churnBytesPerCall'], 0)} bytes/call,'
    ' ${memory['churnObjects']} objects total',
  );
  stdout.writeln(
    '    retained: ${memory['retainedBytes']} bytes (cache, heap delta);'
    ' live heap ${memory['liveHeapBytes']} bytes',
  );
  if (countersEnabled) {
    stdout.writeln('  counters (oracle corpus, cold pass):');
    counters.forEach((k, v) => stdout.writeln('    $k: $v'));
  } else {
    stdout.writeln(
      '  counters: disabled'
      ' (pass --define=whatchord.counters=true to enable)',
    );
  }
}

double _timeMicros(void Function() body) {
  final sw = Stopwatch()..start();
  body();
  sw.stop();
  return sw.elapsedMicroseconds.toDouble();
}

double _hypot(double a, double b) => math.sqrt(a * a + b * b);

String? _argValue(List<String> args, String prefix) {
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}
