/// Converts canonical ASCII accidentals into nicer display glyphs.
String toGlyphAccidentals(String ascii) {
  // Convert double accidentals first to avoid partial replacement.
  return ascii
      .replaceAll('bb', '𝄫')
      .replaceAll('x', '𝄪')
      .replaceAll('#', '♯')
      .replaceAll('b', '♭');
}
