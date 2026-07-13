import '../../models/tonality.dart';
import '../models/chord_symbol.dart';

/// A chord symbol's rendered display strings, split for styled layout.
class ChordSymbolDisplayParts {
  const ChordSymbolDisplayParts({
    required this.root,
    required this.quality,
    required this.bass,
  });

  /// Rendered root (e.g. "F♯").
  final String root;

  /// Rendered quality suffix (e.g. "m7(♭5)").
  final String quality;

  /// Rendered slash bass, or null when absent.
  final String? bass;

  /// Whether a slash bass is present.
  bool get hasBass => bass != null;

  /// The bass, assuming [hasBass].
  String get bassRequired => bass!;

  /// Root and quality joined (no bass).
  String get base => '$root$quality';

  /// Full symbol with a compact slash (e.g. "C7/E").
  String get compactSlash => bass == null ? base : '$base/$bass';

  @override
  String toString() {
    return bass == null ? base : '$base / $bass';
  }
}

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
String noteDisplayLabel(
  String noteName, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  return _NoteNameFormatter(noteNameSystem).compact(noteName);
}

/// Spoken/accessibility form of a note name (e.g. "F sharp").
String noteSemanticLabel(
  String noteName, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
  bool includeNatural = true,
}) {
  return _NoteNameFormatter(
    noteNameSystem,
  ).spoken(noteName, includeNatural: includeNatural);
}

/// Compact UI label for a key (e.g. "E♭ major", "Fis-Dur").
String tonalityDisplayLabel(
  Tonality tonality, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  final formatter = _NoteNameFormatter(noteNameSystem);

  return switch (noteNameSystem) {
    NoteNameSystem.german =>
      '${formatter.tonalityTonic(tonality.tonic.label, isMajor: tonality.isMajor)}-${tonality.isMajor ? 'Dur' : 'Moll'}',
    _ =>
      '${formatter.compact(tonality.tonic.label)} ${tonality.isMajor ? 'major' : 'minor'}',
  };
}

/// Spoken/accessibility label for a key (e.g. "E flat major").
String tonalitySemanticLabel(
  Tonality tonality, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  final formatter = _NoteNameFormatter(noteNameSystem);

  return switch (noteNameSystem) {
    NoteNameSystem.german =>
      '${formatter.tonalityTonic(tonality.tonic.label, isMajor: tonality.isMajor)}-${tonality.isMajor ? 'Dur' : 'Moll'}',
    _ =>
      '${formatter.spoken(tonality.tonic.label, includeNatural: false)} ${tonality.isMajor ? 'major' : 'minor'}',
  };
}

/// Just the tonic label for a key, in the given note-name system.
String tonalityPickerTonicLabel(
  Tonality tonality, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  return _NoteNameFormatter(
    noteNameSystem,
  ).tonalityTonic(tonality.tonic.label, isMajor: tonality.isMajor);
}

/// Converts a canonical ASCII token such as b9, #11, or m7(b5) to UI text.
String theoryTokenDisplayLabel(String token) => toGlyphAccidentals(token);

/// Converts a canonical chord symbol to compact UI text.
String chordSymbolDisplayLabel(
  ChordSymbol symbol, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  return chordSymbolDisplayParts(
    symbol,
    noteNameSystem: noteNameSystem,
  ).toString();
}

/// Converts a chord symbol to compact text for copy, logs, and CLI output.
String chordSymbolTextLabel(
  ChordSymbol symbol, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  return chordSymbolDisplayParts(
    symbol,
    noteNameSystem: noteNameSystem,
  ).compactSlash;
}

/// Renders [symbol] into styled display parts in the given note-name system.
ChordSymbolDisplayParts chordSymbolDisplayParts(
  ChordSymbol symbol, {
  NoteNameSystem noteNameSystem = NoteNameSystem.international,
}) {
  final formatter = _NoteNameFormatter(noteNameSystem);
  final quality = theoryTokenDisplayLabel(symbol.quality);
  return ChordSymbolDisplayParts(
    root: formatter.compact(symbol.root),
    quality: quality,
    bass: symbol.hasBass ? formatter.compact(symbol.bassRequired) : null,
  );
}

