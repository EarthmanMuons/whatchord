import 'package:meta/meta.dart';

import '../models/scale.dart';
import '../models/scale_degree.dart';
import '../models/tonality.dart';

/// The role a diatonic scale degree plays, plus where it tends to resolve.
///
/// [name] is the degree's role name (e.g. "dominant"); [tendency] is a short
/// resolution clause (e.g. "pulls toward I") that is only musically honest in
/// major and minor keys, so it is null for the church modes.
@immutable
class ScaleDegreeFunction {
  const ScaleDegreeFunction({required this.name, this.tendency});

  final String name;
  final String? tendency;
}

/// Describes the [ordinal]th degree (1 = tonic) of a heptatonic [scale]: its
/// role name, and a resolution tendency for the major and minor families.
ScaleDegreeFunction scaleDegreeFunction(Scale scale, int ordinal) {
  if (scale.intervals.length != ScaleDegree.values.length) {
    throw UnsupportedError(
      '${scale.kind.label} does not define seven functional scale degrees.',
    );
  }
  RangeError.checkValueInInterval(
    ordinal,
    1,
    ScaleDegree.values.length,
    'ordinal',
  );

  final degree = ScaleDegree.values[ordinal - 1];
  // The leading-tone vs subtonic distinction follows the actual scale, not the
  // family, so harmonic and melodic minor are correctly named "leading tone".
  final isLeadingTone = (12 - scale.intervals[6]) == 1;
  final name = ordinal == 7
      ? (isLeadingTone ? 'leading tone' : 'subtonic')
      : degree.functionNameForMode(TonalityMode.major);

  return ScaleDegreeFunction(
    name: name,
    tendency: _tendency(scale.kind, ordinal, isLeadingTone),
  );
}

String? _tendency(ScaleKind kind, int ordinal, bool isLeadingTone) {
  switch (_family(kind)) {
    case _Family.major:
      return switch (ordinal) {
        1 => 'home base',
        2 => 'leads to V',
        3 => 'passes toward IV or vi',
        4 => 'pulls toward V or I',
        5 => 'pulls toward I',
        6 => 'leads to ii or IV',
        _ => 'resolves to I',
      };
    case _Family.minor:
      // The dominant triad is minor (v) in natural minor and major (V) once a
      // leading tone is present (harmonic minor), so its roman numeral tracks
      // the scale's seventh degree.
      final dominant = isLeadingTone ? 'V' : 'v';
      return switch (ordinal) {
        1 => 'home base',
        2 => 'leads to $dominant',
        // The mediant is the relative major (♭III) in natural minor, but a
        // leading tone makes it an augmented ♭III+ with no conventional
        // resolution, so the tendency is dropped there.
        3 => isLeadingTone ? null : 'leans toward ♭VI',
        4 => 'pulls toward $dominant or i',
        5 => 'pulls toward i',
        6 => 'leads to iv or $dominant',
        _ => isLeadingTone ? 'resolves to i' : 'leads to ♭III',
      };
    case _Family.modal:
      return null;
  }
}

enum _Family { major, minor, modal }

_Family _family(ScaleKind kind) {
  return switch (kind) {
    ScaleKind.major => _Family.major,
    ScaleKind.aeolian || ScaleKind.harmonicMinor => _Family.minor,
    // Ascending melodic minor is a melodic convention rather than a fixed
    // harmonic vocabulary (its IV is major and vi is diminished), so its degrees
    // show the role name without a resolution tendency.
    ScaleKind.melodicMinor ||
    ScaleKind.dorian ||
    ScaleKind.phrygian ||
    ScaleKind.lydian ||
    ScaleKind.mixolydian ||
    ScaleKind.locrian ||
    ScaleKind.majorPentatonic ||
    ScaleKind.minorPentatonic ||
    ScaleKind.majorBlues ||
    ScaleKind.minorBlues ||
    ScaleKind.wholeTone ||
    ScaleKind.augmented ||
    ScaleKind.diminishedWholeHalf ||
    ScaleKind.diminishedHalfWhole => _Family.modal,
  };
}
