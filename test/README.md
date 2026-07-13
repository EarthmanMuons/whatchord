# Test Organization

Test directories mirror the feature modules under `lib/features/` (plus `core/`
for `lib/core/`). Place a new test in the directory of the feature that owns the
code under test; cross-feature provider tests live with the feature at the
center of the scenario (e.g. `input/same_frame_rebuild_race_test.dart`).

Two directories do not map to features:

- `tool/`: tests for the developer tooling under the repository's `tool/src/`
  (oracle engine, WhatKey scoring).
- `probes/`: skipped diagnostic probes, run explicitly with `--run-skipped`.
  These measure behavior rather than guard it; see each file's header.

## Theory

Theory tests are split by the behavior they protect. Prefer adding new cases to
the narrowest file that explains why the case exists.

- `theory/chord_analyzer_golden_test.dart`: canonical musician-facing chord
  examples. Add cases here when the goal is to document the expected name for a
  chord shape.
- `theory/chord_analyzer_ranking_golden_test.dart`: end-to-end analyzer cases
  where the important behavior is that one plausible interpretation beats
  another.
- `theory/chord_analyzer_spelling_golden_test.dart`: key-signature, enharmonic,
  and spelling-context behavior.
- `theory/chord_candidate_ranking_test.dart`: direct unit tests for
  `ChordCandidateRanking` rules. Use this when the rule decision itself matters
  more than the full analyzer pipeline.
- `theory/theory_transposition_property_test.dart`: generated/property coverage
  for transposition invariants.
- `theory/chord_ranking_prune_guard_test.dart`: ratchet guarding
  `ChordAnalyzer.rankingPruneMargin` against pricing/ranking changes.

## Scale Degree

- `theory/scale_degree_golden_test.dart`: strict scale-degree classification,
  source selection, and roman-numeral rendering for analyzed chords.

## Shared Helpers

- `theory/helpers/chord_analyzer_golden_helpers.dart`: shared golden analyzer
  case model and runner.
- `theory/helpers/theory_test_helpers.dart`: shared test utilities for analysis
  contexts, pitch classes, masks, and chord inputs.
