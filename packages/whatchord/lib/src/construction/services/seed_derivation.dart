import '../../models/chord_identity.dart';
import '../../models/chord_input.dart';
import '../../models/tonality.dart';
import '../models/chord_construction.dart';
import 'construction_derivation.dart';

ChordIdentity buildSeedIdentity({
  required ChordInput? input,
  required Tonality tonality,
  ChordIdentity? currentChordIdentity,
}) {
  if (currentChordIdentity != null) return currentChordIdentity;

  if (input == null || input.noteCount == 0) {
    return _seedIdentity(
      rootPc: tonality.tonicPitchClass,
      quality: _defaultQualityForTonality(tonality),
    );
  }

  final rootPc = input.bassPc;
  final quality = switch (input.noteCount) {
    1 => _defaultQualityForTonality(tonality),
    2 => _qualityForDyad(input, tonality),
    _ => _defaultQualityForTonality(tonality),
  };

  return _seedIdentity(rootPc: rootPc, quality: quality);
}

ChordQualityToken _defaultQualityForTonality(Tonality tonality) {
  return tonality.isMinor ? ChordQualityToken.minor : ChordQualityToken.major;
}

ChordQualityToken _qualityForDyad(ChordInput input, Tonality tonality) {
  final upperInterval = _upperIntervalFromBass(input);

  return switch (upperInterval) {
    2 => ChordQualityToken.sus2,
    3 => ChordQualityToken.minor,
    4 => ChordQualityToken.major,
    5 => ChordQualityToken.sus4,
    6 => ChordQualityToken.diminished,
    _ => _defaultQualityForTonality(tonality),
  };
}

int? _upperIntervalFromBass(ChordInput input) {
  for (var interval = 1; interval < 12; interval++) {
    final pc = (input.bassPc + interval) % 12;
    if ((input.pcMask & (1 << pc)) != 0) return interval;
  }
  return null;
}

ChordIdentity _seedIdentity({
  required int rootPc,
  required ChordQualityToken quality,
}) {
  return buildConstructionIdentity(
    ChordConstruction(
      rootPc: rootPc,
      bassPc: rootPc,
      quality: quality,
      extensions: const {},
    ),
  );
}
