import '../../domain/theory_domain.dart';

abstract final class ChordDisplayConventions {
  static bool usesUpperStructureSlashTriad(ChordIdentity identity) {
    if (!identity.hasSlashBass) return false;

    final isPlainMajorMinor =
        identity.quality == ChordQualityToken.major ||
        identity.quality == ChordQualityToken.minor;
    if (!isPlainMajorMinor) return false;

    if (identity.extensions.length != 1 ||
        !identity.extensions.contains(ChordExtension.add9)) {
      return false;
    }

    final bassInterval = (identity.bassPc - identity.rootPc) % 12;
    if (bassInterval != majorSecondInterval) return false;

    final thirdInterval = identity.quality == ChordQualityToken.major
        ? majorThirdInterval
        : minorThirdInterval;
    final requiredTriadMask =
        (1 << 0) | (1 << thirdInterval) | (1 << perfectFifthInterval);

    return (identity.presentIntervalsMask & requiredTriadMask) ==
        requiredTriadMask;
  }

  static bool usesSixNineSlashBassConvention(ChordIdentity identity) {
    if (!identity.hasSlashBass) return false;
    if (!identity.quality.isSixFamily) return false;
    if (identity.extensions.length != 1 ||
        !identity.extensions.contains(ChordExtension.add9)) {
      return false;
    }

    final bassInterval = (identity.bassPc - identity.rootPc) % 12;
    return bassInterval == majorSecondInterval;
  }

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

  static bool usesMinorSeventhEleventhSlashBassConvention(
    ChordIdentity identity,
  ) {
    if (!identity.hasSlashBass) return false;
    if (identity.quality != ChordQualityToken.minor7) return false;
    if (identity.extensions.length != 1 ||
        !identity.extensions.contains(ChordExtension.add11)) {
      return false;
    }

    final bassInterval = (identity.bassPc - identity.rootPc) % 12;
    if (bassInterval != perfectFourthInterval) return false;

    const requiredMinor7Mask =
        (1 << 0) |
        (1 << minorThirdInterval) |
        (1 << perfectFifthInterval) |
        (1 << minorSeventhInterval);

    return (identity.presentIntervalsMask & requiredMinor7Mask) ==
        requiredMinor7Mask;
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
    if (usesUpperStructureSlashTriad(identity) ||
        usesSixNineSlashBassConvention(identity) ||
        usesSeventhNinthSlashBassConvention(identity) ||
        usesMinorSeventhEleventhSlashBassConvention(identity)) {
      return const {};
    }
    return identity.extensions;
  }
}
