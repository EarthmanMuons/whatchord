import 'package:whatchord/features/theory/theory.dart';

import 'explore_chord_derivation.dart';

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
    final available = _availableSeventhFamilyExtensions(quality);

    return [
      ExploreExtensionControlGroup(
        label: '9',
        allowsMultiple: false,
        choices: [
          const ExploreExtensionChoice(
            label: 'None',
            semanticLabel: 'No ninth',
          ),
          if (available.contains(ChordExtension.flat9))
            ExploreExtensionChoice(
              label: theoryTokenDisplayLabel('b9'),
              semanticLabel: 'Flat ninth',
              extension: ChordExtension.flat9,
            ),
          if (available.contains(ChordExtension.nine))
            const ExploreExtensionChoice(
              label: '9',
              semanticLabel: 'Ninth',
              extension: ChordExtension.nine,
            ),
          if (available.contains(ChordExtension.sharp9))
            ExploreExtensionChoice(
              label: theoryTokenDisplayLabel('#9'),
              semanticLabel: 'Sharp ninth',
              extension: ChordExtension.sharp9,
            ),
        ],
      ),
      ExploreExtensionControlGroup(
        label: '11',
        allowsMultiple: false,
        choices: [
          const ExploreExtensionChoice(
            label: 'None',
            semanticLabel: 'No eleventh',
          ),
          if (available.contains(ChordExtension.eleven))
            const ExploreExtensionChoice(
              label: '11',
              semanticLabel: 'Eleventh',
              extension: ChordExtension.eleven,
            ),
          if (available.contains(ChordExtension.sharp11))
            ExploreExtensionChoice(
              label: theoryTokenDisplayLabel('#11'),
              semanticLabel: 'Sharp eleventh',
              extension: ChordExtension.sharp11,
            ),
        ],
      ),
      ExploreExtensionControlGroup(
        label: '13',
        allowsMultiple: false,
        choices: [
          const ExploreExtensionChoice(
            label: 'None',
            semanticLabel: 'No thirteenth',
          ),
          if (available.contains(ChordExtension.flat13))
            ExploreExtensionChoice(
              label: theoryTokenDisplayLabel('b13'),
              semanticLabel: 'Flat thirteenth',
              extension: ChordExtension.flat13,
            ),
          if (available.contains(ChordExtension.thirteen))
            const ExploreExtensionChoice(
              label: '13',
              semanticLabel: 'Thirteenth',
              extension: ChordExtension.thirteen,
            ),
        ],
      ),
    ];
  }

  if (_allowsTriadLikeSharp11(quality)) {
    return [
      ExploreExtensionControlGroup(
        label: 'Add tones',
        allowsMultiple: true,
        choices: [
          _choice(ChordExtension.add9),
          if (!quality.isSixFamily) _choice(ChordExtension.add13),
        ],
      ),
      ExploreExtensionControlGroup(
        label: '11',
        allowsMultiple: false,
        choices: [
          const ExploreExtensionChoice(
            label: 'None',
            semanticLabel: 'No eleventh',
          ),
          _choice(ChordExtension.add11),
          _choice(ChordExtension.sharp11),
        ],
      ),
    ];
  }

  return [
    ExploreExtensionControlGroup(
      label: 'Extensions',
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
      _removeMutuallyExclusiveTriadLikeExtensions(next, extension);
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
    label: theoryTokenDisplayLabel(extension.shortLabel),
    semanticLabel: extension.longLabel,
    extension: extension,
  );
}

Set<ChordExtension> normalizeExtensionsForQuality({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  final normalized = <ChordExtension>{};
  final availableSeventhExtensions = quality.isSeventhFamily
      ? _availableSeventhFamilyExtensions(quality)
      : const <ChordExtension>{};
  void addSeventhExtension(ChordExtension extension) {
    if (availableSeventhExtensions.contains(extension)) {
      normalized.add(extension);
    }
  }

  for (final extension in extensions) {
    switch (extension) {
      case ChordExtension.add9:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.nine);
        } else {
          normalized.add(ChordExtension.add9);
        }
        break;
      case ChordExtension.add11:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.eleven);
        } else {
          normalized.add(ChordExtension.add11);
        }
        break;
      case ChordExtension.add13:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.thirteen);
        } else if (!quality.isSixFamily) {
          normalized.add(ChordExtension.add13);
        }
        break;
      case ChordExtension.nine:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.nine);
        } else {
          normalized.add(ChordExtension.add9);
        }
        break;
      case ChordExtension.eleven:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.eleven);
        } else {
          normalized.add(ChordExtension.add11);
        }
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.thirteen);
        } else if (!quality.isSixFamily) {
          normalized.add(ChordExtension.add13);
        }
        break;
      case ChordExtension.flat9:
      case ChordExtension.sharp9:
      case ChordExtension.flat13:
        addSeventhExtension(extension);
        break;
      case ChordExtension.sharp11:
        if (quality.isSeventhFamily) {
          addSeventhExtension(extension);
        } else if (_allowsTriadLikeSharp11(quality)) {
          normalized.add(ChordExtension.sharp11);
        }
        break;
    }
  }

  return Set<ChordExtension>.unmodifiable(normalized);
}

bool _allowsTriadLikeSharp11(ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.major ||
    ChordQualityToken.major6 ||
    ChordQualityToken.augmented => true,
    _ => false,
  };
}

void _removeMutuallyExclusiveTriadLikeExtensions(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.add11:
      extensions.remove(ChordExtension.sharp11);
      break;
    case ChordExtension.sharp11:
      extensions.remove(ChordExtension.add11);
      break;
    default:
      break;
  }
}

Set<ChordExtension> _availableSeventhFamilyExtensions(
  ChordQualityToken quality,
) {
  final coreIntervals = coreIntervalsForQuality(quality);
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.nine,
      ChordExtension.sharp9,
      ChordExtension.eleven,
      ChordExtension.sharp11,
      ChordExtension.flat13,
      ChordExtension.thirteen,
    })
      if (!coreIntervals.contains(extension.intervalAboveRoot)) extension,
  };
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
  return ordered
      .map((extension) => theoryTokenDisplayLabel(extension.shortLabel))
      .join(', ');
}
