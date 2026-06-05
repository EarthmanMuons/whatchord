import 'package:meta/meta.dart';

import '../models/chord_identity.dart';
import '../models/scale.dart';
import 'chord_quality_intervals.dart';
import 'note_spelling.dart';

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
  final int pitchClass;
  final String name;
  final String degreeLabel;
}

/// The ordered tones of a scale, independent of chord harmonization.
@immutable
class ScaleToneSet {
  const ScaleToneSet({required this.scale, required this.tones});

  final Scale scale;
  final List<ScaleTone> tones;

  List<int> get pitchClasses => [for (final tone in tones) tone.pitchClass];

  List<String> get toneNames => [for (final tone in tones) tone.name];

  List<String> get degreeLabels => [for (final tone in tones) tone.degreeLabel];
}

/// Builds scale-tone metadata for any supported scale cardinality.
abstract final class ScaleToneBuilder {
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

  final int rootPc;
  final String rootName;

  /// Scale-degree formula relative to the major scale, e.g. "1", "♭3", "♯4".
  final String degreeLabel;

  final ChordQualityToken triadQuality;
  final ChordQualityToken seventhQuality;

  /// Triad roman numeral, e.g. "ii°", "♭III", "♯iv°".
  final String triadRoman;

  /// Seventh-chord roman numeral, e.g. "iiø7", "V7", "Imaj7".
  final String seventhRoman;
}

/// The fully harmonized scale: tones plus per-degree diatonic chords.
@immutable
class ScaleHarmony {
  const ScaleHarmony({required this.tones, required this.degrees});

  final ScaleToneSet tones;
  final List<ScaleDegreeHarmony> degrees;

  Scale get scale => tones.scale;
  List<int> get pitchClasses => tones.pitchClasses;
  List<String> get toneNames => tones.toneNames;
}

/// Harmonizes a [Scale] by stacking thirds within the scale for each degree.
///
/// Qualities are identified by matching the stacked interval set against the
/// canonical chord-quality sets; roman numerals are computed from each degree's
/// deviation against the parallel major rather than from a per-scale table.
abstract final class ScaleHarmonizer {
  static final Map<int, ChordQualityToken> _qualityByMask = {
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

  static ScaleHarmony harmonize(Scale scale) {
    if (scale.kind.harmonization != ScaleHarmonization.heptatonicTertian) {
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
          seventhRoman: _seventhRoman(triadRoman, seventhQuality),
        ),
      );
    }

    return ScaleHarmony(tones: tones, degrees: degrees);
  }

  static int _relInterval(int interval, int rootInterval) {
    final rel = (interval - rootInterval) % 12;
    return rel < 0 ? rel + 12 : rel;
  }

  static ChordQualityToken _qualityForMask(int mask, Scale scale, int index) {
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
    ChordQualityToken triad,
  ) {
    final prefix = _accidentalPrefix(index, rootInterval);

    final upper = thirdRel == majorThirdInterval;
    final base = (upper ? _upperNumerals : _lowerNumerals)[index];

    final decoration = switch (triad) {
      ChordQualityToken.diminished => '°',
      ChordQualityToken.augmented => '+',
      _ => '',
    };

    return '$prefix$base$decoration';
  }

  static String _seventhRoman(String triadRoman, ChordQualityToken seventh) {
    return switch (seventh) {
      ChordQualityToken.dominant7 => '${triadRoman}7',
      ChordQualityToken.dominant7Flat5 => '${triadRoman}7b5',
      ChordQualityToken.dominant7Sharp5 => '${triadRoman}7#5',
      ChordQualityToken.major7 => '${triadRoman}maj7',
      ChordQualityToken.major7Flat5 => '${triadRoman}maj7b5',
      ChordQualityToken.major7Sharp5 => '${triadRoman}maj7#5',
      ChordQualityToken.minor7 => '${triadRoman}7',
      ChordQualityToken.minor7Sharp5 => '${triadRoman}7#5',
      ChordQualityToken.minorMajor7 => '$triadRoman(maj7)',
      ChordQualityToken.halfDiminished7 =>
        '${_stripDegreeSymbol(triadRoman)}ø7',
      ChordQualityToken.diminished7 => '${triadRoman}7',
      _ => triadRoman,
    };
  }

  static String _stripDegreeSymbol(String roman) {
    return roman.endsWith('°') ? roman.substring(0, roman.length - 1) : roman;
  }
}
