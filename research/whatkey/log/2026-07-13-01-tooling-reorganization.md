# 2026-07-13: Tooling reorganization (path updates in prior entries)

**Goal.** Reorganize the repository's `tool/` directory so the WhatKey and
chord-naming research tooling live in dedicated subdirectories, without breaking
the reproducibility of any command recorded in this log.

**Setup.** Engineering change only: no detector, fixture, scoring, or evaluation
code changed behavior. All moves are renames; the git history carries the
continuity.

**What happened.** Research tooling moved out of the flat `tool/` root:

| Old path                                 | New path                               |
| ---------------------------------------- | -------------------------------------- |
| `tool/whatkey_<name>.py`                 | `tool/whatkey/<name>.py`               |
| `tool/whatkey_harness.dart`              | `tool/whatkey/harness.dart`            |
| `tool/whatkey_fixture_batch.dart`        | `tool/whatkey/fixture_batch.dart`      |
| `tool/whatkey_replay_batch.dart`         | `tool/whatkey/replay_batch.dart`       |
| `tool/whatkey_zenodo_bundle.sh`          | `tool/whatkey/zenodo_bundle.sh`        |
| `tool/src/whatkey/whatkey_fixtures.dart` | `tool/whatkey/src/fixtures.dart`       |
| `tool/src/whatkey/whatkey_scoring.dart`  | `tool/whatkey/src/scoring.dart`        |
| `tool/chord_oracle*.{py,dart,json}`      | `tool/chord/oracle*.{py,dart,json}`    |
| `tool/chord_pool_diff.py`                | `tool/chord/pool_diff.py`              |
| `tool/chord_rule_ablation.py`            | `tool/chord/rule_ablation.py`          |
| `tool/when_in_rome_chord_batch.dart`     | `tool/chord/when_in_rome_batch.dart`   |
| `tool/when_in_rome_chord_benchmark.py`   | `tool/chord/when_in_rome_benchmark.py` |
| `tool/choco/*`                           | `tool/chord/choco/*`                   |

Commands recorded in earlier log entries, `PROTOCOL.md` pointers,
`REPRODUCING.md`, and the hand-written data provenance notes were updated
mechanically to the new paths so they remain copy-pasteable from a fresh
checkout. Nothing else in those entries changed: all results, numbers, readings,
and decisions are untouched, and the append-only convention otherwise stands.
Frozen artifacts (`results/`, generated fixture manifests, and harness reports
under `build/`) keep the old paths they recorded at generation time; translate
them through the table above when re-running a command taken from an artifact
rather than from a log entry.

**Verification.** `mise research:whatkey-headline-verify` reproduces the
headline table from the committed test-split artifacts after the move, and the
full app and package test suites pass.

**Decisions.** Reproducibility of recorded commands outranks strict immutability
of entry text for pure path references. Entry prose, outputs, and analysis
remain immutable.

**Next.** None; the mapping table above is the reference if any stale path
surfaces later.
