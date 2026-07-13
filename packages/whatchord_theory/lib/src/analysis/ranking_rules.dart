import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';
import '../services/interval_constants.dart';
import '../services/note_spelling.dart';
import '../services/pitch_class.dart';
import 'candidate_features.dart';
import 'common_name_prior_rule.dart';
import 'ranking_policy.dart' as ranking_policy;

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

/// Candidate-local necessary condition for a rule to fire.
///
/// Returns true if [candidate] could be *either* operand of a rule that returns
/// non-null. It must be a superset of the rule's real firing precondition: if it
/// is ever false for a candidate the rule could actually decide, that decision
/// is silently dropped. It depends only on the single candidate (plus tonality),
/// never on the candidate it is being compared against.
typedef RuleGate =
    bool Function(
      ChordCandidate candidate,
      CandidateFeatures features,
      Tonality tonality,
    );

/// A ranking rule paired with a human-readable name for debugging and for
/// explaining ranking decisions to users.
class NamedRule {
  final String name;
  final RuleFn apply;

  /// Optional candidate-local gate (see [RuleGate]). When set, the pairwise
  /// ranking pass skips [apply] for any pair where the gate is false for either
  /// candidate, since the rule could not fire there anyway. When null, [apply]
  /// is always evaluated (the original behavior).
  final RuleGate? gate;

  const NamedRule(this.name, this.apply, {this.gate});
}

// The two ordered lists below ARE the ranking policy: rules are tried top to
// bottom and the first one to return a non-zero result decides the pair. Order
// is therefore significant; read these lists to audit ranking behavior.
//
// NOTE: docs/site/articles/chord-recognition-algorithm.html documents these
// rules and their order in detail. Update the article when rules or their order
// change.

