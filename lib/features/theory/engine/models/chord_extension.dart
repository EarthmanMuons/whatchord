/// Musical extensions beyond the base chord.
/// Ordering reflects common lead-sheet / theory convention.
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
