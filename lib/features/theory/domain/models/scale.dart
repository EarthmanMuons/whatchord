import 'package:meta/meta.dart';

import 'tonic.dart';

enum ScaleKind {
  major('Major', [0, 2, 4, 5, 7, 9, 11]),
  dorian('Dorian', [0, 2, 3, 5, 7, 9, 10]),
  phrygian('Phrygian', [0, 1, 3, 5, 7, 8, 10]),
  lydian('Lydian', [0, 2, 4, 6, 7, 9, 11]),
  mixolydian('Mixolydian', [0, 2, 4, 5, 7, 9, 10]),
  aeolian('Natural minor', [0, 2, 3, 5, 7, 8, 10]),
  locrian('Locrian', [0, 1, 3, 5, 6, 8, 10]),
  harmonicMinor('Harmonic minor', [0, 2, 3, 5, 7, 8, 11]),
  melodicMinor('Melodic minor', [0, 2, 3, 5, 7, 9, 11]);

  const ScaleKind(this.label, this.intervals);

  /// Conventional name used when describing a built scale (e.g. "C major").
  /// The Scale Explorer menu supplies its own per-section labels, so a single
  /// kind can surface under more than one name (Major vs. Ionian).
  final String label;

  /// Ascending semitone offsets from the root (root = 0).
  final List<int> intervals;
}

@immutable
class Scale {
  final Tonic tonic;
  final ScaleKind kind;

  const Scale(this.tonic, this.kind);

  List<int> get intervals => kind.intervals;

  int get tonicPitchClass => tonic.pitchClass;

  /// Scale-tone pitch classes (0..11) in ascending scale order from the tonic.
  List<int> get pitchClasses => [
    for (final interval in intervals) (tonic.pitchClass + interval) % 12,
  ];

  bool containsPitchClass(int pc) {
    final norm = ((pc % 12) + 12) % 12;
    return pitchClasses.contains(norm);
  }

  String get displayName => '${tonic.label} ${kind.label.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scale && other.tonic == tonic && other.kind == kind;

  @override
  int get hashCode => Object.hash(tonic, kind);

  @override
  String toString() => displayName;
}