/// Cost-independent overrides, applied before the near-tie window check.
/// A hard rule can promote a higher-cost reading to the top, so each is
/// deliberately narrow and guarded.
final List<NamedRule> hardRules = <NamedRule>[
  NamedRule(
    'prefer dominant flat-nine shell over colored diminished',
    _preferCompleteDom7Flat9OverColoredDim7,
    gate: (c, f, _) =>
        _isStableDominantFlatNineShell(c.identity, f) ||
        f.isDimFamily ||
        c.identity.quality == ChordQualityToken.diminished,
  ),
  NamedRule(
    'prefer flat-nine-bass dominant over remote reinterpretation',
    _preferFlatNineBassDominantOverRemoteReinterpretation,
    gate: (c, f, _) =>
        f.isFifthlessFlatNineBassDominant ||
        c.identity.quality == ChordQualityToken.minorMajor7 ||
        c.identity.quality == ChordQualityToken.diminished,
  ),
  NamedRule(
    'prefer complete dominant sharp-nine over non-seventh color',
    _preferCompleteDominantSharp9OverNonSeventhColor,
    gate: (c, f, _) =>
        _isCompleteDominantSharpNineReading(c.identity) ||
        _isStableNonSeventhSharpNineCompetitor(c.identity, f),
  ),
  NamedRule(
    'prefer complete altered sharp-five dominant over remote spellings',
    _preferCompleteAlteredSharpFiveDominantOverRemoteSpellings,
    gate: (c, _, _) =>
        _isAlteredSharpFiveDominant(c.identity) ||
        _isNaturalEleventhSharpFiveDominant(c.identity) ||
        _isRemoteAlteredNonDominantReading(c.identity),
  ),
  NamedRule(
    'prefer conventional inversion in split-nine tritone dominant ambiguity',
    _preferConventionalSplitNineTritoneDominant,
    gate: (c, _, _) =>
        _isSplitNineFlatFiveDominant(c.identity) ||
        _isSharp11Flat13Dominant(c.identity),
  ),
  NamedRule(
    'prefer altered dominant7 over dim7 slash',
    _preferAlteredDom7,
    gate: (c, f, _) => f.isDom7 || f.isDimFamily,
  ),
  NamedRule(
    'prefer conventional altered seventh over add11 slash',
    _preferConventionalAlteredSeventhOverAdd11Slash,
    gate: (c, f, _) =>
        f.isQuestionableAdd11Slash ||
        (f.isSeventhFamily && f.extensionTensionCount > 0),
  ),
  NamedRule(
    'prefer close root-position dominant7 over non-dominant slash',
    _preferDom7RootOverNonDomSlash,
    gate: (c, f, _) =>
        (f.isDom7RootPosition && f.dom7HasShell) ||
        (f.isSlashBass && !f.isDom7 && !f.isAlteredFifthDom7),
  ),
  NamedRule(
    'prefer ninth-bass seventh chord over altered slash',
    _preferNinthBassSeventhOverAlteredSlash,
    gate: (c, f, _) =>
        f.isCompleteNinthBassSeventhChord ||
        (f.isSlashBass &&
            (f.extensionTensionCount > 0 || f.isUnusualSeventhQuality)),
  ),
  NamedRule(
    'prefer root-position altered-fifth dominant over slash',
    _preferRootAlteredFifthDom7,
    gate: (c, f, _) => f.isAlteredFifthDom7,
  ),
  NamedRule(
    'prefer root-position add-chord over sus slash',
    _preferRootAddChordOverSusSlash,
    gate: (c, f, _) =>
        f.isRootPositionNaturalAddChord || (f.isSus && f.isSlashBass),
  ),
  NamedRule(
    'prefer complete triad over structurally deficient reading',
    _preferCompleteTriadOverDeficientReading,
    gate: (c, f, _) => f.isCompleteMajorMinorTriad || f.isStructurallyDeficient,
  ),
  NamedRule(
    'prefer root-position minor-eleventh shell over sus slash',
    _preferRootMinor7Add11ShellOverSusSlash,
    gate: (c, f, _) =>
        f.isRootPositionMinor7Add11Shell ||
        c.identity.quality == ChordQualityToken.dominant7sus4 ||
        c.identity.quality == ChordQualityToken.sus2sus4,
  ),
  NamedRule(
    'prefer simple triad add-tone over seventh-family unusual quality',
    _preferSimpleTriadAddToneOverSeventhFamilyUnusualQuality,
    gate: (c, f, _) =>
        (!f.isSeventhFamily && !f.isSus && f.hasOnlyAddColor) ||
        (f.isSeventhFamily && f.isUnusualSeventhQuality),
  ),
  NamedRule(
    'prefer readable sharp-eleven major over flat-five spelling',
    _preferReadableSharpElevenMajorOverFlatFive,
    gate: (c, _, _) =>
        c.identity.quality == ChordQualityToken.major ||
        c.identity.quality == ChordQualityToken.major7 ||
        c.identity.quality == ChordQualityToken.major7Flat5 ||
        c.identity.quality == ChordQualityToken.majorFlat5,
  ),
];

/// Resolves an exact tritone-dominant ambiguity by bass role.
///
/// {C, Db, D, E, F#, Bb} can be read as C9b5b9 or F#7(#11,b13). Both are
/// complete dominant structures, but the altered-fifth template's extra
/// required tone creates a modest cost advantage that can hide a much more
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
  if ((a.cost - b.cost).abs() > 0.30) return null;

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
  if (preferred.cost > other.cost + 1.30) return null;

  return aIsPreferred ? -1 : 1;
}

