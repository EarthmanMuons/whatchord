/// Converts canonical ASCII accidentals into nicer display glyphs.
String toGlyphAccidentals(String ascii) {
  // Convert double accidentals first to avoid partial replacement.
  return ascii
      .replaceAll('bb', '𝄫')
      .replaceAll('x', '𝄪')
      .replaceAll('#', '♯')
      .replaceAll('b', '♭');
}

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
