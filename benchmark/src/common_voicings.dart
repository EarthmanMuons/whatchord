// A curated pool of common chord voicings: the common chord qualities, each
// with every chord tone taken as the bass (root position plus inversions). The
// complement to the reviewed-oracle corpus: that set is deliberately adversarial
// edge cases, this approximates the structures of real playing.
//
// Only one root (C) per quality is included on purpose. Analysis is
// transposition-invariant when the key moves with the chord (see
// theory_transposition_property_test), so the same quality on a different root
// is structurally identical and would only inflate the pool. (At a fixed key the
// root does affect diatonic tie-breakers, but that is a key-interaction axis,
// not common-chord performance, and belongs in a deliberately-keyed probe or the
// oracle corpus.) Inversions are kept because the bass is a real structural
// variable, not a transposition.
//
// It is a fixture, not generated, so the set is stable and the numbers stay
// comparable. Keep the qualities list to genuinely common chords; add rare or
// synthetic shapes to the oracle corpus instead.

import 'package:whatchord/features/theory/domain/theory_domain.dart';

/// Common chord qualities as semitone intervals above the root.
const Map<String, List<int>> commonChordQualities = {
  'maj': [0, 4, 7],
  'min': [0, 3, 7],
  'dim': [0, 3, 6],
  'aug': [0, 4, 8],
  'sus4': [0, 5, 7],
  'sus2': [0, 2, 7],
  '6': [0, 4, 7, 9],
  'm6': [0, 3, 7, 9],
  '7': [0, 4, 7, 10],
  'maj7': [0, 4, 7, 11],
  'm7': [0, 3, 7, 10],
  'm7b5': [0, 3, 6, 10],
  'dim7': [0, 3, 6, 9],
  'mMaj7': [0, 3, 7, 11],
  '9': [0, 4, 7, 10, 2],
  'maj9': [0, 4, 7, 11, 2],
  'm9': [0, 3, 7, 10, 2],
  'add9': [0, 4, 7, 2],
  '11': [0, 4, 7, 10, 2, 5],
  '13': [0, 4, 7, 10, 2, 9],
};

const List<String> _noteNames = [
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

/// A single common voicing: a human-readable [label] and the analyzer [input].
class CommonVoicing {
  const CommonVoicing(this.label, this.input);

  final String label;
  final ChordInput input;
}

/// Builds the common-voicing pool: each quality in [commonChordQualities] rooted
/// on C, with every chord tone taken as the bass (root position plus
/// inversions). One root per quality by design; see the file comment.
List<CommonVoicing> commonVoicings() {
  const root = 0; // C; analysis is root-invariant, so one root suffices.
  final out = <CommonVoicing>[];
  for (final entry in commonChordQualities.entries) {
    final pcs = [for (final i in entry.value) (root + i) % 12];
    var mask = 0;
    for (final pc in pcs) {
      mask |= 1 << pc;
    }
    for (final bass in pcs) {
      final label = bass == root
          ? '${_noteNames[root]}${entry.key}'
          : '${_noteNames[root]}${entry.key}/${_noteNames[bass]}';
      out.add(
        CommonVoicing(
          label,
          ChordInput(pcMask: mask, bassPc: bass, noteCount: pcs.length),
        ),
      );
    }
  }
  return out;
}
