import 'package:meta/meta.dart';

import '../models/chord_identity.dart';
import '../models/scale.dart';
import 'chord_quality_intervals.dart';
import 'interval_constants.dart';
import 'note_spelling.dart';
import 'scale_degree_roman_numerals.dart';

/// A scale tone with its pitch, spelling, and formula label.
@immutable
class ScaleTone {
  const ScaleTone({
    required this.ordinal,
    required this.pitchClass,
    required this.name,
    required this.degreeLabel,
  });

  /// 1-based position in the scale's ordered tone list.
  final int ordinal;

  /// Pitch class (0..11).
  final int pitchClass;

  /// Spelled note name (e.g. "Eb").
  final String name;

  /// Formula label relative to the parallel major scale (e.g. "♭3").
  final String degreeLabel;
}

/// The ordered tones of a scale, independent of chord harmonization.
@immutable
class ScaleToneSet {
  const ScaleToneSet({required this.scale, required this.tones});

  /// The scale these tones belong to.
  final Scale scale;

  /// The tones in ascending scale order.
  final List<ScaleTone> tones;

  /// Tone pitch classes, aligned with [tones].
  List<int> get pitchClasses => [for (final tone in tones) tone.pitchClass];

  /// Spelled tone names, aligned with [tones].
  List<String> get toneNames => [for (final tone in tones) tone.name];

  /// Formula labels, aligned with [tones].
  List<String> get degreeLabels => [for (final tone in tones) tone.degreeLabel];
}

/// Builds scale-tone metadata for any supported scale cardinality.
abstract final class ScaleToneBuilder {
  /// Spells and labels the tones of [scale].
  static ScaleToneSet build(Scale scale) {
    final pcs = scale.pitchClasses;
    final names = spellScaleTones(
      pitchClasses: pcs,
      tonicLetter: scale.tonic.letter,
      letterOffsets: scale.kind.spellingLetterOffsets,
    );

    return ScaleToneSet(
      scale: scale,
      tones: [
        for (var i = 0; i < pcs.length; i++)
          ScaleTone(
            ordinal: i + 1,
            pitchClass: pcs[i],
            name: names[i],
            degreeLabel: scale.kind.degreeLabels[i],
          ),
      ],
    );
  }
}

/// The diatonic triad and seventh chord built on one scale degree.
@immutable
class ScaleDegreeHarmony {
  const ScaleDegreeHarmony({
    required this.ordinal,
    required this.rootPc,
    required this.rootName,
    required this.degreeLabel,
    required this.triadQuality,
    required this.seventhQuality,
    required this.triadRoman,
    required this.seventhRoman,
  });

  /// 1-based scale degree (1 = tonic).
  final int ordinal;

  /// Pitch class of the degree's root (0..11).
  final int rootPc;

  /// Spelled root name (e.g. "Eb").
  final String rootName;

  /// Scale-degree formula relative to the major scale, e.g. "1", "♭3", "♯4".
  final String degreeLabel;

  /// Quality of the stacked triad on this degree.
  final ChordQuality triadQuality;

  /// Quality of the stacked seventh chord on this degree.
  final ChordQuality seventhQuality;

  /// Triad roman numeral, e.g. "ii°", "♭III", "♯iv°".
  final String triadRoman;

  /// Seventh-chord roman numeral, e.g. "iiø7", "V7", "Imaj7".
  final String seventhRoman;
}

/// The fully harmonized scale: tones plus per-degree diatonic chords.
@immutable
class ScaleHarmony {
  const ScaleHarmony({required this.tones, required this.degrees});

  /// The spelled scale tones.
  final ScaleToneSet tones;

  /// Per-degree diatonic chords, in scale order.
  final List<ScaleDegreeHarmony> degrees;

  /// The harmonized scale.
  Scale get scale => tones.scale;

  /// Shorthand for `tones.pitchClasses`.
  List<int> get pitchClasses => tones.pitchClasses;

