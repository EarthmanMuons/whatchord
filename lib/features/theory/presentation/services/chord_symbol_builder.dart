import '../../domain/theory_domain.dart';
import '../models/chord_symbol.dart';
import 'chord_quality_formatter.dart';

class ChordSymbolBuilder {
  static ChordSymbol fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordNotationStyle notation,
  }) {
    final root = pcToName(identity.rootPc, tonality: tonality);

    String? bass;
    if (identity.hasSlashBass) {
      final interval = (identity.bassPc - identity.rootPc) % 12;
      final role = identity.toneRolesByInterval[interval];
      bass = spellPitchClass(
        identity.bassPc,
        tonality: tonality,
        chordRootName: root,
        role: role,
      );
    }

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
