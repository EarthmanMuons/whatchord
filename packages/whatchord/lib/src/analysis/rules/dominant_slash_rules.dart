// Dominant and slash readings ranking rules. Rule order and policy live in the two
// lists in ../ranking_rules.dart; each function here decides one
// pairwise ambiguity and returns null when it does not apply.

import '../../models/chord_candidate.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/chord_tone_role.dart';
import '../../models/tonality.dart';
import '../../services/interval_constants.dart';
import '../../services/note_spelling.dart';
import '../../services/pitch_class.dart';
import '../candidate_features.dart';
import '../ranking_policy.dart' as ranking_policy;
import 'coverage_simplicity_rules.dart';
import 'named_rule.dart';
import 'rule_scaffold.dart';

/// Resolves an exact tritone-dominant ambiguity by bass role.
///
/// {C, Db, D, E, F#, Bb} can be read as C9b5b9 or F#7(#11,b13). Both are
/// complete dominant structures, but the altered-fifth template's extra
/// required tone creates a modest cost advantage that can hide a much more
/// conventional inversion of the tritone-related dominant.
int? preferConventionalSplitNineTritoneDominant(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsSplitNine = isSplitNineFlatFiveDominant(a.identity);
  final bIsSplitNine = isSplitNineFlatFiveDominant(b.identity);
  final aIsTritoneColor = isSharp11Flat13Dominant(a.identity);
  final bIsTritoneColor = isSharp11Flat13Dominant(b.identity);
  if (!(aIsSplitNine && bIsTritoneColor) &&
      !(bIsSplitNine && aIsTritoneColor)) {
    return null;
  }
  if (intervalAboveRoot(a.identity.rootPc, b.identity.rootPc) !=
      tritoneInterval) {
    return null;
  }
  if (fa.bassRoleRank == fb.bassRoleRank) return null;
  if ((a.cost - b.cost).abs() > ranking_policy.splitNineTritoneWindow) {
    return null;
  }

  return fa.bassRoleRank < fb.bassRoleRank ? -1 : 1;
}

bool isSplitNineFlatFiveDominant(ChordIdentity id) {
  return id.quality == ChordQuality.dominant7Flat5 &&
      id.extensions.length == 2 &&
      id.extensions.contains(ChordExtension.flat9) &&
      id.extensions.contains(ChordExtension.nine);
}

bool isSharp11Flat13Dominant(ChordIdentity id) {
  return id.quality == ChordQuality.dominant7 &&
      id.extensions.length == 2 &&
      id.extensions.contains(ChordExtension.sharp11) &&
      id.extensions.contains(ChordExtension.flat13);
}

/// Prefers a root-position minor-eleventh shell over inverted sus readings.
///
/// Example: {D, F, G, C} with D in the bass is most naturally Dm7(add11), a
/// standard minor-eleventh shell with an omitted fifth, rather than G7sus4/D
/// or Csus2sus4/D. The competing sus readings remain appropriate when their
/// own roots are in the bass.
final RuleFn preferRootMinor7Add11ShellOverSusSlash = preferOver(
  isPreferred: (_, f, _) => f.isRootPositionMinor7Add11Shell,
  competitorQualifies: (c, f, _) =>
      !f.isRootPosition &&
      (c.identity.quality == ChordQuality.dominant7sus4 ||
          c.identity.quality == ChordQuality.sus2sus4),
  costCap: ranking_policy.m7Add11ShellCap,
);

/// Prefers a complete dominant sharp-nine over a root-position non-seventh
/// chord carrying destabilizing altered color.
///
/// Example: {C, Eb, E, G, Bb} with Eb in the bass is C7#9/Eb, not Eb6b9.
/// The seventh completes the conventional altered dominant; without it, the
/// sixth-chord reading remains a genuine split-third ambiguity.
///
/// The same principle covers dense altered dominants with #11 plus either a
/// natural or flat thirteenth: the complete dominant shell is more idiomatic
/// than a major-sixth chord carrying split-third, flat-nine, and eleventh
/// add-tone color.
///
/// Sharp-five dominant sevenths are included when they contain the same
/// complete root/third/altered-fifth/seventh/#9 organization. A complete
/// A7#5#9 is more idiomatic than a root-position sus or add chord whose main
/// evidence is flat-nine and added-thirteenth color.
final RuleFn preferCompleteDominantSharp9OverNonSeventhColor = preferOver(
  isPreferred: (c, _, _) => isCompleteDominantSharpNineReading(c.identity),
  competitorQualifies: (c, f, _) =>
      isStableNonSeventhSharpNineCompetitor(c.identity, f),
  costCap: ranking_policy.dom7Sharp9Cap,
);

