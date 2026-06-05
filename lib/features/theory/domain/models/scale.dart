import 'package:meta/meta.dart';

import 'tonic.dart';

enum ScaleKind {
  major('Major', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(11, '7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  dorian('Dorian', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  phrygian('Phrygian', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(1, '♭2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(8, '♭6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  lydian('Lydian', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(6, '♯4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(11, '7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  mixolydian('Mixolydian', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  aeolian('Natural minor', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(8, '♭6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  locrian('Locrian', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(1, '♭2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(6, '♭5', 4),
    ScaleToneSpec(8, '♭6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  harmonicMinor('Harmonic minor', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(8, '♭6', 5),
    ScaleToneSpec(11, '7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  melodicMinor('Melodic minor', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(11, '7', 6),
  ], harmonization: ScaleHarmonization.heptatonicTertian),
  majorPentatonic('Major pentatonic', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
  ], tonicPolicy: TonicPolicy.parentMajorKeys),
  minorPentatonic('Minor pentatonic', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(10, '♭7', 6),
  ], tonicPolicy: TonicPolicy.parentMinorKeys),
  majorBlues('Major blues', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
  ], tonicPolicy: TonicPolicy.parentMajorKeys),
  minorBlues('Minor blues', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(6, '♭5', 4),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(10, '♭7', 6),
  ], tonicPolicy: TonicPolicy.parentMinorKeys),
  wholeTone('Whole tone', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(6, '♯4', 3),
    ScaleToneSpec(8, '♯5', 4),
    ScaleToneSpec(10, '♭7', 6),
  ], tonicPolicy: TonicPolicy.allSpellings),
  augmented('Augmented', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(8, '♯5', 4),
    ScaleToneSpec(11, '7', 6),
  ], tonicPolicy: TonicPolicy.allSpellings),
  diminishedWholeHalf('Diminished whole-half', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(2, '2', 1),
    ScaleToneSpec(3, '♭3', 2),
    ScaleToneSpec(5, '4', 3),
    ScaleToneSpec(6, '♭5', 4),
    ScaleToneSpec(8, '♯5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(11, '7', 6),
  ], tonicPolicy: TonicPolicy.allSpellings),
  diminishedHalfWhole('Diminished half-whole', [
    ScaleToneSpec(0, '1', 0),
    ScaleToneSpec(1, '♭2', 1),
    ScaleToneSpec(3, '♯2', 1),
    ScaleToneSpec(4, '3', 2),
    ScaleToneSpec(6, '♯4', 3),
    ScaleToneSpec(7, '5', 4),
    ScaleToneSpec(9, '6', 5),
    ScaleToneSpec(10, '♭7', 6),
  ], tonicPolicy: TonicPolicy.allSpellings);

  const ScaleKind(
    this.label,
    this.toneSpecs, {
    this.harmonization = ScaleHarmonization.none,
    this.tonicPolicy = TonicPolicy.conventionalKeys,
  });

  /// Conventional name used when describing a built scale (e.g. "C major").
  /// The Scale Explorer menu supplies its own per-section labels, so a single
  /// kind can surface under more than one name (Major vs. Ionian).
  final String label;

  /// Ordered scale tones from the root upward.
  final List<ScaleToneSpec> toneSpecs;

  /// Ascending semitone offsets from the root (root = 0).
  List<int> get intervals => [
    for (final toneSpec in toneSpecs) toneSpec.interval,
  ];

  /// Scale-tone formula labels relative to the parallel major scale.
  List<String> get degreeLabels => [
    for (final toneSpec in toneSpecs) toneSpec.degreeLabel,
  ];

  /// Letter positions above the tonic used to spell each tone.
  ///
  /// Heptatonic scales walk one letter per tone. Other scales intentionally
  /// skip or repeat letter positions so the spelling matches musician
  /// expectations, e.g. C major pentatonic is C-D-E-G-A, C minor blues is
  /// C-Eb-F-Gb-G-Bb, and C half-whole diminished is C-Db-D#-E-F#-G-A-Bb.
  List<int> get spellingLetterOffsets => [
    for (final toneSpec in toneSpecs) toneSpec.spellingLetterOffset,
  ];

  /// The chord-stack strategy that is musically meaningful for this scale.
  final ScaleHarmonization harmonization;

  bool get supportsChordHarmony =>
      harmonization == ScaleHarmonization.heptatonicTertian;

  /// How the Scale Explorer decides which spelled roots to offer for this kind.
  final TonicPolicy tonicPolicy;
}

enum ScaleHarmonization { none, heptatonicTertian }

/// How a scale kind chooses the spelled tonics to offer as roots.
enum TonicPolicy {
  /// Offer only roots whose scale spells with single accidentals. For the
  /// heptatonic modes this reproduces the conventional key-signature roots
  /// (the spellings one would see on a circle of fifths).
  conventionalKeys,

  /// Borrow the major scale's conventional roots. Pentatonic and blues scales
  /// are heard as the vernacular subset of a parent key, so they share its
  /// practical root vocabulary rather than admitting the extra enharmonic
  /// spellings their sparser interval set would otherwise allow.
  parentMajorKeys,

  /// Borrow the natural-minor scale's conventional roots.
  parentMinorKeys,

  /// Offer every spelled root. Transpositionally symmetric scales have no key
  /// signature to constrain them, so the root is purely a spelling choice and
  /// double accidentals are accepted as the honest consequence.
  allSpellings,
}

@immutable
class ScaleToneSpec {
  const ScaleToneSpec(
    this.interval,
    this.degreeLabel,
    this.spellingLetterOffset,
  );

  final int interval;
  final String degreeLabel;
  final int spellingLetterOffset;
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
