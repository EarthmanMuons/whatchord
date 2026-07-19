// Note coverage, key, and simplicity ranking rules. Rule order and policy live in the two
// lists in ../ranking_rules.dart; each function here decides one
// pairwise ambiguity and returns null when it does not apply.

import '../../models/chord_candidate.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/chord_tone_role.dart';
import '../../models/scale_degree.dart';
import '../../models/tonality.dart';
import '../../services/interval_constants.dart';
import '../../services/note_spelling.dart';
import '../../services/pitch_class.dart';
import '../candidate_features.dart';
import '../ranking_policy.dart' as ranking_policy;

/// Prefers a reading that names every sounding tone over one that drops a
/// tone as added complexity outside the base template.
///
/// Example: {C, D♭, E, G} with G in the bass reads as Cadd♭9/G, not C♯dim/G
/// (which silently drops the C natural). Runs before [preferFewerAlterations]
/// so the note-dropping reading is not rewarded for its apparent simplicity.
int? preferFullyExplainedVoicing(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aDropsTone = fa.unnamedToneCount > 0;
  final bDropsTone = fb.unnamedToneCount > 0;
  if (aDropsTone == bDropsTone) return null;
  final explained = aDropsTone ? b : a;
  final dropped = aDropsTone ? a : b;
  final fExplained = aDropsTone ? fb : fa;
  final fDropped = aDropsTone ? fa : fb;
  if (_shouldNotPreferFullCoverage(
        explained.identity,
        dropped.identity,
        fExplained,
        fDropped,
        tonality,
      ) ||
      _shouldNotPreferDecoratedReadingOverLowerCostNinthShell(
        explained,
        dropped,
      )) {
    return null;
  }
  return aDropsTone ? 1 : -1;
}

bool _shouldNotPreferFullCoverage(
  ChordIdentity explained,
  ChordIdentity dropped,
  CandidateFeatures fExplained,
  CandidateFeatures fDropped,
  Tonality tonality,
) {
  if (fExplained.isUnusualSeventhQuality &&
      isUnusualSeventhMissingThird(explained) &&
      _isMajorMinorAddChord(dropped, fDropped)) {
    final explainedPenalty = _candidateSpellingPenalty(explained, tonality);
    final droppedPenalty = _candidateSpellingPenalty(dropped, tonality);
    return explainedPenalty > droppedPenalty;
  }

  return false;
}

bool _shouldNotPreferDecoratedReadingOverLowerCostNinthShell(
  ChordCandidate explained,
  ChordCandidate dropped,
) {
  return dropped.cost < explained.cost &&
      _isDominantOrMinorSeventhNinthShell(dropped.identity) &&
      (_isMajorSeventhSplitNinth(explained.identity) ||
          isUnusualSeventhMissingThird(explained.identity));
}

bool _isMajorSeventhSplitNinth(ChordIdentity id) {
  return id.quality == ChordQuality.major7 &&
      id.extensions.length == 2 &&
      id.extensions.contains(ChordExtension.flat9) &&
      id.extensions.contains(ChordExtension.sharp9);
}

