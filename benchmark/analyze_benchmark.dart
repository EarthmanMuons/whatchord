// Offline performance baseline for the chord analysis engine.
//
// Measures, by replaying chord corpora through ChordAnalyzer.analyze():
//
//   1. Time, normalized to a fixed CPU reference workload (hardware-stable),
//      for two corpora: the adversarial reviewed-oracle corpus and the common
//      voicing pool (real-playing structures). Sampled adaptively until the
//      mean's 95% CI is tight; stddev reported.
//   2. Memory: allocation churn and retained heap delta (VM-observed).
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
  if (args.contains('--show-baseline')) {
    _printBaseline();
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
  _printSummary(result);
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
/// baseline. Counter changes on the same corpus are deterministic; memory is
/// VM-observed and may have small runtime noise; normalized time changes beyond
/// its CI are meaningful.
void _maybePrintComparison(String outPath, Map<String, Object?> current) {
  if (outPath == _baselinePath) return;
  final file = File(_baselinePath);
  if (!file.existsSync()) return;
  final base = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  stdout.writeln('');
  stdout.writeln('Comparison to baseline ($_baselinePath)');
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

  String changeText(num baseline, num current, {required bool pct}) {
    if (current == baseline) return 'unchanged';
    if (pct && baseline != 0) {
      final change = (current - baseline) / baseline * 100;
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
    }
    final change = current - baseline;
    return '${change >= 0 ? '+' : ''}${_formatInteger(change)}';
  }

  void timeCmp(String corpus, String mode, List<String> path) {
    final b = _at(base, path);
    final c = _at(current, path);
    if (b is! num || c is! num) return;
    stdout.writeln(
      '  ${corpus.padRight(13)}'
      '${mode.padRight(7)}'
      '${_formatNormalized(b).padLeft(10)}'
      '${_formatNormalized(c).padLeft(10)}'
      '${changeText(b, c, pct: true).padLeft(10)}',
    );
  }

  void metricCmp(
    String label,
    List<String> path, {
    required String Function(num value) format,
    required bool pct,
  }) {
    final b = _at(base, path);
    final c = _at(current, path);
    if (b is! num || c is! num) return;
    stdout.writeln(
      '  ${label.padRight(20)}'
      '${format(b).padLeft(15)}'
      '${format(c).padLeft(15)}'
      '${changeText(b, c, pct: pct).padLeft(12)}',
    );
  }

  stdout.writeln('  Time');
  stdout.writeln(
    '  ${'Corpus'.padRight(13)}'
    '${'Mode'.padRight(7)}'
    '${'Baseline'.padLeft(10)}'
    '${'Current'.padLeft(10)}'
    '${'Change'.padLeft(10)}',
  );
  timeCmp('oracle', 'cold', ['time', 'oracle', 'coldNormalized']);
  timeCmp('oracle', 'warm', ['time', 'oracle', 'warmNormalized']);
  timeCmp('common', 'cold', ['time', 'common', 'coldNormalized']);
  timeCmp('common', 'warm', ['time', 'common', 'warmNormalized']);

  stdout.writeln('  Memory, VM-observed');
  stdout.writeln(
    '  ${'Metric'.padRight(20)}'
    '${'Baseline'.padLeft(15)}'
    '${'Current'.padLeft(15)}'
    '${'Change'.padLeft(12)}',
  );
  metricCmp(
    'churn bytes/call',
    ['memory', 'churnBytesPerCall'],
    format: _formatInteger,
    pct: true,
  );
  metricCmp(
    'retained bytes',
    ['memory', 'retainedBytes'],
    format: _formatInteger,
    pct: true,
  );
  stdout.writeln('  Counters, deterministic');
  stdout.writeln(
    '  ${'Metric'.padRight(20)}'
    '${'Baseline'.padLeft(15)}'
    '${'Current'.padLeft(15)}'
    '${'Change'.padLeft(12)}',
  );
  for (final key in (current['counters'] as Map<String, Object?>).keys) {
    metricCmp(
      _counterLabel(key),
      ['counters', key],
      format: _formatInteger,
      pct: false,
    );
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

void _printBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) {
    stderr.writeln('No baseline found at $_baselinePath.');
    exitCode = 1;
    return;
  }
  final baseline = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  _printSummary(baseline, source: _baselinePath);
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
  --out=PATH        Write results JSON to PATH (default: $_defaultOutPath).
                    Use --out=$_baselinePath to update the committed baseline.
  --show-baseline   Print $_baselinePath in the same summary format as a run.
  -h, --help        Show this help and exit.

Unless --out points at the baseline, the run prints a delta against
$_baselinePath when it exists. Compare runs on the same corpora only;
regenerate the baseline after changing a corpus.

Memory measurement needs the VM service (--enable-vm-service) and the
operation counters need the whatchord.counters define; tool/benchmark.sh
sets both for benchmark runs.''');
}

void _printSummary(Map<String, Object?> result, {String? source}) {
  String f(Object? v, int frac) => (v as num).toStringAsFixed(frac);
  Map<String, Object?> mapAt(List<String> path) =>
      _at(result, path) as Map<String, Object?>;

  final meta = mapAt(['meta']);
  final memory = mapAt(['memory']);
  final counters = mapAt(['counters']);
  final countersEnabled = meta['countersEnabled'] == true;
  final targetRelCi = meta['targetRelCi95'] as num? ?? _targetRelCi;

  void timeLine(
    String corpus,
    String mode,
    Map<String, Object?> time,
    String statsKey,
  ) {
    final stats = time[statsKey] as Map<String, Object?>;
    final relCi95 = stats['relCi95'] as num;
    final normalizedKey = statsKey.replaceFirst('UsPerCall', 'Normalized');
    final conv = relCi95 <= targetRelCi ? 'converged' : 'budget-capped';
    final samples = '${stats['n']} $conv';
    stdout.writeln(
      '  ${corpus.padRight(13)}'
      '${mode.padRight(7)}'
      '${_formatNormalized(time[normalizedKey] as num).padLeft(10)}'
      '${('${f(stats['mean'], 3)} us').padLeft(16)}'
      '${('${f(stats['stddev'], 3)} us').padLeft(13)}'
      '${('${f(relCi95 * 100, 1)}%').padLeft(7)}'
      '   $samples',
    );
  }

  stdout.writeln(
    source == null
        ? 'Chord engine benchmark'
        : 'Chord engine benchmark baseline',
  );
  if (source != null) stdout.writeln('  source: $source');
  stdout.writeln('');
  stdout.writeln('Time, normalized to reference workload');
  stdout.writeln(
    '  ${'Corpus'.padRight(13)}'
    '${'Mode'.padRight(7)}'
    '${'Norm'.padLeft(10)}'
    '${'Raw mean'.padLeft(16)}'
    '${'Stddev'.padLeft(13)}'
    '${'CI95'.padLeft(7)}'
    '   Samples',
  );
  final oracleTime = mapAt(['time', 'oracle']);
  timeLine(
    'oracle (${meta['oracleSize']})',
    'cold',
    oracleTime,
    'coldUsPerCall',
  );
  timeLine(
    'oracle (${meta['oracleSize']})',
    'warm',
    oracleTime,
    'warmUsPerCall',
  );
  final commonTime = mapAt(['time', 'common']);
  timeLine(
    'common (${meta['commonSize']})',
    'cold',
    commonTime,
    'coldUsPerCall',
  );
  timeLine(
    'common (${meta['commonSize']})',
    'warm',
    commonTime,
    'warmUsPerCall',
  );
  stdout.writeln('');
  stdout.writeln('Memory, oracle cold pass');
  final churnBytesPerCall = memory['churnBytesPerCall'] as num;
  final retainedBytes = memory['retainedBytes'] as num;
  final liveHeapBytes = memory['liveHeapBytes'] as num;
  stdout.writeln(
    '  ${'churn'.padRight(16)}'
    '${_formatBytes(churnBytesPerCall)}/call'
    ' (${_formatInteger(churnBytesPerCall)} bytes/call)',
  );
  stdout.writeln(
    '  ${'churn objects'.padRight(16)}'
    '${_formatInteger(memory['churnObjects'] as num)} total',
  );
  stdout.writeln(
    '  ${'retained'.padRight(16)}'
    '${_formatBytes(retainedBytes)} (${_formatInteger(retainedBytes)} bytes)',
  );
  stdout.writeln(
    '  ${'live heap'.padRight(16)}'
    '${_formatBytes(liveHeapBytes)} (${_formatInteger(liveHeapBytes)} bytes)',
  );
  if (countersEnabled) {
    stdout.writeln('');
    stdout.writeln('Counters, oracle cold pass');
    counters.forEach(
      (k, v) => stdout.writeln(
        '  ${_counterLabel(k).padRight(20)}${_formatInteger(v as num)}',
      ),
    );
  } else {
    stdout.writeln('');
    stdout.writeln(
      'Counters: disabled'
      ' (pass --define=whatchord.counters=true to enable)',
    );
  }
}

String _formatNormalized(num value) {
  final abs = value.abs();
  if (abs != 0 && abs < 0.0001) return value.toStringAsPrecision(3);
  return value.toStringAsFixed(5);
}

String _formatBytes(num bytes) {
  final abs = bytes.abs();
  if (abs < 1024) return '${_formatInteger(bytes)} B';
  const units = ['KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble() / 1024;
  var unitIndex = 0;
  while (value.abs() >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
}

String _formatInteger(num value) {
  final text = value.round().toString();
  final negative = text.startsWith('-');
  final digits = negative ? text.substring(1) : text;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _counterLabel(String key) {
  final words = key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .toLowerCase();
  return words;
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
