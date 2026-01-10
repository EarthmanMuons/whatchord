import 'package:meta/meta.dart';

import 'chord_identity.dart';

/// A ranked candidate result from chord analysis.
@immutable
class ChordCandidate {
  final ChordIdentity identity;

  /// Score is intentionally unitless.
  final double score;

  const ChordCandidate({required this.identity, required this.score});

  @override
  String toString() => 'ChordCandidate(score=$score, $identity)';
}
