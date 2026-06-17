import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../services/chord_quality_intervals.dart';
import '../services/pitch_class.dart';

/// Cached features extracted from a ChordCandidate for efficient rule evaluation.
///
/// Pre-computes properties like position, quality family, extension types,
/// and dominant7-specific characteristics to avoid repeated calculations
/// during rule application.
class CandidateFeatures {
  final bool isRootPosition;
  final bool isSixFamily;
  final bool isSeventhFamily;
  final bool isDim7;
  final bool isDimFamily;
  final bool isSus;
  final bool isCompleteMinorSharp11;
  final bool isRootPositionMinor7Add11Shell;
  final bool isCompleteMajorSixNine;
  final bool isCompleteMajorMinorTriad;
  final bool isCompleteMajorTriadInversion;
  final bool isMinorSharpFive;
  final bool isIncompleteInvertedSixth;
  final bool isCompleteNinthBassSeventhChord;
  final bool isCompleteMinor7EleventhBassSlash;
  final bool isSecondInversion;
  final bool isAlteredMajor7Sus4;
  final bool isRootDominantSus;
  final bool isRootPositionNaturalAddChord;
  final bool isStructurallyDeficient;
  final bool isUnusualSeventhQuality;

  final bool isDom7;
  final bool isAlteredFifthDom7;
  final bool isFlatFiveDom7;
  final bool isDom7RootPosition;
  final bool isDom7Slash;
  final bool dom7HasShell;
  final bool dom7SlashHasNonBassAlterations;
  final bool isCompleteDominantFlat9;
  final bool isCompleteDominantSharp9;
  final bool isCompleteAlteredFifthDominant;
  final bool isFifthlessFlatNineBassDominant;

  final bool isSlashBass;
  final int bassRoleRank;
  final bool bassIsColorTone;
  final bool hasStableBassRole;

  final int extensionCount;
  final int extensionTensionCount;
  final bool isQuestionableAdd11Slash;
  final ExtensionPreference extPref;
  final bool hasRealExt;
  final bool hasAlteredColor;
  final bool hasNaturalOrAlteredColor;
  final bool hasOnlyAddColor;
  final int unnamedToneCount;

  const CandidateFeatures({
    required this.isRootPosition,
    required this.isSixFamily,
    required this.isSeventhFamily,
    required this.isDim7,
    required this.isDimFamily,
    required this.isSus,
    required this.isCompleteMinorSharp11,
    required this.isRootPositionMinor7Add11Shell,
    required this.isCompleteMajorSixNine,
    required this.isCompleteMajorMinorTriad,
    required this.isCompleteMajorTriadInversion,
    required this.isMinorSharpFive,
    required this.isIncompleteInvertedSixth,
    required this.isCompleteNinthBassSeventhChord,
    required this.isCompleteMinor7EleventhBassSlash,
    required this.isSecondInversion,
    required this.isAlteredMajor7Sus4,
    required this.isRootDominantSus,
    required this.isRootPositionNaturalAddChord,
    required this.isStructurallyDeficient,
    required this.isUnusualSeventhQuality,
    required this.isDom7,
    required this.isAlteredFifthDom7,
    required this.isFlatFiveDom7,
    required this.isDom7RootPosition,
    required this.isDom7Slash,
    required this.dom7HasShell,
    required this.dom7SlashHasNonBassAlterations,
    required this.isCompleteDominantFlat9,
    required this.isCompleteDominantSharp9,
    required this.isCompleteAlteredFifthDominant,
    required this.isFifthlessFlatNineBassDominant,
    required this.isSlashBass,
    required this.bassRoleRank,
    required this.bassIsColorTone,
    required this.hasStableBassRole,
    required this.extensionCount,
    required this.extensionTensionCount,
    required this.isQuestionableAdd11Slash,
    required this.extPref,
    required this.hasRealExt,
    required this.hasAlteredColor,
    required this.hasNaturalOrAlteredColor,
    required this.hasOnlyAddColor,
    required this.unnamedToneCount,
  });

