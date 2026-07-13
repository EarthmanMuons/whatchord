import 'package:whatchord/features/theory/theory.dart';

const defaultTestTonality = Tonality(Tonic.c, TonalityMode.major);

/// Builds an [AnalysisContext] from a tonality, deriving key signature and
/// default spelling policy the same way production analysis does.
AnalysisContext makeAnalysisContext({
  Tonality tonality = defaultTestTonality,
  NoteSpellingPolicy? spellingPolicy,
}) {
  final keySignature = KeySignature.fromTonality(tonality);
  final policy =
      spellingPolicy ??
      NoteSpellingPolicy(preferFlats: keySignature.prefersFlats);

  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: policy,
  );
}

int pc(String name) => pitchClassFromNoteName(name);

int maskOf(Iterable<int> pcs) {
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << (pc % 12);
  }
  return mask;
}

int maskOfNames(Iterable<String> names) => maskOf(names.map(pc));

ChordInput chordInputFromNames({
  required Iterable<String> names,
  String? bass,
  int? noteCount,
}) {
  final noteNames = names.toList(growable: false);

  return ChordInput(
    pcMask: maskOfNames(noteNames),
    bassPc: pc(bass ?? noteNames.first),
    noteCount: noteCount ?? noteNames.length,
  );
}