/// Near-tie tie-breakers, applied in priority order only when two candidates
/// cost within the near-tie window of each other. These encode musical
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
    'prefer complete triad over incomplete 6th',
    _preferCompleteTriadOverIncompleteSixth,
  ),
  NamedRule(
    'prefer upper-structure dominant7 slash',
    _preferUpperStructureDom7,
  ),
  NamedRule(
    'prefer major-seventh upper-structure sus slash',
    _preferMajorSeventhUpperStructureSusSlash,
  ),
  NamedRule(
    'prefer root-position dominant sus over slash',
    _preferRootDominantSusOverSlash,
  ),
  NamedRule(
    'prefer cleaner-spelled tritone-twin extended dominant',
    _preferCleanerSpelledTritoneTwinExtendedDominant,
  ),
  NamedRule(
    'prefer stable extended dominant over altered-fifth slash',
    _preferRootExtendedDom7OverAlteredFifthSlash,
  ),
  NamedRule(
    'prefer complete altered thirteenth dominant over altered minor thirteenth',
    _preferCompleteAlteredThirteenthDominantOverAlteredMinorThirteenth,
  ),
  NamedRule(
    'prefer complete flat-nine flat-thirteen dominant over remote spelling',
    _preferCompleteFlatNineFlatThirteenthDominantOverRemoteSpelling,
  ),
  NamedRule(
    'prefer complete major sharp-eleven inversion over major13sus4',
    _preferCompleteMajorSharpElevenInversionOverMajor13Sus4,
  ),
  NamedRule(
    'prefer complete major inversion over seventh-family color-bass slash',
    _preferCompleteMajorInversionOverSeventhColorBassSlash,
  ),
  NamedRule('prefer root-position diminished7', _preferDim7InRoot),
  NamedRule(
    'prefer dominant7 shell slash over non-dominant seventh-family slash',
    _preferDom7ShellSlashOverSeventhFamilySlash,
  ),
  NamedRule(
    'prefer voicing that names every tone',
    _preferFullyExplainedVoicing,
  ),
  NamedRule(
    'prefer lower-cost add chord over missing-third unusual seventh',
    _preferLowerCostAddChordOverMissingThirdUnusualSeventh,
  ),
  NamedRule(
    'prefer harmonic-minor tonic over split-third inversion',
    _preferHarmonicMinorTonicOverSplitThirdInversion,
  ),
  NamedRule(
    'prefer lower-cost major-seventh-bass inversion over color-bass slash',
    _preferLowerCostMajorSeventhBassInversionOverColorBassSlash,
  ),
  NamedRule('prefer fewer altered/tension colors', _preferFewerAlterations),
  NamedRule('prefer diatonic chords', _preferDiatonic),
  NamedRule(
    'prefer root-position relative minor7 over major6 slash',
    _preferRootMinor7OverMajor6Slash,
  ),
  NamedRule('prefer tonic chord', _preferTonicChord),
  NamedRule(
    'prefer complete triad add-tone over sparse seventh-family color',
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
  NamedRule('prefer cleaner spelling', _preferCleanerSpelling),
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
      !_isFifthlessSixth((aIs6 ? a : b).identity) &&
      !fother.isRootPosition &&
      fother.extensionCount == 0) {
    return aIs6 ? -1 : 1;
  }

  return null;
}

/// Prefers a complete triad core over an incomplete 6th chord.
///
/// Example: {B, E, G} with B in the bass can be read as G6/B or Em/B.
/// The E minor triad is complete, while the G6 reading omits its fifth and
/// depends on an inversion.
///
/// The complete triad may carry simple add-tone color: {A, C, D, E} with E
/// bass is better read as Amadd11/E than C6/9/E, because the A minor triad is
/// complete while the C6/9 reading omits the fifth.
///
/// The same principle applies to bare root-position fifthless sixths when they
/// enharmonically duplicate a complete triad: {C, E♭, G♭} with E♭ in the bass
/// is Cdim/E♭, not a fifthless E♭m6. Root-position sixth chords with explicit
/// color, such as C6/9, stay eligible as context-dependent sonorities.
int? _preferCompleteTriadOverIncompleteSixth(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsIncompleteSixth = _isIncompleteSixthForTriadRule(a.identity);
  final bIsIncompleteSixth = _isIncompleteSixthForTriadRule(b.identity);
  if (aIsIncompleteSixth == bIsIncompleteSixth) return null;

  final aIsCompleteTriad = fa.isCompleteTriad;
  final bIsCompleteTriad = fb.isCompleteTriad;

  if (aIsIncompleteSixth && bIsCompleteTriad) return 1;
  if (bIsIncompleteSixth && aIsCompleteTriad) return -1;

  return null;
}

bool _isFifthlessSixth(ChordIdentity id) {
  if (!id.quality.isSixFamily) return false;

  final roles = id.toneRolesByInterval.values;
  return !roles.contains(ChordToneRole.perfect5);
}

bool _isIncompleteSixthForTriadRule(ChordIdentity id) {
  if (!_isFifthlessSixth(id)) return false;
  if (id.rootPc != id.bassPc) return true;

  return id.extensions.isEmpty;
}

