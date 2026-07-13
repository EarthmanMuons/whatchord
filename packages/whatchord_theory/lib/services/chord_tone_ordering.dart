import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';

/// Shared ordering for chord-member diagnostics and ledgers.
abstract final class ChordToneOrdering {
  /// Returns [intervals] sorted in chord-stack degree order:
  /// root, third, fifth, seventh, then ninth, eleventh, thirteenth.
  static List<int> byDegree(
    Iterable<int> intervals, {
    required ChordIdentity identity,
    Map<int, ChordToneRole>? rolesByInterval,
  }) {
    final roles = rolesByInterval ?? identity.toneRolesByInterval;
    final sorted = intervals.toList()
      ..sort((a, b) {
        final rankA = _degreeOrder(roles[a], a);
        final rankB = _degreeOrder(roles[b], b);
        final primary = rankA.compareTo(rankB);
        if (primary != 0) return primary;
        return a.compareTo(b);
      });

    return List<int>.unmodifiable(sorted);
  }

  static int _degreeOrder(ChordToneRole? role, int interval) {
    if (role != null) return role.degreeOrder;

    return switch (interval) {
      0 => 1,
      3 || 4 => 3,
      7 => 5,
      10 || 11 => 7,
      1 || 2 => 9,
      5 || 6 => 11,
      8 || 9 => 13,
      _ => 99,
    };
  }
}