bool isCompleteDominantSharpNineReading(ChordIdentity id) {
  final fifthRole = switch (id.quality) {
    ChordQuality.dominant7 => ChordToneRole.perfect5,
    ChordQuality.dominant7Sharp5 => ChordToneRole.sharp5,
    _ => null,
  };
  if (fifthRole == null) return false;
  if (!id.extensions.contains(ChordExtension.sharp9)) return false;
  if (id.extensions.any(
    (extension) =>
        extension != ChordExtension.sharp9 &&
        extension != ChordExtension.sharp11 &&
        extension != ChordExtension.thirteen &&
        extension != ChordExtension.flat13,
  )) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.sharp9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(fifthRole) &&
      roles.contains(ChordToneRole.flat7);
}

final RuleFn preferCompleteFlatNineFlatThirteenthDominantOverRemoteSpelling =
    preferOver(
      isPreferred: (c, _, _) =>
          _isCompleteFlatNineFlatThirteenthDominant(c.identity),
      competitorQualifies: (_, f, _) =>
          !f.isDom7 && (f.isDimFamily || f.isSeventhFamily),
    );

bool _isCompleteFlatNineFlatThirteenthDominant(ChordIdentity id) {
  if (id.quality != ChordQuality.dominant7) return false;
  if (!id.extensions.contains(ChordExtension.flat9) ||
      !id.extensions.contains(ChordExtension.flat13)) {
    return false;
  }
  if (id.extensions.any(
    (extension) =>
        extension != ChordExtension.flat9 && extension != ChordExtension.flat13,
  )) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.flat13) &&
      roles.contains(ChordToneRole.flat7);
}

bool _isStableSplitThirdSixth(ChordIdentity id, CandidateFeatures features) {
  if (!features.isSixFamily || !features.hasStableBassRole) return false;
  final extensions = id.extensions;
  if (!extensions.contains(ChordExtension.flat9)) return false;
  return extensions.length == 1 ||
      (extensions.length == 2 &&
          extensions.contains(ChordExtension.addSharp9)) ||
      (extensions.length == 3 &&
          extensions.contains(ChordExtension.addSharp9) &&
          (extensions.contains(ChordExtension.sharp11) ||
              extensions.contains(ChordExtension.add11)));
}

bool isStableNonSeventhSharpNineCompetitor(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (_isStableSplitThirdSixth(id, features)) return true;
  if (!features.hasStableBassRole || features.isSeventhFamily) return false;

  final extensions = id.extensions;
  final hasFlatNine =
      extensions.contains(ChordExtension.flat9) ||
      extensions.contains(ChordExtension.addFlat9);
  final hasDestabilizingUpperColor =
      extensions.contains(ChordExtension.addSharp9) ||
      extensions.contains(ChordExtension.sharp11) ||
      extensions.contains(ChordExtension.add11) ||
      extensions.contains(ChordExtension.thirteen) ||
      extensions.contains(ChordExtension.add13) ||
      extensions.contains(ChordExtension.flat13);

  return hasFlatNine && hasDestabilizingUpperColor;
}

/// Prefers a dominant flat-nine shell in a stable inversion over a
/// diminished reading that needs an added or altered color tone.
///
/// Example: {C, Db, E, G, Bb} with G in the bass is normally C7b9/G, not
/// Gdim7(add11). The dominant reading names a complete, conventional chord;
/// the diminished reading respells E as Fb and treats C as added color.
///
/// Keep this bounded to root, first, and second inversion. With the dominant
/// seventh or a color tone in the bass, the diminished interpretation can be
/// the clearer reading.
final RuleFn preferCompleteDom7Flat9OverColoredDim7 = preferOver(
  isPreferred: (c, f, _) => isStableDominantFlatNineShell(c.identity, f),
  competitorQualifies: (c, f, _) => _isColoredDiminishedReading(c.identity, f),
  costCap: ranking_policy.dom7Flat9Cap,
);

