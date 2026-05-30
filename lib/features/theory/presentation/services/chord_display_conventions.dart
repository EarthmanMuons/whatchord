import '../../domain/theory_domain.dart';

abstract final class ChordDisplayConventions {
  /// True when a seventh-family chord has a single natural 9 extension and the
  /// slash bass is the 9th (M2). Produces symbols like "C9 / D" → "C7 / D"
  /// since the 9 is implied by the bass. (The `nine` extension is not an
  /// add-tone, so the universal compression in [displayedExtensions] doesn't
  /// cover this case.)
  static bool usesSeventhNinthSlashBassConvention(ChordIdentity identity) {
    if (!identity.hasSlashBass) return false;
    if (!identity.quality.isSeventhFamily) return false;
    if (identity.extensions.length != 1 ||
        !identity.extensions.contains(ChordExtension.nine)) {
      return false;
    }

    final bassInterval = (identity.bassPc - identity.rootPc) % 12;
    return bassInterval == majorSecondInterval;
  }

  /// Returns true when the bass note is a standard inversion tone of the chord
  /// (third, fifth, seventh, sixth, or diminished seventh), as opposed to an
  /// extension, suspension, or foreign note in the bass.
  ///
  /// Inversions and bass-note specifications are spoken as "slash" (e.g.,
  /// "C major slash E"); foreign-bass upper-structure readings use "over"
  /// (e.g., "A major over G").
  static bool bassIsInversionTone(ChordIdentity identity) {
    if (!identity.hasSlashBass) return false;
    final interval = intervalAboveRoot(identity.bassPc, identity.rootPc);
    final role = identity.toneRolesByInterval[interval];
    if (role == null) return false;
    return role == ChordToneRole.major3 ||
        role == ChordToneRole.minor3 ||
        role == ChordToneRole.perfect5 ||
        role == ChordToneRole.flat5 ||
        role == ChordToneRole.sharp5 ||
        role == ChordToneRole.sixth ||
        role == ChordToneRole.flat7 ||
        role == ChordToneRole.major7 ||
        role == ChordToneRole.dim7;
  }

  static Set<ChordExtension> displayedExtensions(ChordIdentity identity) {
    if (usesSeventhNinthSlashBassConvention(identity)) {
      return const {};
    }

    if (!identity.hasSlashBass) return identity.extensions;

    final bassInterval = (identity.bassPc - identity.rootPc) % 12;
    return identity.extensions.where((ext) {
      // Drop add-tone extensions whose pitch class is already supplied by the
      // slash bass, avoiding redundant chord symbols like "Ab7(add11)/Db".
      if (!ext.isAddTone) return true;
      if (ext.intervalAboveRoot != bassInterval) return true;
      return false;
    }).toSet();
  }
}
