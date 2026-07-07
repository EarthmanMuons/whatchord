# WhatKey

WhatKey is the working name for automatic key detection in WhatChord: inferring
the key a musician is playing in, live, from the stream of chords they play, and
showing it with honest confidence, including saying nothing when the music does
not support a claim.

## Why this is interesting

Key-finding has a 30+ year literature, but almost all of it is offline,
score-based, and whole-piece: given a complete, clean symbolic score, name the
key. WhatKey's setting is different in three ways that compound:

1. **Causal and streaming.** The detector only ever sees the past, and it must
   update as each chord arrives, from someone noodling on a MIDI keyboard with
   finger rolls, pedal blur, and wrong notes.
2. **Uncertain observations.** The input is not ground-truth notes but the
   output of WhatChord's chord recognizer: ranked candidates with explanation
   costs. The observations themselves carry confidence, and a detector can
   exploit that.
3. **Abstention as a first-class outcome.** A modal vamp has no single right
   answer. Asserting one confidently is worse than staying quiet, so latency,
   stability, and knowing when not to answer are measured, not just accuracy.

That combination appears to be an open niche, which is why this initiative is
run with more rigor than a typical app feature: frozen evaluation protocol,
versioned fixtures, external baselines, and dated logs.

## Status

- **Phase 1 (shipped, July 2026):** chord history capture. The app records a
  sliding window of committed chord events (identity, ranked candidates,
  voicing, tonality context, hold duration) from live MIDI play. In-memory only,
  never persisted; no user data is ever collected.
- **Phase 2 (next):** labeled fixtures, the offline evaluation harness, and the
  first detection algorithms (profile correlation as the floor, then a weighted
  evidence model).

## Reading order

1. This README.
2. [temporal-context-key-detection.md](temporal-context-key-detection.md): the
   full design and implementation plan, including the algorithm menu, decision
   points, performance analysis, and references. Denser than this page; it is
   the source of truth.
3. [PROTOCOL.md](PROTOCOL.md): how results will be evaluated. Draft until
   frozen; frozen before the first tuning experiment.
4. [REPRODUCING.md](REPRODUCING.md): exact steps for rebuilding the Phase 2
   fixture inputs, external corpus checkout, local machine-state prep, and
   frozen split.
5. [log/](log/): dated entries recording what was tried, what happened, and what
   was decided, so nobody has to comb through git history.
6. [data/](data/): fixture, split, and provenance conventions.

## Where the code lives

- `lib/features/history/`: Phase 1 chord event capture (in the app).
- `lib/features/key/`: the key detectors (pure Dart domain, no UI yet); the same
  code the harness benchmarks is what the app will eventually run.
- `lib/features/theory/`: the chord analysis engine the events come from.
- `tool/`: `whatkey_fixture_extract.py` and `whatkey_fixture_batch.dart` build
  labeled fixtures; `whatkey_harness.dart` (with `tool/src/whatkey/`) replays
  fixtures through detectors and reports the protocol metrics. Run via
  `mise research:whatkey-harness-pop-jazz` and
  `mise research:whatkey-harness-dev`.

## Planned, not yet started

- `paper/`: a typst writeup tracked in this repo, once there are results worth
  writing up.
- A debug/profile-build-only in-app panel for observing recorded history and
  detector outputs during development (never in release builds).
