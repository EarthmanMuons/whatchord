/// A chord-tone role describes the *intended letter context* for a pitch
/// inside a chord: e.g. "#11" (letter = 4th above root) vs "b5"
/// (letter = 5th above root), even when both map to the same pitch class.
enum ChordToneRole {
  root,

  // 2nd-degree family
  sus2,
  flat9,
  nine,
  sharp9,
  add9,

  // 3rd-degree family
  minor3,
  major3,

  // 4th-degree family
  sus4,
  eleven,
  sharp11,
  add11,

  // 5th-degree family
  flat5,
  perfect5,
  sharp5,

  // 6th-degree family
  sixth,
  flat13,
  thirteenth,
  add13,

  // 7th-degree family
  dim7, // "bb7" (diminished seventh) as in fully diminished 7th chords
  flat7,
  major7,
}

extension ChordToneRoleDegree on ChordToneRole {
  /// Diatonic scale degree above the chord root (1..7) used to select the letter.
  int get degreeFromRoot {
    switch (this) {
      case ChordToneRole.root:
        return 1;

      case ChordToneRole.sus2:
      case ChordToneRole.flat9:
      case ChordToneRole.nine:
      case ChordToneRole.sharp9:
      case ChordToneRole.add9:
        return 2;

      case ChordToneRole.minor3:
      case ChordToneRole.major3:
        return 3;

      case ChordToneRole.sus4:
      case ChordToneRole.eleven:
      case ChordToneRole.sharp11:
      case ChordToneRole.add11:
        return 4;

      case ChordToneRole.flat5:
      case ChordToneRole.perfect5:
      case ChordToneRole.sharp5:
        return 5;

      case ChordToneRole.sixth:
      case ChordToneRole.flat13:
      case ChordToneRole.thirteenth:
      case ChordToneRole.add13:
        return 6;

      case ChordToneRole.dim7:
      case ChordToneRole.flat7:
      case ChordToneRole.major7:
        return 7;
    }
  }
}
