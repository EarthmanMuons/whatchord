import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';

/// The benchmark workload: every reviewed-oracle voicing, decoded straight from
/// the case keys. A key like `0-4-7-10_b0` means pitch classes {0,4,7,10} with
/// bass pitch class 0. Reusing this corpus ties the benchmark to real, vetted
/// voicings and grows automatically as more oracle cases are reviewed.
List<ChordInput> loadCorpus({String path = 'tool/chord/oracle_reviewed.json'}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Corpus not found at "$path"; run the benchmark from the repo root.',
    );
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json.keys.map(_parseKey).toList(growable: false);
}

ChordInput _parseKey(String key) {
  final parts = key.split('_b');
  final pcs = parts[0].split('-').map(int.parse);
  final bassPc = int.parse(parts[1]);

  var pcMask = 0;
  var noteCount = 0;
  for (final pc in pcs) {
    pcMask |= 1 << pc;
    noteCount++;
  }
  return ChordInput(pcMask: pcMask, bassPc: bassPc, noteCount: noteCount);
}

/// A fixed neutral analysis context (C major). Spelling/tonality bias the
/// ranking tie-breakers, not the bulk of the work, so one stable context keeps
/// the workload reproducible.
AnalysisContext buildContext() {
  final tonic = Tonic.tryFromLabel('C')!;
  final tonality = Tonality(tonic, TonalityMode.major);
  final keySignature = KeySignature.fromTonality(tonality);
  return AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );
}
