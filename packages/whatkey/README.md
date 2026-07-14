# whatkey

Streaming key (tonal center) detection for
[WhatChord](https://whatchord.earthmanmuons.com/). Pure Dart; consumes chord
evidence from the [whatchord][WHATCHORD] engine.

The shipped detector is a compact hidden Markov model run strictly forward in
time: it keeps a posterior over the 24 major and minor keys, updates it from
committed `ChordEvent`s, and abstains when the leading candidates are too close.
When the evidence is ambiguous, it waits instead of guessing.

[WHATCHORD]:
  https://github.com/EarthmanMuons/whatchord/tree/main/packages/whatchord

## Features

- **HMM key detector.** `HmmKeyDetector` is the production detector: chord
  evidence in, a `KeyEstimateFrame` out after every event, with a full ranking
  over all 24 keys.
- **Abstention over guessing.** Claim hysteresis separates "leading candidate"
  from "claimed key", so the detector reports no key at all until the evidence
  clears a margin, and holds a claim through brief contradictions.
- **Behavior presets.** `KeyBehavior` packages the research-tuned timescales,
  trading section-key stability against local-key responsiveness.
- **Honest confidence display.** `DisplayCalibration` maps posterior mass to
  user-facing confidence without changing the detector's decisions.
- **Baselines and alternatives.** The `KeyDetector` interface is also
  implemented by the research detectors (profile correlation, weighted evidence,
  progression, BOCPD, hybrid), kept for comparison and evaluation.

## Getting started

The package requires Dart SDK 3.8 or later and depends on the whatchord engine
for its chord evidence types. It is developed in the [WhatChord monorepo][REPO]
and consumed by the app through the repository's pub workspace; it is not yet
published to pub.dev.

[REPO]: https://github.com/EarthmanMuons/whatchord

## Usage

A detector is driven by committed `ChordEvent`s, which the whatchord engine
produces from live play (via `ChordAnalyzer` and `ChordEventSegmenter`):

```dart
import 'package:whatchord/whatchord.dart';
import 'package:whatkey/whatkey.dart';

void main() {
  final behavior = KeyBehavior.balanced;
  final detector = HmmKeyDetector(decayHalfLife: behavior.emissionHalfLife);

  detector.reset();
  // liveChordEvents: an Iterable<ChordEvent> from your capture pipeline.
  for (final event in liveChordEvents) {
    final frame = detector.onEvent(event);
    final claim = frame.claim;
    print(claim == null ? 'abstains' : 'claims ${claim.tonality.displayName}');
  }
}
```

The [example](example/example.dart) builds the full pipeline: it runs a chord
progression through the whatchord recognizer, feeds the events to the detector,
and prints the claim after each chord. For I vi IV V7 I in C major followed by a
ii-V-I modulation to Eb major, it produces:

```
C     -> abstains (not enough evidence)
Am    -> abstains (not enough evidence)
F     -> claims C major (55% shown)
G7    -> claims C major (61% shown)
C     -> claims C major (79% shown)
Fm7   -> claims C major (87% shown)
Bb7   -> claims C major (65% shown)
Eb    -> claims C major (38% shown)
Ab    -> abstains (not enough evidence)
Eb    -> claims Eb major (51% shown)
```

## Research

The detector design, frozen evaluation protocol, versioned fixtures, external
baselines, and dated experiment logs live in the [WhatKey research
directory][RESEARCH], including the preprint describing the headline results.

[RESEARCH]:
  https://github.com/EarthmanMuons/whatchord/tree/main/research/whatkey

## Additional information

The package follows [Semantic Versioning](https://semver.org/); while the
version is below 1.0.0, minor releases may include breaking API changes (see the
[changelog](CHANGELOG.md)).

Bug reports and questions are welcome on the [issue tracker][ISSUE]. For
suspected wrong key calls, the chord sequence that produced them is the most
useful thing to include.

[ISSUE]: https://github.com/EarthmanMuons/whatchord/issues/new/choose

## License

This package is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2025&ndash;2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
