/// A spelled chord root: a pitch class plus the letter and accidental it is
/// written with (so C# and Db are distinct roots, not one pitch class).
///
/// The choices cover every note name that is diatonic to a standard major or
/// natural-minor key, so each pitch class carries its in-key enharmonic
/// spellings (e.g. F#/Gb, and the boundary spellings B#, Cb, E#, Fb). Roots are
/// declared in chromatic order; within a pitch class the natural spelling leads,
/// then the sharp, then the flat.
enum ExploreRoot {
  c('C', 'C', 0),
  bSharp('B#', 'B', 0),
  cSharp('C#', 'C', 1),
  dFlat('Db', 'D', 1),
  d('D', 'D', 2),
  dSharp('D#', 'D', 3),
  eFlat('Eb', 'E', 3),
  e('E', 'E', 4),
  fFlat('Fb', 'F', 4),
  f('F', 'F', 5),
  eSharp('E#', 'E', 5),
  fSharp('F#', 'F', 6),
  gFlat('Gb', 'G', 6),
  g('G', 'G', 7),
  gSharp('G#', 'G', 8),
  aFlat('Ab', 'A', 8),
  a('A', 'A', 9),
  aSharp('A#', 'A', 10),
  bFlat('Bb', 'B', 10),
  b('B', 'B', 11),
  cFlat('Cb', 'C', 11);

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
/// spelling). Otherwise falls back to the leading spelling for the pitch class
/// (natural where one exists, else the sharp).
ExploreRoot exploreRootForPitchClass(int pitchClass, {String? preferredLabel}) {
  final pc = pitchClass % 12;
  if (preferredLabel != null) {
    for (final root in ExploreRoot.values) {
      if (root.pitchClass == pc && root.label == preferredLabel) return root;
    }
  }
  return ExploreRoot.values.firstWhere((root) => root.pitchClass == pc);
}
