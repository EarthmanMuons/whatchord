/// Pure helpers for turning entered pitch classes into a MIDI voicing.
///
/// The selection is an ordered list (first entry is the bass). We build an
/// ascending stack: each note after the bass is placed at the lowest octave
/// strictly above the previous note. This preserves the order notes were
/// tapped (MIDI order tracks press order) and lets repeats climb to the next
/// octave instead of collapsing. Chord identity is unaffected since analysis
/// works on pitch classes.
class LookupVoicing {
  const LookupVoicing._();

  /// Bass octave (C3..B3). The first note lands here.
  static const int bassOctaveBase = 48;

  /// Highest note we will climb to (C8), to keep voicings on the keyboard.
  static const int _maxMidi = 108;

  /// Builds the ascending MIDI voicing for [orderedPitchClasses].
  static List<int> midiFromPitchClasses(List<int> orderedPitchClasses) {
    final result = <int>[];
    for (final raw in orderedPitchClasses) {
      final pc = raw % 12;
      if (result.isEmpty) {
        result.add(bassOctaveBase + pc);
        continue;
      }

      final prev = result.last;
      var midi = prev - (prev % 12) + pc;
      while (midi <= prev) {
        midi += 12;
      }
      // Stop climbing past the top of the keyboard; further repeats reuse the
      // highest octave for this pitch class.
      while (midi > _maxMidi) {
        midi -= 12;
      }
      result.add(midi);
    }
    return result;
  }
}
