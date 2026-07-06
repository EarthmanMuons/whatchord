# WhatKey Data

Nothing carved yet. This directory will hold the evaluation fixtures and splits
for Phase 2; the conventions are fixed now so the first data checked in already
follows them.

## What will live here

- `fixtures/`: serialized `ChordEvent` streams with time-aligned key labels (and
  functional labels where the source provides them), generated from corpora by
  the extractor tooling in `tool/` or hand-authored.
- `splits/`: the frozen development/test split definitions, by piece and by
  composer, recorded before the first experiment (see `../PROTOCOL.md`).
- One manifest per fixture set.

## Manifest rules

Fixtures embed engine output (candidate rankings and costs), so regenerating
them after an engine change silently changes the dataset. Every fixture set's
manifest records:

- the engine commit the fixtures were generated with;
- the generation script, its parameters, and its own commit;
- the source corpus and its commit pin (When in Rome, ASAP) or "hand-authored";
- per-fixture license and provenance, checked before anything derived from an
  external corpus is committed (When in Rome sub-corpora have heterogeneous
  licenses).

Results are only comparable within a fixture version. Old fixture versions are
kept until no reported result depends on them.

## What will never live here

App-user data. History capture in the app is in-memory only and never persisted;
fixtures come from public corpora and the developer's own captures.
