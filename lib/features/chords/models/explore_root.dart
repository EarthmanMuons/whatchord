/// A spelled chord root: a pitch class plus the letter and accidental it is
/// written with (so C# and Db are distinct roots, not one pitch class).
///
/// The choices cover every note name that is diatonic to a standard major or
/// natural-minor key: each of the seven letters with its flat, natural, and
/// sharp spelling (21 in all). They are declared in wheel order, grouped by
/// letter so each enharmonic sits with its letter sibling (B# next to B, Cb
/// next to C, E# next to E, Fb next to F) rather than with its pitch-class
/// neighbor.
enum ExploreRoot {
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

  const ExploreRoot(this.label, this.letter, this.pitchClass);

  /// Canonical ASCII note name: "C", "F#", "Bb", "Cb".
  final String label;

  /// Diatonic letter only: "C", "F", "B".
  final String letter;

  /// Pitch class 0..11.
  final int pitchClass;
}

/// The root spellings offered in Explore Chords, in wheel order.
const List<ExploreRoot> exploreRootChoices = ExploreRoot.values;

/// Resolves a root spelling for [pitchClass], preferring [preferredLabel] when
/// it names one of the spellings for that pitch class (e.g. the key-signature
/// spelling). Otherwise falls back to the plainest spelling: natural where one
/// exists, else the sharp, else the flat.
ExploreRoot exploreRootForPitchClass(int pitchClass, {String? preferredLabel}) {
  final pc = pitchClass % 12;
  if (preferredLabel != null) {
    for (final root in ExploreRoot.values) {
      if (root.pitchClass == pc && root.label == preferredLabel) return root;
    }
  }
  return ExploreRoot.values
      .where((root) => root.pitchClass == pc)
      .reduce((a, b) => _defaultRank(a) <= _defaultRank(b) ? a : b);
}

/// Ranks spellings for a default pick: natural (0) before sharp (1) before
/// flat (2).
int _defaultRank(ExploreRoot root) {
  if (root.label.length == 1) return 0;
  return root.label[1] == '#' ? 1 : 2;
}
