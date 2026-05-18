import 'package:whatchord/features/theory/theory.dart';

enum ExploreExtensionControlRole { highestExtension, addedTones, colors }

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
    final availableHighestExtensions = _availableSeventhFamilyHighestExtensions(
      quality,
    );
    final availableAddTones = _availableSeventhFamilyAddTones(quality);
    final availableColors = _availableSeventhFamilyColorExtensions(quality);
    final highestExtensionChoices = <ExploreExtensionChoice>[
      const ExploreExtensionChoice(
        label: 'None',
        semanticLabel: 'No highest extension',
      ),
      if (availableHighestExtensions.contains(ChordExtension.nine))
        _choice(ChordExtension.nine),
      if (_allowsSeventhFamilyHighestEleven(quality) &&
          availableHighestExtensions.contains(ChordExtension.eleven))
        _choice(ChordExtension.eleven),
      if (availableHighestExtensions.contains(ChordExtension.thirteen))
        _choice(ChordExtension.thirteen),
    ];
    final addToneChoices = <ExploreExtensionChoice>[
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
        role: ExploreExtensionControlRole.highestExtension,
        allowsMultiple: false,
        choices: highestExtensionChoices,
      ),
      if (addToneChoices.isNotEmpty)
        ExploreExtensionControlGroup(
          label: 'Added tones',
          role: ExploreExtensionControlRole.addedTones,
          allowsMultiple: true,
          choices: addToneChoices,
        ),
      if (colorChoices.isNotEmpty)
        ExploreExtensionControlGroup(
          label: 'Colors',
          role: ExploreExtensionControlRole.colors,
          allowsMultiple: true,
          choices: colorChoices,
        ),
    ];
  }

  final availableAddTones = _availableTriadLikeAddTones(quality);
  final availableColors = _availableTriadLikeColorExtensions(quality);
  return [
    if (availableAddTones.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Added tones',
        role: ExploreExtensionControlRole.addedTones,
        allowsMultiple: true,
        choices: [
          if (availableAddTones.contains(ChordExtension.add9))
            _choice(ChordExtension.add9),
          if (availableAddTones.contains(ChordExtension.add11))
            _choice(ChordExtension.add11),
          if (availableAddTones.contains(ChordExtension.add13))
            _choice(ChordExtension.add13),
        ],
      ),
    if (availableColors.isNotEmpty)
      ExploreExtensionControlGroup(
        label: 'Colors',
        role: ExploreExtensionControlRole.colors,
        allowsMultiple: true,
        choices: [
          if (availableColors.contains(ChordExtension.flat9))
            _choice(ChordExtension.flat9),
          if (availableColors.contains(ChordExtension.sharp11))
            _choice(ChordExtension.sharp11),
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

    var selected = false;
    if (next.contains(extension)) {
      next.remove(extension);
    } else {
      _removeMutuallyExclusiveTriadLikeExtensions(next, extension);
      _removeConflictingSeventhFamilyExtensions(next, extension);
      next.add(extension);
      selected = true;
    }

    if (selected &&
        quality.isSeventhFamily &&
        group.role == ExploreExtensionControlRole.addedTones) {
      _promoteSeventhFamilyAddedTone(next, extension);
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

void _promoteSeventhFamilyAddedTone(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.add9:
      extensions.remove(ChordExtension.add9);
      extensions.add(ChordExtension.nine);
      break;
    case ChordExtension.add11:
      if (!_hasAnyNinth(extensions)) break;
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.add11);
      extensions.add(ChordExtension.eleven);
      break;
    case ChordExtension.add13:
      if (!extensions.contains(ChordExtension.eleven)) break;
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.eleven);
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.add11);
      extensions.remove(ChordExtension.add13);
      extensions.add(ChordExtension.thirteen);
      break;
    default:
      break;
  }
}