bool _isDominantOrMinorSeventhNinthShell(ChordIdentity id) {
  if ((id.quality != ChordQuality.dominant7 &&
          id.quality != ChordQuality.minor7) ||
      !id.extensions.contains(ChordExtension.nine)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      (roles.contains(ChordToneRole.major3) ||
          roles.contains(ChordToneRole.minor3)) &&
      roles.contains(ChordToneRole.flat7) &&
      roles.contains(ChordToneRole.nine);
}

bool _isMajorMinorAddChord(ChordIdentity id, CandidateFeatures features) {
  if (id.quality != ChordQuality.major && id.quality != ChordQuality.minor) {
    return false;
  }
  return features.hasOnlyAddColor;
}

bool isUnusualSeventhMissingThird(ChordIdentity id) {
  if (!id.quality.isSeventhFamily) return false;

  final roles = id.toneRolesByInterval.values;
  return !roles.contains(ChordToneRole.major3) &&
      !roles.contains(ChordToneRole.minor3) &&
      !roles.contains(ChordToneRole.sus2) &&
      !roles.contains(ChordToneRole.sus4);
}

int? preferLowerCostAddChordOverMissingThirdUnusualSeventh(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsAddChord = _isMajorMinorAddChord(a.identity, fa);
  final bIsAddChord = _isMajorMinorAddChord(b.identity, fb);
  if (aIsAddChord == bIsAddChord) return null;

  final addChord = aIsAddChord ? a : b;
  final unusual = aIsAddChord ? b : a;
  if (!isUnusualSeventhMissingThird(unusual.identity)) return null;
  if (addChord.cost > unusual.cost) return null;

  return aIsAddChord ? -1 : 1;
}

/// Lets strong minor-key context resolve a split-third inversion ambiguity.
///
/// Example: {C, Db, E, A} with Db in the bass is Aadd#9/C# in neutral context,
/// but C#m(maj7,b13) in C# minor. The latter is a root-position harmonic-minor
/// tonic containing the tonic, minor third, flat sixth, and raised seventh.
///
/// Keep this pair-specific so harmonic-minor context does not broadly override
/// complete triad inversions or the generic preference for fewer tensions.
int? preferHarmonicMinorTonicOverSplitThirdInversion(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  if (!tonality.isMinor) return null;

  bool isHarmonicMinorTonic(ChordCandidate candidate, CandidateFeatures f) {
    if (!f.isRootPosition ||
        candidate.identity.quality != ChordQuality.minorMajor7 ||
        candidate.identity.extensions.length != 1 ||
        !candidate.identity.extensions.contains(ChordExtension.flat13)) {
      return false;
    }

    final analysis = tonality.scaleDegreeAnalysisForChord(candidate.identity);
    return analysis?.degree == ScaleDegree.one &&
        analysis?.source == ScaleDegreeSource.harmonicMinor;
  }

  bool isSplitThirdMajorInversion(
    ChordCandidate candidate,
    CandidateFeatures f,
  ) {
    return f.isCompleteMajorTriadInversion &&
        candidate.identity.extensions.length == 1 &&
        candidate.identity.extensions.contains(ChordExtension.addSharp9);
  }

  final aIsTonic = isHarmonicMinorTonic(a, fa);
  final bIsTonic = isHarmonicMinorTonic(b, fb);
  if (aIsTonic == bIsTonic) return null;

  final other = aIsTonic ? b : a;
  final fOther = aIsTonic ? fb : fa;
  if (!isSplitThirdMajorInversion(other, fOther)) return null;

  return aIsTonic ? -1 : 1;
}

int? preferFewerAlterations(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final cmp = fa.extensionTensionCount.compareTo(fb.extensionTensionCount);
  if (cmp == 0) return null;
  return cmp;
}

int? preferLowerCostMajorSeventhBassInversionOverColorBassSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final betterIsA = a.cost < b.cost;
  final better = betterIsA ? a : b;
  final worse = betterIsA ? b : a;
  final fBetter = betterIsA ? fa : fb;
  final fWorse = betterIsA ? fb : fa;

  if (better.cost == worse.cost) return null;
  if (!fBetter.isSeventhFamily || !fWorse.isSeventhFamily) return null;
  if (!fBetter.isSlashBass || !fWorse.isSlashBass) return null;
  if (fBetter.bassIsColorTone) return null;
  if (!fWorse.bassIsColorTone) return null;
  final betterBassInterval = intervalAboveRoot(
    better.identity.bassPc,
    better.identity.rootPc,
  );
  if (betterBassInterval != majorSeventhInterval) return null;

  return betterIsA ? -1 : 1;
}

int? preferDiatonic(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final da = tonality.scaleDegreeForChord(a.identity);
  final db = tonality.scaleDegreeForChord(b.identity);

  final aOk = da != null;
  final bOk = db != null;

  if (aOk == bOk) return null;
  return bOk ? 1 : -1;
}

