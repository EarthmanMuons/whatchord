import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';

/// Role-aware degree tokens for currently sounding chord members.
///
/// Examples: 1, b3, 5, b9, #11, 13.
abstract final class ChordMemberDegreeFormatter {
  static List<String> formatDegrees({
    required ChordIdentity identity,
    required Set<int> pitchClasses, // unique 0..11
  }) {
    if (pitchClasses.isEmpty) return const <String>[];

    final entries = <_DegreeEntry>[];
    for (final pc in pitchClasses) {
      final interval = _interval(pc, identity.rootPc);
      final role = identity.toneRolesByInterval[interval];
      final label = _label(role, interval);
      entries.add(_DegreeEntry(interval: interval, role: role, label: label));
    }

    entries.sort((a, b) {
      final ka = _sortKey(a.label);
      final kb = _sortKey(b.label);

      final c1 = ka.baseRank.compareTo(kb.baseRank);
      if (c1 != 0) return c1;

      final c2 = ka.accidentalRank.compareTo(kb.accidentalRank);
      if (c2 != 0) return c2;

      final c3 = ka.baseNumber.compareTo(kb.baseNumber);
      if (c3 != 0) return c3;

      return a.interval.compareTo(b.interval);
    });

    return entries.map((e) => e.label).toList(growable: false);
  }

  static int _interval(int pc, int rootPc) {
    final d = pc - rootPc;
    final m = d % 12;
    return m < 0 ? m + 12 : m;
  }

  static String _label(ChordToneRole? role, int interval) {
    if (role != null) return role.degreeToken;

    // Fallback keeps degree-style notation and favors compound tensions.
    return switch (interval) {
      0 => '1',
      1 => 'b9',
      2 => '9',
      3 => '#9',
      4 => '3',
      5 => '11',
      6 => '#11',
      7 => '5',
      8 => 'b13',
      9 => '13',
      10 => 'b7',
      11 => '7',
      _ => '?',
    };
  }

  static _SortKey _sortKey(String label) {
    final match = RegExp(r'^(bb|b|##|#)?(?:add|sus)?(\d+)$').firstMatch(label);
    if (match == null) {
      return const _SortKey(baseRank: 999, accidentalRank: 0, baseNumber: 999);
    }

    final accidental = match.group(1) ?? '';
    final baseNumber = int.parse(match.group(2)!);

    final baseRank = baseNumber;

    final accidentalRank = switch (accidental) {
      'bb' => -2,
      'b' => -1,
      '' => 0,
      '#' => 1,
      '##' => 2,
      _ => 0,
    };

    return _SortKey(
      baseRank: baseRank,
      accidentalRank: accidentalRank,
      baseNumber: baseNumber,
    );
  }
}

extension on ChordToneRole {
  String get degreeToken {
    switch (this) {
      case ChordToneRole.root:
        return '1';

      case ChordToneRole.sus2:
        return '2';
      case ChordToneRole.flat9:
        return 'b9';
      case ChordToneRole.nine:
        return '9';
      case ChordToneRole.sharp9:
        return '#9';
      case ChordToneRole.add9:
        return '9';

      case ChordToneRole.minor3:
        return 'b3';
      case ChordToneRole.major3:
        return '3';

      case ChordToneRole.sus4:
        return '4';
      case ChordToneRole.eleven:
        return '11';
      case ChordToneRole.sharp11:
        return '#11';
      case ChordToneRole.add11:
        return '11';

      case ChordToneRole.flat5:
        return 'b5';
      case ChordToneRole.perfect5:
        return '5';
      case ChordToneRole.sharp5:
        return '#5';

      case ChordToneRole.sixth:
        return '6';
      case ChordToneRole.flat13:
        return 'b13';
      case ChordToneRole.thirteenth:
        return '13';
      case ChordToneRole.add13:
        return '13';

      case ChordToneRole.dim7:
        return 'bb7';
      case ChordToneRole.flat7:
        return 'b7';
      case ChordToneRole.major7:
        return '7';
    }
  }
}

class _DegreeEntry {
  final int interval;
  final ChordToneRole? role;
  final String label;

  _DegreeEntry({
    required this.interval,
    required this.role,
    required this.label,
  });
}

class _SortKey {
  final int baseRank;
  final int accidentalRank;
  final int baseNumber;

  const _SortKey({
    required this.baseRank,
    required this.accidentalRank,
    required this.baseNumber,
  });
}