  factory CandidateFeatures.from(ChordCandidate c) {
    final id = c.identity;
    final q = id.quality;

    final rootPos = id.rootPc == id.bassPc;
    final pref = extensionPreference(
      id.extensions,
      sharp11AsNaturalColor: q.sharp11IsNaturalColor,
    );
    final realExt = (pref.naturalCount + pref.alterationCount) > 0;
    final bassRoleRank = _bassRoleRank(id);

    final isDim7 = q == ChordQualityToken.diminished7;
    final isDimFamily = isDim7 || q == ChordQualityToken.halfDiminished7;
    final isSlashBass = !rootPos;
    final bassIsColorTone = isSlashBass ? _bassIsColorTone(id) : false;

    final isDom7 = q == ChordQualityToken.dominant7;
    final isFlatFiveDom7 = q == ChordQualityToken.dominant7Flat5;
    final isAlteredFifthDom7 =
        isFlatFiveDom7 || q == ChordQualityToken.dominant7Sharp5;
    final isDom7RootPosition = isDom7 && rootPos;
    final isDom7Slash = isDom7 && isSlashBass;

    final dom7HasShell = (isDom7 || isAlteredFifthDom7) && _dom7HasShell(id);
    final dom7SlashHasNonBassAlterations =
        isDom7Slash && _dom7SlashHasNonBassAlterations(id);

    final hasMaj3Nat11 = _hasMajorThirdNaturalEleventh(id);

    return CandidateFeatures(
      isRootPosition: rootPos,
      isSixFamily: q.isSixFamily,
      isSeventhFamily: q.isSeventhFamily,
      isDim7: isDim7,
      isDimFamily: isDimFamily,
      isSus: q.isSus,
      isCompleteMinorSharp11: _isCompleteMinorSharp11(id),
      isRootPositionMinor7Add11Shell: _isRootPositionMinor7Add11Shell(
        id,
        rootPos,
      ),
      isCompleteMajorSixNine: _isCompleteMajorSixNine(id),
      isCompleteMajorMinorTriad: _isCompleteMajorMinorTriadCore(id),
      isCompleteMajorTriadInversion: _isCompleteMajorTriadInversion(
        id,
        rootPos,
      ),
      isMinorSharpFive: q == ChordQualityToken.minorSharp5,
      isIncompleteInvertedSixth: _isIncompleteInvertedSixth(id, rootPos),
      isCompleteNinthBassSeventhChord: _isCompleteNinthBassSeventhChord(id),
      isCompleteMinor7EleventhBassSlash: _isCompleteMinor7EleventhBassSlash(id),
      isSecondInversion: _bassRoleRank(id) == 2,
      isAlteredMajor7Sus4: _isAlteredMajor7Sus4(id, rootPos),
      isRootDominantSus: _isRootDominantSus(id, rootPos),
      isRootPositionNaturalAddChord:
          rootPos &&
          (q == ChordQualityToken.major ||
              q == ChordQualityToken.minor ||
              q == ChordQualityToken.major6 ||
              q == ChordQualityToken.minor6) &&
          pref.alterationCount == 0 &&
          pref.naturalCount == 0,
      isStructurallyDeficient: _isStructurallyDeficient(id, rootPos),
      isUnusualSeventhQuality: _isUnusualSeventhQuality(q),
      isDom7: isDom7,
      isAlteredFifthDom7: isAlteredFifthDom7,
      isFlatFiveDom7: isFlatFiveDom7,
      isDom7RootPosition: isDom7RootPosition,
      isDom7Slash: isDom7Slash,
      dom7HasShell: dom7HasShell,
      dom7SlashHasNonBassAlterations: dom7SlashHasNonBassAlterations,
      isCompleteDominantFlat9: _isCompleteDominantWithAlteration(
        id,
        quality: ChordQualityToken.dominant7,
        alteration: ChordExtension.flat9,
        alterationRole: ChordToneRole.flat9,
        fifthRole: ChordToneRole.perfect5,
        allowedAdditionalExtensions: const {ChordExtension.sharp11},
      ),
      isCompleteDominantSharp9: _isCompleteDominantWithAlteration(
        id,
        quality: ChordQualityToken.dominant7,
        alteration: ChordExtension.sharp9,
        alterationRole: ChordToneRole.sharp9,
        fifthRole: ChordToneRole.perfect5,
      ),
      isCompleteAlteredFifthDominant: _isCompleteAlteredFifthDominant(id),
      isFifthlessFlatNineBassDominant: _isFifthlessFlatNineBassDominant(id),
      isSlashBass: isSlashBass,
      bassRoleRank: bassRoleRank,
      bassIsColorTone: bassIsColorTone,
      hasStableBassRole: bassRoleRank <= 2,
      extensionCount: id.extensions.length,
      extensionTensionCount: _extensionTensionCount(pref, hasMaj3Nat11),
      isQuestionableAdd11Slash: _isQuestionableAdd11Slash(
        id,
        rootPos,
        hasMaj3Nat11,
      ),
      extPref: pref,
      hasRealExt: realExt,
      hasAlteredColor: pref.alterationCount > 0,
      hasNaturalOrAlteredColor: (pref.naturalCount + pref.alterationCount) > 0,
      hasOnlyAddColor:
          pref.addCount > 0 &&
          pref.alterationCount == 0 &&
          pref.naturalCount == 0,
      unnamedToneCount:
          popCount(id.presentIntervalsMask) - id.toneRolesByInterval.length,
    );
  }

