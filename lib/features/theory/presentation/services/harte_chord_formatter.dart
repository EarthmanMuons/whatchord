import '../../domain/theory_domain.dart';

/// Formats chord identities using Harte-style chord syntax.
///
/// Reference: https://ismir2005.ismir.net/proceedings/1080.pdf
///
/// The formatter uses official shorthand labels when their component set is
/// present, and writes unsupported chord types as explicit degree lists.
abstract final class HarteChordFormatter {
  static String format(ChordIdentity identity) {
    final root = _rootName(identity.rootPc);
    final degrees = _degrees(identity);
    final body = _body(degrees);
    final bass = _bass(identity);

    return '$root:$body$bass';
  }

  static String _body(List<String> degrees) {
    final degreeSet = degrees.toSet();
    final shorthand = _bestShorthandFor(degreeSet);
    if (shorthand == null) return '(${degrees.join(',')})';

    final extras = degrees
        .where((degree) => !shorthand.degrees.contains(degree))
        .toList(growable: false);
    if (extras.isEmpty) return shorthand.label;

    return '${shorthand.label}(${extras.join(',')})';
  }

  static _HarteShorthand? _bestShorthandFor(Set<String> degrees) {
    for (final shorthand in _harteShorthands) {
      if (degrees.containsAll(shorthand.degrees)) return shorthand;
    }
    return null;
  }

  static List<String> _degrees(ChordIdentity identity) {
    final out = <String>[];
    for (var interval = 1; interval < 12; interval++) {
      if ((identity.presentIntervalsMask & (1 << interval)) == 0) continue;
      out.add(_degreeLabel(interval, identity.toneRolesByInterval[interval]));
    }

    out.sort(_compareDegrees);
    return out;
  }

  static String _bass(ChordIdentity identity) {
    if (!identity.hasSlashBass) return '';

    final interval = (identity.bassPc - identity.rootPc) % 12;
    return '/${_degreeLabel(interval, identity.toneRolesByInterval[interval])}';
  }

  static String _degreeLabel(int interval, ChordToneRole? role) {
    if (role != null) {
      return switch (role) {
        ChordToneRole.root => '1',
        ChordToneRole.sus2 => '2',
        ChordToneRole.nine || ChordToneRole.add9 => '9',
        ChordToneRole.flat9 => 'b9',
        ChordToneRole.sharp9 => '#9',
        ChordToneRole.minor3 => 'b3',
        ChordToneRole.major3 => '3',
        ChordToneRole.sus4 => '4',
        ChordToneRole.eleven || ChordToneRole.add11 => '11',
        ChordToneRole.sharp11 => '#11',
        ChordToneRole.flat5 => 'b5',
        ChordToneRole.perfect5 => '5',
        ChordToneRole.sharp5 => '#5',
        ChordToneRole.sixth => '6',
        ChordToneRole.flat13 => 'b13',
        ChordToneRole.thirteenth || ChordToneRole.add13 => '13',
        ChordToneRole.dim7 => 'bb7',
        ChordToneRole.flat7 => 'b7',
        ChordToneRole.major7 => '7',
      };
    }

    return switch (interval % 12) {
      0 => '1',
      1 => 'b9',
      2 => '9',
      3 => 'b3',
      4 => '3',
      5 => '11',
      6 => 'b5',
      7 => '5',
      8 => '#5',
      9 => '6',
      10 => 'b7',
      11 => '7',
      _ => throw StateError('Unreachable interval: $interval'),
    };
  }

  static int _compareDegrees(String a, String b) {
    final primary = _degreeSortRank(a).compareTo(_degreeSortRank(b));
    if (primary != 0) return primary;
    return a.compareTo(b);
  }

  static int _degreeSortRank(String degree) {
    final numeric = int.parse(degree.replaceAll('#', '').replaceAll('b', ''));
    return switch (numeric) {
      2 => 5,
      3 => 10,
      4 => 15,
      5 => 20,
      6 => 30,
      7 => 40,
      9 => 50,
      11 => 60,
      13 => 70,
      1 => 80,
      _ => 90,
    };
  }

  static String _rootName(int pc) {
    return switch (pc % 12) {
      0 => 'C',
      1 => 'Db',
      2 => 'D',
      3 => 'Eb',
      4 => 'E',
      5 => 'F',
      6 => 'F#',
      7 => 'G',
      8 => 'Ab',
      9 => 'A',
      10 => 'Bb',
      11 => 'B',
      _ => throw StateError('Unreachable pitch class: $pc'),
    };
  }
}

class _HarteShorthand {
  const _HarteShorthand(this.label, this.degrees);

  final String label;
  final Set<String> degrees;
}

const _harteShorthands = <_HarteShorthand>[
  _HarteShorthand('maj9', {'3', '5', '7', '9'}),
  _HarteShorthand('min9', {'b3', '5', 'b7', '9'}),
  _HarteShorthand('9', {'3', '5', 'b7', '9'}),
  _HarteShorthand('maj7', {'3', '5', '7'}),
  _HarteShorthand('min7', {'b3', '5', 'b7'}),
  _HarteShorthand('dim7', {'b3', 'b5', 'bb7'}),
  _HarteShorthand('hdim7', {'b3', 'b5', 'b7'}),
  _HarteShorthand('minmaj7', {'b3', '5', '7'}),
  _HarteShorthand('maj6', {'3', '5', '6'}),
  _HarteShorthand('min6', {'b3', '5', '6'}),
  _HarteShorthand('7', {'3', '5', 'b7'}),
  _HarteShorthand('maj', {'3', '5'}),
  _HarteShorthand('min', {'b3', '5'}),
  _HarteShorthand('dim', {'b3', 'b5'}),
  _HarteShorthand('aug', {'3', '#5'}),
  _HarteShorthand('sus4', {'4', '5'}),
];
