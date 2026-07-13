import '../analysis/chord_templates.dart';
import '../models/chord_extension.dart';
import '../models/chord_identity.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';
import 'note_spelling.dart';
import 'pitch_class.dart';
import 'scale_degree_roman_numerals.dart';

/// Pedantic source-aware scale-degree classification for analyzed chords.
///
/// See notes in this file: strict classification requires the real voicing mask.
abstract final class ScaleDegreeClassifier {
  // Single source of truth: chordTemplates.
  static final Map<ChordQualityToken, ChordTemplate> _templateByQuality = {
    for (final t in chordTemplates) t.quality: t,
  };

  /// Classifies [chord] using its own voicing as the interval mask, with strict
  /// validation enabled. Returns null if the chord does not cleanly fit a
  /// functional degree in [tonality].
  static ScaleDegree? strict({
    required Tonality tonality,
    required ChordIdentity chord,
    bool rejectUnexplainedTones = true,
  }) {
    return analyzeChord(
      tonality,
      chord,
      presentIntervalsMask: chord.presentIntervalsMask,
      strictVoicingValidation: true,
      rejectUnexplainedTones: rejectUnexplainedTones,
    )?.degree;
  }

  /// Returns the functional degree for [chord] in [tonality], or null.
  ///
  /// [rootName] is the spelled root the chord is displayed with; when given, a
  /// diatonic degree is only assigned if the root letter matches that degree's
  /// diatonic letter, so an enharmonic respelling (e.g. B instead of Cb in Gb
  /// major) is not labeled as the diatonic degree it shares a pitch class with.
  static ScaleDegree? degreeForChord(
    Tonality tonality,
    ChordIdentity chord, {
    int? presentIntervalsMask,
    bool strictVoicingValidation = true,
    bool rejectUnexplainedTones = false,
    String? rootName,
  }) {
    return analyzeChord(
      tonality,
      chord,
      presentIntervalsMask: presentIntervalsMask,
      strictVoicingValidation: strictVoicingValidation,
      rejectUnexplainedTones: rejectUnexplainedTones,
      rootName: rootName,
    )?.degree;
  }

  /// Returns source-aware functional analysis for [chord] in [tonality].
  ///
  /// See [degreeForChord] for how [rootName] gates the diatonic spelling. When
  /// [rootName] is omitted it falls back to [spellChordRoot], the same resolver
  /// the displayed chord symbol uses, so the label cannot diverge from the
  /// spelling the user sees.
  static ScaleDegreeAnalysis? analyzeChord(
    Tonality tonality,
    ChordIdentity chord, {
    int? presentIntervalsMask,
    bool strictVoicingValidation = true,
    bool rejectUnexplainedTones = false,
    String? rootName,
  }) {
    final effectiveRootName =
        rootName ?? spellChordRoot(chord, tonality: tonality);

    for (final source in _sourcesForTonality(tonality)) {
      final analysis = _analyzeChordInSource(
        tonality,
        chord,
        source: source,
        presentIntervalsMask: presentIntervalsMask,
        strictVoicingValidation: strictVoicingValidation,
        rejectUnexplainedTones: rejectUnexplainedTones,
        rootName: effectiveRootName,
      );
      if (analysis != null) return analysis;
    }

    return null;
  }

