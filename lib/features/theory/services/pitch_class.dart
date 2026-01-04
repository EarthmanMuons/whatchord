/// Utilities for converting note names to pitch classes (0..11).
///
/// Supports:
/// - ASCII accidentals: #, b
/// - Unicode accidentals: ♯, ♭
///
/// Examples: "C", "F#", "Bb", "F♯", "B♭"
int pitchClassFromNoteName(String name) {
  final s = name.trim();
  if (s.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Empty note name');
  }

  // Uppercase first letter, keep accidental chars.
  final letter = s[0].toUpperCase();

  final base = switch (letter) {
    'C' => 0,
    'D' => 2,
    'E' => 4,
    'F' => 5,
    'G' => 7,
    'A' => 9,
    'B' => 11,
    _ => throw ArgumentError.value(name, 'name', 'Invalid note letter'),
  };

  // Normalize accidentals to ASCII.
  final rest = s.substring(1).replaceAll('♯', '#').replaceAll('♭', 'b');

  var accidental = 0;
  for (final ch in rest.runes) {
    final c = String.fromCharCode(ch);
    if (c == '#') accidental += 1;
    if (c == 'b') accidental -= 1;
  }

  final pc = (base + accidental) % 12;
  return pc < 0 ? pc + 12 : pc;
}
