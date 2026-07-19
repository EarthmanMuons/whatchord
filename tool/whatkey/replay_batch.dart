// Replays recorded sounding-set streams through the real Phase 1 capture
// path for WhatKey fixture generation (research/whatkey/).
//
// Reads JSON-lines requests on stdin, one piece per line:
//   {"id": "...", "context": "C:maj", "segmenterMinMs": 200,
//    "snapshots": [{"timestampMs": 0, "midiNotes": [60, 64, 67]}, ...]}
// where each snapshot is the pedal-aware sounding set after a change, and
// writes one JSON line per piece with the committed ChordEvents in the
// fixture event schema (without labels; the caller attaches those).
// segmenterMinMs is optional (default 200, the app's live value); it exists
// for the stacked-filter experiments, and any adopted change must ship in
// the app's segmenter default too.
//
// This is the same pipeline the app runs live: the analyzer with voicing
// evidence, capture gating at fewer than three notes, and the actual
// ChordEventSegmenter (pending-challenger debounce, minimum duration), so
// fixtures built here reflect real capture behavior on performed input,
// finger rolls and pedal blur included.

import 'dart:convert';
import 'dart:io';

import 'package:whatchord/whatchord.dart';

import '../src/chord_id_engine.dart';

final _analyzer = ChordAnalyzer();

void main() {
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.trim().isEmpty) return;

    final request = jsonDecode(line) as Map<String, dynamic>;
    final tonality = parseTonality(request['context'] as String);
    final keySignature = KeySignature.fromTonality(tonality);
    final context = AnalysisContext(
      tonality: tonality,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    );

    final segmenter = ChordEventSegmenter(
      minChordDuration: Duration(
        milliseconds: (request['segmenterMinMs'] as int?) ?? 200,
      ),
    );
    final events = <ChordEvent>[];
    var lastMs = 0;
    for (final raw in (request['snapshots'] as List).cast<Map>()) {
      final snapshot = raw.cast<String, dynamic>();
      lastMs = snapshot['timestampMs'] as int;
      final now = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final midiNotes = (snapshot['midiNotes'] as List).cast<int>()..sort();
      events.addAll(segmenter.onFrame(_frame(midiNotes, context), now));
    }
    events.addAll(
      segmenter.flush(DateTime.fromMillisecondsSinceEpoch(lastMs + 1)),
    );

    stdout.writeln(
      jsonEncode(<String, Object?>{
        'id': request['id'],
        'events': [
          for (var index = 0; index < events.length; index++)
            _eventJson(index, events[index]),
        ],
      }),
    );
  });
}

/// Mirrors `_captureFrameProvider`: null below three sounding notes, else the
/// analyzed chord with its surfaced near-tie alternatives.
CaptureFrame? _frame(List<int> midiNotes, AnalysisContext context) {
  if (midiNotes.length < 3) return null;

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
  final ranked = _analyzer.analyze(input, context: context, voicing: voicing);
  if (ranked.isEmpty) return null;

  return CaptureFrame(
    input: input,
    voicing: voicing,
    candidates: [ranked.first, ...ChordCandidateRanking.alternatives(ranked)],
    tonality: context.tonality,
  );
}

Map<String, Object?> _eventJson(int index, ChordEvent event) => {
  'index': index,
  'timestampMs': event.timestamp.millisecondsSinceEpoch,
  'durationMs': event.duration.inMilliseconds,
  'midiNotes': event.voicing.midiNotes,
  'pcMask': event.input.pcMask,
  'bassPc': event.input.bassPc,
  'noteCount': event.input.noteCount,
  'candidates': [
    for (final candidate in event.candidates)
      <String, Object?>{
        'rootPc': candidate.identity.rootPc,
        'bassPc': candidate.identity.bassPc,
        'quality': candidate.identity.quality.name,
        'extensions': [
          for (final extension in candidate.identity.extensions) extension.name,
        ],
        'presentIntervalsMask': candidate.identity.presentIntervalsMask,
        'cost': candidate.cost,
      },
  ],
};
