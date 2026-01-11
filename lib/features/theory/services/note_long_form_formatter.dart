abstract final class NoteLongFormFormatter {
  /// Convert canonical ASCII names to plain-English
  static String format(String noteName) {
    final s = noteName.trim();
    if (s.isEmpty) return s;

    if (s.length == 1) return s;

    final letter = s[0].toUpperCase();
    final accidental = s.substring(1);

    return switch (accidental) {
      '#' => '$letter sharp',
      'b' => '$letter flat',
      '##' => '$letter double sharp',
      'bb' => '$letter double flat',
      _ => s, // fallback
    };
  }
}
