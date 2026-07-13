import 'package:whatchord_theory/whatchord_theory.dart';

import 'chord_display_conventions.dart';
import 'chord_quality_formatter.dart';

class ChordSymbolBuilder {
  static ChordSymbol fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
    String? rootName,
  }) {
    final root = rootName ?? spellChordRoot(identity, tonality: tonality);

    String? bass;
    if (identity.hasSlashBass) {
      final interval = (identity.bassPc - identity.rootPc) % 12;
      final role = identity.toneRolesByInterval[interval];
      bass = spellSlashBass(
        identity.bassPc,
        tonality: tonality,
        chordRootName: root,
        role: role,
      );
    }

    final quality = ChordQualityFormatter.format(
      quality: identity.quality,
      extensions: ChordDisplayConventions.displayedExtensions(identity),
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
