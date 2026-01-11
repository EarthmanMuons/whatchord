/// Musical extensions beyond the base chord.
/// Ordering reflects common theory convention.
enum ChordExtension {
  flat9,
  nine,
  sharp9,
  eleven,
  sharp11,
  flat13,
  thirteen,
  add9,
  add11,
  add13,
}

extension ChordExtensionOrdering on ChordExtension {
  /// Stable musical ordering for display/debug purposes.
  ///
  /// Lower comes first.
  int get sortOrder {
    switch (this) {
      case ChordExtension.flat9:
        return 1;
      case ChordExtension.nine:
        return 2;
      case ChordExtension.sharp9:
        return 3;
      case ChordExtension.eleven:
        return 4;
      case ChordExtension.sharp11:
        return 5;
      case ChordExtension.flat13:
        return 6;
      case ChordExtension.thirteen:
        return 7;
      case ChordExtension.add9:
        return 8;
      case ChordExtension.add11:
        return 9;
      case ChordExtension.add13:
        return 10;
    }
  }

  /// Compact string form, useful for debug output and formatters.
  String get label {
    switch (this) {
      case ChordExtension.flat9:
        return 'b9';
      case ChordExtension.nine:
        return '9';
      case ChordExtension.sharp9:
        return '#9';
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
}

extension ChordExtensionSemantics on ChordExtension {
  bool get isAddTone {
    switch (this) {
      case ChordExtension.add9:
      case ChordExtension.add11:
      case ChordExtension.add13:
        return true;
      default:
        return false;
    }
  }

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

typedef ExtensionPreference = ({
  int alterationCount,
  int naturalCount,
  int addCount,
  int totalCount,
});

ExtensionPreference extensionPreference(Set<ChordExtension> exts) {
  var alterationCount = 0;
  var naturalCount = 0;
  var addCount = 0;

  for (final e in exts) {
    if (e.isAddTone) {
      addCount++;
    } else if (e.isAlteration) {
      alterationCount++;
    } else {
      // Natural 9/11/13
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