bool isStableDominantFlatNineShell(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (id.quality != ChordQuality.dominant7) return false;
  if (!features.hasStableBassRole) return false;
  if (!id.extensions.contains(ChordExtension.flat9)) return false;
  for (final extension in id.extensions) {
    if (extension != ChordExtension.flat9 &&
        extension != ChordExtension.sharp9 &&
        extension != ChordExtension.sharp11) {
      return false;
    }
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.flat7) &&
      roles.contains(ChordToneRole.flat9);
}

bool _isColoredDiminishedReading(ChordIdentity id, CandidateFeatures features) {
  if (!features.isDimFamily && id.quality != ChordQuality.diminished) {
    return false;
  }
  if (features.extensionCount == 0) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.minor3) &&
      roles.contains(ChordToneRole.flat5);
}

/// Prefers a fifthless flat-nine-bass dominant shell over the two remote
/// reinterpretations produced by the same four pitch classes.
///
/// Example: {C, Db, E, Bb} with Db in the bass is C7b9/Db, not C#m(maj13)
/// or A#dim(add9)/C#. The dominant names the familiar E-Bb tritone shell; the
/// competitors require less common added-tone structures.
///
/// This remains an ambiguity preference, not an absolute analysis: when the
/// bass-rooted minor-major7 reading is rooted on the selected tonic, context
/// provides enough evidence to leave that lower-cost reading ahead.
final RuleFn preferFlatNineBassDominantOverRemoteReinterpretation = preferOver(
  isPreferred: (_, f, _) => f.isFifthlessFlatNineBassDominant,
  competitorQualifies: (c, f, tonality) {
    final isBassRootedMinorMajor7 =
        f.isRootPosition && c.identity.quality == ChordQuality.minorMajor7;
    if (isBassRootedMinorMajor7 &&
        tonality.isMinor &&
        c.identity.rootPc == tonality.tonicPitchClass) {
      // Context provides enough evidence to leave the lower-cost tonic
      // minor-major reading ahead.
      return false;
    }
    return isBassRootedMinorMajor7 ||
        c.identity.quality == ChordQuality.diminished;
  },
  costCap: ranking_policy.flatNineBassCap,
);

/// Resolves C7#9 vs Eb°7 ambiguity by preferring the dominant reading when:
/// - Dominant is in root position with shell tones (3rd + b7) present
/// - Dominant has color tones (extensions/alterations)
/// - Diminished reading would be a slash chord with color-tone bass
///
/// Example: {C, E, Bb, Eb} → prefer C7b9 over Eb°7/C
final RuleFn preferAlteredDom7 = preferOver(
  isPreferred: (_, f, _) => f.isDom7,
  // Require that the dominant is actually "doing something dominant-ish",
  // i.e. it has at least one real extension/alteration. This is what keeps
  // plain C7 from always beating (say) Cdim7 contexts.
  preferredQualifies: (_, f, _) =>
      f.isDom7RootPosition && f.dom7HasShell && f.hasNaturalOrAlteredColor,
  competitorQualifies: (_, f, _) =>
      f.isDimFamily && f.isSlashBass && f.bassIsColorTone,
);

/// Distinguishes upper-structure dominants from inversions.
///
/// When comparing two dominant7 readings (root-position vs slash):
/// - If slash bass is a color tone (e.g., #11, b9, 13) with no other alterations,
///   treat it as an intentional upper-structure voicing → prefer slash
/// - If slash bass is a core tone (3rd/5th/7th), treat it as an inversion → prefer root
///
/// Example: {Gb, C, E, Bb} → prefer C7/F# over Gb7#11
int? preferUpperStructureDom7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (!fa.isDom7 || !fb.isDom7) return null;

  // Safety: ensure we really have (slash vs root-position).
  if (fa.isRootPosition == fb.isRootPosition) return null;

  final slashIsA = fa.isDom7Slash;
  final fSlash = slashIsA ? fa : fb;
  final fRoot = slashIsA ? fb : fa;

  // Safety: ensure we really have (slash vs root-position).
  if (!fSlash.isDom7Slash || !fRoot.isDom7RootPosition) return null;

  // Require shell tones to avoid overfitting to sparse voicings.
  if (!fSlash.dom7HasShell || !fRoot.dom7HasShell) return null;

  // If slash bass is color, it *might* be an upper-structure reading,
  // but only if the slash-dominant doesn't have other alterations besides the bass.
  final slashLooksLikeUpperStructure =
      fSlash.bassIsColorTone && !fSlash.dom7SlashHasNonBassAlterations;

  if (slashLooksLikeUpperStructure) {
    // Slash candidate wins.
    return slashIsA ? -1 : 1;
  } else {
    // Otherwise treat it as an inversion-ish/weird slash and prefer root-position.
    return slashIsA ? 1 : -1;
  }
}

