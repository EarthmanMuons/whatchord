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

  static Set<ChordExtension> displayedExtensions(ChordIdentity identity) {
    if (usesUpperStructureSlashTriad(identity) ||
        usesSixNineSlashBassConvention(identity) ||
        usesSeventhNinthSlashBassConvention(identity)) {
      return const {};
    }
    return identity.extensions;
  }
}