  /// Shorthand for `tones.toneNames`.
  List<String> get toneNames => tones.toneNames;
}

/// Harmonizes a [Scale] by stacking thirds within the scale for each degree.
///
/// Qualities are identified by matching the stacked interval set against the
/// canonical chord-quality sets; roman numerals are computed from each degree's
/// deviation against the parallel major rather than from a per-scale table.
abstract final class ScaleHarmonizer {
  static final Map<int, ChordQuality> _qualityByMask = {
    for (final set in chordQualityIntervalSets) set.canonicalMask: set.quality,
  };

  // Major-scale intervals, used as the reference for roman-numeral accidentals.
  static const List<int> _majorReference = [0, 2, 4, 5, 7, 9, 11];
  static const List<String> _upperNumerals = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
  ];
  static const List<String> _lowerNumerals = [
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
  ];

  /// Harmonizes [scale]; throws [UnsupportedError] for scale kinds without a
  /// tertian chord stack (see `ScaleKind.supportsChordHarmony`).
  static ScaleHarmony harmonize(Scale scale) {
    if (!scale.kind.supportsChordHarmony) {
      throw UnsupportedError(
        '${scale.kind.label} does not define a diatonic tertian chord stack.',
      );
    }

    final intervals = scale.intervals;
    final n = intervals.length;
    final tones = ScaleToneBuilder.build(scale);

    final degrees = <ScaleDegreeHarmony>[];
    for (var i = 0; i < n; i++) {
      final rootInterval = intervals[i];
      final thirdRel = _relInterval(intervals[(i + 2) % n], rootInterval);
      final fifthRel = _relInterval(intervals[(i + 4) % n], rootInterval);
      final seventhRel = _relInterval(intervals[(i + 6) % n], rootInterval);

      final triadMask = chordRootBit | (1 << thirdRel) | (1 << fifthRel);
      final seventhMask = triadMask | (1 << seventhRel);

      final triadQuality = _qualityForMask(triadMask, scale, i);
      final seventhQuality = _qualityForMask(seventhMask, scale, i);

      final triadRoman = _triadRoman(i, rootInterval, thirdRel, triadQuality);

      degrees.add(
        ScaleDegreeHarmony(
          ordinal: i + 1,
          rootPc: tones.pitchClasses[i],
          rootName: tones.toneNames[i],
          degreeLabel: tones.degreeLabels[i],
          triadQuality: triadQuality,
          seventhQuality: seventhQuality,
          triadRoman: triadRoman,
          seventhRoman: romanNumeralForQuality(triadRoman, seventhQuality),
        ),
      );
    }

    return ScaleHarmony(tones: tones, degrees: degrees);
  }

  static int _relInterval(int interval, int rootInterval) {
    final rel = (interval - rootInterval) % 12;
    return rel < 0 ? rel + 12 : rel;
  }

  static ChordQuality _qualityForMask(int mask, Scale scale, int index) {
    final quality = _qualityByMask[mask];
    if (quality == null) {
      throw StateError(
        'No chord quality matches the tertian stack on degree ${index + 1} '
        'of $scale (interval mask $mask).',
      );
    }
    return quality;
  }

  /// Accidental of a scale degree relative to the parallel major scale.
  static String _accidentalPrefix(int index, int rootInterval) {
    final delta = rootInterval - _majorReference[index];
    return delta <= -2
        ? '♭♭'
        : delta == -1
        ? '♭'
        : delta == 0
        ? ''
        : delta == 1
        ? '♯'
        : '×';
  }

  static String _triadRoman(
    int index,
    int rootInterval,
    int thirdRel,
    ChordQuality triad,
  ) {
    final prefix = _accidentalPrefix(index, rootInterval);

    final upper = thirdRel == majorThirdInterval;
    final base = (upper ? _upperNumerals : _lowerNumerals)[index];

    final decoration = switch (triad) {
      ChordQuality.diminished => '°',
      ChordQuality.augmented => '+',
      _ => '',
    };

    return '$prefix$base$decoration';
  }
}
