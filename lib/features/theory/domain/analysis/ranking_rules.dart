import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';
import '../services/chord_quality_intervals.dart';
import '../services/note_spelling.dart';
import '../services/pitch_class.dart';
import 'candidate_features.dart';
import 'common_name_prior_rule.dart';

/// Signature shared by every ranking rule. Returns -1 if `a` ranks higher, 1 if
/// `b` ranks higher, 0 or null if the rule does not apply to this pair.
typedef RuleFn =
    int? Function(
      ChordCandidate a,
      ChordCandidate b,
      CandidateFeatures fa,
      CandidateFeatures fb,
      Tonality tonality,
    );

/// A ranking rule paired with a human-readable name for debugging and for
/// explaining ranking decisions to users.
class NamedRule {
  final String name;
  final RuleFn apply;

  const NamedRule(this.name, this.apply);
}

// The two ordered lists below ARE the ranking policy: rules are tried top to
// bottom and the first one to return a non-zero result decides the pair. Order
// is therefore significant; read these lists to audit ranking behavior.
//
// NOTE: docs/site/articles/under-the-hood.html documents these rules and their
// order in detail. Update the article when rules or their order change.

/// Score-independent overrides, applied before the near-tie window check.
/// A hard rule can promote a lower-scoring reading to the top, so each is
/// deliberately narrow and guarded.
final List<NamedRule> hardRules = <NamedRule>[
  NamedRule(
    'prefer complete dominant flat-nine over colored diminished7',
    _preferCompleteDom7Flat9OverColoredDim7,
  ),
  NamedRule(
    'prefer flat-nine-bass dominant over remote reinterpretation',
    _preferFlatNineBassDominantOverRemoteReinterpretation,
  ),
  NamedRule(
    'prefer complete altered dominant inversion over altered major7',
    _preferCompleteAlteredDom7InversionOverAlteredMajor7,
  ),
  NamedRule(
    'prefer complete dominant sharp-nine over split-third sixth',
    _preferCompleteDom7Sharp9OverSixthFlat9,
  ),
  NamedRule(
    'prefer stable extended dominant over double-accidental altered-fifth slash',
    _preferStableExtendedDom7OverDoubleAccidentalAlteredFifthSlash,
  ),
  NamedRule(
    'prefer complete altered sharp-five dominant over remote spellings',
    _preferCompleteAlteredSharpFiveDominantOverRemoteSpellings,
  ),
  NamedRule(
    'prefer conventional inversion in split-nine tritone dominant ambiguity',
    _preferConventionalSplitNineTritoneDominant,
  ),
  NamedRule('prefer altered dominant7 over dim7 slash', _preferAlteredDom7),
  NamedRule(
    'prefer conventional altered seventh over add11 slash',
    _preferConventionalAlteredSeventhOverAdd11Slash,
  ),
  NamedRule(
    'prefer complete minor sharp11 over altered maj7sus4',
    _preferCompleteMinorSharp11OverAlteredMaj7Sus4,
  ),
  NamedRule(
    'prefer close root-position dominant7 over non-dominant slash',
    _preferDom7RootOverNonDomSlash,
  ),
  NamedRule(
    'prefer ninth-bass seventh chord over altered slash',
    _preferNinthBassSeventhOverAlteredSlash,
  ),
  NamedRule(
    'prefer minor7 eleventh-bass slash over minor7 sharp-five slash',
    _preferMinor7EleventhBassSlashOverMinor7SharpFiveSlash,
  ),
  NamedRule(
    'prefer root-position altered-fifth dominant over slash',
    _preferRootAlteredFifthDom7,
  ),
  NamedRule(
    'prefer root-position add-chord over sus slash',
    _preferRootAddChordOverSusSlash,
  ),
  NamedRule(
    'prefer complete triad over structurally deficient reading',
    _preferCompleteTriadOverDeficientReading,
  ),
  NamedRule(
    'prefer root-position minor-eleventh shell over sus slash',
    _preferRootMinor7Add11ShellOverSusSlash,
  ),
  NamedRule(
    'prefer complete major six-nine over inverted minor-seven sharp-five',
    _preferCompleteMajorSixNineOverInvertedMinor7Sharp5,
  ),
  NamedRule(
    'prefer complete add-nine inversion over minor-seven sharp-five',
    _preferCompleteAddNineInversionOverMinor7Sharp5,
  ),
  NamedRule(
    'prefer simple triad add-tone over seventh-family unusual quality',
    _preferSimpleTriadAddToneOverSeventhFamilyUnusualQuality,
  ),
];

/// Resolves an exact tritone-dominant ambiguity by bass role.
///
/// {C, Db, D, E, F#, Bb} can be read as C9b5b9 or F#7(#11,b13). Both are
/// complete dominant structures, but the altered-fifth template's extra
/// required tone creates a modest score advantage that can hide a much more
/// conventional inversion of the tritone-related dominant.
int? _preferConventionalSplitNineTritoneDominant(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsSplitNine = _isSplitNineFlatFiveDominant(a.identity);
  final bIsSplitNine = _isSplitNineFlatFiveDominant(b.identity);
  final aIsTritoneColor = _isSharp11Flat13Dominant(a.identity);
  final bIsTritoneColor = _isSharp11Flat13Dominant(b.identity);
  if (!(aIsSplitNine && bIsTritoneColor) &&
      !(bIsSplitNine && aIsTritoneColor)) {
    return null;
  }
  if (intervalAboveRoot(a.identity.rootPc, b.identity.rootPc) !=
      tritoneInterval) {
    return null;
  }
  if (fa.bassRoleRank == fb.bassRoleRank) return null;
  if ((a.score - b.score).abs() > 0.30) return null;

  return fa.bassRoleRank < fb.bassRoleRank ? -1 : 1;
}

bool _isSplitNineFlatFiveDominant(ChordIdentity id) {
  return id.quality == ChordQualityToken.dominant7Flat5 &&
      id.extensions.length == 2 &&
      id.extensions.contains(ChordExtension.flat9) &&
      id.extensions.contains(ChordExtension.nine);
}

