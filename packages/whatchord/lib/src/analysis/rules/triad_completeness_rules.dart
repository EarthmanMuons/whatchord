// Triad completeness vs seventh-family inflation ranking rules. Rule order and policy live in the two
// lists in ../ranking_rules.dart; each function here decides one
// pairwise ambiguity and returns null when it does not apply.

import '../../models/chord_candidate.dart';
import '../../models/chord_extension.dart';
import '../../models/chord_identity.dart';
import '../../models/chord_tone_role.dart';
import '../../models/tonality.dart';
import '../candidate_features.dart';
import '../ranking_policy.dart' as ranking_policy;
import 'coverage_simplicity_rules.dart';

/// Prefers a complete major/minor triad with add-tone extensions over a sparse
/// seventh-family chord that inflates the same pitches into remote color.
///
/// A complete triad with simple color tones (e.g., Bbmadd9/Db) is a more
/// conventional and stable structure than forcing the same pitches into a
/// fifthless seventh-family reading (e.g., Dbmaj13, which drops the fifth to
/// book a remote thirteenth).
int? preferCompleteTriadAddToneOverSeventhFamilyAddTone(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  // One candidate must be a complete major/minor triad carrying only
  // add-tone extensions (no alterations or stacked natural extensions).
  final aIsTriadAddTone =
      fa.isCompleteMajorMinorTriad &&
      fa.extPref.alterationCount == 0 &&
      fa.extPref.naturalCount == 0;
  final bIsTriadAddTone =
      fb.isCompleteMajorMinorTriad &&
      fb.extPref.alterationCount == 0 &&
      fb.extPref.naturalCount == 0;
  if (aIsTriadAddTone == bIsTriadAddTone) return null;

  // The other must be a seventh-family chord carrying only unaltered color,
  // indicating the same pitch set is being forced into an unconventional
  // seventh-family framework.
  final fOther = aIsTriadAddTone ? fb : fa;
  final other = aIsTriadAddTone ? b : a;
  if (!fOther.isSeventhFamily) return null;
  if (fOther.extPref.alterationCount > 0) return null;
  if (fOther.extPref.naturalCount > 0 &&
      !_isSparseNaturalExtensionSeventh(other.identity)) {
    return null;
  }

  return aIsTriadAddTone ? -1 : 1;
}

bool _isSparseNaturalExtensionSeventh(ChordIdentity id) {
  if (!id.quality.isSeventhFamily) return false;
  final roles = id.toneRolesByInterval.values;
  final hasFifth =
      roles.contains(ChordToneRole.perfect5) ||
      roles.contains(ChordToneRole.flat5) ||
      roles.contains(ChordToneRole.sharp5);
  if (hasFifth) return false;

  return id.extensions.every(
    (extension) =>
        extension == ChordExtension.add9 ||
        extension == ChordExtension.add11 ||
        extension == ChordExtension.add13 ||
        extension == ChordExtension.nine ||
        extension == ChordExtension.eleven ||
        extension == ChordExtension.thirteen,
  );
}

/// Prefers a complete major/minor triad with natural add-tone color over a
/// seventh-family reading with an unusual quality.
///
/// When a plain triad with a simple add-tone (e.g., Cadd9/G) competes against
/// a seventh-family reading with an unusual quality (e.g., Em7#5/G), the
/// seventh-family vocabulary can create a structural advantage that doesn't
/// reflect musician expectations. This also covers root-position split-ninth
/// triads such as C(addb9,add9), where the complete triad is clearer than a
/// remote unusual seventh slash with natural extension color.
int? preferSimpleTriadAddToneOverSeventhFamilyUnusualQuality(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  // One candidate must be a non-seventh, non-sus triad with at least one
  // add-tone extension (and no alterations or stacked natural extensions).
  // Covers major, minor, augmented, and diminished triads.
  final aIsTriadAddTone =
      !fa.isSeventhFamily && !fa.isSus && fa.hasOnlyAddColor;
  final bIsTriadAddTone =
      !fb.isSeventhFamily && !fb.isSus && fb.hasOnlyAddColor;
  if (aIsTriadAddTone == bIsTriadAddTone) return null;

  // The other must be a seventh-family chord with an unusual quality
  // (altered-fifth, suspended, or flat-five seventh qualities) in an
  // inversion. Standard qualities like plain dominant7, minor7, or major7
  // should not be overridden by this rule.
  final fOther = aIsTriadAddTone ? fb : fa;
  if (!fOther.isSeventhFamily) return null;
  if (!fOther.isUnusualSeventhQuality) return null;
  if (fOther.isRootPosition) return null;

  final fTriad = aIsTriadAddTone ? fa : fb;
  final triad = aIsTriadAddTone ? a : b;
  final triadIsRootPositionSplitNinth = _isRootPositionSplitNinthTriadAddTone(
    triad.identity,
    fTriad,
  );
  if (fOther.extPref.totalCount > 0) {
    if (!triadIsRootPositionSplitNinth) return null;
    if (!fOther.isSlashBass) return null;
    if (fOther.extPref.alterationCount > 0) return null;
  }

  // A complete altered dominant in a conventional inversion is a stronger
  // structural reading than an inverted augmented add-tone chord. Preserve
  // the triad preference when it aligns with the bass, but do not use it to
  // demote readings such as C7#5/E in favor of Abaugadd9/E.
  if (fOther.isCompleteAlteredFifthDominant && !fTriad.isRootPosition) {
    return null;
  }

  // Cost guard: let decisively lower-cost unusual-quality readings
  // through when the gap exceeds what structural inflation explains.
  final preferredCandidate = aIsTriadAddTone ? a : b;
  final otherCandidate = aIsTriadAddTone ? b : a;
  if (preferredCandidate.cost >
      otherCandidate.cost + ranking_policy.triadAddToneCap) {
    return null;
  }

  return aIsTriadAddTone ? -1 : 1;
}

