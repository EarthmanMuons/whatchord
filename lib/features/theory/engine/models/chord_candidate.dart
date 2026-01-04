import 'package:meta/meta.dart';

import 'chord_identity.dart';

/// A ranked candidate result from chord analysis.
@immutable
class ChordCandidate {
  final ChordIdentity identity;

  /// Score is intentionally unitless for now.
  /// In Step 2 we will standardize the scale (e.g., 0..100 or 0..1).
  final double score;

  const ChordCandidate({required this.identity, required this.score});

  @override
  String toString() => 'ChordCandidate(score=$score, $identity)';
}