/// Prefers the conventional major-seventh upper-structure notation for a
/// dominant-sus color when the slash candidate is a complete major-seventh
/// chord a whole step below the bass/root.
///
/// Example: D♭maj7/E♭ is a standard, readable spelling for the same pitch
/// collection as E♭13sus4: D♭ supplies ♭7, F supplies 9, A♭ supplies sus4, and
/// C supplies 13 over the E♭ bass. In that situation the upper-structure slash
/// is more informative than collapsing the voicing into a root-position sus
/// symbol, especially without register evidence proving a root-shell voicing.
int? _preferMajorSeventhUpperStructureSusSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsSlash = _isMajorSeventhUpperStructureSusSlash(a.identity, fb);
  final bIsSlash = _isMajorSeventhUpperStructureSusSlash(b.identity, fa);
  if (aIsSlash == bIsSlash) return null;

  return aIsSlash ? -1 : 1;
}

bool _isMajorSeventhUpperStructureSusSlash(
  ChordIdentity slash,
  CandidateFeatures otherFeatures,
) {
  if (!otherFeatures.isRootDominantSus) return false;
  if (slash.rootPc == slash.bassPc) return false;
  if (slash.quality != ChordQualityToken.major7) return false;
  if (intervalAboveRoot(slash.bassPc, slash.rootPc) != majorSecondInterval) {
    return false;
  }

  final roles = slash.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.major7);
}

