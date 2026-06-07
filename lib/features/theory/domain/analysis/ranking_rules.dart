import '../models/chord_candidate.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';
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
    'prefer simple triad add-tone over seventh-family unusual quality',
    _preferSimpleTriadAddToneOverSeventhFamilyUnusualQuality,
  ),
];

/// Near-tie tie-breakers, applied in priority order only when two candidates
/// score within the near-tie window of each other. These encode musical
/// preferences:
/// - Structural clarity (root position, shell tones)
/// - Functional harmony (diatonic, dominant alterations)
/// - Simplicity (fewer extensions/alterations, avoid suspensions)
final List<NamedRule> tieBreakerRules = <NamedRule>[
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
    'prefer root-position extended dominant over altered-fifth slash',
    _preferRootExtendedDom7OverAlteredFifthSlash,
  ),
  NamedRule(
    'prefer complete major inversion over minor sharp-five',
    _preferCompleteMajorInversionOverMinorSharpFive,
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
  NamedRule('prefer fewer altered/tension colors', _preferFewerAlterations),
  NamedRule('prefer diatonic chords', _preferDiatonic),
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
  NamedRule('prefer more conventional inversion', _preferConventionalInversion),
  NamedRule('prefer 7th chords over triads', _prefer7thChords),
  NamedRule('prefer fewer extensions', _preferFewerExtensions),
  NamedRule('avoid suspended chords', _avoidSuspended),
];

// ---- Six chords vs inverted sevenths -----------------------------------

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
  final aIsPreferred = _isCompleteDom7Flat9(a.identity, fa);
  final bIsPreferred = _isCompleteDom7Flat9(b.identity, fb);
  if (aIsPreferred == bIsPreferred) return null;

  final fDim = aIsPreferred ? fb : fa;
  if (!fDim.isDim7 || fDim.extensionCount == 0) return null;

  final preferredCandidate = aIsPreferred ? a : b;
  final otherCandidate = aIsPreferred ? b : a;
  if (preferredCandidate.score + 0.55 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

bool _isCompleteDom7Flat9(ChordIdentity id, CandidateFeatures features) {
  if (!features.isDom7) return false;
  if (features.bassRoleRank > 2) return false;
  if (id.extensions.length != 1 ||
      !id.extensions.contains(ChordExtension.flat9)) {
    return false;
  }

  final roles = id.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.flat9) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.flat7);
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
  final domHasColor =
      (fDom.extPref.naturalCount + fDom.extPref.alterationCount) > 0;
  if (!domHasColor) return null;

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

/// Prefers a conventional root-position extended dominant over a remote
/// altered-fifth dominant slash spelling in close calls.
///
/// Example: {C, E, G, Bb, D, F#} is better read as C9#11 than D11#5/C.
/// The D-rooted spelling is possible, but it treats the bass as a seventh and
/// respells Bb as A#; the C-rooted reading has the bass, shell, and extensions
/// aligned with the observed voicing.
int? _preferRootExtendedDom7OverAlteredFifthSlash(
  ChordCandidate a,
  ChordCandidate b,
  CandidateFeatures fa,
  CandidateFeatures fb,
  Tonality _,
) {
  final aIsPreferred = _isRootExtendedDom7(a.identity, fa);
  final bIsPreferred = _isRootExtendedDom7(b.identity, fb);
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

bool _isRootExtendedDom7(ChordIdentity id, CandidateFeatures features) {
  if (!features.isDom7RootPosition) return false;
  if (!features.dom7HasShell) return false;
  if (!id.extensions.contains(ChordExtension.nine)) return false;
  return id.extensions.contains(ChordExtension.sharp11);
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
  final domHasColor =
      (fDom.extPref.naturalCount + fDom.extPref.alterationCount) > 0;
  if (!domHasColor) return null;

  if (domCandidate.score + 0.25 < otherCandidate.score) return null;

  return aIsPreferred ? -1 : 1;
}

/// Prefers a complete seventh chord with the ninth in the bass over a remote
/// altered slash spelling.
///
/// Example: {C, D, E, G, Bb} with D in the bass is normally understood as
/// C9/D (often written C7/D), not Em7#5#11/D. The E-rooted spelling is
/// pitch-class valid, but it respells C as B# and treats a plain C dominant
/// stack as a remote altered minor seventh chord.
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
  if (fOther.extensionTensionCount == 0) return null;
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

  final rootHasAlteration = fRoot.extPref.alterationCount > 0;
  final slashHasOnlyAddOrNaturalColor = fSlash.extPref.alterationCount == 0;
  if (!rootHasAlteration || !slashHasOnlyAddOrNaturalColor) return null;

  if (rootCandidate.score + 0.50 < slashCandidate.score) return null;

  return rootIsA ? -1 : 1;
}

/// Avoids promoting remote, non-dominant slash readings whose "simple" color
/// is a natural 11 against a major third.
///
/// Example: {Ab, B, C, E, F} is better read as Fm(maj7)#11/Ab than as
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
      !fa.isSeventhFamily &&
      !fa.isSus &&
      fa.extPref.addCount > 0 &&
      fa.extPref.alterationCount == 0 &&
      fa.extPref.naturalCount == 0;
  final bIsTriadAddTone =
      !fb.isSeventhFamily &&
      !fb.isSus &&
      fb.extPref.addCount > 0 &&
      fb.extPref.alterationCount == 0 &&
      fb.extPref.naturalCount == 0;
  if (aIsTriadAddTone == bIsTriadAddTone) return null;

  // The other must be a seventh-family chord with an unusual quality
  // (altered-fifth, suspended, or flat-five seventh qualities) in an
  // inversion with no extensions at all. Standard qualities like plain
  // dominant7, minor7, or major7 should not be overridden by this rule.
  final fOther = aIsTriadAddTone ? fb : fa;
  final otherQuality = aIsTriadAddTone
      ? b.identity.quality
      : a.identity.quality;
  if (!fOther.isSeventhFamily) return null;
  if (!_isUnusualSeventhQuality(otherQuality)) return null;
  if (fOther.extPref.totalCount > 0) return null;
  if (fOther.isRootPosition) return null;

  // Score guard: let decisively higher-scoring unusual-quality readings
  // through when the gap exceeds what structural inflation explains.
  final preferredCandidate = aIsTriadAddTone ? a : b;
  final otherCandidate = aIsTriadAddTone ? b : a;
  if (preferredCandidate.score + 1.50 < otherCandidate.score) return null;

  return aIsTriadAddTone ? -1 : 1;
}

bool _isUnusualSeventhQuality(ChordQualityToken quality) {
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
/// tone as an unexplained extra.
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
