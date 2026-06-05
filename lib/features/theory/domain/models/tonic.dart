/// A spelled tonic: a pitch class plus the letter and accidental it is written
/// with, so C# and Db are distinct tonics, not one pitch class.
///
/// The values cover every note name diatonic to a standard major or natural-
/// minor key: each of the seven letters with its flat, natural, and sharp
/// spelling (21 in all). They are declared grouped by letter so each enharmonic
/// sits with its letter sibling (Cb next to C, B# next to B) rather than with
/// its pitch-class neighbor. Consumers that want chromatic order sort by
/// [pitchClass].
///
/// This is the shared root vocabulary for both Explore Chords and the Scale
/// Explorer; which subset a scale offers is decided by its tonic policy.
enum Tonic {
  cFlat('Cb', 'C', 11),
  c('C', 'C', 0),
  cSharp('C#', 'C', 1),
  dFlat('Db', 'D', 1),
  d('D', 'D', 2),
  dSharp('D#', 'D', 3),
  eFlat('Eb', 'E', 3),
  e('E', 'E', 4),
  eSharp('E#', 'E', 5),
  fFlat('Fb', 'F', 4),
  f('F', 'F', 5),
  fSharp('F#', 'F', 6),
  gFlat('Gb', 'G', 6),
  g('G', 'G', 7),
  gSharp('G#', 'G', 8),
  aFlat('Ab', 'A', 8),
  a('A', 'A', 9),
  aSharp('A#', 'A', 10),
  bFlat('Bb', 'B', 10),
  b('B', 'B', 11),
  bSharp('B#', 'B', 0);

  const Tonic(this.label, this.letter, this.pitchClass);

  /// Canonical ASCII note name: "C", "F#", "Bb", "Cb".
  final String label;

  /// Diatonic letter only: "C", "F", "B".
  final String letter;

  /// Pitch class 0..11.
  final int pitchClass;

  bool get isSharp => label.length > 1 && label[1] == '#';
  bool get isFlat => label.length > 1 && label[1] == 'b';

  /// Ranks a spelling for a default pick or an enharmonic tiebreak: natural (0)
  /// before sharp (1) before flat (2).
  int get accidentalRank {
    if (label.length == 1) return 0;
    return label[1] == '#' ? 1 : 2;
  }

  /// Returns null if [label] does not match any known tonic.
  static Tonic? tryFromLabel(String label) {
    for (final t in values) {
      if (t.label == label) return t;
    }
    return null;
  }

  /// Resolves a tonic for [pitchClass], preferring [preferredLabel] when it
  /// names one of the spellings for that pitch class (e.g. the key-signature
  /// spelling). Otherwise falls back to the plainest spelling: natural where
  /// one exists, else the sharp, else the flat.
  static Tonic forPitchClass(int pitchClass, {String? preferredLabel}) {
    final pc = pitchClass % 12;
    if (preferredLabel != null) {
      for (final t in values) {
        if (t.pitchClass == pc && t.label == preferredLabel) return t;
      }
    }
    return values
        .where((t) => t.pitchClass == pc)
        .reduce((a, b) => a.accidentalRank <= b.accidentalRank ? a : b);
  }
}
