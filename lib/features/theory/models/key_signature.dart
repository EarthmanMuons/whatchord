import 'package:meta/meta.dart';

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

  bool get prefersFlats => accidentalCount < 0;
  bool get prefersSharps => accidentalCount > 0;

  static KeySignature fromTonality(Tonality tonality) {
    for (final ks in keySignatureRows) {
      if (tonality.isMajor && ks.relativeMajor == tonality) {
        return ks;
      }
      if (tonality.isMinor && ks.relativeMinor == tonality) {
        return ks;
      }
    }

    // This should never happen, but fail loudly if it does.
    throw StateError('No KeySignature found for tonality $tonality');
  }
}

/// Circle-of-fifths-ish ordering that also includes the "full" 15 signatures:
/// 7 flats ... 0 ... 7 sharps
const keySignatureRows = <KeySignature>[
  KeySignature(
    accidentalCount: -7,
    relativeMajor: Tonality('Cb', TonalityMode.major),
    relativeMinor: Tonality('Ab', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -6,
    relativeMajor: Tonality('Gb', TonalityMode.major),
    relativeMinor: Tonality('Eb', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -5,
    relativeMajor: Tonality('Db', TonalityMode.major),
    relativeMinor: Tonality('Bb', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -4,
    relativeMajor: Tonality('Ab', TonalityMode.major),
    relativeMinor: Tonality('F', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -3,
    relativeMajor: Tonality('Eb', TonalityMode.major),
    relativeMinor: Tonality('C', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -2,
    relativeMajor: Tonality('Bb', TonalityMode.major),
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
    relativeMinor: Tonality('F#', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 4,
    relativeMajor: Tonality('E', TonalityMode.major),
    relativeMinor: Tonality('C#', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 5,
    relativeMajor: Tonality('B', TonalityMode.major),
    relativeMinor: Tonality('G#', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 6,
    relativeMajor: Tonality('F#', TonalityMode.major),
    relativeMinor: Tonality('D#', TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 7,
    relativeMajor: Tonality('C#', TonalityMode.major),
    relativeMinor: Tonality('A#', TonalityMode.minor),
  ),
];
