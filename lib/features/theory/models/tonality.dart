import 'package:meta/meta.dart';

import '../services/pitch_class.dart';

enum TonalityMode { major, minor }

@immutable
class Tonality {
  final String tonic; // e.g. "C", "F#", "Bb", "F♯", "B♭"
  final TonalityMode mode;

  const Tonality(this.tonic, this.mode);

  bool get isMajor => mode == TonalityMode.major;
  bool get isMinor => mode == TonalityMode.minor;

  String get label => isMajor ? tonic : tonic.toLowerCase();

  String get displayName => isMajor ? '$tonic major' : '$tonic minor';

  /// Pitch class of the tonic (0..11).
  int get tonicPitchClass => pitchClassFromNoteName(tonic);

  /// Returns whether the pitch class is diatonic to this tonality.
  ///
  /// Phase 3 scope: natural major / natural minor scales only.
  /// (Later: harmonic/melodic minor, modes, etc.)
  bool containsPitchClass(int pc) {
    final rel = (pc - tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    // Diatonic pitch classes for the scale degrees (in semitone offsets).
    const major = <int>{0, 2, 4, 5, 7, 9, 11};
    const minor = <int>{0, 2, 3, 5, 7, 8, 10}; // natural minor

    return isMajor ? major.contains(interval) : minor.contains(interval);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tonality &&
          runtimeType == other.runtimeType &&
          tonic == other.tonic &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(tonic, mode);

  @override
  String toString() => displayName;
}