/// Prefers a conventional extended dominant, in root position or a stable
/// shell-tone inversion, over a remote altered-fifth dominant slash spelling in
/// close calls.
///
/// Example: {C, E, G, Bb, D, F#} is better read as C9#11 than D11#5/C.
/// The same applies to C9#11/Bb: the altered-fifth spelling is possible, but it
/// respells the stable dominant seventh as A# and loses the direct inversion.
final RuleFn preferRootExtendedDom7OverAlteredFifthSlash = preferOver(
  isPreferred: (c, f, _) => _isStableExtendedDom7(c.identity, f),
  competitorQualifies: (_, f, _) =>
      f.isAlteredFifthDom7 && f.isSlashBass && f.dom7HasShell,
);

/// Prefers a bass-rooted suspended dominant over remote slash spellings.
///
/// Example: {D, G, A, C, E} with D in the bass is normally read as D9sus4,
/// not Em7#5(add11)/D. The latter is pitch-class valid, but it respells C as
/// B# and turns a straightforward dominant sus voicing into a remote altered
/// seventh slash chord.
int? preferRootDominantSusOverSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isRootDominantSus;
  final bIsPreferred = fb.isRootDominantSus;
  if (aIsPreferred == bIsPreferred) return null;

  final preferred = aIsPreferred ? a.identity : b.identity;
  final fPreferred = aIsPreferred ? fa : fb;
  if (fPreferred.extPref.alterationCount > 0 &&
      !_isRootDominantSusFlatNine(preferred)) {
    return null;
  }

  final fOther = aIsPreferred ? fb : fa;
  if (!fOther.isSlashBass) return null;

  // When the slash candidate is a conventional major/minor triad with
  // only add-tone extensions (e.g., Abadd11/Eb), prefer it over the
  // root-position dominant sus. The add-tone slash is a simpler and
  // more expected reading — all downstream tie-breakers would also
  // favor it, so resolve directly here.
  final slashQuality = aIsPreferred ? b.identity.quality : a.identity.quality;
  final isConventionalSlash =
      (slashQuality == ChordQuality.major ||
          slashQuality == ChordQuality.minor) &&
      fOther.extPref.alterationCount == 0 &&
      fOther.extPref.naturalCount == 0;
  if (isConventionalSlash) return aIsPreferred ? 1 : -1;

  return aIsPreferred ? -1 : 1;
}

bool _isRootDominantSusFlatNine(ChordIdentity id) {
  return id.bassPc == id.rootPc &&
      id.quality == ChordQuality.dominant7sus4 &&
      id.extensions.length == 1 &&
      id.extensions.contains(ChordExtension.flat9);
}

/// Prefers a complete Lydian major triad inversion over a sparse
/// major-thirteenth-sus4 spelling in close cases.
///
/// Example: {C, D♭, G♭, B♭} with D♭ in the bass is more directly G♭♯11/D♭:
/// G♭-B♭-D♭ is a complete major triad with C as Lydian color. The D♭maj13sus4
/// spelling is possible, but it has neither the major third nor fifth of D♭ and
/// turns the G♭ triad root into a suspended tone.
final RuleFn preferCompleteMajorSharpElevenInversionOverMajor13Sus4 =
    preferOver(
      isPreferred: (c, f, _) =>
          _isCompleteMajorSharpElevenInversion(c.identity, f),
      competitorQualifies: (c, _, _) =>
          _isSparseMajorThirteenSusFour(c.identity),
    );

bool _isCompleteMajorSharpElevenInversion(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (!features.isCompleteMajorTriadInversion) return false;
  if (id.extensions.length != 1 ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.sharp11);
}

