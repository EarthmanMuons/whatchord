import 'package:whatchord/features/theory/domain/theory_domain.dart';

class ExploreExtensionControlGroup {
  const ExploreExtensionControlGroup({
    required this.label,
    required this.allowsMultiple,
    required this.choices,
  });

  final String label;
  final bool allowsMultiple;
  final List<ExploreExtensionChoice> choices;
}

class ExploreExtensionChoice {
  const ExploreExtensionChoice({
    required this.label,
    required this.semanticLabel,
    this.extension,
  });

  final String label;
  final String semanticLabel;
  final ChordExtension? extension;
}

List<ExploreExtensionControlGroup> buildExploreExtensionControlGroups(
  ChordQualityToken quality,
) {
  if (quality.isSeventhFamily) {
    return const [
      ExploreExtensionControlGroup(
        label: '9',
        allowsMultiple: false,
        choices: [
          ExploreExtensionChoice(label: 'None', semanticLabel: 'No ninth'),
          ExploreExtensionChoice(
            label: 'b9',
            semanticLabel: 'Flat ninth',
            extension: ChordExtension.flat9,
          ),
          ExploreExtensionChoice(
            label: '9',
            semanticLabel: 'Ninth',
            extension: ChordExtension.nine,
          ),
          ExploreExtensionChoice(
            label: '#9',
            semanticLabel: 'Sharp ninth',
            extension: ChordExtension.sharp9,
          ),
        ],
      ),
      ExploreExtensionControlGroup(
        label: '11',
        allowsMultiple: false,
        choices: [
          ExploreExtensionChoice(label: 'None', semanticLabel: 'No eleventh'),
          ExploreExtensionChoice(
            label: '11',
            semanticLabel: 'Eleventh',
            extension: ChordExtension.eleven,
          ),
          ExploreExtensionChoice(
            label: '#11',
            semanticLabel: 'Sharp eleventh',
            extension: ChordExtension.sharp11,
          ),
        ],
      ),
      ExploreExtensionControlGroup(
        label: '13',
        allowsMultiple: false,
        choices: [
          ExploreExtensionChoice(label: 'None', semanticLabel: 'No thirteenth'),
          ExploreExtensionChoice(
            label: 'b13',
            semanticLabel: 'Flat thirteenth',
            extension: ChordExtension.flat13,
          ),
          ExploreExtensionChoice(
            label: '13',
            semanticLabel: 'Thirteenth',
            extension: ChordExtension.thirteen,
          ),
        ],
      ),
    ];
  }

  return [
    ExploreExtensionControlGroup(
      label: 'Added tones',
      allowsMultiple: true,
      choices: [
        _choice(ChordExtension.add9),
        _choice(ChordExtension.add11),
        if (!quality.isSixFamily) _choice(ChordExtension.add13),
      ],
    ),
  ];
}

Set<ChordExtension> selectExploreExtensionChoice({
  required ChordQualityToken quality,
  required Set<ChordExtension> currentExtensions,
  required ExploreExtensionControlGroup group,
  required ExploreExtensionChoice choice,
}) {
  final next = normalizeExtensionsForQuality(
    quality: quality,
    extensions: currentExtensions,
  ).toSet();

  if (group.allowsMultiple) {
    final extension = choice.extension;
    if (extension == null) return Set<ChordExtension>.unmodifiable(next);

    if (next.contains(extension)) {
      next.remove(extension);
    } else {
      next.add(extension);
    }
  } else {
    for (final option in group.choices) {
      final extension = option.extension;
      if (extension != null) next.remove(extension);
    }

    final extension = choice.extension;
    if (extension != null) next.add(extension);
  }

  return normalizeExtensionsForQuality(quality: quality, extensions: next);
}

ExploreExtensionChoice _choice(ChordExtension extension) {
  return ExploreExtensionChoice(
    label: extension.shortLabel,
    semanticLabel: extension.longLabel,
    extension: extension,
  );
}

Set<ChordExtension> normalizeExtensionsForQuality({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  final normalized = <ChordExtension>{};

  for (final extension in extensions) {
    switch (extension) {
      case ChordExtension.add9:
        normalized.add(
          quality.isSeventhFamily ? ChordExtension.nine : ChordExtension.add9,
        );
        break;
      case ChordExtension.add11:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.eleven
              : ChordExtension.add11,
        );
        break;
      case ChordExtension.add13:
        if (quality.isSeventhFamily) {
          normalized.add(ChordExtension.thirteen);
        } else if (!quality.isSixFamily) {
          normalized.add(ChordExtension.add13);
        }
        break;
      case ChordExtension.nine:
        normalized.add(
          quality.isSeventhFamily ? ChordExtension.nine : ChordExtension.add9,
        );
        break;
      case ChordExtension.eleven:
        normalized.add(
          quality.isSeventhFamily
              ? ChordExtension.eleven
              : ChordExtension.add11,
        );
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          normalized.add(ChordExtension.thirteen);
        } else if (!quality.isSixFamily) {
          normalized.add(ChordExtension.add13);
        }
        break;
      case ChordExtension.flat9:
      case ChordExtension.sharp9:
      case ChordExtension.sharp11:
      case ChordExtension.flat13:
        if (quality.isSeventhFamily) {
          normalized.add(extension);
        }
        break;
    }
  }

  return Set<ChordExtension>.unmodifiable(normalized);
}

String extensionSetId(Set<ChordExtension> extensions) {
  if (extensions.isEmpty) return 'none';

  final ordered = extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return ordered.map((extension) => extension.name).join('|');
}

String extensionSetLabel(Set<ChordExtension> extensions) {
  if (extensions.isEmpty) return 'None';

  final ordered = extensions.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return ordered.map((extension) => extension.shortLabel).join(', ');
}