class _NoteNameFormatter {
  const _NoteNameFormatter(this.system);

  final NoteNameSystem system;

  String compact(String noteName) {
    final parsed = _ParsedNote.parse(noteName);
    if (parsed == null) return toGlyphAccidentals(noteName);

    final accidental = toGlyphAccidentals(parsed.accidental);
    return switch (system) {
      NoteNameSystem.international => '${parsed.letter}$accidental',
      NoteNameSystem.german => _germanCompact(parsed),
      NoteNameSystem.fixedDo => '${_fixedDoBase(parsed.letter)}$accidental',
    };
  }

  String spoken(String noteName, {required bool includeNatural}) {
    final parsed = _ParsedNote.parse(noteName);
    if (parsed == null) return noteName.trim();

    return switch (system) {
      NoteNameSystem.international => _internationalSpoken(
        parsed,
        includeNatural: includeNatural,
      ),
      NoteNameSystem.german => _germanSpoken(parsed),
      NoteNameSystem.fixedDo => _fixedDoSpoken(
        parsed,
        includeNatural: includeNatural,
      ),
    };
  }

  String tonalityTonic(String noteName, {required bool isMajor}) {
    final label = compact(noteName);
    if (isMajor) return label;

    return switch (system) {
      NoteNameSystem.german => label.toLowerCase(),
      _ => label.toLowerCase(),
    };
  }

  String _germanCompact(_ParsedNote note) {
    if (note.letter == 'B') {
      return switch (note.accidental) {
        '' => 'H',
        'b' => 'B',
        'bb' => 'H𝄫',
        '#' => 'H♯',
        '##' || 'x' => 'H𝄪',
        _ => 'H${toGlyphAccidentals(note.accidental)}',
      };
    }

    return switch (note.accidental) {
      '' => note.letter,
      '#' => '${note.letter}is',
      '##' || 'x' => '${note.letter}isis',
      'b' => '${note.letter}${_germanFlatSuffix(note.letter)}',
      'bb' =>
        '${note.letter}${_germanFlatSuffix(note.letter)}${_germanFlatSuffix(note.letter)}',
      _ => '${note.letter}${toGlyphAccidentals(note.accidental)}',
    };
  }

  String _germanSpoken(_ParsedNote note) => _germanCompact(note);

  String _germanFlatSuffix(String letter) {
    return switch (letter) {
      'A' || 'E' => 's',
      _ => 'es',
    };
  }

  String _internationalSpoken(
    _ParsedNote note, {
    required bool includeNatural,
  }) {
    final natural = includeNatural ? '${note.letter} natural' : note.letter;
    return switch (note.accidental) {
      '' => natural,
      '#' => '${note.letter} sharp',
      'b' => '${note.letter} flat',
      '##' || 'x' => '${note.letter} double sharp',
      'bb' => '${note.letter} double flat',
      _ => '${note.letter} ${note.accidental}',
    };
  }

  String _fixedDoSpoken(_ParsedNote note, {required bool includeNatural}) {
    final base = _fixedDoBase(note.letter);
    return switch (note.accidental) {
      '' => includeNatural ? '$base natural' : base,
      '#' => '$base sharp',
      'b' => '$base flat',
      '##' || 'x' => '$base double sharp',
      'bb' => '$base double flat',
      _ => '$base ${note.accidental}',
    };
  }

  String _fixedDoBase(String letter) {
    return switch (letter) {
      'C' => 'Do',
      'D' => 'Re',
      'E' => 'Mi',
      'F' => 'Fa',
      'G' => 'Sol',
      'A' => 'La',
      'B' => 'Si',
      _ => letter,
    };
  }
}

class _ParsedNote {
  const _ParsedNote({required this.letter, required this.accidental});

  final String letter;
  final String accidental;

  static String get _letters => 'ABCDEFG';

  static _ParsedNote? parse(String noteName) {
    final s = noteName.trim();
    if (s.isEmpty) return null;

    final letter = s[0].toUpperCase();
    if (!_letters.contains(letter)) return null;

    final accidental = s.substring(1);
    return _ParsedNote(letter: letter, accidental: accidental);
  }
}
