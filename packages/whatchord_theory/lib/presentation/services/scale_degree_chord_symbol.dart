import 'package:whatchord_theory/whatchord_theory.dart';

/// The display chord symbol for one diatonic scale degree, honoring the 7ths
/// toggle. Shared by the degree list and the scale copy menu so both spell the
/// same chord identically.
String scaleDegreeChordSymbol({
  required ScaleDegreeHarmony degree,
  required bool showSevenths,
  required Tonality tonality,
  required ChordNotationStyle notation,
  required NoteNameSystem noteNameSystem,
}) {
  final quality = showSevenths ? degree.seventhQuality : degree.triadQuality;
  final identity = ChordIdentity(
    rootPc: degree.rootPc,
    bassPc: degree.rootPc,
    quality: quality,
    presentIntervalsMask: quality.canonicalMask,
  );
  final symbol = ChordSymbolBuilder.fromIdentity(
    identity: identity,
    tonality: tonality,
    notation: notation,
    rootName: degree.rootName,
  );
  return chordSymbolDisplayParts(
    symbol,
    noteNameSystem: noteNameSystem,
  ).toString();
}