bool _hasAnyNinth(Set<ChordExtension> extensions) {
  return extensions.contains(ChordExtension.nine) ||
      extensions.contains(ChordExtension.add9) ||
      extensions.contains(ChordExtension.flat9) ||
      extensions.contains(ChordExtension.sharp9);
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
  final availableSeventhHighestExtensions = quality.isSeventhFamily
      ? _availableSeventhFamilyHighestExtensions(quality)
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

  void addSeventhHighestExtension(ChordExtension extension) {
    if (availableSeventhHighestExtensions.contains(extension)) {
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
          addSeventhHighestExtension(ChordExtension.nine);
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
          addSeventhHighestExtension(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.eleven:
        if (quality.isSeventhFamily) {
          if (_allowsSeventhFamilyHighestEleven(quality)) {
            addSeventhHighestExtension(ChordExtension.eleven);
          }
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          addSeventhHighestExtension(ChordExtension.thirteen);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
        }
        break;
      case ChordExtension.sharp9:
      case ChordExtension.flat13:
        addSeventhColor(extension);
        break;
      case ChordExtension.flat9:
        if (quality.isSeventhFamily) {
          addSeventhColor(extension);
        } else {
          addTriadLikeExtension(ChordExtension.flat9);
        }
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

  if (quality.isSeventhFamily) {
    _promoteSeventhFamilyCompletedStacks(normalized);
  }

  return Set<ChordExtension>.unmodifiable(normalized);
}

void _promoteSeventhFamilyCompletedStacks(Set<ChordExtension> extensions) {
  if (extensions.contains(ChordExtension.add11) && _hasAnyNinth(extensions)) {
    extensions.remove(ChordExtension.nine);
    extensions.remove(ChordExtension.add9);
    extensions.remove(ChordExtension.add11);
    extensions.add(ChordExtension.eleven);
  }

  if (extensions.contains(ChordExtension.add13) &&
      extensions.contains(ChordExtension.eleven)) {
    extensions.remove(ChordExtension.nine);
    extensions.remove(ChordExtension.eleven);
    extensions.remove(ChordExtension.add9);
    extensions.remove(ChordExtension.add11);
    extensions.remove(ChordExtension.add13);
    extensions.add(ChordExtension.thirteen);
  }
}

bool _allowsTriadLikeSharp11(ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.major ||
    ChordQualityToken.minor ||
    ChordQualityToken.major6 ||
    ChordQualityToken.minor6 ||
    ChordQualityToken.augmented => true,
    _ => false,
  };
}

bool _allowsTriadLikeFlat9(ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.major6 || ChordQualityToken.minor6 => true,
    _ => false,
  };
}

Set<ChordExtension> _availableTriadLikeExtensions(ChordQualityToken quality) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.add9,
      ChordExtension.add11,
      ChordExtension.add13,
      ChordExtension.sharp11,
    })
      if (!canonicalIntervals.contains(extension.intervalAboveRoot) &&
          (!_isTriadLikeSharp11(extension) ||
              _allowsTriadLikeSharp11(quality)) &&
          (!_isTriadLikeFlat9(extension) || _allowsTriadLikeFlat9(quality)))
        extension,
  };
}

Set<ChordExtension> _availableTriadLikeAddTones(ChordQualityToken quality) {
  final available = _availableTriadLikeExtensions(quality);
  return {
    for (final extension in const {
      ChordExtension.add9,
      ChordExtension.add11,
      ChordExtension.add13,
    })
      if (available.contains(extension)) extension,
  };
}

Set<ChordExtension> _availableTriadLikeColorExtensions(
  ChordQualityToken quality,
) {
  final available = _availableTriadLikeExtensions(quality);
  return {
    if (available.contains(ChordExtension.flat9)) ChordExtension.flat9,
    if (available.contains(ChordExtension.sharp11)) ChordExtension.sharp11,
  };
}

bool _isTriadLikeFlat9(ChordExtension extension) {
  return extension == ChordExtension.flat9;
}

bool _isTriadLikeSharp11(ChordExtension extension) {
  return extension == ChordExtension.sharp11;
}

bool _allowsSeventhFamilyHighestEleven(ChordQualityToken quality) {
  return quality.isSeventhFamily;
}

void _removeMutuallyExclusiveTriadLikeExtensions(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.add9:
      extensions.remove(ChordExtension.flat9);
      break;
    case ChordExtension.flat9:
      extensions.remove(ChordExtension.add9);
      break;
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
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.add9);
      break;
    case ChordExtension.sharp9:
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

Set<ChordExtension> _availableSeventhFamilyHighestExtensions(
  ChordQualityToken quality,
) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.nine,
      ChordExtension.eleven,
      ChordExtension.thirteen,
    })
      if (!canonicalIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}

Set<ChordExtension> _availableSeventhFamilyAddTones(ChordQualityToken quality) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {ChordExtension.add11, ChordExtension.add13})
      if (!canonicalIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}

Set<ChordExtension> _availableSeventhFamilyColorExtensions(
  ChordQualityToken quality,
) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.sharp9,
      ChordExtension.sharp11,
      ChordExtension.flat13,
    })
      if (!canonicalIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}
