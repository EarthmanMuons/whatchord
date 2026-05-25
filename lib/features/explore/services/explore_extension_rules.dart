import 'package:whatchord/features/theory/theory.dart';

/// Keeps Explore selections musically meaningful when the base quality changes.
///
/// The same pitch can be notated differently depending on context: triad-like
/// chords use add tones, while seventh-family chords can use stacked 9/11/13
/// extensions once the lower stack is present.
Set<ChordExtension> normalizeExtensionsForQuality({
  required ChordQualityToken quality,
  required Set<ChordExtension> extensions,
}) {
  final normalized = <ChordExtension>{};
  final stack = quality.isSeventhFamily
      ? seventhStackExtensions(quality)
      : const <ChordExtension>{};
  final addTones = quality.isSeventhFamily
      ? seventhAddTones(quality)
      : const <ChordExtension>{};
  final alterations = quality.isSeventhFamily
      ? seventhAlterations(quality)
      : const <ChordExtension>{};
  final triadLike = !quality.isSeventhFamily
      ? triadLikeExtensions(quality)
      : const <ChordExtension>{};

  void addStackExtension(ChordExtension extension) {
    if (stack.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addSeventhAddTone(ChordExtension extension) {
    if (addTones.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addSeventhAlteration(ChordExtension extension) {
    if (alterations.contains(extension)) {
      normalized.add(extension);
    }
  }

  void addTriadLikeExtension(ChordExtension extension) {
    if (triadLike.contains(extension)) {
      normalized.add(extension);
    }
  }

  for (final extension in extensions) {
    switch (extension) {
      case ChordExtension.add9:
        if (quality.isSeventhFamily) {
          addStackExtension(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.addSharp9:
        if (quality.isSeventhFamily) {
          addSeventhAlteration(ChordExtension.sharp9);
        } else {
          addTriadLikeExtension(ChordExtension.addSharp9);
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
          addStackExtension(ChordExtension.nine);
        } else {
          addTriadLikeExtension(ChordExtension.add9);
        }
        break;
      case ChordExtension.eleven:
        if (quality.isSeventhFamily) {
          addStackExtension(ChordExtension.eleven);
        } else {
          addTriadLikeExtension(ChordExtension.add11);
        }
        break;
      case ChordExtension.thirteen:
        if (quality.isSeventhFamily) {
          addStackExtension(ChordExtension.thirteen);
        } else {
          addTriadLikeExtension(ChordExtension.add13);
        }
        break;
      case ChordExtension.sharp9:
        if (quality.isSeventhFamily) {
          addSeventhAlteration(extension);
        } else {
          addTriadLikeExtension(ChordExtension.addSharp9);
        }
        break;
      case ChordExtension.flat13:
        addSeventhAlteration(extension);
        break;
      case ChordExtension.flat9:
        if (quality.isSeventhFamily) {
          addSeventhAlteration(extension);
        } else {
          addTriadLikeExtension(ChordExtension.flat9);
        }
        break;
      case ChordExtension.sharp11:
        if (quality.isSeventhFamily) {
          addSeventhAlteration(extension);
        } else {
          addTriadLikeExtension(ChordExtension.sharp11);
        }
        break;
    }
  }

  if (quality.isSeventhFamily) {
    promoteCompletedStacks(normalized);
  }

  return Set<ChordExtension>.unmodifiable(normalized);
}

/// Turns add-tone picks into stacked extensions when the implied stack exists.
///
/// Example: selecting add11 above an existing ninth should become an eleventh,
/// because 11 implies the lower 9 in standard seventh-family chord spelling.
void promoteAddedToneToStack(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  switch (selected) {
    case ChordExtension.add9:
      extensions.remove(ChordExtension.add9);
      extensions.add(ChordExtension.nine);
      break;
    case ChordExtension.addSharp9:
      extensions.remove(ChordExtension.addSharp9);
      extensions.add(ChordExtension.sharp9);
      break;
    case ChordExtension.add11:
      if (!hasAnyNinth(extensions)) break;
      _replaceWithStackedEleventh(extensions);
      break;
    case ChordExtension.add13:
      if (!extensions.contains(ChordExtension.eleven)) break;
      _replaceWithStackedThirteenth(extensions);
      break;
    default:
      break;
  }
}

/// Collapses skipped add tones after bulk normalization or quality changes.
void promoteCompletedStacks(Set<ChordExtension> extensions) {
  if (extensions.contains(ChordExtension.add11) && hasAnyNinth(extensions)) {
    _replaceWithStackedEleventh(extensions);
  }

  if (extensions.contains(ChordExtension.add13) &&
      extensions.contains(ChordExtension.eleven)) {
    _replaceWithStackedThirteenth(extensions);
  }
}

bool hasAnyNinth(Set<ChordExtension> extensions) {
  return extensions.contains(ChordExtension.nine) ||
      extensions.contains(ChordExtension.add9) ||
      extensions.contains(ChordExtension.flat9) ||
      extensions.contains(ChordExtension.sharp9);
}

void removeTriadLikeConflicts(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  // Triad-like chords expose enharmonic alternatives as separate controls, but
  // the resulting chord should not contain both versions of the same degree.
  switch (selected) {
    case ChordExtension.add9:
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.addSharp9);
      break;
    case ChordExtension.addSharp9:
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.add9);
      break;
    case ChordExtension.flat9:
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.addSharp9);
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

void removeSeventhConflicts(
  Set<ChordExtension> extensions,
  ChordExtension selected,
) {
  // Stacked extensions, explicit add tones, and alterations are mutually
  // exclusive when they spell the same chord degree or imply incompatible stack
  // intent.
  switch (selected) {
    case ChordExtension.nine:
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.addSharp9);
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
      extensions.remove(ChordExtension.addSharp9);
      break;
    case ChordExtension.addSharp9:
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.eleven);
      extensions.remove(ChordExtension.thirteen);
      extensions.remove(ChordExtension.flat9);
      extensions.remove(ChordExtension.sharp9);
      extensions.remove(ChordExtension.add9);
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
      extensions.remove(ChordExtension.addSharp9);
      break;
    case ChordExtension.sharp9:
      extensions.remove(ChordExtension.nine);
      extensions.remove(ChordExtension.add9);
      extensions.remove(ChordExtension.addSharp9);
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

/// Extensions available before splitting them into add-tone and alteration UI.
Set<ChordExtension> triadLikeExtensions(ChordQualityToken quality) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {
      ChordExtension.flat9,
      ChordExtension.add9,
      ChordExtension.addSharp9,
      ChordExtension.add11,
      ChordExtension.add13,
      ChordExtension.sharp11,
    })
      if (!canonicalIntervals.contains(extension.intervalAboveRoot) &&
          (extension != ChordExtension.sharp11 ||
              _allowsTriadLikeSharp11(quality)) &&
          (extension != ChordExtension.addSharp9 ||
              _allowsTriadLikeAddSharp9(quality)) &&
          (extension != ChordExtension.flat9 || _allowsTriadLikeFlat9(quality)))
        extension,
  };
}

Set<ChordExtension> triadLikeAddTones(ChordQualityToken quality) {
  final available = triadLikeExtensions(quality);
  return {
    for (final extension in const {
      ChordExtension.add9,
      ChordExtension.addSharp9,
      ChordExtension.add11,
      ChordExtension.add13,
    })
      if (available.contains(extension)) extension,
  };
}

Set<ChordExtension> triadLikeAlterations(ChordQualityToken quality) {
  final available = triadLikeExtensions(quality);
  return {
    if (available.contains(ChordExtension.flat9)) ChordExtension.flat9,
    if (available.contains(ChordExtension.sharp11)) ChordExtension.sharp11,
  };
}

Set<ChordExtension> seventhStackExtensions(ChordQualityToken quality) {
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

/// Add-tone choices for seventh-family chords intentionally start above add9.
///
/// In this UI, choosing an added ninth on a seventh chord promotes directly to
/// the stacked ninth.
Set<ChordExtension> seventhAddTones(ChordQualityToken quality) {
  final canonicalIntervals = quality.canonicalIntervals;
  return {
    for (final extension in const {ChordExtension.add11, ChordExtension.add13})
      if (!canonicalIntervals.contains(extension.intervalAboveRoot)) extension,
  };
}

Set<ChordExtension> seventhAlterations(ChordQualityToken quality) {
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

void _replaceWithStackedEleventh(Set<ChordExtension> extensions) {
  extensions.remove(ChordExtension.nine);
  extensions.remove(ChordExtension.add9);
  extensions.remove(ChordExtension.add11);
  extensions.add(ChordExtension.eleven);
}

void _replaceWithStackedThirteenth(Set<ChordExtension> extensions) {
  extensions.remove(ChordExtension.nine);
  extensions.remove(ChordExtension.eleven);
  extensions.remove(ChordExtension.add9);
  extensions.remove(ChordExtension.add11);
  extensions.remove(ChordExtension.add13);
  extensions.add(ChordExtension.thirteen);
}

bool _allowsTriadLikeSharp11(ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.major ||
    ChordQualityToken.minor ||
    ChordQualityToken.minorSharp5 ||
    ChordQualityToken.major6 ||
    ChordQualityToken.minor6 ||
    ChordQualityToken.augmented => true,
    _ => false,
  };
}

bool _allowsTriadLikeAddSharp9(ChordQualityToken quality) {
  return switch (quality) {
    ChordQualityToken.major ||
    ChordQualityToken.major6 ||
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
