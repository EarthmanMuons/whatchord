# Test Organization

Test directories mirror the feature modules under `lib/features/` (plus `core/`
for `lib/core/`). Place a new test in the directory of the feature that owns the
code under test; cross-feature provider tests live with the feature at the
center of the scenario (e.g. `input/same_frame_rebuild_race_test.dart`).

Engine and formatter tests live with the engine in `packages/whatchord/test/`
(see its README), and key detector tests live in `packages/whatkey/test/`; both
run via `dart test` from their package. The `theory/` and `key/` directories
here hold only the app-side tests (Riverpod providers and state).

Two directories do not map to features:

- `tool/`: tests for the developer tooling under the repository's `tool/src/`
  (oracle engine, WhatKey scoring).
- `probes/`: skipped diagnostic probes, run explicitly with `--run-skipped`.
  These measure behavior rather than guard it; see each file's header.
