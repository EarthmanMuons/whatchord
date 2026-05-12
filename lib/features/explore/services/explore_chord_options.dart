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
    final headlineChoices = <ExploreExtensionChoice>[
      const ExploreExtensionChoice(
        label: 'None',
        semanticLabel: 'No extension headline',
      ),
      if (available.contains(ChordExtension.nine))
        _headlineChoice(ChordExtension.nine),
      if (_allowsSeventhHeadlineEleven(quality) &&
          available.contains(ChordExtension.eleven))
        _headlineChoice(ChordExtension.eleven),
      if (available.contains(ChordExtension.thirteen))
        _headlineChoice(ChordExtension.thirteen),
    ];
    final colorChoices = <ExploreExtensionChoice>[
      if (available.contains(ChordExtension.flat9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b9'),
          semanticLabel: 'Flat ninth',
          extension: ChordExtension.flat9,
        ),
      if (available.contains(ChordExtension.sharp9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#9'),
          semanticLabel: 'Sharp ninth',
          extension: ChordExtension.sharp9,
        ),
      if (available.contains(ChordExtension.sharp11))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#11'),
          semanticLabel: 'Sharp eleventh',
          extension: ChordExtension.sharp11,
        ),
      if (available.contains(ChordExtension.flat13))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b13'),
          semanticLabel: 'Flat thirteenth',
          extension: ChordExtension.flat13,
        ),
    ];

    return [
      ExploreExtensionControlGroup(
        label: 'Extension',
        allowsMultiple: false,
        choices: headlineChoices,
      ),
      if (colorChoices.isNotEmpty)
        ExploreExtensionControlGroup(
          label: 'Colors',
          allowsMultiple: true,
          choices: colorChoices,
        ),
    ];
  }

  if (_allowsTriadLikeSharp11(quality)) {
    final available = _availableTriadLikeExtensions(quality);
    return [
      ExploreExtensionControlGroup(
        label: 'Extension',
        allowsMultiple: false,
        choices: [
          const ExploreExtensionChoice(
            label: 'None',
            semanticLabel: 'No extension',
          ),
          if (available.contains(ChordExtension.add9))
            _choice(ChordExtension.add9),
          if (available.contains(ChordExtension.add11))
            _choice(ChordExtension.add11),
          if (available.contains(ChordExtension.sharp11))
            _choice(ChordExtension.sharp11),
          if (available.contains(ChordExtension.add13))
            _choice(ChordExtension.add13),
        ],
      ),
    ];
  }

  final available = _availableTriadLikeExtensions(quality);
  return [
    ExploreExtensionControlGroup(
      label: 'Extension',
      allowsMultiple: false,
      choices: [
        const ExploreExtensionChoice(
          label: 'None',
          semanticLabel: 'No extension',
        ),
        if (available.contains(ChordExtension.add9))
          _choice(ChordExtension.add9),
        if (available.contains(ChordExtension.add11))
          _choice(ChordExtension.add11),
        if (available.contains(ChordExtension.add13))
          _choice(ChordExtension.add13),
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
      _removeMutuallyExclusiveSeventhColorExtensions(next, extension);
      next.add(extension);
    }
  } else {
    for (final option in group.choices) {
      final extension = option.extension;
      if (extension != null) next.remove(extension);
    }

    final extension = choice.extension;
    if (extension != null) {
      _removeMutuallyExclusiveSeventhColorExtensions(next, extension);
      next.add(extension);
    }
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

ExploreExtensionChoice _headlineChoice(ChordExtension extension) {
  return ExploreExtensionChoice(
    label: theoryTokenDisplayLabel(_headlineControlLabel(extension)),
    semanticLabel: extension.longLabel,
    extension: extension,
  );
}

String _headlineControlLabel(ChordExtension extension) {
  return switch (extension) {
    ChordExtension.nine => ChordExtension.add9.shortLabel,
    ChordExtension.eleven => ChordExtension.add11.shortLabel,
    ChordExtension.thirteen => ChordExtension.add13.shortLabel,
    _ => extension.shortLabel,
  };
}

Set<ChordExtension> normalizeExtensionsForQuality({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  final normalized = <ChordExtension>{};
  final availableSeventhExtensions = quality.isSeventhFamily
      ? _availableSeventhFamilyExtensions(quality)
      : const <ChordExtension>{};
  final availableTriadLikeExtensions = !quality.isSeventhFamily
      ? _availableTriadLikeExtensions(quality)
      : const <ChordExtension>{};
  void addSeventhExtension(ChordExtension extension) {
    if (availableSeventhExtensions.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addTriadLikeExtension(ChordExtension extension) {
    if (availableTriadLikeExtensions.contains(extension)) {
      normalized.add(extension);
    }
  }

  for (final extension in extensions) {
    switch (extension) {
      case ChordExtension.add9:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.add11:
        if (quality.isSeventhFamily) {
          if (_allowsSeventhHeadlineEleven(quality)) {
            addSeventhExtension(ChordExtension.eleven);
          }
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.add13:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.thirteen);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
        }
        break;
      case ChordExtension.nine:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.eleven:
        if (quality.isSeventhFamily) {
          if (_allowsSeventhHeadlineEleven(quality)) {
            addSeventhExtension(ChordExtension.eleven);
          }
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          addSeventhExtension(ChordExtension.thirteen);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
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
        } else {
          addTriadLikeExtension(ChordExtension.sharp11);
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

Set<ChordExtension> _availableTriadLikeExtensions(ChordQualityToken quality) {
  final coreIntervals = coreIntervalsForQuality(quality);
  return {
    for (final extension in const {
      ChordExtension.add9,
      ChordExtension.add11,
      ChordExtension.add13,
      ChordExtension.sharp11,
    })
      if (!coreIntervals.contains(extension.intervalAboveRoot) &&
          (!_isTriadLikeSharp11(extension) || _allowsTriadLikeSharp11(quality)))
        extension,
  };
}

bool _isTriadLikeSharp11(ChordExtension extension) {
  return extension == ChordExtension.sharp11;
}

bool _allowsSeventhHeadlineEleven(ChordQualityToken quality) {
  return quality.isSeventhFamily;
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

void _removeMutuallyExclusiveSeventhColorExtensions(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.flat9:
      extensions.remove(ChordExtension.sharp9);
      break;
    case ChordExtension.sharp9:
      extensions.remove(ChordExtension.flat9);
      break;
    case ChordExtension.flat13:
      extensions.remove(ChordExtension.thirteen);
      break;
    case ChordExtension.thirteen:
      extensions.remove(ChordExtension.flat13);
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
