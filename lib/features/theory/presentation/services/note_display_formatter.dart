/// Converts canonical ASCII accidentals into nicer display glyphs.
String toGlyphAccidentals(String ascii) {
  // Convert double accidentals first to avoid partial replacement.
  return ascii
      .replaceAll('bb', '𝄫')
      .replaceAll('x', '𝄪')
      .replaceAll('#', '♯')
      .replaceAll('b', '♭');
}

/// Converts a canonical ASCII note token to the compact UI form.
String noteDisplayLabel(String noteName) => toGlyphAccidentals(noteName);

/// Converts a canonical ASCII token such as b9, #11, or m7(b5) to UI text.
String theoryTokenDisplayLabel(String token) => toGlyphAccidentals(token);

// Converts chord-symbol typography glyphs to SMuFL PUA codepoints.
String toSmufl(String s) {
  // Accidentals (PUA)
  s = s
      .replaceAll('bb', '\uE264') // accidentalDoubleFlat
      .replaceAll('𝄫', '\uE264')
      .replaceAll('x', '\uE263') // accidentalDoubleSharp
      .replaceAll('𝄪', '\uE263')
      .replaceAll('#', '\uE262') // accidentalSharp
      .replaceAll('♯', '\uE262')
      .replaceAll('b', '\uE260') // accidentalFlat
      .replaceAll('♭', '\uE260');

  // // Chord quality glyphs (PUA)
  // s = s
  // .replaceAll('°', '\uE870') // csymDiminished
  // .replaceAll('ø', '\uE871') // csymHalfDiminished
  // .replaceAll('+', '\uE872') // csymAugmented
  // .replaceAll('−', '\uE874'); // csymMinor

  // "Major seventh" indicator glyph (PUA)
  // s = s.replaceAll('Δ', '\uE873'); // csymMajorSeventh

  return s;
}
