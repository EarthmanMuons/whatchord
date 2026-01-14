import '../../domain/theory_domain.dart' show ChordToneRole;

/// Formatting-only labels for chord tone role tokens.
extension ChordToneRoleTokenLabels on ChordToneRole {
  String get label {
    switch (this) {
      case ChordToneRole.root:
        return '1';

      case ChordToneRole.sus2:
        return 'sus2';
      case ChordToneRole.flat9:
        return 'b9';
      case ChordToneRole.nine:
        return '9';
      case ChordToneRole.sharp9:
        return '#9';
      case ChordToneRole.add9:
        return 'add9';

      case ChordToneRole.minor3:
        return 'b3';
      case ChordToneRole.major3:
        return '3';

      case ChordToneRole.sus4:
        return 'sus4';
      case ChordToneRole.eleven:
        return '11';
      case ChordToneRole.sharp11:
        return '#11';
      case ChordToneRole.add11:
        return 'add11';

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
        return 'add13';

      case ChordToneRole.dim7:
        return 'bb7';
      case ChordToneRole.flat7:
        return 'b7';
      case ChordToneRole.major7:
        return '7';
    }
  }
}
