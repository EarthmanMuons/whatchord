import '../models/scale.dart';
import '../models/tonic.dart';
import 'note_spelling.dart';

/// The tonic spellings worth offering as scale roots for [kind].
///
/// The set depends on the kind's [ScaleKind.tonicPolicy]:
///
/// - [TonicPolicy.conventionalKeys] keeps only roots whose scale spells with
///   single accidentals. For the diatonic modes this is exactly the 15 standard
///   key signatures, so the three boundary pitch classes carry both enharmonic
///   spellings (e.g. Gb and F#); nonsense roots like D# major, whose scales need
///   double accidentals, are excluded. Harmonic and melodic minor have no
///   traditional key signature but follow the same single-accidental rule.
/// - [TonicPolicy.parentMajorKeys] / [TonicPolicy.parentMinorKeys] borrow the
///   conventional roots of the parent major or natural-minor scale, so a
///   pentatonic or blues scale shares its parent key's root vocabulary.
/// - [TonicPolicy.allSpellings] offers every spelled root, for symmetric scales
///   that have no key signature to constrain them.
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
    // Same pitch class (an enharmonic pair): natural, then sharp, then flat, so
    // a raised note sits next to the natural it came from (C, C#, Db, D).
    return a.accidentalRank.compareTo(b.accidentalRank);
  });
  return ordered;
}

bool _hasDoubleAccidental(String name) =>
    name.contains('x') || name.contains('bb');