  static bool _isCompleteDominantWithAlteration(
    ChordIdentity id, {
    required ChordQualityToken quality,
    required ChordExtension alteration,
    required ChordToneRole alterationRole,
    required ChordToneRole fifthRole,
    Set<ChordExtension> allowedAdditionalExtensions = const {},
  }) {
    if (id.quality != quality) return false;
    if (!id.extensions.contains(alteration)) {
      return false;
    }
    for (final extension in id.extensions) {
      if (extension != alteration &&
          !allowedAdditionalExtensions.contains(extension)) {
        return false;
      }
    }

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(alterationRole) &&
        roles.contains(ChordToneRole.major3) &&
        roles.contains(fifthRole) &&
        roles.contains(ChordToneRole.flat7);
  }

  /// Returns true for a fifthless dominant7 flat-nine shell whose flat-ninth is
  /// the bass note.
  ///
  /// This identifies the narrow ambiguous shape that can be heard as a familiar
  /// altered-dominant shell or as a more remote chord rooted on the bass.
  static bool _isFifthlessFlatNineBassDominant(ChordIdentity id) {
    if (id.quality != ChordQualityToken.dominant7) return false;
    if (id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.flat9)) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    if (!roles.contains(ChordToneRole.root) ||
        !roles.contains(ChordToneRole.major3) ||
        !roles.contains(ChordToneRole.flat7) ||
        roles.contains(ChordToneRole.perfect5)) {
      return false;
    }

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    if (bassInterval != 1) return false;
    return id.toneRolesByInterval[bassInterval] == ChordToneRole.flat9;
  }

  static bool _isCompleteAlteredFifthDominant(ChordIdentity id) {
    final quality = id.quality;
    if (quality != ChordQualityToken.dominant7Flat5 &&
        quality != ChordQualityToken.dominant7Sharp5) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    final hasAlteredFifth =
        roles.contains(ChordToneRole.flat5) ||
        roles.contains(ChordToneRole.sharp5);
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.major3) &&
        hasAlteredFifth &&
        roles.contains(ChordToneRole.flat7);
  }

  static bool _isUnusualSeventhQuality(ChordQualityToken quality) {
    return quality == ChordQualityToken.minor7Sharp5 ||
        quality == ChordQualityToken.dominant7sus2 ||
        quality == ChordQualityToken.dominant7sus4 ||
        quality == ChordQualityToken.dominant7Flat5 ||
        quality == ChordQualityToken.dominant7Sharp5 ||
        quality == ChordQualityToken.major7sus2 ||
        quality == ChordQualityToken.major7sus4 ||
        quality == ChordQualityToken.major7Flat5 ||
        quality == ChordQualityToken.major7Sharp5;
  }

  static bool _isCompleteMinorSharp11(ChordIdentity id) {
    if (id.quality != ChordQualityToken.minor) return false;
    if (id.extensions.length != 1) return false;
    if (!id.extensions.contains(ChordExtension.sharp11)) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.minor3) &&
        roles.contains(ChordToneRole.perfect5) &&
        roles.contains(ChordToneRole.sharp11);
  }

  static bool _isRootPositionMinor7Add11Shell(
    ChordIdentity id,
    bool rootPosition,
  ) {
    if (!rootPosition ||
        id.quality != ChordQualityToken.minor7 ||
        id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.add11)) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.minor3) &&
        roles.contains(ChordToneRole.flat7) &&
        roles.contains(ChordToneRole.add11);
  }

  static bool _isCompleteMajorSixNine(ChordIdentity id) {
    if (id.quality != ChordQualityToken.major6 ||
        id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.add9)) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.major3) &&
        roles.contains(ChordToneRole.perfect5) &&
        roles.contains(ChordToneRole.sixth) &&
        roles.contains(ChordToneRole.add9);
  }

  static bool _isCompleteMajorMinorTriadCore(ChordIdentity id) {
    final q = id.quality;
    if (q != ChordQualityToken.major && q != ChordQualityToken.minor) {
      return false;
    }
    if (id.extensions.any(
      (extension) => _isTriadCoreDestabilizingExtension(extension, quality: q),
    )) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    final hasThird = q == ChordQualityToken.major
        ? roles.contains(ChordToneRole.major3)
        : roles.contains(ChordToneRole.minor3);

    return roles.contains(ChordToneRole.root) &&
        hasThird &&
        roles.contains(ChordToneRole.perfect5);
  }

  static bool _isCompleteMajorTriadInversion(ChordIdentity id, bool rootPos) {
    if (rootPos) return false;
    if (id.quality != ChordQualityToken.major) return false;
    if (_bassRoleRank(id) > 2) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.major3) &&
        roles.contains(ChordToneRole.perfect5);
  }

  static bool _isTriadCoreDestabilizingExtension(
    ChordExtension extension, {
    required ChordQualityToken quality,
  }) {
    if (quality == ChordQualityToken.major &&
        extension == ChordExtension.add11) {
      return true;
    }

    return extension == ChordExtension.flat9 ||
        extension == ChordExtension.sharp9 ||
        extension == ChordExtension.addSharp9 ||
        extension == ChordExtension.sharp11 ||
        extension == ChordExtension.flat13;
  }

  static bool _isIncompleteInvertedSixth(ChordIdentity id, bool rootPos) {
    if (!id.quality.isSixFamily) return false;
    if (rootPos) return false;

    final roles = id.toneRolesByInterval.values;
    return !roles.contains(ChordToneRole.perfect5);
  }

  static bool _isCompleteNinthBassSeventhChord(ChordIdentity id) {
    if (!id.quality.isSeventhFamily) return false;
    if (id.rootPc == id.bassPc) return false;
    if (id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.nine)) {
      return false;
    }

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    if (bassInterval != majorSecondInterval) return false;

    final roles = id.toneRolesByInterval.values;
    final hasThird =
        roles.contains(ChordToneRole.major3) ||
        roles.contains(ChordToneRole.minor3) ||
        roles.contains(ChordToneRole.sus2) ||
        roles.contains(ChordToneRole.sus4);
    final hasSeventh =
        roles.contains(ChordToneRole.flat7) ||
        roles.contains(ChordToneRole.major7);

    return roles.contains(ChordToneRole.root) &&
        hasThird &&
        roles.contains(ChordToneRole.perfect5) &&
        hasSeventh;
  }

  static bool _isCompleteMinor7EleventhBassSlash(ChordIdentity id) {
    if (id.quality != ChordQualityToken.minor7) return false;
    if (id.rootPc == id.bassPc) return false;
    if (id.extensions.length != 1 ||
        !id.extensions.contains(ChordExtension.add11)) {
      return false;
    }

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    if (bassInterval != perfectFourthInterval) return false;

    final roles = id.toneRolesByInterval.values;
    return roles.contains(ChordToneRole.root) &&
        roles.contains(ChordToneRole.minor3) &&
        roles.contains(ChordToneRole.perfect5) &&
        roles.contains(ChordToneRole.flat7);
  }

  static bool _isAlteredMajor7Sus4(ChordIdentity id, bool rootPos) {
    if (!rootPos) return false;
    if (id.quality != ChordQualityToken.major7sus4) return false;
    return id.extensions.contains(ChordExtension.flat13);
  }

  static bool _isRootDominantSus(ChordIdentity id, bool rootPos) {
    if (!rootPos) return false;
    final q = id.quality;
    if (q != ChordQualityToken.dominant7sus2 &&
        q != ChordQualityToken.dominant7sus4) {
      return false;
    }

    final roles = id.toneRolesByInterval.values;
    final hasSuspension = q == ChordQualityToken.dominant7sus2
        ? roles.contains(ChordToneRole.sus2)
        : roles.contains(ChordToneRole.sus4);
    return hasSuspension && roles.contains(ChordToneRole.flat7);
  }

  /// A reading that omits a core triad tone in a way that makes it weaker than
  /// a competing complete major/minor triad: a plain suspended triad (no third
  /// and no seventh) or a seventh-family slash that omits every fifth.
  static bool _isStructurallyDeficient(ChordIdentity id, bool rootPos) {
    final q = id.quality;

    // Plain suspended triad: no third, and no seventh that would make it a real
    // dominant/major sus. Dominant7sus/major7sus keep their seventh and are not
    // deficient.
    if (q == ChordQualityToken.sus2 || q == ChordQualityToken.sus4) {
      return true;
    }

    // Seventh-family slash that omits every fifth (perfect, diminished, or
    // augmented). Root-position fifthless sevenths are common and intentional,
    // so only the inverted/slash form counts as deficient here.
    if (q.isSeventhFamily && !rootPos) {
      final roles = id.toneRolesByInterval.values;
      final hasFifth =
          roles.contains(ChordToneRole.perfect5) ||
          roles.contains(ChordToneRole.flat5) ||
          roles.contains(ChordToneRole.sharp5);
      if (!hasFifth) return true;
    }

    return false;
  }

  static bool _isQuestionableAdd11Slash(
    ChordIdentity id,
    bool rootPos,
    bool hasMaj3Nat11,
  ) {
    if (rootPos) return false;
    if (id.quality == ChordQualityToken.dominant7 ||
        id.quality == ChordQualityToken.dominant7Flat5 ||
        id.quality == ChordQualityToken.dominant7Sharp5) {
      return false;
    }
    return hasMaj3Nat11;
  }

  static int _extensionTensionCount(
    ExtensionPreference pref,
    bool hasMaj3Nat11,
  ) {
    var count = pref.alterationCount;

    // A natural 11 against a major third is at least as harmonically loaded as
    // an altered color. Do not let the "fewer alterations" tie-breaker prefer
    // this spelling over an otherwise stronger #11/rooted interpretation.
    if (hasMaj3Nat11) count++;

    return count;
  }

  static bool _hasMajorThirdNaturalEleventh(ChordIdentity id) {
    final roles = id.toneRolesByInterval.values;
    final hasMajorThird = roles.contains(ChordToneRole.major3);
    final hasNaturalEleventh =
        id.extensions.contains(ChordExtension.add11) ||
        id.extensions.contains(ChordExtension.eleven);
    return hasMajorThird && hasNaturalEleventh;
  }

  /// Returns true if the voicing contains the dominant7 "shell" (major 3rd + flat 7th).
  /// Shell tones are the minimal chord tones that define dominant function.
  static bool _dom7HasShell(ChordIdentity id) {
    final roles = id.toneRolesByInterval.values;
    final has3 = roles.contains(ChordToneRole.major3);
    final has7 = roles.contains(ChordToneRole.flat7);
    return has3 && has7;
  }

  static bool _dom7SlashHasNonBassAlterations(ChordIdentity id) {
    if (id.quality != ChordQualityToken.dominant7) return false;
    if (id.rootPc == id.bassPc) return false;

    // Identify which extension token corresponds to the bass role (if any),
    // so we can ignore it when deciding if the chord has "extra" alterations.
    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    final bassRole = id.toneRolesByInterval[bassInterval];
    final bassExt = _extensionFromRole(bassRole);

    // Look for any alteration extensions other than the one explained by bass.
    for (final e in id.extensions) {
      if (e == bassExt) continue;
      if (_isAlterationExtension(e)) return true;
    }
    return false;
  }

  static bool _isAlterationExtension(ChordExtension e) {
    return e == ChordExtension.flat9 ||
        e == ChordExtension.sharp9 ||
        e == ChordExtension.sharp11 ||
        e == ChordExtension.flat13;
  }

  static ChordExtension? _extensionFromRole(ChordToneRole? role) {
    // Only roles that map cleanly to ChordExtension tokens.
    return switch (role) {
      ChordToneRole.flat9 => ChordExtension.flat9,
      ChordToneRole.sharp9 => ChordExtension.sharp9,
      ChordToneRole.sharp11 => ChordExtension.sharp11,
      ChordToneRole.flat13 => ChordExtension.flat13,
      ChordToneRole.nine => ChordExtension.nine,
      ChordToneRole.eleven => ChordExtension.eleven,
      ChordToneRole.thirteenth => ChordExtension.thirteen,
      ChordToneRole.add9 => ChordExtension.add9,
      ChordToneRole.addSharp9 => ChordExtension.addSharp9,
      ChordToneRole.splitMinor3 => ChordExtension.addSharp9,
      ChordToneRole.add11 => ChordExtension.add11,
      ChordToneRole.add13 => ChordExtension.add13,
      _ => null,
    };
  }

  /// Returns true when the bass is acting as a color tone (extension/alteration)
  /// rather than a core inversion tone (3rd/5th/7th).
  ///
  /// This distinction helps identify upper-structure voicings vs traditional inversions.
  static bool _bassIsColorTone(ChordIdentity id) {
    final interval = intervalAboveRoot(id.bassPc, id.rootPc);
    final role = id.toneRolesByInterval[interval];

    if (role == null) {
      // Conservative: don't treat unknown bass-role as "color"
      // (prevents over-promoting slash interpretations).
      return false;
    }

    return !_isCoreInversionBassRole(role);
  }

  static bool _isCoreInversionBassRole(ChordToneRole role) {
    return role == ChordToneRole.root ||
        role == ChordToneRole.major3 ||
        role == ChordToneRole.minor3 ||
        role == ChordToneRole.perfect5 ||
        role == ChordToneRole.flat5 ||
        role == ChordToneRole.sharp5 ||
        role == ChordToneRole.sixth ||
        role == ChordToneRole.flat7 ||
        role == ChordToneRole.major7 ||
        role == ChordToneRole.dim7;
  }

  static int _bassRoleRank(ChordIdentity id) {
    final interval = intervalAboveRoot(id.bassPc, id.rootPc);

    // Rank inversions by commonality/stability:
    if (interval == 0) return 0; // Root position
    if (interval == 3 || interval == 4) return 1; // 1st inv (3rd in bass)
    if (interval == 7) return 2; // 2nd inv (5th in bass)
    if (interval == 10 || interval == 11) return 3; // 3rd inv (7th in bass)
    return 4; // Other slash chords
  }
}
