import 'package:meta/meta.dart';

import 'tonic.dart';

enum ScaleKind {
  major(
    'Major',
    [0, 2, 4, 5, 7, 9, 11],
    degreeLabels: ['1', '2', '3', '4', '5', '6', '7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  dorian(
    'Dorian',
    [0, 2, 3, 5, 7, 9, 10],
    degreeLabels: ['1', '2', '♭3', '4', '5', '6', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  phrygian(
    'Phrygian',
    [0, 1, 3, 5, 7, 8, 10],
    degreeLabels: ['1', '♭2', '♭3', '4', '5', '♭6', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  lydian(
    'Lydian',
    [0, 2, 4, 6, 7, 9, 11],
    degreeLabels: ['1', '2', '3', '♯4', '5', '6', '7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  mixolydian(
    'Mixolydian',
    [0, 2, 4, 5, 7, 9, 10],
    degreeLabels: ['1', '2', '3', '4', '5', '6', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  aeolian(
    'Natural minor',
    [0, 2, 3, 5, 7, 8, 10],
    degreeLabels: ['1', '2', '♭3', '4', '5', '♭6', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  locrian(
    'Locrian',
    [0, 1, 3, 5, 6, 8, 10],
    degreeLabels: ['1', '♭2', '♭3', '4', '♭5', '♭6', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  harmonicMinor(
    'Harmonic minor',
    [0, 2, 3, 5, 7, 8, 11],
    degreeLabels: ['1', '2', '♭3', '4', '5', '♭6', '7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  melodicMinor(
    'Melodic minor',
    [0, 2, 3, 5, 7, 9, 11],
    degreeLabels: ['1', '2', '♭3', '4', '5', '6', '7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 5, 6],
    harmonization: ScaleHarmonization.heptatonicTertian,
  ),
  majorPentatonic(
    'Major pentatonic',
    [0, 2, 4, 7, 9],
    degreeLabels: ['1', '2', '3', '5', '6'],
    spellingLetterOffsets: [0, 1, 2, 4, 5],
  ),
  minorPentatonic(
    'Minor pentatonic',
    [0, 3, 5, 7, 10],
    degreeLabels: ['1', '♭3', '4', '5', '♭7'],
    spellingLetterOffsets: [0, 2, 3, 4, 6],
  ),
  majorBlues(
    'Major blues',
    [0, 2, 3, 4, 7, 9],
    degreeLabels: ['1', '2', '♭3', '3', '5', '6'],
    spellingLetterOffsets: [0, 1, 2, 2, 4, 5],
  ),
  minorBlues(
    'Minor blues',
    [0, 3, 5, 6, 7, 10],
    degreeLabels: ['1', '♭3', '4', '♭5', '5', '♭7'],
    spellingLetterOffsets: [0, 2, 3, 4, 4, 6],
  ),
  wholeTone(
    'Whole tone',
    [0, 2, 4, 6, 8, 10],
    degreeLabels: ['1', '2', '3', '♯4', '♯5', '♭7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 6],
  ),
  augmented(
    'Augmented',
    [0, 3, 4, 7, 8, 11],
    degreeLabels: ['1', '♭3', '3', '5', '♯5', '7'],
    spellingLetterOffsets: [0, 2, 2, 4, 4, 6],
  ),
  diminishedWholeHalf(
    'Diminished whole-half',
    [0, 2, 3, 5, 6, 8, 9, 11],
    degreeLabels: ['1', '2', '♭3', '4', '♭5', '♯5', '6', '7'],
    spellingLetterOffsets: [0, 1, 2, 3, 4, 4, 5, 6],
  ),
  diminishedHalfWhole(
    'Diminished half-whole',
    [0, 1, 3, 4, 6, 7, 9, 10],
    degreeLabels: ['1', '♭2', '♯2', '3', '♯4', '5', '6', '♭7'],
    spellingLetterOffsets: [0, 1, 1, 2, 3, 4, 5, 6],
  );

  const ScaleKind(
    this.label,
    this.intervals, {
    required this.degreeLabels,
    required this.spellingLetterOffsets,
    this.harmonization = ScaleHarmonization.none,
  });

  /// Conventional name used when describing a built scale (e.g. "C major").
  /// The Scale Explorer menu supplies its own per-section labels, so a single
  /// kind can surface under more than one name (Major vs. Ionian).
  final String label;

  /// Ascending semitone offsets from the root (root = 0).
  final List<int> intervals;

  /// Scale-tone formula labels relative to the parallel major scale.
  final List<String> degreeLabels;

  /// Letter positions above the tonic used to spell each tone.
  ///
  /// Heptatonic scales walk one letter per tone. Other scales intentionally
  /// skip or repeat letter positions so the spelling matches musician
  /// expectations, e.g. C major pentatonic is C-D-E-G-A, C minor blues is
  /// C-Eb-F-Gb-G-Bb, and C half-whole diminished is C-Db-D#-E-F#-G-A-Bb.
  final List<int> spellingLetterOffsets;

  /// The chord-stack strategy that is musically meaningful for this scale.
  final ScaleHarmonization harmonization;

  bool get supportsChordHarmony =>
      harmonization == ScaleHarmonization.heptatonicTertian;
}

enum ScaleHarmonization { none, heptatonicTertian }

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