/// Prefers a root-position relative-minor seventh over the equivalent
/// major-sixth slash reading.
///
/// Example: {A, C, E, G} with A in the bass is Am7, not C6/A. The two names
/// describe the same pitch set, but the sounding bass supplies the complete
/// minor-seventh root. The same relationship extends to matching add11/add9
/// color: Am7(add11) is clearer than C6/9/A.
int? preferRootMinor7OverMajor6Slash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsMinor7 = a.identity.quality == ChordQuality.minor7;
  final bIsMinor7 = b.identity.quality == ChordQuality.minor7;
  if (aIsMinor7 == bIsMinor7) return null;

  final minor7 = aIsMinor7 ? a : b;
  final fMinor7 = aIsMinor7 ? fa : fb;
  final major6 = aIsMinor7 ? b : a;
  final fMajor6 = aIsMinor7 ? fb : fa;

  if (!fMinor7.isRootPosition ||
      major6.identity.quality != ChordQuality.major6 ||
      !fMajor6.isSlashBass ||
      major6.identity.bassPc != minor7.identity.rootPc) {
    return null;
  }

  final minor7Extensions = minor7.identity.extensions;
  final major6Extensions = major6.identity.extensions;
  final plainPair = minor7Extensions.isEmpty && major6Extensions.isEmpty;
  final matchingColorPair =
      minor7Extensions.length == 1 &&
      (minor7Extensions.contains(ChordExtension.add11) ||
          minor7Extensions.contains(ChordExtension.eleven)) &&
      major6Extensions.length == 1 &&
      major6Extensions.contains(ChordExtension.add9);
  if (!plainPair && !matchingColorPair) return null;

  return aIsMinor7 ? -1 : 1;
}

/// Prefers the selected key's tonic chord in otherwise ambiguous near-ties.
///
/// This lets context resolve relative major/minor sonorities without overriding
/// stronger structural evidence.
int? preferTonicChord(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final da = tonality.scaleDegreeForChord(a.identity);
  final db = tonality.scaleDegreeForChord(b.identity);
  if (da == null || db == null) return null;

  final aIsI = da == ScaleDegree.one;
  final bIsI = db == ScaleDegree.one;

  if (aIsI == bIsI) return null;

  return bIsI ? 1 : -1;
}

/// Prefers stacked natural extensions (9, 11, 13) over "add" extensions,
/// then prefers fewer total extensions for simpler interpretations.
int? preferNaturalExtensions(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final natural = fb.extPref.naturalCount.compareTo(fa.extPref.naturalCount);
  if (natural != 0) {
    final preferred = natural < 0 ? a : b;
    final other = natural < 0 ? b : a;
    final fPreferred = natural < 0 ? fa : fb;
    final fOther = natural < 0 ? fb : fa;
    if (fPreferred.isStructurallyDeficient &&
        !fPreferred.dom7HasShell &&
        !fOther.isStructurallyDeficient) {
      return null;
    }
    if (_shouldNotPreferFullCoverage(
          preferred.identity,
          other.identity,
          fPreferred,
          fOther,
          tonality,
        ) ||
        _shouldNotPreferDecoratedReadingOverLowerCostNinthShell(
          preferred,
          other,
        )) {
      return null;
    }
    return natural;
  }

  final add = fa.extPref.addCount.compareTo(fb.extPref.addCount);
  if (add != 0) {
    final preferred = add < 0 ? a : b;
    final other = add < 0 ? b : a;
    final fPreferred = add < 0 ? fa : fb;
    final fOther = add < 0 ? fb : fa;
    if (_shouldNotPreferFullCoverage(
      preferred.identity,
      other.identity,
      fPreferred,
      fOther,
      tonality,
    )) {
      return null;
    }
    return add;
  }

  final total = fa.extPref.totalCount.compareTo(fb.extPref.totalCount);
  if (total != 0) {
    final preferred = total < 0 ? a : b;
    final other = total < 0 ? b : a;
    final fPreferred = total < 0 ? fa : fb;
    final fOther = total < 0 ? fb : fa;
    if (_shouldNotPreferFullCoverage(
      preferred.identity,
      other.identity,
      fPreferred,
      fOther,
      tonality,
    )) {
      return null;
    }
    return total;
  }

  return null;
}

