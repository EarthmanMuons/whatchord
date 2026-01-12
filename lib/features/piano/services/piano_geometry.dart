import 'package:flutter/foundation.dart';

@immutable
class PianoGeometry {
  PianoGeometry({required this.firstWhiteMidi, required this.whiteKeyCount})
    : whiteMidis = _computeWhiteMidis(firstWhiteMidi, whiteKeyCount);

  /// MIDI note number of the first *white* key at index 0.
  final int firstWhiteMidi;

  /// Number of white keys in this keyboard span.
  final int whiteKeyCount;

  /// Precomputed MIDI note numbers for each white key index.
  final List<int> whiteMidis;

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

  static List<int> _computeWhiteMidis(int firstWhiteMidi, int whiteKeyCount) {
    final out = <int>[];
    int midi = firstWhiteMidi;

    // Determine which white PC we start on.
    final startPc = firstWhiteMidi % 12;
    final startPos = _whitePitchClassesInOctave.indexOf(startPc);
    final normalizedStartPos = startPos < 0 ? 0 : startPos;

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