bool _isRootPositionSplitNinthTriadAddTone(
  ChordIdentity id,
  CandidateFeatures features,
) {
  return features.isRootPosition &&
      features.isCompleteMajorMinorTriad &&
      !features.isSeventhFamily &&
      !features.isSus &&
      features.hasOnlyAddColor &&
      id.extensions.contains(ChordExtension.addFlat9) &&
      id.extensions.contains(ChordExtension.add9);
}

/// Prefers a readable Lydian major spelling over an enharmonic flat-five
/// spelling when both describe the same sparse pitch-class collection.
///
/// Example: {A♭, C, D} with C in the bass is more readable as A♭♯11/C than
/// G♯(♭5)/B♯. The flat-five triad is interval-correct, but it needs a wrap
/// accidental to spell the third; the #11 spelling preserves the observed
/// A♭-C major-third sonority and treats D as Lydian color. The same applies
/// to fifthless major-seventh voicings: D♭-F-C-G is more idiomatic as
/// D♭maj7♯11 than D♭maj7♭5/A𝄫 bookkeeping.
int? preferReadableSharpElevenMajorOverFlatFive(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures _,
  CandidateFeatures _,
  Tonality tonality,
) {
  final aIsPreferred = _isSparseSharpElevenMajor(a.identity);
  final bIsPreferred = _isSparseSharpElevenMajor(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final preferred = aIsPreferred ? a : b;
  final other = aIsPreferred ? b : a;
  if (_isSparseSharpElevenMajorTriad(preferred.identity) &&
      !preferred.identity.hasSlashBass) {
    return null;
  }
  if (!_isMatchingMajorFlatFiveCounterpart(other.identity)) return null;
  if (preferred.identity.rootPc != other.identity.rootPc ||
      preferred.identity.bassPc != other.identity.bassPc ||
      preferred.identity.presentIntervalsMask !=
          other.identity.presentIntervalsMask) {
    return null;
  }

  if (cleanerSpelledSide(preferred, other, tonality, margin: 15) != -1) {
    return null;
  }

  if (preferred.cost > other.cost + ranking_policy.sharpElevenMajorCap) {
    return null;
  }

  return aIsPreferred ? -1 : 1;
}

bool _isSparseSharpElevenMajor(ChordIdentity id) {
  return _isSparseSharpElevenMajorTriad(id) ||
      _isFifthlessSharpElevenMajorSeventh(id);
}

bool _isSparseSharpElevenMajorTriad(ChordIdentity id) {
  if (id.quality != ChordQuality.major) return false;
  if (id.extensions.length != 1 ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.sharp11) &&
      !roles.contains(ChordToneRole.perfect5);
}

bool _isFifthlessSharpElevenMajorSeventh(ChordIdentity id) {
  if (id.quality != ChordQuality.major7) return false;
  if (id.extensions.length != 1 ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.major7) &&
      roles.contains(ChordToneRole.sharp11) &&
      !roles.contains(ChordToneRole.perfect5);
}

bool _isMatchingMajorFlatFiveCounterpart(ChordIdentity id) {
  return _isPlainMajorFlatFive(id) || _isPlainMajorSeventhFlatFive(id);
}

bool _isPlainMajorFlatFive(ChordIdentity id) {
  if (id.quality != ChordQuality.majorFlat5) return false;
  if (id.extensions.isNotEmpty) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.flat5) &&
      !roles.contains(ChordToneRole.perfect5);
}

bool _isPlainMajorSeventhFlatFive(ChordIdentity id) {
  if (id.quality != ChordQuality.major7Flat5) return false;
  if (id.extensions.isNotEmpty) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.flat5) &&
      roles.contains(ChordToneRole.major7) &&
      !roles.contains(ChordToneRole.perfect5);
}

/// Prefers a complete major/minor triad carrying only natural/add color over
/// a structurally deficient reading that omits a core tone.
///
/// A complete triad (root + 3rd + 5th) with simple add color is a strong,
/// stable gestalt. Raw cost can rank it below a larger template that
/// books more "required" tones, even when that larger reading omits a core
/// tone of its own. This prefers the complete triad over:
/// - a seventh-family slash that omits every fifth (e.g. D♭maj13/F), and
/// - a plain suspended triad with no seventh (e.g. Fsus4♭13).
///
/// Example: {F, B♭, C, D♭} with F in the bass is B♭m(add9)/F, not
/// D♭maj13/F (fifthless) or Fsus4♭13 (no third, no seventh).
///
/// The deficient side is deliberately narrow so that complete seventh chords,
/// altered-fifth chords (which keep a flat/sharp fifth), six chords, and
/// dominant/major suspended chords (which keep a seventh) are never demoted.
/// A cost guard keeps a decisively lower-cost reading in front.
int? preferCompleteTriadOverDeficientReading(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsTriad = fa.isCompleteMajorMinorTriad;
  final bIsTriad = fb.isCompleteMajorMinorTriad;
  if (aIsTriad == bIsTriad) return null;

  final fOther = aIsTriad ? fb : fa;
  if (!fOther.isStructurallyDeficient) return null;

  final triadCandidate = aIsTriad ? a : b;
  final otherCandidate = aIsTriad ? b : a;
  if (triadCandidate.cost >
      otherCandidate.cost + ranking_policy.completeTriadCap) {
    return null;
  }

  return aIsTriad ? -1 : 1;
}
