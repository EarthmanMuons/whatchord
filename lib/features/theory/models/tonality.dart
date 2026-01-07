import 'package:meta/meta.dart';

import '../engine/models/chord_identity.dart';
import '../services/pitch_class.dart';
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

  /// Phase 3: diatonic functional degree for an analyzed chord identity.
  ///
  /// Returns null when:
  /// - the root is not diatonic to the tonality (borrowed/secondary/etc), OR
  /// - the chord quality does not match the expected diatonic chord quality
  ///   for that degree in this tonality (e.g. D major in C major).
  ScaleDegree? scaleDegreeForChord(ChordIdentity id) {
    final degree = scaleDegreeForRootPc(id.rootPc);
    if (degree == null) return null;

    final allowed = _allowedQualitiesForDegree(degree);
    return allowed.contains(id.quality) ? degree : null;
  }

  /// Scale degree for a *root pitch class* only (no quality validation).
  ScaleDegree? scaleDegreeForRootPc(int rootPc) {
    final rel = (rootPc - tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    if (isMajor) {
      // Major scale: 0,2,4,5,7,9,11
      return switch (interval) {
        0 => ScaleDegree.one,
        2 => ScaleDegree.two,
        4 => ScaleDegree.three,
        5 => ScaleDegree.four,
        7 => ScaleDegree.five,
        9 => ScaleDegree.six,
        11 => ScaleDegree.seven,
        _ => null,
      };
    } else {
      // Natural minor: 0,2,3,5,7,8,10
      return switch (interval) {
        0 => ScaleDegree.one,
        2 => ScaleDegree.two,
        3 => ScaleDegree.three,
        5 => ScaleDegree.four,
        7 => ScaleDegree.five,
        8 => ScaleDegree.six,
        10 => ScaleDegree.seven,
        _ => null,
      };
    }
  }

  Set<ChordQualityToken> _allowedQualitiesForDegree(ScaleDegree d) {
    // Phase 3 scope: “common diatonic” triads + sevenths (natural minor).
    //
    // This is intentionally permissive for 6-family where it aligns with
    // diatonic function (e.g., I6 or vi6 in major).
    if (isMajor) {
      return switch (d) {
        ScaleDegree.one => const {
          ChordQualityToken.major,
          ChordQualityToken.major6,
          ChordQualityToken.major7,
        },
        ScaleDegree.two => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.three => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.four => const {
          ChordQualityToken.major,
          ChordQualityToken.major6,
          ChordQualityToken.major7,
        },
        ScaleDegree.five => const {
          ChordQualityToken.major,
          ChordQualityToken.dominant7,
        },
        ScaleDegree.six => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor6,
          ChordQualityToken.minor7,
        },
        ScaleDegree.seven => const {
          ChordQualityToken.diminished,
          ChordQualityToken.halfDiminished7,
          // You can decide whether to allow diminished7 here; it is not
          // diatonic to major, but it can show up in practice as a leading-tone
          // fully diminished from harmonic minor borrowing.
          // ChordQualityToken.diminished7,
        },
      };
    } else {
      // Natural minor diatonic harmony:
      // i: minor
      // ii°: diminished / ø7
      // III: major
      // iv: minor
      // v: minor (harmonic minor would make V / V7, but that’s Phase 4)
      // VI: major
      // VII: major (and VII7 is a dominant7 quality in natural minor: e.g. G7 in A minor)
      return switch (d) {
        ScaleDegree.one => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor6,
          ChordQualityToken.minor7,
        },
        ScaleDegree.two => const {
          ChordQualityToken.diminished,
          ChordQualityToken.halfDiminished7,
        },
        ScaleDegree.three => const {
          ChordQualityToken.major,
          ChordQualityToken.major6,
          ChordQualityToken.major7,
        },
        ScaleDegree.four => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.five => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
          // Optional Phase-4-esque allowance:
          // ChordQualityToken.major,
          // ChordQualityToken.dominant7,
        },
        ScaleDegree.six => const {
          ChordQualityToken.major,
          ChordQualityToken.major6,
          ChordQualityToken.major7,
        },
        ScaleDegree.seven => const {
          ChordQualityToken.major,
          ChordQualityToken.dominant7,
        },
      };
    }
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
