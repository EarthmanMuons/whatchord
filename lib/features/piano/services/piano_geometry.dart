import 'package:flutter/foundation.dart';

@immutable
class PianoKeyRect {
  /// Horizontal bounds of a rendered piano key in keyboard-local coordinates.
  ///
  /// The coordinate space is defined by the full keyboard width, with `left`
  /// and `right` measured from the keyboard's left edge.
  final double left;
  final double right;
  const PianoKeyRect(this.left, this.right);

  double get width => right - left;
}

@immutable
class PianoGeometry {
  PianoGeometry({required this.firstWhiteMidi, required this.whiteKeyCount})
    : _startPos = _computeStartPos(firstWhiteMidi),
      whiteMidis = _computeWhiteMidis(firstWhiteMidi, whiteKeyCount);

  /// MIDI note number of the first *white* key at index 0.
  final int firstWhiteMidi;

  /// Number of white keys in this keyboard span.
  final int whiteKeyCount;

  /// Precomputed MIDI note numbers for each white key index.
  final List<int> whiteMidis;

  /// Normalized starting position within the 7 white pitch classes.
  final int _startPos;

  /// Visual layout ratios shared by all piano renderers.
  ///
  /// These values define the relative size and placement of black keys with
  /// respect to white keys and must remain consistent across rendering and
  /// interaction logic.
  static const double blackKeyWidthRatio = 0.62;
  static const double blackKeyHeightRatio = 0.62;

  /// Horizontal bias applied to black-key centers, expressed as a fraction of
  /// the white key width.
  static const double smallBlackKeyBiasRatio = 0.10; // C#, D#
  static const double largeBlackKeyBiasRatio = 0.15; // F#, A#

  static const int fullKeyboardWhiteKeyCount = 52;

  static double whiteKeyWidthForViewport({
    required double viewportWidth,
    required int visibleWhiteKeyCount,
  }) {
    return viewportWidth / visibleWhiteKeyCount;
  }

  static int visibleWhiteKeyCountForViewport({
    required double viewportWidth,
    required double minWhiteKeyWidth,
    int minVisibleWhiteKeyCount = 1,
    int maxVisibleWhiteKeyCount = fullKeyboardWhiteKeyCount,
  }) {
    final rawCount = (viewportWidth / minWhiteKeyWidth).floor();
    return rawCount.clamp(minVisibleWhiteKeyCount, maxVisibleWhiteKeyCount);
  }

  // MIDI pitch classes (C=0).
  static const int _pcC = 0;
  static const int _pcD = 2;
  static const int _pcE = 4;
  static const int _pcF = 5;
  static const int _pcG = 7;
  static const int _pcA = 9;
  static const int _pcB = 11;

  static const List<int> _whitePitchClassesInOctave = <int>[
    _pcC,
    _pcD,
    _pcE,
    _pcF,
    _pcG,
    _pcA,
    _pcB,
  ];

  static int _computeStartPos(int firstWhiteMidi) {
    final startPc = firstWhiteMidi % 12;
    final startPos = _whitePitchClassesInOctave.indexOf(startPc);
    return startPos < 0 ? 0 : startPos;
  }

  static List<int> _computeWhiteMidis(int firstWhiteMidi, int whiteKeyCount) {
    final out = <int>[];
    int midi = firstWhiteMidi;

    // Determine which white PC we start on.
    final normalizedStartPos = _computeStartPos(firstWhiteMidi);

    out.add(midi);

    for (int i = 0; i < whiteKeyCount - 1; i++) {
      final pc = _whitePitchClassesInOctave[(normalizedStartPos + i) % 7];
      final step = (pc == _pcE || pc == _pcB) ? 1 : 2; // E->F, B->C
      midi += step;
      out.add(midi);
    }

    return List<int>.unmodifiable(out);
  }

  int whiteMidiForIndex(int whiteIndex) => whiteMidis[whiteIndex];

