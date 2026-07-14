# whatchord

The pure Dart chord identification and harmony analysis engine behind
[WhatChord](https://whatchord.earthmanmuons.com/). No Flutter dependencies; the
only runtime dependency is `package:meta`.

The engine optimizes for musician-expected naming: given an observed voicing, it
prefers the stable, conventional reading over simple note-matching, surfaces the
plausible alternatives instead of hiding ambiguity, and can explain why the
winner ranked first.

## Features

- **Chord identification.** `ChordAnalyzer.analyze()` takes a `ChordInput` (a
  set of pitch classes plus the bass) and an `AnalysisContext` (key and spelling
  policy) and returns ranked `ChordCandidate` results, memoized in a 512-entry
  LRU cache.
- **Alternatives and explanations.** `ChordCandidateRanking.alternatives()`
  picks out the readings priced close to the winner, and
  `ChordAnalyzer.explain()` returns each candidate's cost breakdown along with
  the rule that ordered it against its neighbor.
- **Chord construction.** The inverse question: given a selected root, quality,
  extensions, and bass, `ChordExampleBuilder` derives a canonical example
  voicing, and the option services report which extensions and bass notes are
  compatible with the current selection.
- **Formatting.** Renders chord identities as symbols (textual or traditional
  symbolic notation), spoken names, long-form academic names, and Harte
  notation.
- **Notes, scales, and degrees.** Context-aware enharmonic note spelling, chord
  quality intervals, scale harmonization, Roman numeral degree classification,
  and scale voicings.
- **Temporal context.** `ChordEvent` (a committed chord from live play) and
  `ChordEventSegmenter` turn a stream of analyses into discrete events; these
  feed the [whatkey][WHATKEY] key detectors.

[WHATKEY]: https://github.com/EarthmanMuons/whatchord/tree/main/packages/whatkey

## Getting started

The package requires Dart SDK 3.8 or later and runs anywhere Dart runs (VM,
Flutter, web). It is developed in the [WhatChord monorepo][REPO] and consumed by
the app through the repository's pub workspace; it is not yet published to
pub.dev.

[REPO]: https://github.com/EarthmanMuons/whatchord

## Usage

```dart
import 'package:whatchord/whatchord.dart';

void main() {
  const tonality = Tonality(Tonic.c, TonalityMode.major);
  final keySignature = KeySignature.fromTonality(tonality);
  final context = AnalysisContext(
    tonality: tonality,
    keySignature: keySignature,
    spellingPolicy: NoteSpellingPolicy(preferFlats: keySignature.prefersFlats),
  );

  // C E G A reads as C6 or as Am7 over C; the engine weighs both.
  final pcs = [for (final n in ['C', 'E', 'G', 'A']) pitchClassFromNoteName(n)];
  final input = ChordInput(
    pcMask: pcs.fold(0, (mask, pc) => mask | 1 << pc),
    bassPc: pcs.first,
    noteCount: pcs.length,
  );

  final candidates = ChordAnalyzer.analyze(input, context: context);
  final symbol = ChordSymbolBuilder.formatIdentity(
    identity: candidates.first.identity,
    tonality: tonality,
    notation: ChordNotationStyle.textual,
  );
  print(symbol); // C6
}
```

The [example](example/example.dart) is a fuller tour: presentation formatting,
alternatives, ranking explanations, chord construction from a spec, and scale
harmonization.

Two secondary libraries ship alongside the main one:

- `package:whatchord/testing.dart` provides factories for analysis contexts and
  chord inputs, for use in downstream tests.
- `package:whatchord/diagnostics.dart` exposes engine instrumentation counters
  for benchmarks and performance analysis.

## Design notes

Analysis and construction answer different questions and are tuned differently:
analysis names an observed voicing the way a musician would expect, while
construction produces canonical, clean examples of a selected chord symbol. The
ranking is cost-based; hard preference rules are kept to a minimum and each
surviving rule is documented in the explanation traces.

## Additional information

The package follows [Semantic Versioning](https://semver.org/); while the
version is below 1.0.0, minor releases may include breaking API changes (see the
[changelog](CHANGELOG.md)).

If you believe a chord has been identified incorrectly, please [open an
issue][ISSUE]. When possible, include the notes played, the key signature, and
the chord reported versus the expected result.

[ISSUE]: https://github.com/EarthmanMuons/whatchord/issues/new/choose

## License

This package is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2025&ndash;2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
