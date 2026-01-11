import '../engine/models/chord_extension.dart';
import '../engine/models/chord_identity.dart';
import '../models/tonality.dart';
import 'chord_quality_token_labels.dart';
import 'note_spelling.dart' show pcToName;

class ChordLongFormFormatter {
  static String format({
    required ChordIdentity identity,
    required Tonality tonality,
  }) {
    final root = pcToName(identity.rootPc, tonality: tonality);

    final quality = identity.quality.label(ChordQualityLabelForm.long);
    final extPhrase = extensionsLongPhrase(identity.extensions);

    // Base: "C major seventh", "F# half-diminished seventh", etc.
    var s = '$root $quality$extPhrase';

    if (identity.hasSlashBass) {
      final bass = pcToName(identity.bassPc, tonality: tonality);
      // Avoid "C major ... over C"
      if (bass != root) {
        s = '$s over $bass';
      }
    }

    return s.trim();
  }
}

String extensionsLongPhrase(Set<ChordExtension> exts) {
  if (exts.isEmpty) return '';

  final ordered = exts.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // Separate "add ..." from "real extensions/alterations" if you want a nicer read.
  final adds = <String>[];
  final real = <String>[];

  for (final e in ordered) {
    if (e.isAddTone) {
      adds.add(e.longLabel); // "add nine"
    } else {
      real.add(e.longLabel); // "flat nine", "sharp eleven", "thirteen"
    }
  }

  // Example outputs:
  // - "with flat nine and sharp eleven"
  // - "with nine and thirteen"
  // - "with add nine"
  // - "with nine, sharp eleven, and add thirteen"
  final parts = <String>[];
  if (real.isNotEmpty) parts.add(_englishJoin(real));
  if (adds.isNotEmpty) parts.add(_englishJoin(adds));

  return ' with ${_englishJoin(parts)}';
}

String _englishJoin(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;
  if (items.length == 2) return '${items[0]} and ${items[1]}';
  final allButLast = items.sublist(0, items.length - 1);
  return '${allButLast.join(', ')}, and ${items.last}';
}