bool _isSparseMajorThirteenSusFour(ChordIdentity id) {
  if (id.quality != ChordQuality.major7sus4) return false;
  if (!id.extensions.contains(ChordExtension.thirteen)) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.sus4) &&
      roles.contains(ChordToneRole.major7) &&
      roles.contains(ChordToneRole.thirteen) &&
      !roles.contains(ChordToneRole.major3) &&
      !roles.contains(ChordToneRole.perfect5);
}

/// Prefers a complete major triad inversion over a seventh-family slash chord
/// where the bass note only appears as a color-tone add-extension.
///
/// Example: {A, B, C, F} with A in the bass reads naturally as F(#11)/A
/// (first inversion, bass=M3), not Cmaj13sus4/A where the bass A is
/// merely a thirteenth on an unrelated root. The inversion reading keeps
/// all four tones in a single coherent chord name without borrowing the bass
/// as an ornament.
final RuleFn preferCompleteMajorInversionOverSeventhColorBassSlash = preferOver(
  isPreferred: (_, f, _) => f.isCompleteMajorTriadInversion,
  competitorQualifies: (_, f, _) => f.isSeventhFamily && f.bassIsColorTone,
);

bool _isStableExtendedDom7(ChordIdentity id, CandidateFeatures features) {
  if (!features.isDom7RootPosition && !features.isDom7Slash) return false;
  if (!features.dom7HasShell) return false;
  if (!id.extensions.contains(ChordExtension.nine)) return false;
  if (!id.extensions.contains(ChordExtension.sharp11)) return false;

  final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
  return bassInterval == chordRootInterval ||
      bassInterval == majorThirdInterval ||
      bassInterval == perfectFifthInterval ||
      bassInterval == minorSeventhInterval;
}

/// Prefers a complete sharp-nine/sharp-eleven dominant thirteenth over a
/// root-position minor-thirteenth spelling that needs both flat-nine and
/// sharp-eleven color.
///
/// Example: {C, Db, Eb, E, F#, G, A} can be read as A13#9#11/F# or
/// F#m13(b9,#11). Both name every pitch, but the dominant reading preserves the
/// complete A-C#-E-G shell and uses standard altered-dominant vocabulary, while
/// the minor reading depends on the much less idiomatic b9/#11 minor color
/// combination.
final RuleFn preferCompleteAlteredThirteenthDominantOverAlteredMinorThirteenth =
    preferOver(
      isPreferred: (c, _, _) =>
          _isCompleteSharpNineSharpElevenThirteenthDominant(c.identity),
      competitorQualifies: (c, f, _) =>
          _isAlteredMinorThirteenth(c.identity, f),
    );

bool _isCompleteSharpNineSharpElevenThirteenthDominant(ChordIdentity id) {
  if (id.quality != ChordQuality.dominant7) return false;
  if (id.extensions.length != 3 ||
      !id.extensions.contains(ChordExtension.sharp9) ||
      !id.extensions.contains(ChordExtension.sharp11) ||
      !id.extensions.contains(ChordExtension.thirteen)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.sharp9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.sharp11) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.thirteen) &&
      roles.contains(ChordToneRole.flat7);
}

bool _isAlteredMinorThirteenth(ChordIdentity id, CandidateFeatures features) {
  if (id.quality != ChordQuality.minor7 || !features.hasStableBassRole) {
    return false;
  }
  if (id.extensions.length != 3 ||
      !id.extensions.contains(ChordExtension.flat9) ||
      !id.extensions.contains(ChordExtension.sharp11) ||
      !id.extensions.contains(ChordExtension.thirteen)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.minor3) &&
      roles.contains(ChordToneRole.sharp11) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.thirteen) &&
      roles.contains(ChordToneRole.flat7);
}

