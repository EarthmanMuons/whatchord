# Engine Test Organization

Run with `dart test` from the package root.

Tests are split by the behavior they protect. Prefer adding new cases to the
narrowest file that explains why the case exists.

## Chord Analysis

- `chord_analyzer_golden_test.dart`: canonical musician-facing chord examples.
  Add cases here when the goal is to document the expected name for a chord
  shape.
- `chord_analyzer_ranking_golden_test.dart`: end-to-end analyzer cases where the
  important behavior is that one plausible interpretation beats another.
- `chord_analyzer_spelling_golden_test.dart`: key-signature, enharmonic, and
  spelling-context behavior.
- `chord_candidate_ranking_test.dart`: direct unit tests for
  `ChordCandidateRanking` rules. Use this when the rule decision itself matters
  more than the full analyzer pipeline.
- `theory_transposition_property_test.dart`: generated/property coverage for
  transposition invariants.
- `chord_ranking_prune_guard_test.dart`: ratchet guarding
  `ChordAnalyzer.rankingPruneMargin` against pricing/ranking changes.

## Scale Degree

- `scale_degree_golden_test.dart`: strict scale-degree classification, source
  selection, and roman-numeral rendering for analyzed chords.

## Shared Helpers

- `package:whatchord_theory/testing.dart`: factories for analysis contexts,
  pitch classes, masks, and chord inputs. Lives in `lib/` so consumers of the
  package (including the app's own tests) can use it too.
- `helpers/chord_analyzer_golden_helpers.dart`: shared golden analyzer case
  model and runner.
