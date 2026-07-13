/// Musical extensions beyond the base chord.
/// Ordering reflects common theory convention.
enum ChordExtension {
  flat9,
  nine,
  sharp9,
  addSharp9,
  eleven,
  sharp11,
  flat13,
  thirteen,
  add9,
  add11,
  add13,
  addFlat9,
}

/// Display ordering for [ChordExtension].
extension ChordExtensionOrdering on ChordExtension {
  /// Stable musical ordering for display/debug purposes.
  ///
  /// Lower comes first.
  int get sortOrder {
    switch (this) {
      case ChordExtension.flat9:
        return 1;
      case ChordExtension.addFlat9:
        return 2;
      case ChordExtension.nine:
        return 3;
      case ChordExtension.sharp9:
        return 4;
      case ChordExtension.addSharp9:
        return 5;
      case ChordExtension.eleven:
        return 6;
      case ChordExtension.sharp11:
        return 7;
      case ChordExtension.flat13:
        return 8;
      case ChordExtension.thirteen:
        return 9;
      case ChordExtension.add9:
        return 10;
      case ChordExtension.add11:
        return 11;
      case ChordExtension.add13:
        return 12;
    }
  }
}

/// Rendered labels for [ChordExtension] in each naming style.
extension ChordExtensionLabels on ChordExtension {
  /// Compact token for symbolic/textual chord formatters.
  String get shortLabel {
    switch (this) {
      case ChordExtension.flat9:
        return 'b9';
      case ChordExtension.addFlat9:
        return 'addb9';
      case ChordExtension.nine:
        return '9';
      case ChordExtension.sharp9:
        return '#9';
      case ChordExtension.addSharp9:
        return 'add#9';
      case ChordExtension.eleven:
        return '11';
      case ChordExtension.sharp11:
        return '#11';
      case ChordExtension.flat13:
        return 'b13';
      case ChordExtension.thirteen:
        return '13';
      case ChordExtension.add9:
        return 'add9';
      case ChordExtension.add11:
        return 'add11';
      case ChordExtension.add13:
        return 'add13';
    }
  }

  /// Idiomatic spoken form used in the spoken name formatter.
  String get spokenLabel {
    switch (this) {
      case ChordExtension.flat9:
        return 'flat nine';
      case ChordExtension.addFlat9:
        return 'add flat nine';
      case ChordExtension.nine:
        return 'nine';
      case ChordExtension.sharp9:
        return 'sharp nine';
      case ChordExtension.addSharp9:
        return 'add sharp nine';
      case ChordExtension.eleven:
        return 'eleven';
      case ChordExtension.sharp11:
        return 'sharp eleven';
      case ChordExtension.flat13:
        return 'flat thirteen';
      case ChordExtension.thirteen:
        return 'thirteen';
      case ChordExtension.add9:
        return 'add nine';
      case ChordExtension.add11:
        return 'add eleven';
      case ChordExtension.add13:
        return 'add thirteen';
    }
  }

  /// Plain-English token used in the long-press explanation.
  String get longLabel {
    switch (this) {
      case ChordExtension.flat9:
        return 'flat nine';
      case ChordExtension.addFlat9:
        return 'added flat nine';
      case ChordExtension.nine:
        return 'nine';
      case ChordExtension.sharp9:
        return 'sharp nine';
      case ChordExtension.addSharp9:
        return 'added sharp nine';
      case ChordExtension.eleven:
        return 'eleven';
      case ChordExtension.sharp11:
        return 'sharp eleven';
      case ChordExtension.flat13:
        return 'flat thirteen';
      case ChordExtension.thirteen:
        return 'thirteen';
      case ChordExtension.add9:
        return 'added nine';
      case ChordExtension.add11:
        return 'added eleven';
      case ChordExtension.add13:
        return 'added thirteen';
    }
  }
}

/// Classification predicates over [ChordExtension].
extension ChordExtensionSemantics on ChordExtension {
  /// Whether this is an added tone (add9, add11, ...) rather than a stacked
  /// extension or alteration.
  bool get isAddTone {
    switch (this) {
      case ChordExtension.add9:
      case ChordExtension.addFlat9:
      case ChordExtension.addSharp9:
      case ChordExtension.add11:
      case ChordExtension.add13:
        return true;
      default:
        return false;
    }
  }

  /// Whether this is an unaltered stacked extension (9, 11, or 13).
  bool get isNaturalExtension {
    switch (this) {
      case ChordExtension.nine:
      case ChordExtension.eleven:
      case ChordExtension.thirteen:
        return true;
      default:
        return false;
    }
  }

  /// Whether this is a chromatically altered color (b9, #9, #11, b13).
  bool get isAlteration {
    switch (this) {
      case ChordExtension.flat9:
      case ChordExtension.sharp9:
      case ChordExtension.sharp11:
      case ChordExtension.flat13:
        return true;
      default:
        return false;
    }
  }

  /// "Real" meaning: natural extensions and alterations (everything that is not addX).
  bool get isRealExtension => !isAddTone;
}

/// Counts of an extension set by classification, used to compare readings.
typedef ExtensionPreference = ({
  int alterationCount,
  int naturalCount,
  int addCount,
  int totalCount,
});

/// Tallies [exts] into an [ExtensionPreference].
///
/// [sharp11AsNaturalColor] reclassifies a raised eleventh as a natural
/// (stacked) extension instead of an alteration. Callers set it for qualities
/// where the #11 is the Lydian color rather than a tension (see
/// `ChordQualityToken.sharp11IsNaturalColor`).
ExtensionPreference extensionPreference(
  Set<ChordExtension> exts, {
  bool sharp11AsNaturalColor = false,
}) {
  var alterationCount = 0;
  var naturalCount = 0;
  var addCount = 0;

  for (final e in exts) {
    if (e.isAddTone) {
      addCount++;
    } else if (e.isAlteration &&
        !(sharp11AsNaturalColor && e == ChordExtension.sharp11)) {
      alterationCount++;
    } else {
      // Natural 9/11/13, plus a Lydian #11 when the caller opts in.
      naturalCount++;
    }
  }

  return (
    alterationCount: alterationCount,
    naturalCount: naturalCount,
    addCount: addCount,
    totalCount: exts.length,
  );
}

/// Pitch mapping for [ChordExtension].
extension ChordExtensionInterval on ChordExtension {
  /// Semitone interval above the chord root that this extension represents (0..11).
  ///
  /// Note: addX uses the same pitch-class as X; the distinction is not pitch,
  /// but functional/notation intent.
  int get intervalAboveRoot {
    switch (this) {
      case ChordExtension.flat9:
      case ChordExtension.addFlat9:
        return 1;
      case ChordExtension.nine:
      case ChordExtension.add9:
        return 2;
      case ChordExtension.sharp9:
      case ChordExtension.addSharp9:
        return 3;
      case ChordExtension.eleven:
      case ChordExtension.add11:
        return 5;
      case ChordExtension.sharp11:
        return 6;
      case ChordExtension.flat13:
        return 8;
      case ChordExtension.thirteen:
      case ChordExtension.add13:
        return 9;
    }
  }

  /// [intervalAboveRoot] as a bit in a 12-bit interval mask.
  int get intervalBit => 1 << intervalAboveRoot;
}
