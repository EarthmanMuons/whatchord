import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/tonality.dart';
import 'note_spelling.dart' show pcToName, spellPitchClass;

/// Role-aware spelling for the *currently sounding* chord members.
abstract final class ChordMemberSpeller {
  /// Returns spelled chord members for the given voicing pitch classes.
  ///
  /// - Uses [identity.toneRolesByInterval] to choose the correct *letter*
  ///   (e.g., dim7 => "bb7" letter, so D# becomes Eb in an F#dim7 context).
  /// - Falls back to tonality-aware pc spelling if role is unknown.
  static List<String> spellMembers({
    required ChordIdentity identity,
    required Set<int> pitchClasses, // unique 0..11
    required Tonality tonality,
  }) {
    if (pitchClasses.isEmpty) return const <String>[];

    final rootName = pcToName(identity.rootPc, tonality: tonality);

    // Build (interval -> spelled name) for all present tones we can classify.
    final entries = <_Member>[];

    for (final pc in pitchClasses) {
      final interval = _interval(pc, identity.rootPc);
      final role = identity.toneRolesByInterval[interval];

      final name = spellPitchClass(
        pc,
        tonality: tonality,
        chordRootName: rootName,
        role: role,
      );

      entries.add(_Member(pc: pc, interval: interval, role: role, name: name));
    }

    // Sort musically:
    // 1) by diatonic degree implied by role (root, 3rd, 5th, 7th, extensions)
    // 2) then by chromatic interval as a stable tie-breaker
    entries.sort((a, b) {
      final da = _degreeRank(a.role, a.interval);
      final db = _degreeRank(b.role, b.interval);
      final c1 = da.compareTo(db);
      if (c1 != 0) return c1;
      return a.interval.compareTo(b.interval);
    });

    return entries.map((e) => e.name).toList(growable: false);
  }

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  static int _degreeRank(ChordToneRole? role, int interval) {
    // Prefer role-based ordering when available.
    if (role != null) return role.degreeFromRoot;

    // Fallback: reasonable ordering by common chord-tone buckets.
    // Root(0) first, then 2/3/4/5/6/7-ish.
    return switch (interval) {
      0 => 1,
      1 || 2 => 2,
      3 || 4 => 3,
      5 || 6 => 4,
      7 || 8 => 5,
      9 => 6,
      10 || 11 => 7,
      _ => 99,
    };
  }
}

class _Member {
  final int pc;
  final int interval;
  final ChordToneRole? role;
  final String name;

  _Member({
    required this.pc,
    required this.interval,
    required this.role,
    required this.name,
  });
}
