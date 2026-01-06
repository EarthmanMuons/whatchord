/// Converts canonical ASCII accidentals into nicer display glyphs.
///
/// Canonical internal representation:
///   - sharp: '#'
///   - flat:  'b'
///
/// Display representation:
///   - sharp: '♯'
///   - flat:  '♭'
String formatNoteDisplay(String asciiName) {
  return asciiName.replaceAll('b', '♭').replaceAll('#', '♯');
}