/// Prefers complete altered sharp-five dominant notation over remote spellings.
///
/// Example: {C, Db, E, F#, Ab, Bb} is better read as C7#5(b9,#11)/Ab than
/// Ab11#5 or Bbm9#5#11. The competing spellings are pitch-class valid, but the
/// C-rooted spelling names the same material with conventional altered-dominant
/// vocabulary. The same principle applies to the simpler complete 7#5b9 shell.
int? preferCompleteAlteredSharpFiveDominantOverRemoteSpellings(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsPreferred = isAlteredSharpFiveDominant(a.identity);
  final bIsPreferred = isAlteredSharpFiveDominant(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final preferred = aIsPreferred ? a : b;
  final fPreferred = aIsPreferred ? fa : fb;
  final fOther = aIsPreferred ? fb : fa;
  final preferredHasSharpEleven = preferred.identity.extensions.contains(
    ChordExtension.sharp11,
  );
  if (!preferredHasSharpEleven && !fPreferred.isRootPosition) return null;

  if (_isStableExtendedDom7(other.identity, fOther) &&
      _alteredSharpFiveHasDoubleAccidental(preferred.identity, tonality)) {
    return null;
  }

  if (!isNaturalEleventhSharpFiveDominant(other.identity) &&
      !isRemoteAlteredNonDominantReading(other.identity)) {
    return null;
  }

  if (preferred.cost > other.cost + ranking_policy.nearTieWindow) return null;

  return aIsPreferred ? -1 : 1;
}

bool isAlteredSharpFiveDominant(ChordIdentity id) {
  if (id.quality != ChordQuality.dominant7Sharp5) return false;
  if (!id.extensions.contains(ChordExtension.flat9)) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.sharp5) &&
      roles.contains(ChordToneRole.flat7);
}

bool _alteredSharpFiveHasDoubleAccidental(ChordIdentity id, Tonality tonality) {
  final sharpFivePc = (id.rootPc + augmentedFifthInterval) % 12;
  if ((id.presentIntervalsMask & (1 << augmentedFifthInterval)) == 0) {
    return false;
  }

  final rootName = spellChordRoot(id, tonality: tonality);
  final sharpFiveName = spellPitchClass(
    sharpFivePc,
    tonality: tonality,
    chordRootName: rootName,
    role: ChordToneRole.sharp5,
  );
  return sharpFiveName.contains('x') || sharpFiveName.contains('bb');
}

bool isRemoteAlteredNonDominantReading(ChordIdentity id) {
  final isRemoteQuality = switch (id.quality) {
    ChordQuality.minorMajor7 ||
    ChordQuality.minor7Sharp5 ||
    ChordQuality.halfDiminished7 => true,
    _ => false,
  };
  return isRemoteQuality && id.extensions.isNotEmpty;
}

bool isNaturalEleventhSharpFiveDominant(ChordIdentity id) {
  if (id.quality != ChordQuality.dominant7Sharp5) return false;
  if (!id.extensions.contains(ChordExtension.eleven)) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.eleven) &&
      roles.contains(ChordToneRole.sharp5) &&
      roles.contains(ChordToneRole.flat7);
}

/// Prefers root-position diminished7 even though they're symmetrical.
///
/// Fully diminished 7th chords have identical interval structure in all inversions
/// (stacked minor 3rds), but the bass note often indicates functional intent:
/// - Leading-tone dim7: bass = tendency tone resolving up
/// - Passing/neighbor dim7: bass = dissonant approach to target chord
///
/// When costs are tied, prefer the interpretation where the bass note
/// is named as the root for notational clarity and functional analysis.
///
/// Example: {B, D, F, Ab} → prefer B°7 over D°7/B when bass is B
int? preferDim7InRoot(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (!fa.isDim7 && !fb.isDim7) return null;

  if (fa.isDim7 && fb.isDim7) {
    if (fa.isRootPosition == fb.isRootPosition) return null;
    return fb.isRootPosition ? 1 : -1;
  }

  final aIsPreferredDim7 = fa.isDim7 && fa.isRootPosition;
  final bIsPreferredDim7 = fb.isDim7 && fb.isRootPosition;

  if (aIsPreferredDim7 == bIsPreferredDim7) return null;

  final otherIsSlash = aIsPreferredDim7
      ? !fb.isRootPosition
      : !fa.isRootPosition;
  if (!otherIsSlash) return null;

  return bIsPreferredDim7 ? 1 : -1;
}

