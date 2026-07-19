/// Feed a chord progression through the whatchord engine into the WhatKey
/// detector: watch it abstain while evidence is thin, converge on the key,
/// and follow a modulation.
///
/// Run with: dart run example/example.dart
library;

import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

final _analyzer = ChordAnalyzer();

void main() {
  // The KeyBehavior presets package the research-tuned timescales; balanced
  // follows section-scale key changes within a few chords.
  final behavior = KeyBehavior.balanced;
  final detector = HmmKeyDetector(decayHalfLife: behavior.emissionHalfLife);

  // I vi IV V7 I in C major, then a ii-V-I modulation to Eb major.
  final progression = [
    ['C', 'E', 'G'],
    ['A', 'C', 'E'],
    ['F', 'A', 'C'],
    ['G', 'B', 'D', 'F'],
    ['C', 'E', 'G'],
    ['F', 'Ab', 'C', 'Eb'],
    ['Bb', 'D', 'F', 'Ab'],
    ['Eb', 'G', 'Bb'],
    ['Ab', 'C', 'Eb'],
    ['Eb', 'G', 'Bb'],
  ];

  detector.reset();
  for (var i = 0; i < progression.length; i++) {
    final event = eventFromNames(index: i, names: progression[i]);
    final frame = detector.onEvent(event);
    final chord = symbolFor(event);
    print('${chord.padRight(5)} -> ${describe(frame, behavior)}');
  }
}

const _context = Tonality(Tonic.c, TonalityMode.major);

/// Builds a committed [ChordEvent] by running the notes through the actual
/// chord recognizer, exactly as the app's capture pipeline does.
ChordEvent eventFromNames({required int index, required List<String> names}) {
  final pcs = [for (final name in names) pitchClassFromNoteName(name)];
  var mask = 0;
  for (final pc in pcs) {
    mask |= 1 << pc;
  }

  final input = ChordInput(
    pcMask: mask,
    bassPc: pcs.first,
    noteCount: pcs.length,
  );
  final voicing = ObservedVoicing.fromMidi([
    48 + pcs.first,
    for (final pc in pcs.skip(1)) 60 + pc,
  ]);
  final keySignature = KeySignature.fromTonality(_context);
  final candidates = _analyzer.analyze(
    input,
    context: AnalysisContext(
      tonality: _context,
      keySignature: keySignature,
      spellingPolicy: NoteSpellingPolicy(
        preferFlats: keySignature.prefersFlats,
      ),
    ),
    voicing: voicing,
  );

  return ChordEvent(
    timestamp: DateTime.fromMillisecondsSinceEpoch(index * 2000),
    input: input,
    voicing: voicing,
    candidates: candidates,
    tonality: _context,
    duration: const Duration(seconds: 2),
  );
}

/// The recognized chord symbol for [event]'s top candidate.
String symbolFor(ChordEvent event) {
  return ChordSymbolBuilder.formatIdentity(
    identity: event.candidates.first.identity,
    tonality: event.tonality,
    notation: ChordNotationStyle.textual,
  );
}

/// One line describing [frame]: the claimed key with its calibrated display
/// confidence, or the abstention.
String describe(KeyEstimateFrame frame, KeyBehavior behavior) {
  final claim = frame.claim;
  if (claim == null) return 'abstains (not enough evidence)';

  final displayed = DisplayCalibration.calibrate(
    frame.ranked,
    temperature: behavior.displayTemperature,
  );
  final confidence = (displayed.first.confidence * 100).toStringAsFixed(0);
  return 'claims ${claim.tonality.displayName} ($confidence% shown)';
}
