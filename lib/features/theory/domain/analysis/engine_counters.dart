/// Compile-time gate for [EngineCounters].
///
/// When `whatchord.counters` is not defined (the default, which includes every
/// release build), this resolves to a `const false`. Each guarded
/// `if (kEngineCountersEnabled) ...` call site then folds to `if (false)` and is
/// dead-code eliminated by the compiler, so the counters cost nothing in normal
/// builds.
///
/// Enable them for the benchmark harness with:
///
/// ```
/// dart run --define=whatchord.counters=true benchmark/analyze_benchmark.dart
/// ```
const bool kEngineCountersEnabled = bool.fromEnvironment('whatchord.counters');

/// Deterministic, hardware-independent tallies of analysis work.
///
/// These count algorithmic steps (cache lookups, roots considered, templates
/// evaluated, candidates produced) rather than wall-clock time, so they are a
/// reproducible regression signal regardless of the machine. Only mutated when
/// [kEngineCountersEnabled] is true; otherwise the increments compile away.
abstract final class EngineCounters {
  static int cacheHits = 0;
  static int cacheMisses = 0;
  static int rootsConsidered = 0;
  static int templatesEvaluated = 0;
  static int candidatesProduced = 0;

  static void reset() {
    cacheHits = 0;
    cacheMisses = 0;
    rootsConsidered = 0;
    templatesEvaluated = 0;
    candidatesProduced = 0;
  }

  static Map<String, int> snapshot() => <String, int>{
    'cacheHits': cacheHits,
    'cacheMisses': cacheMisses,
    'rootsConsidered': rootsConsidered,
    'templatesEvaluated': templatesEvaluated,
    'candidatesProduced': candidatesProduced,
  };
}
