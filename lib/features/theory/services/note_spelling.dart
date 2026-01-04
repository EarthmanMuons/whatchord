import '../models/note_spelling_policy.dart';

String pcToName(int pc, {required NoteSpellingPolicy policy}) {
  final i = pc % 12;

  if (policy.preferFlats) {
    const flats = [
      'C',
      'Db',
      'D',
      'Eb',
      'E',
      'F',
      'Gb',
      'G',
      'Ab',
      'A',
      'Bb',
      'B',
    ];
    return flats[i];
  } else {
    const sharps = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    return sharps[i];
  }
}