int? preferRootPosition(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  if (fa.isRootPosition == fb.isRootPosition) return null;
  final preferred = fa.isRootPosition ? a : b;
  final other = fa.isRootPosition ? b : a;
  final fPreferred = fa.isRootPosition ? fa : fb;
  final fOther = fa.isRootPosition ? fb : fa;
  if (_shouldNotPreferFullCoverage(
        preferred.identity,
        other.identity,
        fPreferred,
        fOther,
        tonality,
      ) ||
      _shouldNotPreferDecoratedReadingOverLowerCostNinthShell(
        preferred,
        other,
      )) {
    return null;
  }
  return fb.isRootPosition ? 1 : -1;
}

int? preferConventionalInversion(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final cmp = fa.bassRoleRank.compareTo(fb.bassRoleRank);
  if (cmp == 0) return null;
  final preferred = cmp < 0 ? a : b;
  final other = cmp < 0 ? b : a;
  final fPreferred = cmp < 0 ? fa : fb;
  final fOther = cmp < 0 ? fb : fa;
  if (_shouldNotPreferFullCoverage(
        preferred.identity,
        other.identity,
        fPreferred,
        fOther,
        tonality,
      ) ||
      _shouldNotPreferDecoratedReadingOverLowerCostNinthShell(
        preferred,
        other,
      )) {
    return null;
  }
  return cmp;
}

/// Resolves near-tied extended dominant readings rooted a tritone apart by
/// choosing the reading musicians can read directly.
///
/// Tritone-twin dominants describe the same tension collection from either
/// root (C7alt vs F#9#11). Which root is clearer depends on how its members
/// spell in context: {C, Db, E, F#, Ab, Bb} over E is C7(#5,b9,#11)/E, not
/// F#9#11/E, because the F# reading spells A# and B#. Plain fifthless-7b5
/// twins carry no extensions and are handled later by
/// [preferCleanerTritoneFlatFiveDominantSpelling].
int? preferCleanerSpelledTritoneTwinExtendedDominant(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsDominant = fa.isDom7 || fa.isAlteredFifthDom7;
  final bIsDominant = fb.isDom7 || fb.isAlteredFifthDom7;
  if (!aIsDominant || !bIsDominant) return null;
  if (!fa.hasRealExt && !fb.hasRealExt) return null;

  // A complete natural-thirteenth stack is a stronger identity than spelling
  // readability; leave those pairs to the structural rules below.
  if (a.identity.extensions.contains(ChordExtension.thirteen) ||
      b.identity.extensions.contains(ChordExtension.thirteen)) {
    return null;
  }
  if (intervalAboveRoot(a.identity.rootPc, b.identity.rootPc) !=
      tritoneInterval) {
    return null;
  }

  return cleanerSpelledSide(a, b, tonality, margin: 10);
}

/// Resolves exact tritone-equivalent dominant-seven-flat-five ties by choosing
/// the spelling musicians can read directly.
///
/// A plain 7b5 chord is symmetric at the tritone: {C, D, F#, Ab} can be either
/// D7b5/C or Ab7b5/C. Bass role still wins earlier for root-position cases,
/// but when both readings are otherwise tied, avoid spellings like G#7b5/B#.
int? preferCleanerTritoneFlatFiveDominantSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures _,
  CandidateFeatures _,
  Tonality tonality,
) {
  if (!_isPlainTritoneFlatFiveDominantPair(a.identity, b.identity)) {
    return null;
  }
  if ((a.cost - b.cost).abs() > ranking_policy.tritoneSpellingWindow) {
    return null;
  }

  return cleanerSpelledSide(a, b, tonality, margin: 0);
}

bool _isPlainTritoneFlatFiveDominantPair(ChordIdentity a, ChordIdentity b) {
  return a.quality == ChordQuality.dominant7Flat5 &&
      b.quality == ChordQuality.dominant7Flat5 &&
      a.extensions.isEmpty &&
      b.extensions.isEmpty &&
      intervalAboveRoot(a.rootPc, b.rootPc) == tritoneInterval;
}

