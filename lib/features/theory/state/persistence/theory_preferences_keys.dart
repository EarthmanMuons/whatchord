/// Storage keys and persisted values for music theory preferences.
class TheoryPreferencesKeys {
  static const chordNotationStyle = 'theory.chordNotationStyle';
  static const selectedTonality = 'theory.selectedTonality';
  static const showScaleNotes = 'theory.showScaleNotes';
}

/// Stable serialized values for theory preferences.
class TheoryPreferencesValues {
  static const chordNotationStyleSymbolic = 'symbolic';
  static const chordNotationStyleTextual = 'textual';
  static const tonalityModeMajor = 'major';
  static const tonalityModeMinor = 'minor';
}