/// Prefers a root-position dominant7 (with shell) over a non-dominant slash
/// interpretation in near-ties.
///
/// This catches cases like:
///   {C, E, Bb, Db, F#, Ab, G} -> prefer C7(b9,#11,b13)
/// over remote minor-major / extended slash readings.
final RuleFn preferDom7RootOverNonDomSlash = preferOver(
  isPreferred: (_, f, _) => f.isDom7RootPosition && f.dom7HasShell,
  preferredQualifies: (c, f, _) {
    // Ensure the dominant reading is not "plain"; it should have some color.
    if (!f.hasNaturalOrAlteredColor) return false;

    // Do not promote a fifthless dominant whose natural 11 clashes with its
    // major third (Ab11 shells); without the fifth the 11 reads as a
    // suspension and the avoid-tone price is there for a reason. A complete
    // eleventh with its fifth (C11 over C-E-G-Bb-F) stays promotable.
    final roles = c.identity.toneRolesByInterval.values;
    return !(roles.contains(ChordToneRole.major3) &&
        !roles.contains(ChordToneRole.perfect5) &&
        (roles.contains(ChordToneRole.eleven) ||
            roles.contains(ChordToneRole.add11)));
  },
  // Only when the competing interpretation is a slash and not itself
  // dominant7.
  competitorQualifies: (_, f, _) =>
      f.isSlashBass && !f.isDom7 && !f.isAlteredFifthDom7,
  costCap: ranking_policy.dom7RootCap,
);

/// Prefers root-position altered-fifth dominants over close slash readings.
///
/// Flat-five and sharp-five dominant sevenths are tritone-symmetric, so a
/// slash interpretation can remain competitive on price even when the
/// root-position name is clearer. Prefer the root-position reading when it has a real
/// alteration and the slash reading only has added or natural color tones.
int? preferRootAlteredFifthDom7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (!fa.isAlteredFifthDom7 || !fb.isAlteredFifthDom7) return null;
  if (fa.isRootPosition == fb.isRootPosition) return null;

  final rootIsA = fa.isRootPosition;
  final fRoot = rootIsA ? fa : fb;
  final fSlash = rootIsA ? fb : fa;
  final rootCandidate = rootIsA ? a : b;
  final slashCandidate = rootIsA ? b : a;

  if (!fRoot.dom7HasShell || !fSlash.dom7HasShell) return null;

  if (!fRoot.hasAlteredColor || fSlash.hasAlteredColor) return null;

  if (_isWholeToneAlteredFifthRootVsNinthSlash(rootCandidate, slashCandidate)) {
    return null;
  }

  if (rootCandidate.cost >
      slashCandidate.cost + ranking_policy.alteredFifthCap) {
    return null;
  }

  return rootIsA ? -1 : 1;
}

bool _isWholeToneAlteredFifthRootVsNinthSlash(
  ChordCandidate rootCandidate,
  ChordCandidate slashCandidate,
) {
  final rootExtensions = rootCandidate.identity.extensions;
  final slashExtensions = slashCandidate.identity.extensions;

  final rootOnlyWholeToneColor =
      rootExtensions.length == 1 &&
      (rootExtensions.contains(ChordExtension.sharp11) ||
          rootExtensions.contains(ChordExtension.flat13));
  if (!rootOnlyWholeToneColor) return false;

  final slashIsNinthAlteredFifth =
      slashExtensions.length == 1 &&
      slashExtensions.contains(ChordExtension.nine) &&
      (slashCandidate.identity.quality == ChordQuality.dominant7Sharp5 ||
          slashCandidate.identity.quality == ChordQuality.dominant7Flat5);
  if (!slashIsNinthAlteredFifth) return false;

  return slashCandidate.cost <= rootCandidate.cost;
}

/// Prefers a complete seventh chord with the ninth in the bass over a remote
/// altered slash spelling.
///
/// Example: {C, D, E, G, Bb} with D in the bass is normally understood as
/// C9/D (often written C7/D), not Em7#5#11/D. Likewise, a complete
/// Dbm(maj9)/Eb is preferred over Emaj13#5/D#. The competing spellings
/// are pitch-class valid, but reinterpret a complete natural ninth chord as a
/// remote altered chord.
final RuleFn preferNinthBassSeventhOverAlteredSlash = preferOver(
  isPreferred: (_, f, _) => f.isCompleteNinthBassSeventhChord,
  competitorQualifies: (_, f, _) =>
      f.isSlashBass &&
      (f.extensionTensionCount > 0 || f.isUnusualSeventhQuality),
  costCap: ranking_policy.ninthBassCap,
);

