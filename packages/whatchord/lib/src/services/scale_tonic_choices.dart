import '../models/scale.dart';
import '../models/tonic.dart';
import 'note_spelling.dart';

/// The tonic spellings worth offering as scale roots for [kind], selected by its
/// [ScaleKind.tonicPolicy].
///
/// Ordered chromatically by pitch class; within a shared pitch class the natural
/// comes first, then the sharp, then the flat, so a cluster reads C, C#, Db.
List<Tonic> tonicChoicesForKind(ScaleKind kind) {
  final tonics = switch (kind.tonicPolicy) {
    TonicPolicy.conventionalKeys => _singleAccidentalTonics(kind),
    TonicPolicy.parentMajorKeys => _singleAccidentalTonics(ScaleKind.major),
    TonicPolicy.parentMinorKeys => _singleAccidentalTonics(ScaleKind.aeolian),
    TonicPolicy.allSpellings => Tonic.values.toList(),
  };
  return _chromaticallyOrdered(tonics);
}

/// Tonics whose [kind] scale spells without any double accidentals.
List<Tonic> _singleAccidentalTonics(ScaleKind kind) {
  final choices = <Tonic>[];
  for (final tonic in Tonic.values) {
    final scale = Scale(tonic, kind);
    final names = spellScaleTones(
      pitchClasses: scale.pitchClasses,
      tonicLetter: tonic.letter,
      letterOffsets: kind.spellingLetterOffsets,
    );
    if (names.any(_hasDoubleAccidental)) continue;
    choices.add(tonic);
  }
  return choices;
}

List<Tonic> _chromaticallyOrdered(List<Tonic> tonics) {
  final ordered = [...tonics];
  ordered.sort((a, b) {
    final byPitchClass = a.pitchClass.compareTo(b.pitchClass);
    if (byPitchClass != 0) return byPitchClass;
    return a.accidentalRank.compareTo(b.accidentalRank); // natural, sharp, flat
  });
  return ordered;
}

bool _hasDoubleAccidental(String name) =>
    name.contains('x') || name.contains('bb');
