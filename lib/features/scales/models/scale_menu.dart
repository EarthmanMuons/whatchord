import 'package:meta/meta.dart';

import 'package:whatchord/features/theory/theory.dart';

/// A grouping of scales in the Scale Explorer menu. Each section presents one
/// lens on the catalog: [common] lists the practical names a musician reaches
/// for, while [diatonicModes] lists the seven rotations of the major scale as a
/// clean family. The major scale and natural minor therefore appear in both
/// sections (as Major/Natural minor and Ionian/Aeolian) since they answer
/// different questions about the same sound.
enum ScaleSection {
  common('Common scales', properNounNames: false),
  diatonicModes('Diatonic modes', properNounNames: true);

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
    section: ScaleSection.common,
    kind: ScaleKind.major,
  ),
  ScaleMenuEntry(
    label: 'Natural minor',
    section: ScaleSection.common,
    kind: ScaleKind.aeolian,
  ),
  ScaleMenuEntry(
    label: 'Harmonic minor',
    section: ScaleSection.common,
    kind: ScaleKind.harmonicMinor,
  ),
  ScaleMenuEntry(
    label: 'Melodic minor',
    section: ScaleSection.common,
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
];

/// The [ScaleSection.common] entry for [kind]. The explorer seeds and reseeds
/// onto these practical-name rows rather than their modal equivalents.
ScaleMenuEntry commonScaleEntry(ScaleKind kind) => scaleMenuEntries.firstWhere(
  (entry) => entry.section == ScaleSection.common && entry.kind == kind,
);
