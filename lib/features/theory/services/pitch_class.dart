/// Utilities for converting note names to pitch classes (0..11) and
/// normalizing note-name spellings.
///
/// Canonical form (ASCII-only):
///   - Letter A–G (uppercase)
///   - Accidentals as ASCII: b, #
///   - Optional double accidentals: bb, x (double-sharp)
///
/// Accepted inputs:
///   - ASCII accidentals: #, b
///   - Unicode accidentals: ♯, ♭, 𝄪, 𝄫
///
/// Examples accepted:
///   "C", "F#", "Bb", "F♯", "B♭", "G𝄪", "Abb"
///
/// Canonical examples:
///   " f♯ " -> "F#"
///   "b♭"   -> "Bb"
///   "G𝄪"   -> "Gx"
String normalizeNoteNameToAscii(String name) {
  final s = name.trim();
  if (s.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Empty note name');
  }

  // 1) Normalize glyph accidentals to ASCII tokens.
  // Do double-accidentals first to avoid partial replacement issues.
  var t = s
      .replaceAll('𝄪', 'x') // double sharp
      .replaceAll('𝄫', 'bb') // double flat
      .replaceAll('♯', '#')
      .replaceAll('♭', 'b');

  // 2) Uppercase the note letter.
  final letter = t[0].toUpperCase();
  const validLetters = {'A', 'B', 'C', 'D', 'E', 'F', 'G'};
  if (!validLetters.contains(letter)) {
    throw ArgumentError.value(name, 'name', 'Invalid note letter');
  }

  // 3) Pull accidental region and canonicalize "##" -> "x".
  var rest = t.substring(1);

  if (rest.isEmpty) return letter;

  // Accept common ASCII double-sharp as "##" and canonicalize to "x".
  if (rest == '##') rest = 'x';

  // Quick validation: only b/#/x are allowed in the accidental region.
  for (final codePoint in rest.runes) {
    final c = String.fromCharCode(codePoint);
    if (c != 'b' && c != '#' && c != 'x') {
      throw ArgumentError.value(
        name,
        'name',
        'Invalid accidental character: "$c"',
      );
    }
  }

  // Disallow mixing x with other accidentals.
  if (rest.contains('x')) {
    if (rest != 'x') {
      throw ArgumentError.value(
        name,
        'name',
        'Invalid accidental sequence: "$rest"',
      );
    }
    return '${letter}x';
  }

  // Count sharps/flats (up to double).
  var acc = 0;
  for (final codePoint in rest.runes) {
    final c = String.fromCharCode(codePoint);
    if (c == '#') acc += 1;
    if (c == 'b') acc -= 1;
  }

  if (acc < -2 || acc > 2) {
    throw ArgumentError.value(
      name,
      'name',
      'Accidentals beyond double-flat/double-sharp not supported: "$rest"',
    );
  }

  final accText = switch (acc) {
    -2 => 'bb',
    -1 => 'b',
    0 => '',
    1 => '#',
    2 => 'x',
    _ => '',
  };

  return '$letter$accText';
}

/// Returns the pitch class (0..11) for a note name.
/// Accepts Unicode accidentals, but internally canonicalizes to ASCII first.
int pitchClassFromNoteName(String name) {
  final canon = normalizeNoteNameToAscii(name);

  final letter = canon[0]; // already validated and uppercase
  final base = switch (letter) {
    'C' => 0,
    'D' => 2,
    'E' => 4,
    'F' => 5,
    'G' => 7,
    'A' => 9,
    'B' => 11,
    _ => throw StateError('Unreachable: invalid note letter "$letter"'),
  };

  final rest = canon.substring(1);

  var accidental = 0;
  if (rest == 'x') {
    accidental = 2;
  } else {
    for (final codePoint in rest.runes) {
      final c = String.fromCharCode(codePoint);
      if (c == '#') accidental += 1;
      if (c == 'b') accidental -= 1;
    }
  }

  final pc = (base + accidental) % 12;
  return pc < 0 ? pc + 12 : pc;
}
