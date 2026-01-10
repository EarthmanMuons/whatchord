import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';
import '../models/tonality.dart';
import 'chord_quality_formatter.dart';
import 'note_spelling.dart' show pcToName;

class ChordSymbolBuilder {
  static ChordSymbol fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
  }) {
    final root = pcToName(identity.rootPc, tonality: tonality);

    final bass = identity.hasSlashBass
        ? pcToName(identity.bassPc, tonality: tonality)
        : null;

    final quality = ChordQualityFormatter.format(
      quality: identity.quality,
      extensions: identity.extensions,
      notation: notation,
    );

    return ChordSymbol(root: root, quality: quality, bass: bass);
  }

  static String formatIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
  }) {
    return fromIdentity(
      identity: identity,
      tonality: tonality,
      notation: notation,
    ).toString();
  }
}