  static ScaleDegreeAnalysis? _analyzeChordInSource(
    Tonality tonality,
    ChordIdentity chord, {
    required ScaleDegreeSource source,
    required String rootName,
    int? presentIntervalsMask,
    bool strictVoicingValidation = true,
    bool rejectUnexplainedTones = false,
  }) {
    final degree = _degreeForRootPcInSource(tonality, chord.rootPc, source);
    if (degree == null) return null;

    if (!_rootSpellingMatchesDegree(tonality, rootName, degree)) return null;

    final q = chord.quality;

    // Conservative exclusions for strict functional degree.
    if (q.isSus) return null;

    // Degree whitelist gate (cheap and prevents “obviously non-diatonic” labels).
    final allowedQualities = _allowedQualitiesForDegree(source, degree);

    // IMPORTANT: added-sixth chords should be treated as diatonic if their
    // underlying triad quality is diatonic AND the 6 is diatonic to the key.
    final baseQualityForWhitelist = _baseQualityForSix(q) ?? q;
    if (!allowedQualities.contains(baseQualityForWhitelist)) return null;

    // Extension policy: every declared extension must belong to the active
    // source collection. This keeps major-key altered dominants chromatic while
    // allowing minor-key V7b9 when it comes from harmonic minor.
    if (!_extensionsAreDiatonicToKey(
      tonality,
      chord.rootPc,
      chord.extensions,
      source,
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

    // 3) Any present base tones must belong to the active source collection.
    final presentBase = relMask & baseMask;
    if (!_allIntervalsInMaskAreDiatonic(
      tonality,
      chord.rootPc,
      presentBase,
      source,
    )) {
      return null;
    }

    // 4) Optional “most pedantic” mode: reject unexplained tones.
    if (rejectUnexplainedTones) {
      final explainable = baseMask | extMask;
      final unexplained = relMask & ~explainable;
      if (unexplained != 0) return null;
    }

    return ScaleDegreeAnalysis(
      degree: degree,
      source: source,
      romanNumeral: _romanNumeralFor(degree, source, q),
      spokenScaleDegree: _spokenScaleDegreeFor(degree, source),
      functionName: _functionNameFor(degree, source),
    );
  }

  /// Returns scale degree for a root pitch class only (no quality validation).
  static ScaleDegree? degreeForRootPc(Tonality tonality, int rootPc) {
    final source = tonality.isMajor
        ? ScaleDegreeSource.major
        : ScaleDegreeSource.naturalMinor;
    return _degreeForRootPcInSource(tonality, rootPc, source);
  }

  static ScaleDegree? _degreeForRootPcInSource(
    Tonality tonality,
    int rootPc,
    ScaleDegreeSource source,
  ) {
    final rel = (rootPc - tonality.tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    switch (source) {
      case ScaleDegreeSource.major:
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
      case ScaleDegreeSource.naturalMinor:
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
      case ScaleDegreeSource.harmonicMinor:
        return switch (interval) {
          0 => ScaleDegree.one,
          2 => ScaleDegree.two,
          3 => ScaleDegree.three,
          5 => ScaleDegree.four,
          7 => ScaleDegree.five,
          8 => ScaleDegree.six,
          11 => ScaleDegree.seven,
          _ => null,
        };
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static const _degreeLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  /// Whether [rootName]'s letter occupies [degree]'s diatonic position in
  /// [tonality]. An enharmonic respelling lands on a different letter (B vs Cb)
  /// and is rejected; an unparsable name is allowed so we never over-reject.
  static bool _rootSpellingMatchesDegree(
    Tonality tonality,
    String rootName,
    ScaleDegree degree,
  ) {
    final letter = _letterOf(rootName);
    if (letter == null) return true;
    return letter == _expectedLetterForDegree(tonality, degree);
  }

  static String? _letterOf(String rootName) {
    final ascii = normalizeNoteNameToAscii(rootName);
    if (ascii.isEmpty) return null;
    final letter = ascii[0].toUpperCase();
    return _degreeLetters.contains(letter) ? letter : null;
  }

  static String _expectedLetterForDegree(
    Tonality tonality,
    ScaleDegree degree,
  ) {
    final tonicIndex = _degreeLetters.indexOf(tonality.tonic.letter);
    final start = tonicIndex < 0 ? 0 : tonicIndex;
    return _degreeLetters[(start + degree.index) % 7];
  }

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
    ScaleDegreeSource source,
  ) {
    for (var i = 0; i < 12; i++) {
      if ((intervalsMask & (1 << i)) == 0) continue;
      final pc = _pcAdd(rootPc, i);
      if (!_containsPitchClass(tonality, pc, source)) return false;
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
    ScaleDegreeSource source,
  ) {
    for (final e in exts) {
      final pc = _pcAdd(rootPc, e.intervalAboveRoot);
      if (!_containsPitchClass(tonality, pc, source)) return false;
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
    ScaleDegreeSource source,
    ScaleDegree d,
  ) {
    switch (source) {
      case ScaleDegreeSource.major:
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
      case ScaleDegreeSource.naturalMinor:
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
      case ScaleDegreeSource.harmonicMinor:
        return switch (d) {
          ScaleDegree.one => const {
            ChordQualityToken.minor,
            ChordQualityToken.minorMajor7,
          },
          ScaleDegree.two => const {
            ChordQualityToken.diminished,
            ChordQualityToken.halfDiminished7,
          },
          ScaleDegree.three => const {
            ChordQualityToken.augmented,
            ChordQualityToken.major7Sharp5,
          },
          ScaleDegree.four => const {
            ChordQualityToken.minor,
            ChordQualityToken.minor7,
          },
          ScaleDegree.five => const {
            ChordQualityToken.major,
            ChordQualityToken.dominant7,
            ChordQualityToken.dominant7Sharp5,
          },
          ScaleDegree.six => const {
            ChordQualityToken.major,
            ChordQualityToken.major7,
          },
          ScaleDegree.seven => const {
            ChordQualityToken.diminished,
            ChordQualityToken.diminished7,
          },
        };
    }
  }

  static List<ScaleDegreeSource> _sourcesForTonality(Tonality tonality) {
    if (tonality.isMajor) return const [ScaleDegreeSource.major];
    return const [
      ScaleDegreeSource.naturalMinor,
      ScaleDegreeSource.harmonicMinor,
    ];
  }

  static bool _containsPitchClass(
    Tonality tonality,
    int pc,
    ScaleDegreeSource source,
  ) {
    final rel = (pc - tonality.tonicPitchClass) % 12;
    final interval = rel < 0 ? rel + 12 : rel;

    return switch (source) {
      ScaleDegreeSource.major => switch (interval) {
        0 || 2 || 4 || 5 || 7 || 9 || 11 => true,
        _ => false,
      },
      ScaleDegreeSource.naturalMinor => switch (interval) {
        0 || 2 || 3 || 5 || 7 || 8 || 10 => true,
        _ => false,
      },
      ScaleDegreeSource.harmonicMinor => switch (interval) {
        0 || 2 || 3 || 5 || 7 || 8 || 11 => true,
        _ => false,
      },
    };
  }

  static String _romanNumeralFor(
    ScaleDegree degree,
    ScaleDegreeSource source,
    ChordQualityToken quality,
  ) {
    final base = degree.romanNumeralForSource(source);
    return romanNumeralForQuality(base, quality);
  }

  static String _spokenScaleDegreeFor(
    ScaleDegree degree,
    ScaleDegreeSource source,
  ) {
    if (source == ScaleDegreeSource.major) {
      return degree.spokenScaleDegreeForMode(TonalityMode.major);
    }
    if (source == ScaleDegreeSource.naturalMinor) {
      return degree.spokenScaleDegreeForMode(TonalityMode.minor);
    }
    return switch (degree) {
      ScaleDegree.one => 'first',
      ScaleDegree.two => 'second, diminished',
      ScaleDegree.three => 'flat third, augmented',
      ScaleDegree.four => 'fourth',
      ScaleDegree.five => 'fifth, major',
      ScaleDegree.six => 'flat sixth',
      ScaleDegree.seven => 'raised seventh, diminished',
    };
  }

  static String _functionNameFor(ScaleDegree degree, ScaleDegreeSource source) {
    if (source == ScaleDegreeSource.major) {
      return degree.functionNameForMode(TonalityMode.major);
    }
    if (source == ScaleDegreeSource.naturalMinor) {
      return degree.functionNameForMode(TonalityMode.minor);
    }
    return switch (degree) {
      ScaleDegree.one => 'tonic',
      ScaleDegree.two => 'supertonic',
      ScaleDegree.three => 'mediant',
      ScaleDegree.four => 'subdominant',
      ScaleDegree.five => 'dominant',
      ScaleDegree.six => 'submediant',
      ScaleDegree.seven => 'leading tone',
    };
  }
}
