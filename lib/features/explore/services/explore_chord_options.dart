import 'package:whatchord/features/theory/theory.dart';

import 'explore_chord_derivation.dart';

enum ExploreExtensionControlRole { headline, addedTone, color }

class ExploreExtensionControlGroup {
  const ExploreExtensionControlGroup({
    required this.label,
    required this.role,
    required this.allowsMultiple,
    required this.choices,
  });

  final String label;
  final ExploreExtensionControlRole role;
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
    final availableHeadlines = _availableSeventhFamilyHeadlineExtensions(
      quality,
    );
    final availableAddTones = _availableSeventhFamilyAddTones(quality);
    final availableColors = _availableSeventhFamilyColorExtensions(quality);
    final headlineChoices = <ExploreExtensionChoice>[
      const ExploreExtensionChoice(
        label: 'None',
        semanticLabel: 'No highest extension',
      ),
      if (availableHeadlines.contains(ChordExtension.nine))
        _headlineChoice(ChordExtension.nine),
      if (_allowsSeventhHeadlineEleven(quality) &&
          availableHeadlines.contains(ChordExtension.eleven))
        _headlineChoice(ChordExtension.eleven),
      if (availableHeadlines.contains(ChordExtension.thirteen))
        _headlineChoice(ChordExtension.thirteen),
    ];
    final addToneChoices = <ExploreExtensionChoice>[
      const ExploreExtensionChoice(
        label: 'None',
        semanticLabel: 'No added tones',
      ),
      if (availableAddTones.contains(ChordExtension.add9))
        _choice(ChordExtension.add9),
      if (availableAddTones.contains(ChordExtension.add11))
        _choice(ChordExtension.add11),
      if (availableAddTones.contains(ChordExtension.add13))
        _choice(ChordExtension.add13),
    ];
    final colorChoices = <ExploreExtensionChoice>[
      if (availableColors.contains(ChordExtension.flat9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b9'),
          semanticLabel: 'Flat ninth',
          extension: ChordExtension.flat9,
        ),
      if (availableColors.contains(ChordExtension.sharp9))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#9'),
          semanticLabel: 'Sharp ninth',
          extension: ChordExtension.sharp9,
        ),
      if (availableColors.contains(ChordExtension.sharp11))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('#11'),
          semanticLabel: 'Sharp eleventh',
          extension: ChordExtension.sharp11,
        ),
      if (availableColors.contains(ChordExtension.flat13))
        ExploreExtensionChoice(
          label: theoryTokenDisplayLabel('b13'),
          semanticLabel: 'Flat thirteenth',
          extension: ChordExtension.flat13,
        ),
    ];

    return [
      ExploreExtensionControlGroup(
        label: 'Highest extension',
        role: ExploreExtensionControlRole.headline,
        allowsMultiple: false,
        choices: headlineChoices,
      ),
      if (addToneChoices.length > 1)
        ExploreExtensionControlGroup(
          label: 'Added tones',
          role: ExploreExtensionControlRole.addedTone,
          allowsMultiple: false,
          choices: addToneChoices,
        ),
      if (colorChoices.isNotEmpty)
        ExploreExtensionControlGroup(
          label: 'Colors',
          role: ExploreExtensionControlRole.color,
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
        role: ExploreExtensionControlRole.headline,
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
      role: ExploreExtensionControlRole.headline,
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
      _removeConflictingSeventhFamilyExtensions(next, extension);
      next.add(extension);
    }
  } else {
    for (final option in group.choices) {
      final extension = option.extension;
      if (extension != null) next.remove(extension);
    }

    final extension = choice.extension;
    if (extension != null) {
      _removeConflictingSeventhFamilyExtensions(next, extension);
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
  final availableSeventhHeadlines = quality.isSeventhFamily
      ? _availableSeventhFamilyHeadlineExtensions(quality)
      : const <ChordExtension>{};
  final availableSeventhAddTones = quality.isSeventhFamily
      ? _availableSeventhFamilyAddTones(quality)
      : const <ChordExtension>{};
  final availableSeventhColors = quality.isSeventhFamily
      ? _availableSeventhFamilyColorExtensions(quality)
      : const <ChordExtension>{};
  final availableTriadLikeExtensions = !quality.isSeventhFamily
      ? _availableTriadLikeExtensions(quality)
      : const <ChordExtension>{};

  void addSeventhHeadline(ChordExtension extension) {
    if (availableSeventhHeadlines.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addSeventhAddTone(ChordExtension extension) {
    if (availableSeventhAddTones.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addSeventhColor(ChordExtension extension) {
    if (availableSeventhColors.contains(extension)) {
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
          addSeventhAddTone(ChordExtension.add9);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.add11:
        if (quality.isSeventhFamily) {
          addSeventhAddTone(ChordExtension.add11);
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.add13:
        if (quality.isSeventhFamily) {
          addSeventhAddTone(ChordExtension.add13);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
        }
        break;
      case ChordExtension.nine:
        if (quality.isSeventhFamily) {
          addSeventhHeadline(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.eleven:
        if (quality.isSeventhFamily) {
          if (_allowsSeventhHeadlineEleven(quality)) {
            addSeventhHeadline(ChordExtension.eleven);
          }
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          addSeventhHeadline(ChordExtension.thirteen);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
        }
        break;
      case ChordExtension.flat9:
      case ChordExtension.sharp9:
      case ChordExtension.flat13:
        addSeventhColor(extension);
        break;
      case ChordExtension.sharp11:
        if (quality.isSeventhFamily) {
          addSeventhColor(extension);
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

void _removeConflictingSeventhFamilyExtensions(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.nine:
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.sharp9);
      break;
    case ChordExtension.eleven:
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.add11);
      extensions.remove(ChordExtension.sharp11);
      break;
    case ChordExtension.thirteen:
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.add11);
      extensions.remove(ChordExtension.add13);
      extensions.remove(ChordExtension.flat13);
      break;
    case ChordExtension.add9:
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.eleven);
      extensions.remove(ChordExtension.thirteen);
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.sharp9);
      break;
    case ChordExtension.add11:
      extensions.remove(ChordExtension.eleven);
      extensions.remove(ChordExtension.thirteen);
      extensions.remove(ChordExtension.sharp11);
      break;
    case ChordExtension.add13:
      extensions.remove(ChordExtension.thirteen);
      extensions.remove(ChordExtension.flat13);
      break;
    case ChordExtension.flat9:
      extensions.remove(ChordExtension.sharp9);
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.add9);
      break;
    case ChordExtension.sharp9:
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.add9);
      break;
    case ChordExtension.sharp11:
      extensions.remove(ChordExtension.eleven);
      extensions.remove(ChordExtension.add11);
      break;
    case ChordExtension.flat13:
      extensions.remove(ChordExtension.thirteen);
      extensions.remove(ChordExtension.add13);
      break;
  }
}

Set<ChordExtension> _availableSeventhFamilyHeadlineExtensions(
  ChordQualityToken quality,
) {
  final coreIntervals = coreIntervalsForQuality(quality);
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.nine,
      ChordExtension.eleven,
      ChordExtension.thirteen,
    })
      if (!coreIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}

Set<ChordExtension> _availableSeventhFamilyAddTones(ChordQualityToken quality) {
  final coreIntervals = coreIntervalsForQuality(quality);
  return {
    for (final extension in const {
      ChordExtension.add9,
      ChordExtension.add11,
      ChordExtension.add13,
    })
      if (!coreIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}

Set<ChordExtension> _availableSeventhFamilyColorExtensions(
  ChordQualityToken quality,
) {
  final coreIntervals = coreIntervalsForQuality(quality);
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.sharp9,
      ChordExtension.sharp11,
      ChordExtension.flat13,
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
