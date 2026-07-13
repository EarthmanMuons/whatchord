import 'package:meta/meta.dart';

import 'chord_identity.dart';

/// A ranked candidate result from chord analysis.
@immutable
class ChordCandidate {
  final ChordIdentity identity;

  /// Explanation cost is intentionally unitless; lower is better.
  final double cost;

  const ChordCandidate({required this.identity, required this.cost});

  @override
  String toString() => 'ChordCandidate(cost=$cost, $identity)';
}