/// Returns -1 or 1 for the candidate whose members spell more readably in
/// context, or null when the penalty difference does not exceed [margin].
int? cleanerSpelledSide(
  ChordCandidate a,
  ChordCandidate b,
  Tonality tonality, {
  required int margin,
}) {
  final aPenalty = _candidateSpellingPenalty(a.identity, tonality);
  final bPenalty = _candidateSpellingPenalty(b.identity, tonality);
  if ((aPenalty - bPenalty).abs() <= margin) return null;
  return aPenalty < bPenalty ? -1 : 1;
}

int _candidateSpellingPenalty(ChordIdentity identity, Tonality tonality) {
  final rootName = spellChordRoot(identity, tonality: tonality);
  var penalty = _readabilityPenalty(rootName);

  for (final entry in identity.toneRolesByInterval.entries) {
    final pc = (identity.rootPc + entry.key) % 12;
    final member = spellPitchClass(
      pc,
      tonality: tonality,
      chordRootName: rootName,
      role: entry.value,
    );
    penalty += _readabilityPenalty(member);
  }

  return penalty;
}

int _readabilityPenalty(String name) {
  final ascii = normalizeNoteNameToAscii(name);
  if (ascii.isEmpty) return 1000;

  final accidental = ascii.substring(1);
  var penalty = 0;
  for (final c in accidental.split('')) {
    if (c == '#' || c == 'b') penalty += 10;
    if (c == 'x') penalty += 20;
  }
  if (accidental.length == 2) penalty += 30;
  if (ascii == 'B#' || ascii == 'Cb' || ascii == 'E#' || ascii == 'Fb') {
    penalty += 16;
  }
  return penalty;
}

int? prefer7thChords(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  if (fa.isSeventhFamily == fb.isSeventhFamily) return null;
  final preferred = fa.isSeventhFamily ? a : b;
  final other = fa.isSeventhFamily ? b : a;
  final fPreferred = fa.isSeventhFamily ? fa : fb;
  final fOther = fa.isSeventhFamily ? fb : fa;
  if (!_hasSeventhRole(preferred.identity)) return null;
  if (_shouldNotPreferSeventhFamilyOverStableSixth(
    preferred,
    other,
    fPreferred,
    fOther,
  )) {
    return null;
  }
  if (_shouldNotPreferFullCoverage(
    preferred.identity,
    other.identity,
    fPreferred,
    fOther,
    tonality,
  )) {
    return null;
  }
  return fb.isSeventhFamily ? 1 : -1;
}

bool _hasSeventhRole(ChordIdentity id) {
  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.dim7) ||
      roles.contains(ChordToneRole.flat7) ||
      roles.contains(ChordToneRole.major7);
}

bool _shouldNotPreferSeventhFamilyOverStableSixth(
  ChordCandidate preferred,
  ChordCandidate other,
  CandidateFeatures fPreferred,
  CandidateFeatures fOther,
) {
  if (!fPreferred.isSus ||
      !fPreferred.isSeventhFamily ||
      !fPreferred.isUnusualSeventhQuality ||
      fPreferred.isRootPosition) {
    return false;
  }
  final preferredRoles = preferred.identity.toneRolesByInterval.values;
  if (preferredRoles.contains(ChordToneRole.major3) ||
      preferredRoles.contains(ChordToneRole.minor3)) {
    return false;
  }
  if (!fOther.isSixFamily) return false;
  if (fOther.unnamedToneCount > 0) return false;
  if (other.cost > preferred.cost + ranking_policy.nearTieWindow) {
    return false;
  }
  return true;
}

int? preferFewerExtensions(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final cmp = fa.extensionCount.compareTo(fb.extensionCount);
  if (cmp == 0) return null;
  return cmp;
}

int? avoidSuspended(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isSus == fb.isSus) return null;
  return fa.isSus ? 1 : -1;
}

/// Last-resort readability preference: when no structural rule separates two
/// near-tied readings, prefer the one whose members spell more cleanly rather
/// than falling through to the arbitrary root-order fallback.
int? preferCleanerSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures _,
  CandidateFeatures _,
  Tonality tonality,
) {
  return cleanerSpelledSide(a, b, tonality, margin: 0);
}
