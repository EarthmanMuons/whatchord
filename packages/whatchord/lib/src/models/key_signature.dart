import 'package:meta/meta.dart';

import 'tonality.dart';
import 'tonic.dart';

/// A key signature and the relative major/minor pair it belongs to.
@immutable
class KeySignature {
  /// Negative = flats, positive = sharps. e.g. -2 means 2 flats, +3 means 3 sharps.
  final int accidentalCount;

  /// The major key with this signature.
  final Tonality relativeMajor;

  /// The minor key with this signature.
  final Tonality relativeMinor;

  const KeySignature({
    required this.accidentalCount,
    required this.relativeMajor,
    required this.relativeMinor,
  });

  /// Alias that matches common theory naming: circle-of-fifths index.
  int get fifths => accidentalCount;

  /// Human-readable accidental count (e.g. "2 flats", "1 sharp").
  String get label {
    if (accidentalCount == 0) return 'no sharps/flats';
    final n = accidentalCount.abs();
    final countText = n == 1 ? '1' : '$n';
    return accidentalCount > 0
        ? '$countText sharp${n == 1 ? '' : 's'}'
        : '$countText flat${n == 1 ? '' : 's'}';
  }

  /// Whether this signature spells accidentals as flats.
  bool get prefersFlats => accidentalCount < 0;

  /// Whether this signature spells accidentals as sharps.
  bool get prefersSharps => accidentalCount > 0;

  /// The signature for [tonality]; throws for tonalities without a
  /// conventional key signature.
  static KeySignature fromTonality(Tonality tonality) {
    for (final ks in keySignatures) {
      if (tonality.isMajor && ks.relativeMajor == tonality) {
        return ks;
      }
      if (tonality.isMinor && ks.relativeMinor == tonality) {
        return ks;
      }
    }
    throw StateError('No KeySignature found for tonality $tonality');
  }
}

/// Convenient, non-cyclic access: Tonality -> KeySignature.
extension TonalityKeySignature on Tonality {
  /// The key signature for this tonality.
  KeySignature get keySignature => KeySignature.fromTonality(this);
}

/// Circle-of-fifths-ish ordering that also includes the "full" 15 signatures:
/// 7 flats ... 0 ... 7 sharps
const keySignatures = <KeySignature>[
  KeySignature(
    accidentalCount: -7,
    relativeMajor: Tonality(Tonic.cFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.aFlat, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -6,
    relativeMajor: Tonality(Tonic.gFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.eFlat, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -5,
    relativeMajor: Tonality(Tonic.dFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.bFlat, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -4,
    relativeMajor: Tonality(Tonic.aFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.f, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -3,
    relativeMajor: Tonality(Tonic.eFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.c, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -2,
    relativeMajor: Tonality(Tonic.bFlat, TonalityMode.major),
    relativeMinor: Tonality(Tonic.g, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: -1,
    relativeMajor: Tonality(Tonic.f, TonalityMode.major),
    relativeMinor: Tonality(Tonic.d, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 0,
    relativeMajor: Tonality(Tonic.c, TonalityMode.major),
    relativeMinor: Tonality(Tonic.a, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 1,
    relativeMajor: Tonality(Tonic.g, TonalityMode.major),
    relativeMinor: Tonality(Tonic.e, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 2,
    relativeMajor: Tonality(Tonic.d, TonalityMode.major),
    relativeMinor: Tonality(Tonic.b, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 3,
    relativeMajor: Tonality(Tonic.a, TonalityMode.major),
    relativeMinor: Tonality(Tonic.fSharp, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 4,
    relativeMajor: Tonality(Tonic.e, TonalityMode.major),
    relativeMinor: Tonality(Tonic.cSharp, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 5,
    relativeMajor: Tonality(Tonic.b, TonalityMode.major),
    relativeMinor: Tonality(Tonic.gSharp, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 6,
    relativeMajor: Tonality(Tonic.fSharp, TonalityMode.major),
    relativeMinor: Tonality(Tonic.dSharp, TonalityMode.minor),
  ),
  KeySignature(
    accidentalCount: 7,
    relativeMajor: Tonality(Tonic.cSharp, TonalityMode.major),
    relativeMinor: Tonality(Tonic.aSharp, TonalityMode.minor),
  ),
];
