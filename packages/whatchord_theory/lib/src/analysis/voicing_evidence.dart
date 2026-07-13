import '../models/chord_identity.dart';
import '../models/chord_tone_role.dart';
import '../models/observed_voicing.dart';
import '../services/pitch_class.dart';

/// Register-evidence predicates the ranking layer consults to break near-ties.
///
/// Voicing is evidence, not ground truth: players distribute notes for
/// ergonomics, omit roots, and double for texture. So this only contributes a
/// narrow, high-confidence signal, and only within the ranking near-tie window,
/// where it prefers a reading the register clearly supports over one it does
/// not. It never changes costs and never overrides a clear cost gap.
abstract final class VoicingEvidence {
  /// Minimum bass-to-next-note gap (semitones) that counts as an isolated bass.
  static const int _isolationGap = 3;

  /// Whether the voicing presents [id] as an upper-structure slash: a complete
  /// chord core stacked above an isolated color-tone bass.
  ///
  /// This is the signature of voicings like an Am7 sitting above a low, gapped
  /// D bass, which musicians read as Am7/D rather than a root-position D9sus4.
  static bool supportsUpperStructureSlash(
    ChordIdentity id,
    ObservedVoicing voicing,
  ) {
    if (voicing.isInert) return false;
    if (!id.hasSlashBass) return false;

    final bassInterval = intervalAboveRoot(id.bassPc, id.rootPc);
    final bassRole = id.toneRolesByInterval[bassInterval];
    if (bassRole == null || _isCoreRole(bassRole)) return false;

    if (!_coreIsComplete(id)) return false;

    final bassMidi = voicing.bassMidi;
    for (final pc in _corePitchClasses(id)) {
      final lowest = voicing.lowestMidiOf(pc);
      if (lowest == null || lowest <= bassMidi) return false;
    }

    return voicing.bassGap >= _isolationGap;
  }

  static bool _coreIsComplete(ChordIdentity id) {
    final roles = id.toneRolesByInterval.values.toSet();
    final hasRoot = roles.contains(ChordToneRole.root);
    final hasThird =
        roles.contains(ChordToneRole.minor3) ||
        roles.contains(ChordToneRole.major3) ||
        roles.contains(ChordToneRole.sus2) ||
        roles.contains(ChordToneRole.sus4);
    final hasFifth =
        roles.contains(ChordToneRole.perfect5) ||
        roles.contains(ChordToneRole.flat5) ||
        roles.contains(ChordToneRole.sharp5);
    final hasSeventh =
        roles.contains(ChordToneRole.flat7) ||
        roles.contains(ChordToneRole.major7) ||
        roles.contains(ChordToneRole.dim7);
    final needsSeventh = id.quality.isSeventhFamily;
    return hasRoot && hasThird && hasFifth && (!needsSeventh || hasSeventh);
  }

  static Set<int> _corePitchClasses(ChordIdentity id) {
    final out = <int>{};
    for (final entry in id.toneRolesByInterval.entries) {
      if (_isCoreRole(entry.value)) out.add((id.rootPc + entry.key) % 12);
    }
    return out;
  }

  static bool _isCoreRole(ChordToneRole role) => switch (role) {
    ChordToneRole.root ||
    ChordToneRole.sus2 ||
    ChordToneRole.sus4 ||
    ChordToneRole.minor3 ||
    ChordToneRole.major3 ||
    ChordToneRole.flat5 ||
    ChordToneRole.perfect5 ||
    ChordToneRole.sharp5 ||
    ChordToneRole.sixth ||
    ChordToneRole.dim7 ||
    ChordToneRole.flat7 ||
    ChordToneRole.major7 => true,
    _ => false,
  };
}
