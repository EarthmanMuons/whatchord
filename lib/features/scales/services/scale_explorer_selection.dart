import 'package:whatchord/features/theory/theory.dart';

import 'scale_voicing.dart';

Set<int> selectedDegreeChordMidi({
  required Scale scale,
  required ScaleHarmony? harmony,
  required int? selectedOrdinal,
  required bool showSevenths,
}) {
  if (selectedOrdinal == null || harmony == null) return const <int>{};

  final degree = harmony.degrees[selectedOrdinal - 1];
  return degreeChordMidi(scale, degree, seventh: showSevenths).toSet();
}

String? selectedScaleDegreeFunctionLabel({
  required Scale scale,
  required int? selectedOrdinal,
  required bool supportsChordHarmony,
}) {
  if (selectedOrdinal == null || !supportsChordHarmony) return null;

  final function = scaleDegreeFunction(scale, selectedOrdinal);
  final tendency = function.tendency;
  final text = tendency == null ? function.name : '${function.name}, $tendency';
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

Tonic resolveScaleExplorerTonic({
  required List<Tonic> choices,
  required int pitchClass,
  Tonic? exact,
  required bool preferFlat,
}) {
  if (exact != null && choices.contains(exact)) return exact;

  final matches = choices
      .where((tonic) => tonic.pitchClass == pitchClass)
      .toList();
  if (matches.isEmpty) return choices.first;

  for (final tonic in matches) {
    if (preferFlat ? tonic.isFlat : tonic.isSharp) return tonic;
  }
  return matches.first;
}

bool keepsSelectedOrdinalForScaleChange({
  required ScaleKind current,
  required ScaleKind next,
}) {
  if (next.intervals.length != current.intervals.length) return false;
  return next.supportsChordHarmony;
}
