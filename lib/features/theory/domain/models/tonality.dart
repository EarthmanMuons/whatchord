import 'package:meta/meta.dart';

import '../services/pitch_class.dart';
import '../services/scale_degree_classifier.dart';
import 'chord_identity.dart';
import 'scale_degree.dart';

enum TonalityMode { major, minor }

@immutable
class Tonality {
  final String tonic; // canonical ASCII: "C", "F#", "Bb"
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
  /// Current behavior: natural major / natural minor pitch-class sets.
  bool containsPitchClass(int pc) {
    final rel = (pc - tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    if (isMajor) {
      // Major: 0,2,4,5,7,9,11
      return switch (interval) {
        0 || 2 || 4 || 5 || 7 || 9 || 11 => true,
        _ => false,
      };
    } else {
      // Natural minor: 0,2,3,5,7,8,10
      return switch (interval) {
        0 || 2 || 3 || 5 || 7 || 8 || 10 => true,
        _ => false,
      };
    }
  }

  /// Convenience: returns the diatonic scale degree for a root pitch class,
  /// or null if non-diatonic in the current natural major/minor model.
  ///
  /// This delegates to [ScaleDegreeClassifier] so Tonality does not own
  /// scale-degree mapping logic.
  ScaleDegree? scaleDegreeForRootPc(int rootPc) =>
      ScaleDegreeClassifier.degreeForRootPc(this, rootPc);

  /// Convenience: strict diatonic degree for a chord identity using the
  /// chord’s actual present-interval mask.
  ///
  /// This is intentionally a thin delegating wrapper; all rules live in
  /// [ScaleDegreeClassifier].
  ScaleDegree? scaleDegreeForChord(
    ChordIdentity id, {
    bool rejectUnexplainedTones = true,
  }) {
    return ScaleDegreeClassifier.degreeForChord(
      this,
      id,
      presentIntervalsMask: id.presentIntervalsMask,
      strictVoicingValidation: true,
      rejectUnexplainedTones: rejectUnexplainedTones,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tonality && other.tonic == tonic && other.mode == mode;

  @override
  int get hashCode => Object.hash(tonic, mode);

  @override
  String toString() => displayName;
}
