import 'package:flutter/foundation.dart';

import 'tonality.dart';

@immutable
class KeySignature {
  /// Negative = flats, positive = sharps. e.g. -2 means 2 flats, +3 means 3 sharps.
  final int accidentalCount;
  final Tonality relativeMajor;
  final Tonality relativeMinor;

  const KeySignature({
    required this.accidentalCount,
    required this.relativeMajor,
    required this.relativeMinor,
  });

  String get label {
    if (accidentalCount == 0) return 'no sharps/flats';
    final n = accidentalCount.abs();
    final countText = n == 1 ? '1' : '$n';
    return accidentalCount > 0
        ? '$countText sharp${n == 1 ? '' : 's'}'
        : '$countText flat${n == 1 ? '' : 's'}';
  }
}

/// Circle-of-fifths-ish ordering that also includes the "full" 15 signatures:
/// 7 flats ... 0 ... 7 sharps
const keySignatureRows = <KeySignature>[
  KeySignature(
    accidentalCount: -7,
    relativeMajor: Tonality('C♭', TonalityMode.major),
    relativeMinor: Tonality('A♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -6,
    relativeMajor: Tonality('G♭', TonalityMode.major),
    relativeMinor: Tonality('E♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -5,
    relativeMajor: Tonality('D♭', TonalityMode.major),
    relativeMinor: Tonality('B♭', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -4,
    relativeMajor: Tonality('A♭', TonalityMode.major),
    relativeMinor: Tonality('F', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -3,
    relativeMajor: Tonality('E♭', TonalityMode.major),
    relativeMinor: Tonality('C', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -2,
    relativeMajor: Tonality('B♭', TonalityMode.major),
    relativeMinor: Tonality('G', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -1,
    relativeMajor: Tonality('F', TonalityMode.major),
    relativeMinor: Tonality('D', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 0,
    relativeMajor: Tonality('C', TonalityMode.major),
    relativeMinor: Tonality('A', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 1,
    relativeMajor: Tonality('G', TonalityMode.major),
    relativeMinor: Tonality('E', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 2,
    relativeMajor: Tonality('D', TonalityMode.major),
    relativeMinor: Tonality('B', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 3,
    relativeMajor: Tonality('A', TonalityMode.major),
    relativeMinor: Tonality('F♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 4,
    relativeMajor: Tonality('E', TonalityMode.major),
    relativeMinor: Tonality('C♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 5,
    relativeMajor: Tonality('B', TonalityMode.major),
    relativeMinor: Tonality('G♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 6,
    relativeMajor: Tonality('F♯', TonalityMode.major),
    relativeMinor: Tonality('D♯', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 7,
    relativeMajor: Tonality('C♯', TonalityMode.major),
    relativeMinor: Tonality('A♯', TonalityMode.minor),
  ),
];
