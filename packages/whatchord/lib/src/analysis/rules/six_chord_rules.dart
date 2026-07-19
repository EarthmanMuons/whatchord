// Six chords vs inverted sevenths ranking rules. Rule order and policy live in the two
// lists in ../ranking_rules.dart; each function here decides one
// pairwise ambiguity and returns null when it does not apply.

import '../../models/chord_candidate.dart';
import '../../models/chord_identity.dart';
import '../../models/chord_tone_role.dart';
import '../../models/tonality.dart';
import '../../services/interval_constants.dart';
import '../../services/pitch_class.dart';
import '../candidate_features.dart';
import 'named_rule.dart';
import 'rule_scaffold.dart';

/// Prefers the reading the voicing presents as an upper-structure slash: a
/// complete chord stacked above an isolated color-tone bass (e.g. an Am7 over a
/// low, gapped D reads as Am7/D rather than a root-position D9sus4). Applies
/// only when exactly one candidate carries that register evidence.
int? preferVoicingUpperStructureSlash(
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
final RuleFn prefer6thInRoot = preferOver(
  isPreferred: (_, f, _) => f.isSixFamily,
  preferredQualifies: (c, f, _) =>
      f.isRootPosition && !_isFifthlessSixth(c.identity),
  competitorQualifies: (_, f, _) => !f.isRootPosition && f.extensionCount == 0,
);

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
int? preferCompleteTriadOverIncompleteSixth(
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
int? preferMajorSeventhUpperStructureSusSlash(
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
  if (slash.quality != ChordQuality.major7) return false;
  if (intervalAboveRoot(slash.bassPc, slash.rootPc) != majorSecondInterval) {
    return false;
  }

  final roles = slash.toneRolesByInterval.values;
  return roles.contains(ChordToneRole.root) &&
      roles.contains(ChordToneRole.major3) &&
      roles.contains(ChordToneRole.perfect5) &&
      roles.contains(ChordToneRole.major7);
}
