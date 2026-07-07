# WhatKey Data

Evaluation fixtures and splits for Phase 2.

## Layout

- `sources/`: hand-authored inputs, currently `sources/pop-jazz/` chord charts
  (JSON: voiced chords as note names, beats, and per-chord key labels). These
  are pass/fail regression probes for the detectors, not a statistical sample;
  see the protocol's corpora section.
- `fixtures/<set>/`: generated fixture sets, one JSON file per piece or
  progression plus a `manifest.json`. Regenerate the hand-authored set with
  `mise research:whatkey-fixtures-pop-jazz`.
- `splits/`: the frozen development/test split definitions, by piece and by
  composer where the corpus allows, recorded before the first experiment (see
  `../PROTOCOL.md`). The When-in-Rome v1 split is frozen in
  `splits/when-in-rome-v1.json`.
- `provenance/`: corpus license and source-gate notes for fixture sets derived
  from external corpora.

Corpus-derived sets (`mise research:whatkey-fixtures-when-in-rome`) generate
into `build/whatkey-fixtures/` and are committed here only once the source
sub-corpus license is verified. `when-in-rome-v1` passed that gate (limited to
`bach-wtc`, `brahms-lieder`, `schubert-lieder`, and `tavern`; see
`provenance/when-in-rome-v1.md`) and is committed under
`fixtures/when-in-rome-v1/`: the protocol is frozen against this set, so the
frozen artifact must be durable in the repo rather than rebuilt on demand from a
local corpus checkout. Committed fixture sets are immutable; an engine or
generator change produces a new versioned set beside them. Licensing boundaries
for this subtree are summarized in `NOTICE.md`.

## Fixture format

A fixture (`whatkey-fixture/1`) is a labeled `ChordEvent` stream: per event,
wall-clock `timestampMs` and `durationMs`, the voicing (`midiNotes`, `pcMask`,
`bassPc`, `noteCount`), the engine's ranked `candidates` (chosen plus surfaced
near-tie alternatives, with quality, extensions, and explanation cost), and
`labels` (`localKey`, optional `figure` and `acceptableKeys`; a null `localKey`
marks a passage where abstention is the best outcome).

Conventions:

- Keys use the wire format `Tonic:mode`, e.g. `C:maj`, `F#:min`.
- Candidates are ranked by the real engine (`tool/whatkey_fixture_batch.dart`)
  with voicing evidence, mirroring the app's live capture path.
- The ranking runs under a fixed neutral analysis context (default `C:maj`,
  recorded in the manifest), never the annotated key, so tonality-gated ranking
  tie-breakers cannot leak ground truth into the observations.
- Score offsets and chart beats become wall-clock times at the fixed tempo
  recorded in the manifest; a When-in-Rome event's duration is the gap to the
  next annotation.

## Manifest rules

Fixtures embed engine output (candidate rankings and costs), so regenerating
them after an engine change silently changes the dataset. Every fixture set's
manifest (`whatkey-manifest/1`) records:

- the engine commit the fixtures were generated with (plus a lib-dirty flag);
- the generation script and its arguments;
- the analysis context and tempo used;
- the source corpus and its commit pin (When in Rome, ASAP) or "hand-authored";
- per-fixture license and provenance, checked before anything derived from an
  external corpus is committed (When in Rome sub-corpora have heterogeneous
  licenses).

Results are only comparable within a fixture version. Old fixture versions are
kept until no reported result depends on them.

## What will never live here

App-user data. History capture in the app is in-memory only and never persisted;
fixtures come from public corpora and the developer's own captures.
