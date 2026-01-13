import 'package:meta/meta.dart';

import '../domain/models/chord_identity.dart';
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
  /// Currently: natural major / natural minor pitch-class sets.
  bool containsPitchClass(int pc) {
    final rel = (pc - tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    // Diatonic pitch classes for the scale degrees (in semitone offsets).
    const major = <int>{0, 2, 4, 5, 7, 9, 11};
    const minor = <int>{0, 2, 3, 5, 7, 8, 10}; // natural minor

    return isMajor ? major.contains(interval) : minor.contains(interval);
  }

  /// Diatonic functional degree for an analyzed chord identity.
  ///
  /// Returns null when:
  /// - the root is not diatonic to the tonality (borrowed/secondary/etc), OR
  /// - the chord quality does not match the expected diatonic chord quality
  ///   for that degree in this tonality (e.g. D major in C major).
  ///
  /// Special handling:
  /// - major6/minor6 are treated as *added-sixth* chords (e.g., C6 = C-E-G-A).
  ///   Their diatonicity depends on whether their required chord tones are
  ///   diatonic to the key, so they cannot be validated purely by degree-based
  ///   whitelists.
  ScaleDegree? scaleDegreeForChord(ChordIdentity id) {
    final degree = scaleDegreeForRootPc(id.rootPc);
    if (degree == null) return null;

    final q = id.quality;

    // Added-sixth chord qualities (matches the ChordTemplate masks):
    //   major6: required M3 (+4) and M6 (+9) [P5 optional]
    //   minor6: required m3 (+3) and M6 (+9) [P5 optional]
    if (q == ChordQualityToken.major6 || q == ChordQualityToken.minor6) {
      final base = _baseQualityForSix(q);

      // 1) The degree must allow the underlying triad quality diatonically.
      //    (prevents "degree" classification when the function/quality is off)
      final allowedBase = _allowedQualitiesForDegree(degree);
      if (!allowedBase.contains(base)) return null;

      // 2) Required chord tones must be diatonic to the tonality.
      //    This is the key fix: e.g., Am6 in C major has F# (non-diatonic).
      final thirdPc = _pcAdd(id.rootPc, q == ChordQualityToken.major6 ? 4 : 3);
      final sixthPc = _pcAdd(id.rootPc, 9);

      return (containsPitchClass(thirdPc) && containsPitchClass(sixthPc))
          ? degree
          : null;
    }

    final allowed = _allowedQualitiesForDegree(degree);
    return allowed.contains(q) ? degree : null;
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

  /// Degree-based diatonic quality whitelist for triads + sevenths.
  ///
  /// Note: major6/minor6 are intentionally excluded; see scaleDegreeForChord()
  /// for correct validation of added-sixth chords.
  Set<ChordQualityToken> _allowedQualitiesForDegree(ScaleDegree d) {
    if (isMajor) {
      return switch (d) {
        ScaleDegree.one => const {
          ChordQualityToken.major,
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
          ChordQualityToken.major7,
        },
        ScaleDegree.five => const {
          ChordQualityToken.major,
          ChordQualityToken.dominant7,
        },
        ScaleDegree.six => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.seven => const {
          ChordQualityToken.diminished,
          ChordQualityToken.halfDiminished7,
          // Fully diminished 7th is not diatonic to major; it typically appears
          // as a borrowed leading-tone chord (e.g., from harmonic minor context).
          // ChordQualityToken.diminished7,
        },
      };
    } else {
      // Natural minor diatonic harmony:
      // i: minor / m7
      // ii°: diminished / ø7
      // III: major / maj7
      // iv: minor / m7
      // v: minor / m7  (harmonic minor would make V / V7)
      // VI: major / maj7
      // VII: major / (dominant7 is diatonic here: e.g., G7 in A natural minor)
      return switch (d) {
        ScaleDegree.one => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.two => const {
          ChordQualityToken.diminished,
          ChordQualityToken.halfDiminished7,
        },
        ScaleDegree.three => const {
          ChordQualityToken.major,
          ChordQualityToken.major7,
        },
        ScaleDegree.four => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
        },
        ScaleDegree.five => const {
          ChordQualityToken.minor,
          ChordQualityToken.minor7,
          // Harmonic minor expansion would add:
          // ChordQualityToken.major,
          // ChordQualityToken.dominant7,
        },
        ScaleDegree.six => const {
          ChordQualityToken.major,
          ChordQualityToken.major7,
        },
        ScaleDegree.seven => const {
          ChordQualityToken.major,
          ChordQualityToken.dominant7,
        },
      };
    }
  }

  /// For added-sixth qualities, determine the underlying triad quality.
  static ChordQualityToken _baseQualityForSix(ChordQualityToken q) {
    return switch (q) {
      ChordQualityToken.major6 => ChordQualityToken.major,
      ChordQualityToken.minor6 => ChordQualityToken.minor,
      _ => q,
    };
  }

  static int _pcAdd(int pc, int semitones) {
    final v = (pc + semitones) % 12;
    return v < 0 ? v + 12 : v;
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
