import '../models/scale.dart';
import '../models/tonic.dart';
import 'note_spelling.dart';

/// The tonic spellings worth offering as scale roots for [kind].
///
/// A tonic is offered only when its scale spells with single accidentals
/// (no double sharps or flats). For the diatonic modes this is exactly the 15
/// standard key signatures, so the three boundary pitch classes carry both
/// enharmonic spellings (e.g. Gb and F#); nonsense roots like D# major, whose
/// scales need double accidentals, are excluded. Harmonic and melodic minor
/// have no traditional key signature but follow the same single-accidental rule.
///
/// Ordered chromatically by pitch class; within a shared pitch class the
/// raised (sharp) spelling precedes the flat one, so a pair reads C, C#, Db, D.
List<Tonic> tonicChoicesForKind(ScaleKind kind) {
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

  choices.sort((a, b) {
    final byPitchClass = a.pitchClass.compareTo(b.pitchClass);
    if (byPitchClass != 0) return byPitchClass;
    // Same pitch class (an enharmonic pair): show the sharp spelling first, so
    // the raised note sits next to the natural it came from (C, C#, Db, D).
    return (a.isFlat ? 1 : 0).compareTo(b.isFlat ? 1 : 0);
  });

  return choices;
}

bool _hasDoubleAccidental(String name) =>
    name.contains('x') || name.contains('bb');
