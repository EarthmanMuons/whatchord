import 'models/chord_candidate.dart';
import 'models/chord_input.dart';

/// Pure chord analysis entry point.
///
/// Step 1: stubbed (returns empty list), but includes memoization wiring.
/// Step 2: implement template + scoring + optional tonality bias.
abstract final class ChordAnalyzer {
  static final Map<int, List<ChordCandidate>> _cache =
      <int, List<ChordCandidate>>{};

  static List<ChordCandidate> analyze(ChordInput input) {
    final key = input.cacheKey;

    final cached = _cache[key];
    if (cached != null) return cached;

    // Step 2: implement template/scoring here.
    const result = <ChordCandidate>[];

    _cache[key] = result;
    return result;
  }

  /// Helpful during development/tuning.
  static void clearCache() => _cache.clear();
}