/// Avoids promoting remote, non-dominant slash readings whose "simple" color
/// is a natural 11 against a major third.
///
/// Example: {Ab, B, C, E, F} is better read as Fm(maj7,#11)/Ab than as
/// Cmaj7#5(add11)/G#, because the F-rooted reading is a normal inversion of
/// a complete altered seventh chord while the C-rooted reading depends on a
/// non-dominant add11 clash and a less stable slash bass.
int? preferConventionalAlteredSeventhOverAdd11Slash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsQuestionableSlash = fa.isQuestionableAdd11Slash;
  final bIsQuestionableSlash = fb.isQuestionableAdd11Slash;
  if (aIsQuestionableSlash == bIsQuestionableSlash) return null;

  final questionable = aIsQuestionableSlash ? a : b;
  final conventional = aIsQuestionableSlash ? b : a;
  final fq = aIsQuestionableSlash ? fa : fb;
  final fc = aIsQuestionableSlash ? fb : fa;

  if (!fc.isSeventhFamily) return null;
  if (fc.extensionTensionCount == 0) return null;
  if (!fc.hasAlteredColor) return null;
  // A rule that promotes the "conventional" reading must not promote a
  // rare-vocabulary respelling like m7#5.
  if (conventional.identity.quality.isRareVocabulary) return null;
  if (isUnusualSeventhMissingThird(conventional.identity)) return null;
  if (fc.bassRoleRank >= fq.bassRoleRank) return null;

  // Keep this rule bounded to close structural ambiguities. Wider gaps should
  // still be decided by the raw template fit.
  if (conventional.cost >
      questionable.cost + ranking_policy.alteredSeventhCap) {
    return null;
  }

  return aIsQuestionableSlash ? 1 : -1;
}

/// Prefers a root-position major/minor add-chord over a sus-family slash
/// interpretation of the same notes.
///
/// Example: {C, E, G, F} is naturally read as Cadd11, not Fmaj7sus2/C.
/// The F-rooted sus reading fits the template cleanly (no extra tones), so it
/// can earn a lower raw cost. But that cost advantage is a structural artifact:
/// the major7sus2 template accounts for more tones as required structure than
/// the two-required-tone major template, even though musicians universally hear
/// the simpler root-position reading.
///
/// The cost guard lets the sus reading win when the cost difference is
/// decisive rather than merely a template-complexity artifact.
final RuleFn preferRootAddChordOverSusSlash = preferOver(
  isPreferred: (_, f, _) => f.isRootPositionNaturalAddChord,
  preferredQualifies: (c, _, _) => _hasOnlyNaturalAddTones(c.identity),
  competitorQualifies: (_, f, _) => f.isSus && f.isSlashBass,
  costCap: ranking_policy.addChordCap,
);

bool _hasOnlyNaturalAddTones(ChordIdentity id) {
  return id.extensions.every(
    (extension) =>
        extension == ChordExtension.add9 ||
        extension == ChordExtension.add11 ||
        extension == ChordExtension.add13,
  );
}

/// Prefers a dominant7 slash with shell tones and either a stable inversion
/// bass or a color-tone bass over a non-dominant seventh-family slash of
/// similar cost.
///
/// When the same notes can be read as either a strongly-voiced dominant7
/// (major 3rd + flat 7th present, with the bass as a core inversion tone or
/// color extension) or as a non-dominant seventh-family slash, the dominant
/// reading is the one musicians expect.
///
/// Example: {C, D♭, E♭, F, A♭, A} with A♭ bass reads as F7(♯9,♭13)/A♭,
/// not as C♯maj9♭13/A♭. The F dominant interpretation has shell tones (A +
/// E♭) and a color-tone bass (A♭ = ♯9 of F), while the C♯ reading requires
/// an unusual root and treats the same A♭ as a structural fifth inversion.
final RuleFn preferDom7ShellSlashOverSeventhFamilySlash = preferOver(
  isPreferred: (_, f, _) => f.isDom7Slash,
  // Color-bass dominant slashes are the original target of this rule; a
  // stable-bass slash qualifies only as a complete flat-nine shell.
  preferredQualifies: (c, f, _) =>
      f.dom7HasShell &&
      (f.bassIsColorTone ||
          (f.hasStableBassRole &&
              isStableDominantFlatNineShell(c.identity, f))),
  competitorQualifies: (_, f, _) =>
      f.isSeventhFamily && !f.isDom7 && f.isSlashBass,
);
