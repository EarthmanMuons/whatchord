import '../../domain/theory_domain.dart';
import '../models/chord_symbol.dart';
import 'chord_display_conventions.dart';
import 'chord_quality_token_labels.dart';
import 'note_display_formatter.dart';

class ChordLongFormFormatter {
  static String format({
    required ChordIdentity identity,
    required Tonality tonality,
    NoteNameSystem noteNameSystem = NoteNameSystem.international,
    ChordLongFormAccidentalStyle accidentalStyle =
        ChordLongFormAccidentalStyle.glyph,
    String? rootNameOverride,
  }) {
    final rootName =
        rootNameOverride ?? spellChordRoot(identity, tonality: tonality);
    final root = _noteName(rootName, accidentalStyle, noteNameSystem);
    final extensions = ChordDisplayConventions.displayedExtensions(identity);

    final quality = _qualityLongPhrase(
      quality: identity.quality,
      extensions: extensions,
    );
    final extPhrase = _extensionsLongPhrase(
      extensions,
      absorbedHeadline: _absorbedLongFormExtensionForParts(
        quality: identity.quality,
        extensions: extensions,
      ),
    );

    // Base: "C major seventh", "F♯ half-diminished seventh", etc.
    var s = '$root $quality$extPhrase';

    if (identity.hasSlashBass) {
      final interval = (identity.bassPc - identity.rootPc) % 12;
      final role = identity.toneRolesByInterval[interval];

      final bassName = spellPitchClass(
        identity.bassPc,
        tonality: tonality,
        chordRootName: rootName,
        role: role,
      );
      final bass = _noteName(bassName, accidentalStyle, noteNameSystem);

      if (bass != root) {
        s = '$s over $bass';
      }
    }

    return s.trim();
  }
}

enum ChordLongFormAccidentalStyle { glyph, plainText }

String extensionsLongPhrase(Set<ChordExtension> exts) {
  return _extensionsLongPhrase(exts);
}

String _extensionsLongPhrase(
  Set<ChordExtension> exts, {
  ChordExtension? absorbedHeadline,
}) {
  if (exts.isEmpty) return '';

  final ordered = exts.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // Separate "add ..." from "real extensions/alterations" if you want a nicer read.
  final adds = <String>[];
  final real = <String>[];

  for (final e in ordered) {
    if (_isAbsorbedExtension(e, absorbedHeadline)) continue;

    if (e.isAddTone) {
      adds.add(e.longLabel); // "add nine"
    } else {
      real.add(e.longLabel); // "flat nine", "sharp eleven", "thirteen"
    }
  }

  // Example outputs:
  // - "with flat nine and sharp eleven"
  // - "with nine and thirteen"
  // - "with added nine"
  // - "with nine, sharp eleven, and added thirteen"
  final parts = <String>[];
  if (real.isNotEmpty) parts.add(_englishJoin(real));
  if (adds.isNotEmpty) parts.add(_englishJoin(adds));
  if (parts.isEmpty) return '';

  return ' with ${_englishJoin(parts)}';
}

String _qualityLongPhrase({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  if (quality.isSixFamily && extensions.contains(ChordExtension.add9)) {
    return switch (quality) {
      ChordQualityToken.major6 => 'major six-nine',
      ChordQualityToken.minor6 => 'minor six-nine',
      _ => quality.label(ChordQualityLabelForm.academic),
    };
  }

  final base = quality.label(ChordQualityLabelForm.academic);
  final headline = _headlineExtensionForParts(
    quality: quality,
    extensions: extensions,
  );

  if (headline == null) return base;

  final promoted = _replaceSeventhWithHeadline(base, headline.longLabel);
  return promoted == base ? base : promoted;
}

ChordExtension? _absorbedLongFormExtensionForParts({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  if (quality.isSixFamily && extensions.contains(ChordExtension.add9)) {
    return ChordExtension.add9;
  }

  return _headlineExtensionForParts(quality: quality, extensions: extensions);
}

ChordExtension? _headlineExtensionForParts({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  if (!quality.isSeventhFamily || quality == ChordQualityToken.diminished7) {
    return null;
  }

  if (extensions.contains(ChordExtension.thirteen)) {
    return ChordExtension.thirteen;
  }
  if (extensions.contains(ChordExtension.eleven)) {
    return ChordExtension.eleven;
  }
  if (extensions.contains(ChordExtension.nine)) {
    return ChordExtension.nine;
  }

  return null;
}

bool _isAbsorbedExtension(ChordExtension extension, ChordExtension? headline) {
  switch (headline) {
    case ChordExtension.nine:
      return extension == ChordExtension.nine;
    case ChordExtension.eleven:
      return extension == ChordExtension.nine ||
          extension == ChordExtension.eleven;
    case ChordExtension.thirteen:
      return extension == ChordExtension.nine ||
          extension == ChordExtension.eleven ||
          extension == ChordExtension.thirteen;
    case ChordExtension.add9:
      return extension == ChordExtension.add9;
    default:
      return false;
  }
}

String _replaceSeventhWithHeadline(String base, String headline) {
  if (base.contains('seventh')) {
    return base.replaceFirst('seventh', headline);
  }
  return base;
}

String _noteName(
  String noteName,
  ChordLongFormAccidentalStyle style,
  NoteNameSystem noteNameSystem,
) {
  return switch (style) {
    ChordLongFormAccidentalStyle.glyph => noteDisplayLabel(
      noteName,
      noteNameSystem: noteNameSystem,
    ),
    ChordLongFormAccidentalStyle.plainText => noteSemanticLabel(
      noteName,
      noteNameSystem: noteNameSystem,
      includeNatural: false,
    ),
  };
}

String _englishJoin(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;
  if (items.length == 2) return '${items[0]} and ${items[1]}';
  final allButLast = items.sublist(0, items.length - 1);
  return '${allButLast.join(', ')}, and ${items.last}';
}