  /// Returns the pitch class (C=0) of the white key at [whiteIndex].
  int whitePitchClassForIndex(int whiteIndex) {
    return _whitePitchClassesInOctave[(_startPos + whiteIndex) % 7];
  }

  /// Returns whether a black key exists immediately after a given white pitch class.
  ///
  /// Black keys occur after C, D, F, G, and A.
  static bool hasBlackAfterWhitePc(int whitePc) {
    return whitePc == _pcC ||
        whitePc == _pcD ||
        whitePc == _pcF ||
        whitePc == _pcG ||
        whitePc == _pcA;
  }

  /// Returns true if [midi] corresponds to a black key.
  static bool isBlackMidi(int midi) {
    switch (midi % 12) {
      case 1: // C#
      case 3: // D#
      case 6: // F#
      case 8: // G#
      case 10: // A#
        return true;
      default:
        return false;
    }
  }

  /// Returns the horizontal center bias for a black key, based on pitch class.
  ///
  /// The bias is applied relative to the boundary between adjacent white keys.
  static double blackCenterBiasForPc(int blackPc, double whiteKeyWidth) {
    switch (blackPc) {
      case 1: // C#
        return -whiteKeyWidth * smallBlackKeyBiasRatio;
      case 3: // D#
        return whiteKeyWidth * smallBlackKeyBiasRatio;
      case 6: // F#
        return -whiteKeyWidth * largeBlackKeyBiasRatio;
      case 10: // A#
        return whiteKeyWidth * largeBlackKeyBiasRatio;
      case 8: // G#
      default:
        return 0.0;
    }
  }

  /// Returns the horizontal bounds of the rendered key for [midi].
  ///
  /// The returned rectangle is expressed in the coordinate space of the full
  /// keyboard span represented by this geometry instance.
  ///
  /// - White keys occupy exactly one [whiteKeyWidth] at their corresponding index.
  /// - Black keys use a reduced width and pitch-class–specific center bias.
  ///
  /// Callers must ensure that [whiteKeyWidth] and [totalWidth] are derived from the
  /// same keyboard span.
  PianoKeyRect keyRectForMidi({
    required int midi,
    required double whiteKeyWidth,
    required double totalWidth,
  }) {
    // Exact white-key match.
    final exactWhite = whiteMidis.indexOf(midi);
    if (exactWhite >= 0) {
      final l = exactWhite * whiteKeyWidth;
      return PianoKeyRect(l, l + whiteKeyWidth);
    }

    final blackW = whiteKeyWidth * blackKeyWidthRatio;

    // Identify the white key preceding this black key.
    int? whiteIndex;
    for (int i = 0; i < whiteMidis.length - 1; i++) {
      if (whiteMidis[i] + 1 != midi) continue;

      final whitePc = whitePitchClassForIndex(i);
      if (!hasBlackAfterWhitePc(whitePc)) break;

      whiteIndex = i;
      break;
    }

    // Fallback: treat as preceding white key.
    if (whiteIndex == null) {
      final idx = whiteIndexForMidi(midi);
      final l = idx * whiteKeyWidth;
      return PianoKeyRect(l, l + whiteKeyWidth);
    }

    final boundaryX = (whiteIndex + 1) * whiteKeyWidth;
    final blackPc = midi % 12;
    final centerX = boundaryX + blackCenterBiasForPc(blackPc, whiteKeyWidth);

    double left = centerX - (blackW / 2.0);
    left = left.clamp(0.0, totalWidth - blackW);
    return PianoKeyRect(left, left + blackW);
  }

  int whiteIndexForMidi(int midi) {
    // Exact match (common for middle C).
    final exact = whiteMidis.indexOf(midi);
    if (exact >= 0) return exact;

    // Map black notes to the preceding white key index.
    int idx = 0;
    for (int i = 0; i < whiteMidis.length; i++) {
      if (whiteMidis[i] <= midi) idx = i;
      if (whiteMidis[i] > midi) break;
    }
    return idx.clamp(0, whiteMidis.length - 1);
  }
}