bool _isSharp11Flat13Dominant(ChordIdentity id) {
  return id.quality == ChordQualityToken.dominant7 &&
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
int? _preferRootMinor7Add11ShellOverSusSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isRootPositionMinor7Add11Shell;
  final bIsPreferred = fb.isRootPositionMinor7Add11Shell;
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  final otherIsInvertedDominantSus =
      !fOther.isRootPosition &&
      other.identity.quality == ChordQualityToken.dominant7sus4;
  final otherIsInvertedDoubleSus =
      !fOther.isRootPosition &&
      other.identity.quality == ChordQualityToken.sus2sus4;
  if (!otherIsInvertedDominantSus && !otherIsInvertedDoubleSus) return null;

  final preferred = aIsPreferred ? a : b;
  if (preferred.score + 1.30 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a complete major 6/9 over a minor7 sharp-five extension spelling.
///
/// Example: {Eb, G, Bb, C, F} with Bb in the bass is most naturally Eb6/9/Bb,
/// not Gm7#5(add11)/Bb. The altered-minor template's extra required tone can
/// create a modest score advantage despite the conventional complete 6/9
/// reading.
int? _preferCompleteMajorSixNineOverInvertedMinor7Sharp5(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isCompleteMajorSixNine;
  final bIsPreferred = fb.isCompleteMajorSixNine;
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  if (other.identity.quality != ChordQualityToken.minor7Sharp5 ||
      !_minor7SharpFiveExtensionStackIsRemote(other.identity)) {
    return null;
  }

  final preferred = aIsPreferred ? a : b;
  if (preferred.score + 0.30 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

bool _minor7SharpFiveExtensionStackIsRemote(ChordIdentity id) {
  final extensions = id.extensions;
  if (extensions.isEmpty) return false;
  if (!extensions.contains(ChordExtension.add11) &&
      !extensions.contains(ChordExtension.eleven)) {
    return false;
  }
  return extensions.every(
    (extension) =>
        extension == ChordExtension.nine ||
        extension == ChordExtension.add9 ||
        extension == ChordExtension.eleven ||
        extension == ChordExtension.add11,
  );
}

/// Prefers a complete major/minor add9 inversion over root-position minor7#5.
///
/// Example: {C, D, E, G} with E in the bass is normally Cadd9/E, not Em7#5.
/// The minor7#5 template names all four pitch classes as required tones, but
/// it respells the C as B# and turns a complete add9 triad inversion into a
/// rarer altered-fifth seventh chord.
int? _preferCompleteAddNineInversionOverMinor7Sharp5(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsPreferred = _isCompleteAddNineTriadInversion(a.identity, fa);
  final bIsPreferred = _isCompleteAddNineTriadInversion(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (other.identity.quality != ChordQualityToken.minor7Sharp5) return null;
  if (!fOther.isRootPosition) return null;
  if (other.identity.extensions.isNotEmpty) return null;
  if (!_hasAwkwardMinor7SharpFiveSpelling(other.identity, tonality)) {
    return null;
  }

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteAddNineTriadInversion(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (!features.isCompleteMajorMinorTriad || features.isRootPosition) {
    return false;
  }
  if (id.extensions.length != 1 ||
      !id.extensions.contains(ChordExtension.add9)) {
    return false;
  }

  final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
  final expectedThird = id.quality == ChordQualityToken.major ? 4 : 3;
  return bassInterval == expectedThird || bassInterval == 7;
}

bool _hasAwkwardMinor7SharpFiveSpelling(ChordIdentity id, Tonality tonality) {
  if (id.quality != ChordQualityToken.minor7Sharp5) return false;
  final role = id.toneRolesByInterval[augmentedFifthInterval];
  if (role == null) return false;

  final rootName = spellChordRoot(id, tonality: tonality);
  final sharpFiveName = spellPitchClass(
    id.rootPc + augmentedFifthInterval,
    tonality: tonality,
    chordRootName: rootName,
    role: role,
  );
  final ascii = normalizeNoteNameToAscii(sharpFiveName);
  return ascii == 'B#' ||
      ascii == 'Cb' ||
      ascii == 'E#' ||
      ascii == 'Fb' ||
      ascii.contains('x') ||
      ascii.contains('bb');
}

/// Near-tie tie-breakers, applied in priority order only when two candidates
/// score within the near-tie window of each other. These encode musical
/// preferences:
/// - Structural clarity (root position, shell tones)
/// - Functional harmony (diatonic, dominant alterations)
/// - Simplicity (fewer extensions/alterations, avoid suspensions)
final List<NamedRule> tieBreakerRules = <NamedRule>[
  // Voicing evidence is consulted first: when the register clearly presents one
  // reading as an upper-structure slash and the other not, that observation
  // outranks the naming conventions below.
  NamedRule(
    'prefer voicing-supported upper-structure slash',
    _preferVoicingUpperStructureSlash,
  ),
  NamedRule('prefer root-position 6th over inverted 7th', _prefer6thInRoot),
  NamedRule(
    'prefer complete triad over incomplete inverted 6th',
    _preferCompleteTriadOverIncompleteInvertedSixth,
  ),
  NamedRule(
    'prefer upper-structure dominant7 slash',
    _preferUpperStructureDom7,
  ),
  NamedRule(
    'prefer root-position dominant sus over slash',
    _preferRootDominantSusOverSlash,
  ),
  NamedRule(
    'prefer stable extended dominant over altered-fifth slash',
    _preferRootExtendedDom7OverAlteredFifthSlash,
  ),
  NamedRule(
    'prefer complete sharp-nine thirteenth dominant over colored sixth',
    _preferCompleteSharpNineThirteenthDominantOverColoredSixth,
  ),
  NamedRule(
    'prefer complete flat-nine flat-thirteen dominant over remote spelling',
    _preferCompleteFlatNineFlatThirteenthDominantOverRemoteSpelling,
  ),
  NamedRule(
    'prefer sharp-five sharp-eleven dominant spelling over flat-five flat-thirteen',
    _preferSharpFiveSharpElevenDominantSpelling,
  ),
  NamedRule(
    'prefer complete major inversion over minor sharp-five',
    _preferCompleteMajorInversionOverMinorSharpFive,
  ),
  NamedRule(
    'prefer complete lydian six-nine over major13sus4',
    _preferCompleteLydianSixNineOverMajor13Sus4,
  ),
  NamedRule(
    'prefer complete major inversion over seventh-family color-bass slash',
    _preferCompleteMajorInversionOverSeventhColorBassSlash,
  ),
  NamedRule('prefer root-position diminished7', _preferDim7InRoot),
  NamedRule('prefer dominant7 over dim7 slash', _preferDom7Shell),
  NamedRule(
    'prefer dominant7 shell slash over non-dominant seventh-family slash',
    _preferDom7ShellSlashOverSeventhFamilySlash,
  ),
  NamedRule(
    'prefer voicing that names every tone',
    _preferFullyExplainedVoicing,
  ),
  NamedRule(
    'prefer harmonic-minor tonic over split-third inversion',
    _preferHarmonicMinorTonicOverSplitThirdInversion,
  ),
  NamedRule('prefer fewer altered/tension colors', _preferFewerAlterations),
  NamedRule('prefer diatonic chords', _preferDiatonic),
  NamedRule(
    'prefer root-position relative minor7 over major6 slash',
    _preferRootMinor7OverMajor6Slash,
  ),
  NamedRule('prefer tonic chord', _preferTonicChord),
  NamedRule('prefer I chord when bass is tonic', _preferTonicAsI),
  NamedRule(
    'prefer complete triad add-tone over seventh-family add-tone',
    _preferCompleteTriadAddToneOverSeventhFamilyAddTone,
  ),
  NamedRule(
    'prefer natural extensions over adds, then fewer total',
    _preferNaturalExtensions,
  ),
  NamedRule('prefer root position', _preferRootPosition),
  NamedRule('prefer common naming preference', preferCommonNamePrior),
  NamedRule(
    'prefer cleaner tritone flat-five dominant spelling',
    _preferCleanerTritoneFlatFiveDominantSpelling,
  ),
  NamedRule('prefer more conventional inversion', _preferConventionalInversion),
  NamedRule('prefer 7th chords over triads', _prefer7thChords),
  NamedRule('prefer fewer extensions', _preferFewerExtensions),
  NamedRule('avoid suspended chords', _avoidSuspended),
];

// ---- Six chords vs inverted sevenths -----------------------------------

/// Prefers the reading the voicing presents as an upper-structure slash: a
/// complete chord stacked above an isolated color-tone bass (e.g. an Am7 over a
/// low, gapped D reads as Am7/D rather than a root-position D9sus4). Applies
/// only when exactly one candidate carries that register evidence.
int? _preferVoicingUpperStructureSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isVoicingUpperStructureSlash == fb.isVoicingUpperStructureSlash) {
    return null;
  }
  return fa.isVoicingUpperStructureSlash ? -1 : 1;
}

/// Resolves ambiguity between 6th chords and inverted 7th chords.
///
/// Example: {C, E, G, A} could be C6 or Am7/C. Prefer C6 in root position
/// when the 7th chord interpretation would be inverted with no extensions.
int? _prefer6thInRoot(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isSixFamily == fb.isSixFamily) return null;

  final aIs6 = fa.isSixFamily;
  final fsix = aIs6 ? fa : fb;
  final fother = aIs6 ? fb : fa;

  if (fsix.isRootPosition &&
      !fother.isRootPosition &&
      fother.extensionCount == 0) {
    return aIs6 ? -1 : 1;
  }

  return null;
}

/// Prefers a complete major/minor triad core over an incomplete inverted 6th
/// chord.
///
/// Example: {B, E, G} with B in the bass can be read as G6/B or Em/B.
/// The E minor triad is complete, while the G6 reading omits its fifth and
/// depends on an inversion. Keep this narrow so root-position 6th colors
/// with an omitted fifth are not demoted to relative-minor slash chords.
///
/// The complete triad may carry simple add-tone color: {A, C, D, E} with E
/// bass is better read as Amadd11/E than C6/9/E, because the A minor triad is
/// complete while the C6/9 reading omits the fifth.
int? _preferCompleteTriadOverIncompleteInvertedSixth(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsIncompleteSixth = fa.isIncompleteInvertedSixth;
  final bIsIncompleteSixth = fb.isIncompleteInvertedSixth;
  if (aIsIncompleteSixth == bIsIncompleteSixth) return null;

  final aIsCompleteTriad = fa.isCompleteMajorMinorTriad;
  final bIsCompleteTriad = fb.isCompleteMajorMinorTriad;

  if (aIsIncompleteSixth && bIsCompleteTriad) return 1;
  if (bIsIncompleteSixth && aIsCompleteTriad) return -1;

  return null;
}

// ---- Dominant and slash readings ---------------------------------------

/// Prefers a complete dominant sharp-nine over a root-position sixth chord
/// carrying split-third altered color.
///
/// Example: {C, Eb, E, G, Bb} with Eb in the bass is C7#9/Eb, not Eb6b9.
/// The seventh completes the conventional altered dominant; without it, the
/// sixth-chord reading remains a genuine split-third ambiguity.
///
/// The same principle covers dense altered dominants with #11 plus either a
/// natural or flat thirteenth: the complete dominant shell is more idiomatic
/// than a major-sixth chord carrying split-third, flat-nine, and eleventh
/// add-tone color.
int? _preferCompleteDom7Sharp9OverSixthFlat9(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteDominantSharpNineReading(a.identity);
  final bIsPreferred = _isCompleteDominantSharpNineReading(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (!_isStableSplitThirdSixth(other.identity, fOther)) {
    return null;
  }

  final preferredCandidate = aIsPreferred ? a : b;
  if (preferredCandidate.score + 0.55 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteDominantSharpNineReading(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7) return false;
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
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.flat7);
}

int? _preferCompleteFlatNineFlatThirteenthDominantOverRemoteSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteFlatNineFlatThirteenthDominant(a.identity);
  final bIsPreferred = _isCompleteFlatNineFlatThirteenthDominant(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final fOther = aIsPreferred ? fb : fa;
  if (fOther.isDom7) return null;
  if (!fOther.isDimFamily && !fOther.isSeventhFamily) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteFlatNineFlatThirteenthDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7) return false;
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

/// Prefers a complete 9#11 dominant in a stable inversion over an altered
/// sharp-five slash reading that would require double-accidental spelling.
///
/// Example: {C, D, E, F#, G, Bb} with Bb in the bass is C9#11/Bb, not
/// F#7#5(b9,#11)/A#. The latter is pitch-class valid, but it spells the
/// sounding D as Cx, while the C-rooted dominant names every tone directly.
int? _preferStableExtendedDom7OverDoubleAccidentalAlteredFifthSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsPreferred = _isStableExtendedDom7(a.identity, fa);
  final bIsPreferred = _isStableExtendedDom7(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  if (!_isAlteredSharpFiveDominant(other.identity)) return null;
  if (!_alteredSharpFiveHasDoubleAccidental(other.identity, tonality)) {
    return null;
  }

  final preferred = aIsPreferred ? a : b;
  if (preferred.score + 0.30 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a complete altered dominant in a stable inversion over a rare
/// root-position altered major7 reinterpretation.
///
/// Example: {A, C, C#, F, G} with C# in the bass is A7#5#9/C#, not
/// C#maj7b5b13 or Dbmaj7#5#11. The dominant reading is a conventional altered
/// chord in first inversion; the major7 readings each combine an altered fifth
/// quality with an additional alteration.
int? _preferCompleteAlteredDom7InversionOverAlteredMajor7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred =
      fa.isCompleteAlteredFifthDominant &&
      fa.isSlashBass &&
      fa.hasStableBassRole &&
      fa.hasAlteredColor;
  final bIsPreferred =
      fb.isCompleteAlteredFifthDominant &&
      fb.isSlashBass &&
      fb.hasStableBassRole &&
      fb.hasAlteredColor;
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (!fOther.isRootPosition) return null;
  if (other.identity.quality != ChordQualityToken.major7Flat5 &&
      other.identity.quality != ChordQualityToken.major7Sharp5) {
    return null;
  }
  if (fOther.extensionTensionCount == 0) return null;

  final preferredCandidate = aIsPreferred ? a : b;
  if (preferredCandidate.score + 0.55 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a complete dominant flat-nine in a stable inversion over a
/// diminished7 reading that needs an added or altered color tone.
///
/// Example: {C, Db, E, G, Bb} with G in the bass is normally C7b9/G, not
/// Gdim7(add11). The dominant reading names a complete, conventional chord;
/// the diminished reading respells E as Fb and treats C as added color.
///
/// Keep this bounded to root, first, and second inversion. With the dominant
/// seventh or a color tone in the bass, the diminished interpretation can be
/// the clearer reading.
int? _preferCompleteDom7Flat9OverColoredDim7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isCompleteDominantFlat9 && fa.hasStableBassRole;
  final bIsPreferred = fb.isCompleteDominantFlat9 && fb.hasStableBassRole;
  if (aIsPreferred == bIsPreferred) return null;

  final fDim = aIsPreferred ? fb : fa;
  if (!fDim.isDim7 || fDim.extensionCount == 0) return null;

  final preferredCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;
  if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a fifthless flat-nine-bass dominant shell over the two remote
/// reinterpretations produced by the same four pitch classes.
///
/// Example: {C, Db, E, Bb} with Db in the bass is C7b9/Db, not C#mM7(add13)
/// or A#dim(add9)/C#. The dominant names the familiar E-Bb tritone shell; the
/// competitors require less common added-tone structures.
///
/// This remains an ambiguity preference, not an absolute analysis: when the
/// bass-rooted minor-major7 reading is rooted on the selected tonic, context
/// provides enough evidence to leave that higher-scoring reading ahead.
int? _preferFlatNineBassDominantOverRemoteReinterpretation(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsPreferred = fa.isFifthlessFlatNineBassDominant;
  final bIsPreferred = fb.isFifthlessFlatNineBassDominant;
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  final otherIsBassRootedMinorMajor7 =
      fOther.isRootPosition &&
      other.identity.quality == ChordQualityToken.minorMajor7;
  final otherIsDiminishedTriad =
      other.identity.quality == ChordQualityToken.diminished;
  if (!otherIsBassRootedMinorMajor7 && !otherIsDiminishedTriad) return null;

  if (tonality.isMinor &&
      otherIsBassRootedMinorMajor7 &&
      other.identity.rootPc == tonality.tonicPitchClass) {
    return null;
  }

  final preferredCandidate = aIsPreferred ? a : b;
  if (preferredCandidate.score + 0.55 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Resolves C7#9 vs Eb°7 ambiguity by preferring the dominant reading when:
/// - Dominant is in root position with shell tones (3rd + b7) present
/// - Dominant has color tones (extensions/alterations)
/// - Diminished reading would be a slash chord with color-tone bass
///
/// Example: {C, E, Bb, Eb} → prefer C7b9 over Eb°7/C
int? _preferAlteredDom7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  // Engage only for (dominant7) vs (fully diminished7) comparisons.
  final aIsDom7 = fa.isDom7;
  final bIsDom7 = fb.isDom7;
  final aIsDimFamily = fa.isDimFamily;
  final bIsDimFamily = fb.isDimFamily;

  final domVsDim = (aIsDom7 && bIsDimFamily) || (bIsDom7 && aIsDimFamily);
  if (!domVsDim) return null;

  final fDom = aIsDom7 ? fa : fb;
  final fDim = aIsDom7 ? fb : fa;
  final domIsA = aIsDom7;

  if (!fDom.isDom7RootPosition) return null;
  if (!fDom.dom7HasShell) return null;
  if (!fDim.isSlashBass) return null;
  if (!fDim.bassIsColorTone) return null;

  // Require that the dominant is actually "doing something dominant-ish",
  // i.e. it has at least one real extension/alteration.
  // This is what keeps plain C7 from always beating (say) Cdim7 contexts.
  if (!fDom.hasNaturalOrAlteredColor) return null;

  // If all of the above holds: prefer dominant7 interpretation.
  return domIsA ? -1 : 1;
}

/// Distinguishes upper-structure dominants from inversions.
///
/// When comparing two dominant7 readings (root-position vs slash):
/// - If slash bass is a color tone (e.g., #11, b9, 13) with no other alterations,
///   treat it as an intentional upper-structure voicing → prefer slash
/// - If slash bass is a core tone (3rd/5th/7th), treat it as an inversion → prefer root
///
/// Example: {Gb, C, E, Bb} → prefer C7/F# over Gb7#11
int? _preferUpperStructureDom7(
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
int? _preferRootExtendedDom7OverAlteredFifthSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isStableExtendedDom7(a.identity, fa);
  final bIsPreferred = _isStableExtendedDom7(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final fOther = aIsPreferred ? fb : fa;
  if (!fOther.isAlteredFifthDom7) return null;
  if (!fOther.isSlashBass) return null;
  if (!fOther.dom7HasShell) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers the conventional altered-fifth spelling for fully symmetric
/// same-root dominant ambiguities.
///
/// Example: {C, D, E, F#, Ab, Bb} can be spelled as either C9#5#11 or
/// C9b5b13 with the same score. In that narrow tie, #5 plus #11 is the clearer
/// altered-dominant reading: the augmented fifth is a chord tone, while F#
/// remains an upper color.
int? _preferSharpFiveSharpElevenDominantSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isNineSharpFiveSharpEleven(a.identity);
  final bIsPreferred = _isNineSharpFiveSharpEleven(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  if (!_isNineFlatFiveFlatThirteen(other.identity)) {
    return null;
  }

  final preferred = aIsPreferred ? a : b;
  if (preferred.identity.rootPc != other.identity.rootPc) return null;
  if ((preferred.identity.presentIntervalsMask & (1 << perfectFifthInterval)) !=
      0) {
    return null;
  }

  return aIsPreferred ? -1 : 1;
}

bool _isNineSharpFiveSharpEleven(ChordIdentity id) {
  return id.quality == ChordQualityToken.dominant7Sharp5 &&
      id.extensions.length == 2 &&
      (id.extensions.contains(ChordExtension.nine) ||
          id.extensions.contains(ChordExtension.flat9)) &&
      id.extensions.contains(ChordExtension.sharp11);
}

bool _isNineFlatFiveFlatThirteen(ChordIdentity id) {
  return id.quality == ChordQualityToken.dominant7Flat5 &&
      id.extensions.length == 2 &&
      (id.extensions.contains(ChordExtension.nine) ||
          id.extensions.contains(ChordExtension.flat9)) &&
      id.extensions.contains(ChordExtension.flat13);
}

/// Prefers a bass-rooted suspended dominant over remote slash spellings.
///
/// Example: {D, G, A, C, E} with D in the bass is normally read as D9sus4,
/// not Em7#5(add11)/D. The latter is pitch-class valid, but it respells C as
/// B# and turns a straightforward dominant sus voicing into a remote altered
/// seventh slash chord.
int? _preferRootDominantSusOverSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isRootDominantSus;
  final bIsPreferred = fb.isRootDominantSus;
  if (aIsPreferred == bIsPreferred) return null;

  final fPreferred = aIsPreferred ? fa : fb;
  if (fPreferred.extPref.alterationCount > 0) return null;

  final fOther = aIsPreferred ? fb : fa;
  if (!fOther.isSlashBass) return null;

  // When the slash candidate is a conventional major/minor triad with
  // only add-tone extensions (e.g., Abadd11/Eb), prefer it over the
  // root-position dominant sus. The add-tone slash is a simpler and
  // more expected reading — all downstream tie-breakers would also
  // favor it, so resolve directly here.
  final slashQuality = aIsPreferred ? b.identity.quality : a.identity.quality;
  final isConventionalSlash =
      (slashQuality == ChordQualityToken.major ||
          slashQuality == ChordQualityToken.minor) &&
      fOther.extPref.alterationCount == 0 &&
      fOther.extPref.naturalCount == 0;
  if (isConventionalSlash) return aIsPreferred ? 1 : -1;

  return aIsPreferred ? -1 : 1;
}

/// Prefers the ordinary inverted major triad reading over the
/// enharmonically equivalent minor-sharp-five reading.
///
/// Example: {C, Eb, Ab} with C or Eb in the bass is normally heard and written
/// as Ab/C or Ab/Eb, not Cm#5. The latter is pitch-class valid, but it depends
/// on spelling Ab as G# and treats a complete consonant triad as an altered
/// minor color.
int? _preferCompleteMajorInversionOverMinorSharpFive(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsMajorInversion = fa.isCompleteMajorTriadInversion;
  final bIsMajorInversion = fb.isCompleteMajorTriadInversion;
  if (aIsMajorInversion == bIsMajorInversion) return null;

  final fOther = aIsMajorInversion ? fb : fa;
  if (!fOther.isMinorSharpFive) return null;

  return aIsMajorInversion ? -1 : 1;
}

/// Prefers a complete Lydian major 6/9 over a suspended major-thirteenth
/// spelling of the same collection.
///
/// Example: {C, Db, Eb, F#, Ab, Bb} is more directly G♭6/9#11 than
/// D♭maj13sus4: the G♭ reading preserves a major triad with 6/9/#11 color,
/// while the D♭ reading turns the same G♭ into a suspension.
int? _preferCompleteLydianSixNineOverMajor13Sus4(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteLydianSixNine(a.identity);
  final bIsPreferred = _isCompleteLydianSixNine(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  if (!_isMajorThirteenSusFour(other.identity)) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteLydianSixNine(ChordIdentity id) {
  if (id.quality != ChordQualityToken.major6) return false;
  if (!id.extensions.contains(ChordExtension.add9) ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.sixth) &&
      roles.contains(ChordToneRole.add9) &&
      roles.contains(ChordToneRole.sharp11);
}

bool _isMajorThirteenSusFour(ChordIdentity id) {
  if (id.quality != ChordQualityToken.major7sus4) return false;
  if (!id.extensions.contains(ChordExtension.nine) ||
      !id.extensions.contains(ChordExtension.thirteen)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.sus4) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.major7) &&
      roles.contains(ChordToneRole.nine) &&
      roles.contains(ChordToneRole.thirteen);
}

/// Prefers a complete major triad inversion over a seventh-family slash chord
/// where the bass note only appears as a color-tone add-extension.
///
/// Example: {A, B, C, F} with A in the bass reads naturally as F(#11)/A
/// (first inversion, bass=M3), not Cmaj7sus4(add13)/A where the bass A is
/// merely an add13 extension on an unrelated root. The inversion reading keeps
/// all four tones in a single coherent chord name without borrowing the bass
/// as an ornament.
int? _preferCompleteMajorInversionOverSeventhColorBassSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsMajorInversion = fa.isCompleteMajorTriadInversion;
  final bIsMajorInversion = fb.isCompleteMajorTriadInversion;
  if (aIsMajorInversion == bIsMajorInversion) return null;

  final fOther = aIsMajorInversion ? fb : fa;
  if (!fOther.isSeventhFamily || !fOther.bassIsColorTone) return null;

  return aIsMajorInversion ? -1 : 1;
}

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

/// Prefers a complete sharp-nine dominant thirteenth over a heavily colored
/// major-sixth spelling of the same pitch classes.
///
/// Example: {C, Db, Eb, F#, G, Bb} can be read as Eb13#9 or F#6(b9,#11).
/// The dominant reading has a complete shell and familiar altered-dominant
/// color; the sixth reading is structurally complete but asks a major-sixth
/// chord to carry both b9 and #11 alterations.
int? _preferCompleteSharpNineThirteenthDominantOverColoredSixth(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteSharpNineThirteenthDominant(a.identity);
  final bIsPreferred = _isCompleteSharpNineThirteenthDominant(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (!_isColoredSixthFlatNineSharpEleven(other.identity, fOther)) {
    return null;
  }

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteSharpNineThirteenthDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7) return false;
  if (id.extensions.length != 2 ||
      !id.extensions.contains(ChordExtension.sharp9) ||
      !id.extensions.contains(ChordExtension.thirteen)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.sharp9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.thirteen) &&
      roles.contains(ChordToneRole.flat7);
}

bool _isColoredSixthFlatNineSharpEleven(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (id.quality != ChordQualityToken.major6 || !features.hasStableBassRole) {
    return false;
  }
  if (id.extensions.length != 2 ||
      !id.extensions.contains(ChordExtension.flat9) ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.sharp11) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.sixth);
}

/// Prefers complete altered-dominant notation with #11 over remote spellings.
///
/// Example: {C, Db, E, F#, Ab, Bb} is better read as C7#5(b9,#11)/Ab than
/// Ab11#5 or Bbm9#5#11. The competing spellings are pitch-class valid, but the
/// C-rooted spelling names the same material with conventional altered-dominant
/// vocabulary.
int? _preferCompleteAlteredSharpFiveDominantOverRemoteSpellings(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final aIsPreferred = _isAlteredSharpFiveDominant(a.identity);
  final bIsPreferred = _isAlteredSharpFiveDominant(b.identity);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final preferred = aIsPreferred ? a : b;
  final fOther = aIsPreferred ? fb : fa;
  if (_isStableExtendedDom7(other.identity, fOther) &&
      _alteredSharpFiveHasDoubleAccidental(preferred.identity, tonality)) {
    return null;
  }

  if (!_isNaturalEleventhSharpFiveDominant(other.identity) &&
      !_isRemoteAlteredNonDominantReading(other.identity)) {
    return null;
  }

  if (preferred.score + 0.20 < other.score) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isAlteredSharpFiveDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7Sharp5) return false;
  if (!id.extensions.contains(ChordExtension.flat9) ||
      !id.extensions.contains(ChordExtension.sharp11)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.sharp11) &&
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

bool _isRemoteAlteredNonDominantReading(ChordIdentity id) {
  final isRemoteQuality = switch (id.quality) {
    ChordQualityToken.minorMajor7 ||
    ChordQualityToken.minor7Sharp5 ||
    ChordQualityToken.halfDiminished7 => true,
    _ => false,
  };
  return isRemoteQuality && id.extensions.isNotEmpty;
}

bool _isNaturalEleventhSharpFiveDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7Sharp5) return false;
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
/// When scores are tied, prefer the interpretation where the bass note
/// is named as the root for notational clarity and functional analysis.
///
/// Example: {B, D, F, Ab} → prefer B°7 over D°7/B when bass is B
int? _preferDim7InRoot(
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

/// Prefers dominant7 shell (3+b7) over dim7 slash reinterpretation.
///
/// When the same notes can be read as either a dominant7 with shell tones
/// or a diminished7 slash with color-tone bass, prefer the dominant reading
/// (matches musician expectation for altered dominant voicings).
int? _preferDom7Shell(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsDom = fa.isDom7;
  final bIsDom = fb.isDom7;
  final aIsDim7 = fa.isDim7;
  final bIsDim7 = fb.isDim7;

  // Only engage on dominant7 vs diminished7 comparisons.
  final domVsDim = (aIsDom && bIsDim7) || (bIsDom && aIsDim7);
  if (!domVsDim) return null;

  final domIsA = aIsDom;
  final fDom = domIsA ? fa : fb;
  final fDim = domIsA ? fb : fa;

  // Require strong dominant evidence (shell).
  if (!fDom.dom7HasShell) return null;

  // If the diminished7 candidate is a slash reading and its bass is a color tone,
  // prefer the dominant reading (musician expectation for altered dominants).
  final dimIsSlash = fDim.isSlashBass;
  if (!dimIsSlash) return null;

  // Use the same "color bass" classifier you already built (it works beyond dom7),
  // or add a generic one. If you don't have a generic one yet, treat any non-core
  // bass role as "color".
  if (!fDim.bassIsColorTone) return null;

  // Dominant wins.
  return domIsA ? -1 : 1;
}

/// Prefers a root-position dominant7 (with shell) over a non-dominant slash
/// interpretation in near-ties.
///
/// This catches cases like:
///   {C, E, Bb, Db, F#, Ab, G} -> prefer C7(b9,#11,b13)
/// over remote minor-major / extended slash readings.
int? _preferDom7RootOverNonDomSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isDom7RootPosition && fa.dom7HasShell;
  final bIsPreferred = fb.isDom7RootPosition && fb.dom7HasShell;
  if (aIsPreferred == bIsPreferred) return null;

  final fDom = aIsPreferred ? fa : fb;
  final fOther = aIsPreferred ? fb : fa;
  final domCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;

  // Only when the competing interpretation is a slash and not itself dominant7.
  if (!fOther.isSlashBass) return null;
  if (fOther.isDom7) return null;
  if (fOther.isAlteredFifthDom7) return null;

  // Ensure the dominant reading is not "plain"; it should have some color.
  if (!fDom.hasNaturalOrAlteredColor) return null;

  if (domCandidate.score + 0.25 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a complete seventh chord with the ninth in the bass over a remote
/// altered slash spelling.
///
/// Example: {C, D, E, G, Bb} with D in the bass is normally understood as
/// C9/D (often written C7/D), not Em7#5#11/D. Likewise, a complete
/// Dbm(maj9)/Eb is preferred over Emaj7#5(add13)/D#. The competing spellings
/// are pitch-class valid, but reinterpret a complete natural ninth chord as a
/// remote altered seventh chord.
int? _preferNinthBassSeventhOverAlteredSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isCompleteNinthBassSeventhChord;
  final bIsPreferred = fb.isCompleteNinthBassSeventhChord;
  if (aIsPreferred == bIsPreferred) return null;

  final fOther = aIsPreferred ? fb : fa;
  final preferredCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;

  if (!fOther.isSlashBass) return null;
  if (fOther.extensionTensionCount == 0 && !fOther.isUnusualSeventhQuality) {
    return null;
  }
  if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers the complete minor seventh upper-structure slash reading over a
/// remote minor-seven-sharp-five slash spelling.
///
/// Example: {D, A, C, E, G} with D in the bass has D9sus4 as the strongest
/// root-position sus reading, but if comparing slash alternatives, Am7/D is
/// clearer than Em7#5(add11)/D. The latter respells C as B# and turns a
/// complete minor seventh chord into a remote altered-fifth chord.
int? _preferMinor7EleventhBassSlashOverMinor7SharpFiveSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isCompleteMinor7EleventhBassSlash;
  final bIsPreferred = fb.isCompleteMinor7EleventhBassSlash;
  if (aIsPreferred == bIsPreferred) return null;

  final fOther = aIsPreferred ? fb : fa;
  final preferredCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;
  if (!fOther.isSlashBass) return null;
  if (otherCandidate.identity.quality != ChordQualityToken.minor7Sharp5) {
    return null;
  }

  if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers root-position altered-fifth dominants over close slash readings.
///
/// Flat-five and sharp-five dominant sevenths are tritone-symmetric, so a
/// slash interpretation can score competitively even when the root-position
/// name is clearer. Prefer the root-position reading when it has a real
/// alteration and the slash reading only has added or natural color tones.
int? _preferRootAlteredFifthDom7(
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

  if (rootCandidate.score + 0.50 < slashCandidate.score) return null;

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
      (slashCandidate.identity.quality == ChordQualityToken.dominant7Sharp5 ||
          slashCandidate.identity.quality == ChordQualityToken.dominant7Flat5);
  if (!slashIsNinthAlteredFifth) return false;

  return slashCandidate.score >= rootCandidate.score;
}

/// Avoids promoting remote, non-dominant slash readings whose "simple" color
/// is a natural 11 against a major third.
///
/// Example: {Ab, B, C, E, F} is better read as FmM7#11/Ab than as
/// Cmaj7#5(add11)/G#, because the F-rooted reading is a normal inversion of
/// a complete altered seventh chord while the C-rooted reading depends on a
/// non-dominant add11 clash and a less stable slash bass.
int? _preferConventionalAlteredSeventhOverAdd11Slash(
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
  if (fc.bassRoleRank >= fq.bassRoleRank) return null;

  // Keep this rule bounded to close structural ambiguities. Wider gaps should
  // still be decided by the raw template fit.
  if (conventional.score + 0.55 < questionable.score) return null;

  return aIsQuestionableSlash ? 1 : -1;
}

/// Prefers a complete minor triad with a single sharp-eleventh color over a
/// root-position major-7-sus4 reading that needs an altered thirteenth.
///
/// Example: {E, A, C, D#} is more defensibly Am#11/E than Emaj7sus4(b13):
/// the A-rooted reading preserves a complete minor triad, while the E-rooted
/// reading has neither a third nor fifth and depends on b13 color.
int? _preferCompleteMinorSharp11OverAlteredMaj7Sus4(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsMinorSharp11 = fa.isCompleteMinorSharp11;
  final bIsMinorSharp11 = fb.isCompleteMinorSharp11;
  if (aIsMinorSharp11 == bIsMinorSharp11) return null;

  final fMinor = aIsMinorSharp11 ? fa : fb;
  final fSus = aIsMinorSharp11 ? fb : fa;
  final minorCandidate = aIsMinorSharp11 ? a : b;
  final susCandidate = aIsMinorSharp11 ? b : a;

  if (!fMinor.isSecondInversion) return null;
  if (!fSus.isAlteredMajor7Sus4) return null;

  // Keep the override narrow: if the template score strongly favors the sus
  // reading, let score win.
  if (minorCandidate.score + 0.35 < susCandidate.score) return null;

  return aIsMinorSharp11 ? -1 : 1;
}

/// Prefers a root-position major/minor add-chord over a sus-family slash
/// interpretation of the same notes.
///
/// Example: {C, E, G, F} is naturally read as Cadd11, not Fmaj7sus2/C.
/// The F-rooted sus reading fits the template cleanly (no extra tones), so it
/// earns a higher raw score. But the score advantage is a structural artifact:
/// the major7sus2 template has three required tones, which accumulates more
/// reward than the two-required-tone major template, even though musicians
/// universally hear the simpler root-position reading.
///
/// The 1.50-point guard lets the sus reading win when the score difference is
/// decisive rather than merely a template-complexity artifact.
int? _preferRootAddChordOverSusSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = fa.isRootPositionNaturalAddChord;
  final bIsPreferred = fb.isRootPositionNaturalAddChord;
  if (aIsPreferred == bIsPreferred) return null;

  final fSus = aIsPreferred ? fb : fa;
  if (!fSus.isSus || !fSus.isSlashBass) return null;

  final preferredCandidate = aIsPreferred ? a : b;
  final susCandidate = aIsPreferred ? b : a;

  if (preferredCandidate.score + 1.50 < susCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

// ---- Triad completeness vs seventh-family inflation --------------------

/// Prefers a complete major/minor triad with add-tone extensions over a
/// seventh-family chord whose extensions are all add-tones in a near-tie.
///
/// A complete triad with simple color tones (e.g., Bbmadd9/Db) is a more
/// conventional and stable structure than forcing the same pitches into a
/// seventh-family framework with unusual extension pairings (e.g.,
/// Dbmaj7(add13) where a maj7(add13) is rare in practice).
int? _preferCompleteTriadAddToneOverSeventhFamilyAddTone(
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

  // The other must be a seventh-family chord carrying only add-tone
  // extensions, indicating the same pitch set is being forced into an
  // unconventional seventh-family framework.
  final fOther = aIsTriadAddTone ? fb : fa;
  if (!fOther.isSeventhFamily) return null;
  if (fOther.extPref.alterationCount > 0) return null;
  if (fOther.extPref.naturalCount > 0) return null;

  return aIsTriadAddTone ? -1 : 1;
}

/// Prefers a complete major/minor triad with natural add-tone color over a
/// seventh-family reading with an unusual quality and no extensions.
///
/// When a plain triad with a simple add-tone (e.g., Cadd9/G) competes
/// against a seventh-family reading with an unusual quality (e.g.,
/// Em7#5/G), the seventh-family template's extra required tones create a
/// structural score advantage that doesn't reflect musician expectations.
/// Both oracles (music21, tonal) converge on the simpler triad reading.
int? _preferSimpleTriadAddToneOverSeventhFamilyUnusualQuality(
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
  // inversion with no extensions at all. Standard qualities like plain
  // dominant7, minor7, or major7 should not be overridden by this rule.
  final fOther = aIsTriadAddTone ? fb : fa;
  if (!fOther.isSeventhFamily) return null;
  if (!fOther.isUnusualSeventhQuality) return null;
  if (fOther.extPref.totalCount > 0) return null;
  if (fOther.isRootPosition) return null;

  // A complete altered dominant in a conventional inversion is a stronger
  // structural reading than an inverted augmented add-tone chord. Preserve
  // the triad preference when it aligns with the bass, but do not use it to
  // demote readings such as C7#5/E in favor of Abaugadd9/E.
  final fTriad = aIsTriadAddTone ? fa : fb;
  if (fOther.isCompleteAlteredFifthDominant && !fTriad.isRootPosition) {
    return null;
  }

  // Score guard: let decisively higher-scoring unusual-quality readings
  // through when the gap exceeds what structural inflation explains.
  final preferredCandidate = aIsTriadAddTone ? a : b;
  final otherCandidate = aIsTriadAddTone ? b : a;
  if (preferredCandidate.score + 1.50 < otherCandidate.score) return null;

  return aIsTriadAddTone ? -1 : 1;
}

/// Prefers a complete major/minor triad carrying only natural/add color over
/// a structurally deficient reading that omits a core tone.
///
/// A complete triad (root + 3rd + 5th) with simple add color is a strong,
/// stable gestalt. The raw scorer can rank it below a larger template that
/// books more "required" tones, even when that larger reading omits a core
/// tone of its own. This prefers the complete triad over:
/// - a seventh-family slash that omits every fifth (e.g. D♭maj7(add13)/F), and
/// - a plain suspended triad with no seventh (e.g. Fsus4♭13).
///
/// Example: {F, B♭, C, D♭} with F in the bass is B♭m(add9)/F, not
/// D♭maj7(add13)/F (fifthless) or Fsus4♭13 (no third, no seventh).
///
/// The deficient side is deliberately narrow so that complete seventh chords,
/// altered-fifth chords (which keep a flat/sharp fifth), six chords, and
/// dominant/major suspended chords (which keep a seventh) are never demoted.
/// A score guard keeps a decisively higher-scoring reading in front.
int? _preferCompleteTriadOverDeficientReading(
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
  if (triadCandidate.score + 0.55 < otherCandidate.score) return null;

  return aIsTriad ? -1 : 1;
}

/// Prefers a dominant7 slash with shell tones and a color-tone bass over a
/// non-dominant seventh-family slash of similar score.
///
/// When the same notes can be read as either a strongly-voiced dominant7
/// (major 3rd + flat 7th present, bass is a color extension rather than a
/// core inversion tone) or as a non-dominant seventh-family slash, the
/// dominant reading is the one musicians expect.
///
/// Example: {C, D♭, E♭, F, A♭, A} with A♭ bass reads as F7(♯9,♭13)/A♭,
/// not as C♯maj9♭13/A♭. The F dominant interpretation has shell tones (A +
/// E♭) and a color-tone bass (A♭ = ♯9 of F), while the C♯ reading requires
/// an unusual root and treats the same A♭ as a structural fifth inversion.
int? _preferDom7ShellSlashOverSeventhFamilySlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsDom7Slash = fa.isDom7Slash;
  final bIsDom7Slash = fb.isDom7Slash;
  if (aIsDom7Slash == bIsDom7Slash) return null;

  final domIsA = aIsDom7Slash;
  final fDom = domIsA ? fa : fb;
  final fOther = domIsA ? fb : fa;

  if (!fDom.dom7HasShell) return null;
  if (!fDom.bassIsColorTone) return null;
  if (!fOther.isSeventhFamily) return null;
  if (fOther.isDom7) return null;
  if (!fOther.isSlashBass) return null;

  return domIsA ? -1 : 1;
}

// ---- Note coverage, key, and simplicity --------------------------------

/// Prefers a reading that names every sounding tone over one that drops a
/// tone as added complexity outside the base template.
///
/// Example: {C, D♭, E, G} with G in the bass reads as Cadd♭9/G, not C♯dim/G
/// (which silently drops the C natural). Runs before [_preferFewerAlterations]
/// so the note-dropping reading is not rewarded for its apparent simplicity.
int? _preferFullyExplainedVoicing(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aDropsTone = fa.unnamedToneCount > 0;
  final bDropsTone = fb.unnamedToneCount > 0;
  if (aDropsTone == bDropsTone) return null;
  return aDropsTone ? 1 : -1;
}

/// Lets strong minor-key context resolve a split-third inversion ambiguity.
///
/// Example: {C, Db, E, A} with Db in the bass is Aadd#9/C# in neutral context,
/// but C#mM7b13 in C# minor. The latter is a root-position harmonic-minor
/// tonic containing the tonic, minor third, flat sixth, and raised seventh.
///
/// Keep this pair-specific so harmonic-minor context does not broadly override
/// complete triad inversions or the generic preference for fewer tensions.
int? _preferHarmonicMinorTonicOverSplitThirdInversion(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  if (!tonality.isMinor) return null;

  bool isHarmonicMinorTonic(ChordCandidate candidate, CandidateFeatures f) {
    if (!f.isRootPosition ||
        candidate.identity.quality != ChordQualityToken.minorMajor7 ||
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

int? _preferFewerAlterations(
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

int? _preferDiatonic(
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
int? _preferRootMinor7OverMajor6Slash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsMinor7 = a.identity.quality == ChordQualityToken.minor7;
  final bIsMinor7 = b.identity.quality == ChordQualityToken.minor7;
  if (aIsMinor7 == bIsMinor7) return null;

  final minor7 = aIsMinor7 ? a : b;
  final fMinor7 = aIsMinor7 ? fa : fb;
  final major6 = aIsMinor7 ? b : a;
  final fMajor6 = aIsMinor7 ? fb : fa;

  if (!fMinor7.isRootPosition ||
      major6.identity.quality != ChordQualityToken.major6 ||
      !fMajor6.isSlashBass ||
      major6.identity.bassPc != minor7.identity.rootPc) {
    return null;
  }

  final minor7Extensions = minor7.identity.extensions;
  final major6Extensions = major6.identity.extensions;
  final plainPair = minor7Extensions.isEmpty && major6Extensions.isEmpty;
  final matchingColorPair =
      minor7Extensions.length == 1 &&
      minor7Extensions.contains(ChordExtension.add11) &&
      major6Extensions.length == 1 &&
      major6Extensions.contains(ChordExtension.add9);
  if (!plainPair && !matchingColorPair) return null;

  return aIsMinor7 ? -1 : 1;
}

/// Prefers the selected key's tonic chord in otherwise ambiguous near-ties.
///
/// This lets context resolve relative major/minor sonorities without overriding
/// stronger structural evidence.
int? _preferTonicChord(
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

/// Prefers the I chord when the bass is the tonic pitch class.
///
/// When multiple diatonic interpretations are possible with tonic in bass,
/// favor the most stable/expected reading (the I chord itself) over other
/// scale degrees that happen to have tonic as a chord tone.
///
/// Example in C major with bass = C:
/// - Prefer "C" (I) over "Am/C" (vi/I) or "Fmaj7/C" (IV/I)
/// - Tonic bass + tonic chord = strongest harmonic stability
///
/// Only applies when both candidates are diatonic to the key.
int? _preferTonicAsI(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality tonality,
) {
  final tonic = tonality.tonicPitchClass;

  final da = tonality.scaleDegreeForChord(a.identity);
  final db = tonality.scaleDegreeForChord(b.identity);
  if (da == null || db == null) return null;

  final bassIsTonic = a.identity.bassPc == tonic;
  if (!bassIsTonic) return null;

  final aIsI = da == ScaleDegree.one;
  final bIsI = db == ScaleDegree.one;

  if (aIsI == bIsI) return null;

  return bIsI ? 1 : -1;
}

/// Prefers stacked natural extensions (9, 11, 13) over "add" extensions,
/// then prefers fewer total extensions for simpler interpretations.
int? _preferNaturalExtensions(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final natural = fb.extPref.naturalCount.compareTo(fa.extPref.naturalCount);
  if (natural != 0) return natural;

  final add = fa.extPref.addCount.compareTo(fb.extPref.addCount);
  if (add != 0) return add;

  final total = fa.extPref.totalCount.compareTo(fb.extPref.totalCount);
  if (total != 0) return total;

  return null;
}

int? _preferRootPosition(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isRootPosition == fb.isRootPosition) return null;
  return fb.isRootPosition ? 1 : -1;
}

int? _preferConventionalInversion(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final cmp = fa.bassRoleRank.compareTo(fb.bassRoleRank);
  if (cmp == 0) return null;
  return cmp;
}

/// Resolves exact tritone-equivalent dominant-seven-flat-five ties by choosing
/// the spelling musicians can read directly.
///
/// A plain 7b5 chord is symmetric at the tritone: {C, D, F#, Ab} can be either
/// D7b5/C or Ab7b5/C. Bass role still wins earlier for root-position cases,
/// but when both readings are otherwise tied, avoid spellings like G#7b5/B#.
int? _preferCleanerTritoneFlatFiveDominantSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures _,
  CandidateFeatures _,
  Tonality tonality,
) {
  if (!_isPlainTritoneFlatFiveDominantPair(a.identity, b.identity)) {
    return null;
  }
  if ((a.score - b.score).abs() > 0.05) return null;

  final aPenalty = _candidateSpellingPenalty(a.identity, tonality);
  final bPenalty = _candidateSpellingPenalty(b.identity, tonality);
  if (aPenalty == bPenalty) return null;
  return aPenalty < bPenalty ? -1 : 1;
}

bool _isPlainTritoneFlatFiveDominantPair(ChordIdentity a, ChordIdentity b) {
  return a.quality == ChordQualityToken.dominant7Flat5 &&
      b.quality == ChordQualityToken.dominant7Flat5 &&
      a.extensions.isEmpty &&
      b.extensions.isEmpty &&
      intervalAboveRoot(a.rootPc, b.rootPc) == tritoneInterval;
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

int? _prefer7thChords(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isSeventhFamily == fb.isSeventhFamily) return null;
  return fb.isSeventhFamily ? 1 : -1;
}

int? _preferFewerExtensions(
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

int? _avoidSuspended(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  if (fa.isSus == fb.isSus) return null;
  return fa.isSus ? 1 : -1;
}
