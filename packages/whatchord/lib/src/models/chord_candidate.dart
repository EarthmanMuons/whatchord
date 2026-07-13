import 'package:meta/meta.dart';

import 'chord_identity.dart';

/// A ranked candidate result from chord analysis.
@immutable
class ChordCandidate {
  /// The chord identity this candidate names.
  final ChordIdentity identity;

  /// Explanation cost is intentionally unitless; lower is better.
  final double cost;

  const ChordCandidate({required this.identity, required this.cost});

  @override
  String toString() => 'ChordCandidate(cost=$cost, $identity)';
}
