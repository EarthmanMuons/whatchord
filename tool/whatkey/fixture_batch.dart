// Engine driver for WhatKey fixture generation (research/whatkey/).
//
// Reads JSON-lines requests on stdin, one chord event per line:
//   {"id": "...", "midiNotes": [48, 60, 64, 67], "context": "C:maj"}
// and writes one JSON line per request with the engine's ranked candidates.
//
// This mirrors the app's live capture path (`_captureFrameProvider` in
// features/history): the analyzer runs with voicing evidence and default
// pruning, and the emitted list is the chosen candidate plus its surfaced
// near-tie alternatives, so fixture events carry exactly what a recorded
// `ChordEvent` would.

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';

import '../src/chord_id_engine.dart';

void main() {
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.trim().isEmpty) return;

    final request = jsonDecode(line) as Map<String, dynamic>;
    final midiNotes = (request['midiNotes'] as List).cast<int>()..sort();
    final tonality = parseTonality(request['context'] as String);
    final keySignature = KeySignature.fromTonality(tonality);
    final context = AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );

    var pcMask = 0;
    for (final note in midiNotes) {
      pcMask |= 1 << (note % 12);
    }
    final input = ChordInput(
      pcMask: pcMask,
      bassPc: midiNotes.first % 12,
      noteCount: midiNotes.length,
    );
    final voicing = ObservedVoicing.fromMidi(midiNotes);

    final ranked = ChordAnalyzer.analyze(
      input,
      context: context,
      voicing: voicing,
    );
    final alternativeCount = ChordCandidateRanking.alternativeCount(ranked);

    stdout.writeln(
      jsonEncode(<String, Object?>{
        'id': request['id'],
        'candidates': [
          for (var i = 0; i <= alternativeCount && i < ranked.length; i++)
            <String, Object?>{
              'rootPc': ranked[i].identity.rootPc,
              'bassPc': ranked[i].identity.bassPc,
              'quality': ranked[i].identity.quality.name,
              'extensions': [
                for (final extension in ranked[i].identity.extensions)
                  extension.name,
              ],
              'presentIntervalsMask': ranked[i].identity.presentIntervalsMask,
              'cost': ranked[i].cost,
            },
        ],
      }),
    );
  });
}
