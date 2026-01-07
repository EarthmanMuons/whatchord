import '../engine/models/chord_identity.dart';
import '../models/chord_symbol.dart';
import '../models/tonality.dart';
import 'chord_quality_formatter.dart';
import 'note_spelling.dart' show pcToName;

/// Builds and/or formats a full chord symbol string (root + quality + optional slash bass).
///
/// - Root/bass spelling are derived from the given [tonality] via [pcToName].
/// - Quality formatting is delegated to [ChordQualityFormatter].
class ChordSymbolFormatter {
  /// Create a structured [ChordSymbol] you can pass around in UI.
  static ChordSymbol fromIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordSymbolStyle style,
  }) {
    final root = pcToName(identity.rootPc, tonality: tonality);

    final bass = identity.hasSlashBass
        ? pcToName(identity.bassPc, tonality: tonality)
        : null;

    final quality = ChordQualityFormatter.format(
      quality: identity.quality,
      extensions: identity.extensions,
      style: style,
    );

    return ChordSymbol(root: root, quality: quality, bass: bass);
  }

  /// Convenience: formatted display string.
  static String formatIdentity({
    required ChordIdentity identity,
    required Tonality tonality,
    required ChordSymbolStyle style,
  }) {
    return fromIdentity(
      identity: identity,
      tonality: tonality,
      style: style,
    ).toString();
  }
}
