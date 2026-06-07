import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

/// A grouping of scales in the Scale Explorer menu. Each section presents one
/// lens on the catalog: [essential] lists the practical names a musician
/// reaches for, while [diatonicModes] lists the seven rotations of the major
/// scale as a clean family. The major scale and natural minor therefore appear
/// in both sections (as Major/Natural minor and Ionian/Aeolian) since they
/// answer different questions about the same sound.
enum ScaleSection {
  essential('Essential scales', properNounNames: false),
  diatonicModes('Diatonic modes', properNounNames: true),
  pentatonicAndBlues('Pentatonic and blues', properNounNames: false),
  dominantAndAltered('Dominant and altered', properNounNames: false),
  harmonicMajor('Harmonic major scales', properNounNames: false),
  symmetric('Symmetric scales', properNounNames: false);

  const ScaleSection(this.title, {required this.properNounNames});

  final String title;

  /// Whether this section's scales are named after proper nouns. The modes are
  /// (Dorian, Phrygian, ...), so they stay capitalized when written after a
  /// tonic ("C Dorian"), unlike the descriptive major/minor qualities, which
  /// are conventionally lowercased ("C major").
  final bool properNounNames;
}

/// A selectable row in the Scale Explorer menu. The menu owns its own display
/// labels and ordering so a single [ScaleKind] can surface under more than one
/// name; [kind] is the underlying scale the row builds.
@immutable
class ScaleMenuEntry {
  const ScaleMenuEntry({
    required this.label,
    required this.section,
    required this.kind,
  });

  final String label;
  final ScaleSection section;
  final ScaleKind kind;

  /// The label as it reads after a tonic in a heading: mode names keep their
  /// capital ("Dorian"), while the major/minor qualities are lowercased
  /// ("major", "natural minor").
  String get headerLabel =>
      section.properNounNames ? label : label.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleMenuEntry &&
          other.label == label &&
          other.section == section &&
          other.kind == kind;

  @override
  int get hashCode => Object.hash(label, section, kind);
}

/// The Scale Explorer catalog, in display order.
const List<ScaleMenuEntry> scaleMenuEntries = [
  ScaleMenuEntry(
    label: 'Major',
    section: ScaleSection.essential,
    kind: ScaleKind.major,
  ),
  ScaleMenuEntry(
    label: 'Natural minor',
    section: ScaleSection.essential,
    kind: ScaleKind.aeolian,
  ),
  ScaleMenuEntry(
    label: 'Harmonic minor',
    section: ScaleSection.essential,
    kind: ScaleKind.harmonicMinor,
  ),
  ScaleMenuEntry(
    label: 'Jazz melodic minor',
    section: ScaleSection.essential,
    kind: ScaleKind.melodicMinor,
  ),
  ScaleMenuEntry(
    label: 'Ionian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.major,
  ),
  ScaleMenuEntry(
    label: 'Dorian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.dorian,
  ),
  ScaleMenuEntry(
    label: 'Phrygian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.phrygian,
  ),
  ScaleMenuEntry(
    label: 'Lydian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.lydian,
  ),
  ScaleMenuEntry(
    label: 'Mixolydian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.mixolydian,
  ),
  ScaleMenuEntry(
    label: 'Aeolian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.aeolian,
  ),
  ScaleMenuEntry(
    label: 'Locrian',
    section: ScaleSection.diatonicModes,
    kind: ScaleKind.locrian,
  ),
  ScaleMenuEntry(
    label: 'Phrygian dominant',
    section: ScaleSection.dominantAndAltered,
    kind: ScaleKind.phrygianDominant,
  ),
  ScaleMenuEntry(
    label: 'Lydian dominant',
    section: ScaleSection.dominantAndAltered,
    kind: ScaleKind.lydianDominant,
  ),
  ScaleMenuEntry(
    label: 'Altered',
    section: ScaleSection.dominantAndAltered,
    kind: ScaleKind.altered,
  ),
  ScaleMenuEntry(
    label: 'Harmonic major',
    section: ScaleSection.harmonicMajor,
    kind: ScaleKind.harmonicMajor,
  ),
  ScaleMenuEntry(
    label: 'Double harmonic major',
    section: ScaleSection.harmonicMajor,
    kind: ScaleKind.doubleHarmonicMajor,
  ),
  ScaleMenuEntry(
    label: 'Major pentatonic',
    section: ScaleSection.pentatonicAndBlues,
    kind: ScaleKind.majorPentatonic,
  ),
  ScaleMenuEntry(
    label: 'Minor pentatonic',
    section: ScaleSection.pentatonicAndBlues,
    kind: ScaleKind.minorPentatonic,
  ),
  ScaleMenuEntry(
    label: 'Major blues',
    section: ScaleSection.pentatonicAndBlues,
    kind: ScaleKind.majorBlues,
  ),
  ScaleMenuEntry(
    label: 'Minor blues',
    section: ScaleSection.pentatonicAndBlues,
    kind: ScaleKind.minorBlues,
  ),
  ScaleMenuEntry(
    label: 'Whole tone',
    section: ScaleSection.symmetric,
    kind: ScaleKind.wholeTone,
  ),
  ScaleMenuEntry(
    label: 'Augmented',
    section: ScaleSection.symmetric,
    kind: ScaleKind.augmented,
  ),
  ScaleMenuEntry(
    label: 'Augmented inverse',
    section: ScaleSection.symmetric,
    kind: ScaleKind.augmentedInverse,
  ),
  ScaleMenuEntry(
    label: 'Diminished whole-half',
    section: ScaleSection.symmetric,
    kind: ScaleKind.diminishedWholeHalf,
  ),
  ScaleMenuEntry(
    label: 'Diminished half-whole',
    section: ScaleSection.symmetric,
    kind: ScaleKind.diminishedHalfWhole,
  ),
];

/// The [ScaleSection.essential] entry the explorer seeds onto for [kind]. The
/// explorer seeds and reseeds onto these practical-name rows rather than their
/// modal equivalents, so [kind] must be one that has a [ScaleSection.essential]
/// row (the major/minor seed kinds), not an arbitrary [ScaleKind].
ScaleMenuEntry seedScaleEntry(ScaleKind kind) => scaleMenuEntries.firstWhere(
  (entry) => entry.section == ScaleSection.essential && entry.kind == kind,
  orElse: () => throw ArgumentError.value(
    kind,
    'kind',
    'has no ${ScaleSection.essential.title} row to seed onto',
  ),
);
