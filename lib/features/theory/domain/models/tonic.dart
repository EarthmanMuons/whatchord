enum Tonic {
  c('C', 'C', 0),
  d('D', 'D', 2),
  e('E', 'E', 4),
  f('F', 'F', 5),
  g('G', 'G', 7),
  a('A', 'A', 9),
  b('B', 'B', 11),
  fSharp('F#', 'F', 6),
  cSharp('C#', 'C', 1),
  gSharp('G#', 'G', 8),
  dSharp('D#', 'D', 3),
  aSharp('A#', 'A', 10),
  bFlat('Bb', 'B', 10),
  eFlat('Eb', 'E', 3),
  aFlat('Ab', 'A', 8),
  dFlat('Db', 'D', 1),
  gFlat('Gb', 'G', 6),
  cFlat('Cb', 'C', 11);

  const Tonic(this.label, this.letter, this.pitchClass);

  /// Canonical ASCII note name: "C", "F#", "Bb", etc.
  final String label;

  /// Diatonic letter only: "C", "F", "B", etc.
  final String letter;

  /// Pitch class 0..11.
  final int pitchClass;

  bool get isSharp => label.length > 1 && label[1] == '#';
  bool get isFlat => label.length > 1 && label[1] == 'b';

  /// Returns null if [label] does not match any known tonic.
  static Tonic? tryFromLabel(String label) {
    for (final t in values) {
      if (t.label == label) return t;
    }
    return null;
  }
}