// ---- Dominant and slash readings ---------------------------------------

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
int? _preferCompleteDominantSharp9OverNonSeventhColor(
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
  if (!_isStableNonSeventhSharpNineCompetitor(other.identity, fOther)) {
    return null;
  }

  final preferredCandidate = aIsPreferred ? a : b;
  if (preferredCandidate.cost > other.cost + 0.30) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteDominantSharpNineReading(ChordIdentity id) {
  final fifthRole = switch (id.quality) {
    ChordQualityToken.dominant7 => ChordToneRole.perfect5,
    ChordQualityToken.dominant7Sharp5 => ChordToneRole.sharp5,
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

bool _isStableNonSeventhSharpNineCompetitor(
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
int? _preferCompleteDom7Flat9OverColoredDim7(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isStableDominantFlatNineShell(a.identity, fa);
  final bIsPreferred = _isStableDominantFlatNineShell(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (!_isColoredDiminishedReading(other.identity, fOther)) return null;

  final preferredCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;
  if (preferredCandidate.cost > otherCandidate.cost + 0.30) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isStableDominantFlatNineShell(
  ChordIdentity id,
  CandidateFeatures features,
) {
  if (id.quality != ChordQualityToken.dominant7) return false;
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
  if (!features.isDimFamily && id.quality != ChordQualityToken.diminished) {
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
  if (preferredCandidate.cost > other.cost + 0.35) return null;

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
      (slashQuality == ChordQualityToken.major ||
          slashQuality == ChordQualityToken.minor) &&
      fOther.extPref.alterationCount == 0 &&
      fOther.extPref.naturalCount == 0;
  if (isConventionalSlash) return aIsPreferred ? 1 : -1;

  return aIsPreferred ? -1 : 1;
}

bool _isRootDominantSusFlatNine(ChordIdentity id) {
  return id.bassPc == id.rootPc &&
      id.quality == ChordQualityToken.dominant7sus4 &&
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
int? _preferCompleteMajorSharpElevenInversionOverMajor13Sus4(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteMajorSharpElevenInversion(a.identity, fa);
  final bIsPreferred = _isCompleteMajorSharpElevenInversion(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  if (!_isSparseMajorThirteenSusFour(other.identity)) return null;

  return aIsPreferred ? -1 : 1;
}

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
  if (id.quality != ChordQualityToken.major7sus4) return false;
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

/// Prefers a complete sharp-nine/sharp-eleven dominant thirteenth over a
/// root-position minor-thirteenth spelling that needs both flat-nine and
/// sharp-eleven color.
///
/// Example: {C, Db, Eb, E, F#, G, A} can be read as A13#9#11/F# or
/// F#m13(b9,#11). Both name every pitch, but the dominant reading preserves the
/// complete A-C#-E-G shell and uses standard altered-dominant vocabulary, while
/// the minor reading depends on the much less idiomatic b9/#11 minor color
/// combination.
int? _preferCompleteAlteredThirteenthDominantOverAlteredMinorThirteenth(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isCompleteSharpNineSharpElevenThirteenthDominant(
    a.identity,
  );
  final bIsPreferred = _isCompleteSharpNineSharpElevenThirteenthDominant(
    b.identity,
  );
  if (aIsPreferred == bIsPreferred) return null;

  final other = aIsPreferred ? b : a;
  final fOther = aIsPreferred ? fb : fa;
  if (!_isAlteredMinorThirteenth(other.identity, fOther)) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteSharpNineSharpElevenThirteenthDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7) return false;
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
  if (id.quality != ChordQualityToken.minor7 || !features.hasStableBassRole) {
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

  if (!_isNaturalEleventhSharpFiveDominant(other.identity) &&
      !_isRemoteAlteredNonDominantReading(other.identity)) {
    return null;
  }

  if (preferred.cost > other.cost + ranking_policy.nearTieWindow) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isAlteredSharpFiveDominant(ChordIdentity id) {
  if (id.quality != ChordQualityToken.dominant7Sharp5) return false;
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
/// When costs are tied, prefer the interpretation where the bass note
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

  // Do not promote a fifthless dominant whose natural 11 clashes with its
  // major third (Ab11 shells); without the fifth the 11 reads as a
  // suspension and the avoid-tone price is there for a reason. A complete
  // eleventh with its fifth (C11 over C-E-G-Bb-F) stays promotable.
  final domRoles = domCandidate.identity.toneRolesByInterval.values;
  if (domRoles.contains(ChordToneRole.major3) &&
      !domRoles.contains(ChordToneRole.perfect5) &&
      (domRoles.contains(ChordToneRole.eleven) ||
          domRoles.contains(ChordToneRole.add11))) {
    return null;
  }

  if (domCandidate.cost > otherCandidate.cost + 0.45) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers root-position altered-fifth dominants over close slash readings.
///
/// Flat-five and sharp-five dominant sevenths are tritone-symmetric, so a
/// slash interpretation can remain competitive on price even when the
/// root-position name is clearer. Prefer the root-position reading when it has a real
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

  if (rootCandidate.cost > slashCandidate.cost + 0.30) return null;

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
  if (preferredCandidate.cost > otherCandidate.cost + 0.60) return null;

  return aIsPreferred ? -1 : 1;
}

/// Avoids promoting remote, non-dominant slash readings whose "simple" color
/// is a natural 11 against a major third.
///
/// Example: {Ab, B, C, E, F} is better read as Fm(maj7,#11)/Ab than as
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
  if (!fc.hasAlteredColor) return null;
  // A rule that promotes the "conventional" reading must not promote a
  // rare-vocabulary respelling like m7#5.
  if (conventional.identity.quality.isRareVocabulary) return null;
  if (_isUnusualSeventhMissingThird(conventional.identity)) return null;
  if (fc.bassRoleRank >= fq.bassRoleRank) return null;

  // Keep this rule bounded to close structural ambiguities. Wider gaps should
  // still be decided by the raw template fit.
  if (conventional.cost > questionable.cost + 0.70) return null;

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
/// The 1.50-point guard lets the sus reading win when the cost difference is
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
  if (!_hasOnlyNaturalAddTones(preferredCandidate.identity)) return null;

  if (preferredCandidate.cost > susCandidate.cost + 1.50) return null;

  return aIsPreferred ? -1 : 1;
}

bool _hasOnlyNaturalAddTones(ChordIdentity id) {
  return id.extensions.every(
    (extension) =>
        extension == ChordExtension.add9 ||
        extension == ChordExtension.add11 ||
        extension == ChordExtension.add13,
  );
}

// ---- Triad completeness vs seventh-family inflation --------------------

/// Prefers a complete major/minor triad with add-tone extensions over a sparse
/// seventh-family chord that inflates the same pitches into remote color.
///
/// A complete triad with simple color tones (e.g., Bbmadd9/Db) is a more
/// conventional and stable structure than forcing the same pitches into a
/// fifthless seventh-family reading (e.g., Dbmaj13, which drops the fifth to
/// book a remote thirteenth).
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
  if (preferredCandidate.cost > otherCandidate.cost + 1.50) return null;

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
int? _preferReadableSharpElevenMajorOverFlatFive(
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

  if (_cleanerSpelledSide(preferred, other, tonality, margin: 15) != -1) {
    return null;
  }

  if (preferred.cost > other.cost + 1.50) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isSparseSharpElevenMajor(ChordIdentity id) {
  return _isSparseSharpElevenMajorTriad(id) ||
      _isFifthlessSharpElevenMajorSeventh(id);
}

bool _isSparseSharpElevenMajorTriad(ChordIdentity id) {
  if (id.quality != ChordQualityToken.major) return false;
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
  if (id.quality != ChordQualityToken.major7) return false;
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
  if (id.quality != ChordQualityToken.majorFlat5) return false;
  if (id.extensions.isNotEmpty) return false;

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.flat5) &&
      !roles.contains(ChordToneRole.perfect5);
}

bool _isPlainMajorSeventhFlatFive(ChordIdentity id) {
  if (id.quality != ChordQualityToken.major7Flat5) return false;
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
  if (triadCandidate.cost > otherCandidate.cost + 0.45) return null;

  return aIsTriad ? -1 : 1;
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
  if (fDom.bassIsColorTone) {
    // Color-bass dominant slashes are the original target of this rule.
  } else if (fDom.hasStableBassRole) {
    final dom = domIsA ? a : b;
    if (!_isStableDominantFlatNineShell(dom.identity, fDom)) return null;
  } else {
    return null;
  }
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
      _isUnusualSeventhMissingThird(explained) &&
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
          _isUnusualSeventhMissingThird(explained.identity));
}

bool _isMajorSeventhSplitNinth(ChordIdentity id) {
  return id.quality == ChordQualityToken.major7 &&
      id.extensions.length == 2 &&
      id.extensions.contains(ChordExtension.flat9) &&
      id.extensions.contains(ChordExtension.sharp9);
}

bool _isDominantOrMinorSeventhNinthShell(ChordIdentity id) {
  if ((id.quality != ChordQualityToken.dominant7 &&
          id.quality != ChordQualityToken.minor7) ||
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
  if (id.quality != ChordQualityToken.major &&
      id.quality != ChordQualityToken.minor) {
    return false;
  }
  return features.hasOnlyAddColor;
}

bool _isUnusualSeventhMissingThird(ChordIdentity id) {
  if (!id.quality.isSeventhFamily) return false;

  final roles = id.toneRolesByInterval.values;
  return !roles.contains(ChordToneRole.major3) &&
      !roles.contains(ChordToneRole.minor3) &&
      !roles.contains(ChordToneRole.sus2) &&
      !roles.contains(ChordToneRole.sus4);
}

int? _preferLowerCostAddChordOverMissingThirdUnusualSeventh(
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
  if (!_isUnusualSeventhMissingThird(unusual.identity)) return null;
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

int? _preferLowerCostMajorSeventhBassInversionOverColorBassSlash(
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

/// Prefers stacked natural extensions (9, 11, 13) over "add" extensions,
/// then prefers fewer total extensions for simpler interpretations.
int? _preferNaturalExtensions(
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

int? _preferRootPosition(
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

int? _preferConventionalInversion(
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
/// [_preferCleanerTritoneFlatFiveDominantSpelling].
int? _preferCleanerSpelledTritoneTwinExtendedDominant(
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

  return _cleanerSpelledSide(a, b, tonality, margin: 10);
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
  if ((a.cost - b.cost).abs() > 0.05) return null;

  return _cleanerSpelledSide(a, b, tonality, margin: 0);
}

bool _isPlainTritoneFlatFiveDominantPair(ChordIdentity a, ChordIdentity b) {
  return a.quality == ChordQualityToken.dominant7Flat5 &&
      b.quality == ChordQualityToken.dominant7Flat5 &&
      a.extensions.isEmpty &&
      b.extensions.isEmpty &&
      intervalAboveRoot(a.rootPc, b.rootPc) == tritoneInterval;
}

/// Returns -1 or 1 for the candidate whose members spell more readably in
/// context, or null when the penalty difference does not exceed [margin].
int? _cleanerSpelledSide(
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

int? _prefer7thChords(
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

/// Last-resort readability preference: when no structural rule separates two
/// near-tied readings, prefer the one whose members spell more cleanly rather
/// than falling through to the arbitrary root-order fallback.
int? _preferCleanerSpelling(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures _,
  CandidateFeatures _,
  Tonality tonality,
) {
  return _cleanerSpelledSide(a, b, tonality, margin: 0);
}
