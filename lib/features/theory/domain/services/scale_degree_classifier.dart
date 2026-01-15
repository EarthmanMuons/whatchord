import '../analysis/chord_templates.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';

/// Pedantic diatonic scale-degree classification for analyzed chords.
///
/// See notes in this file: strict classification requires the real voicing mask.
abstract final class ScaleDegreeClassifier {
  // Single source of truth: chordTemplates.
  static final Map<ChordQualityToken, ChordTemplate> _templateByQuality = {
    for (final t in chordTemplates) t.quality: t,
  };

  /// Convenience API matching your test callsites.
  ///
  /// Uses the chord’s own presentIntervalsMask and enforces strict validation.
  static ScaleDegree? strict({
    required Tonality tonality,
    required ChordIdentity chord,
    bool rejectUnexplainedTones = true,
  }) {
    return degreeForChord(
      tonality,
      chord,
      presentIntervalsMask: chord.presentIntervalsMask,
      strictVoicingValidation: true,
      rejectUnexplainedTones: rejectUnexplainedTones,
    );
  }

  /// Returns the diatonic functional degree for [chord] in [tonality], or null.
  static ScaleDegree? degreeForChord(
    Tonality tonality,
    ChordIdentity chord, {
    int? presentIntervalsMask,
    bool strictVoicingValidation = true,
    bool rejectUnexplainedTones = false,
  }) {
    final degree = degreeForRootPc(tonality, chord.rootPc);
    if (degree == null) return null;

    final q = chord.quality;

    // Conservative exclusions (optional; keep if you want “strict functional degree”
    // to exclude suspensions/power chords).
    if (q.isSus || q == ChordQualityToken.power5) return null;

    // Degree whitelist gate (cheap and prevents “obviously non-diatonic” labels).
    final allowedQualities = _allowedQualitiesForDegree(tonality, degree);

    // IMPORTANT: added-sixth chords should be treated as diatonic if their
    // underlying triad quality is diatonic AND the 6 is diatonic to the key.
    final baseQualityForWhitelist = _baseQualityForSix(q) ?? q;
    if (!allowedQualities.contains(baseQualityForWhitelist)) return null;

    // Extension policy: altered extensions are non-diatonic in this model.
    if (!_extensionsAreDiatonicToKey(
      tonality,
      chord.rootPc,
      chord.extensions,
    )) {
      return null;
    }

    // Strict validation requires the true voicing mask.
    final int relMask;
    if (strictVoicingValidation) {
      if (presentIntervalsMask == null) {
        // No false positives: refuse to classify without the real voicing mask.
        return null;
      }
      relMask = presentIntervalsMask & 0xFFF;
    } else {
      relMask = _approxPresentIntervalsMask(chord);
    }

    // Single source of truth for required/optional/base = chordTemplates.
    final tmpl = _templateByQuality[q];
    if (tmpl == null) return null;

    const rootBit = 1 << 0;
    final requiredMask = tmpl.requiredMask | rootBit;
    final baseMask = tmpl.baseMask | rootBit;

    // 1) Required tones must actually be present in the voicing.
    if ((relMask & requiredMask) != requiredMask) return null;

    // 2) Declared extensions must be present in the voicing.
    final extMask = _extensionMask(chord.extensions);
    if ((relMask & extMask) != extMask) return null;

    // 3) Any present base tones must be diatonic to the key.
    final presentBase = relMask & baseMask;
    if (!_allIntervalsInMaskAreDiatonic(tonality, chord.rootPc, presentBase)) {
      return null;
    }

    // 4) Optional “most pedantic” mode: reject unexplained tones.
    if (rejectUnexplainedTones) {
      final explainable = baseMask | extMask;
      final unexplained = relMask & ~explainable;
      if (unexplained != 0) return null;
    }

    return degree;
  }

  /// Returns scale degree for a root pitch class only (no quality validation).
  static ScaleDegree? degreeForRootPc(Tonality tonality, int rootPc) {
    final rel = (rootPc - tonality.tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    if (tonality.isMajor) {
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static ChordQualityToken? _baseQualityForSix(ChordQualityToken q) {
    return switch (q) {
      ChordQualityToken.major6 => ChordQualityToken.major,
      ChordQualityToken.minor6 => ChordQualityToken.minor,
      _ => null,
    };
  }

  static int _pcAdd(int pc, int semitones) {
    final v = (pc + semitones) % 12;
    return v < 0 ? v + 12 : v;
  }

  static bool _allIntervalsInMaskAreDiatonic(
    Tonality tonality,
    int rootPc,
    int intervalsMask,
  ) {
    for (var i = 0; i < 12; i++) {
      if ((intervalsMask & (1 << i)) == 0) continue;
      final pc = _pcAdd(rootPc, i);
      if (!tonality.containsPitchClass(pc)) return false;
    }
    return true;
  }

  static int _extensionMask(Set<ChordExtension> exts) {
    var m = 0;
    for (final e in exts) {
      m |= e.intervalBit; // from ChordExtensionInterval
    }
    return m;
  }

  static bool _extensionsAreDiatonicToKey(
    Tonality tonality,
    int rootPc,
    Set<ChordExtension> exts,
  ) {
    for (final e in exts) {
      if (e.isAlteration) return false;

      final pc = _pcAdd(rootPc, e.intervalAboveRoot);
      if (!tonality.containsPitchClass(pc)) return false;
    }
    return true;
  }

  static int _approxPresentIntervalsMask(ChordIdentity chord) {
    var mask = 0;
    mask |= 1 << 0; // root

    for (final i in chord.toneRolesByInterval.keys) {
      mask |= 1 << (i % 12);
    }
    for (final e in chord.extensions) {
      mask |= e.intervalBit;
    }
    return mask & 0xFFF;
  }

  static Set<ChordQualityToken> _allowedQualitiesForDegree(
    Tonality tonality,
    ScaleDegree d,
  ) {
    if (tonality.isMajor) {
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
        },
      };
    } else {
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
}
