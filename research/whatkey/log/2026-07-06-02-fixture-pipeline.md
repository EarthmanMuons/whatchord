# 2026-07-06: Fixture pipeline and the hand-authored pop/jazz set

**Goal.** Build the Phase 2 fixture pipeline: labeled `ChordEvent` streams the
offline harness can replay, from both When in Rome and hand-authored charts.

**Setup.** Engine at commit `349fb2c4` (lib/ unchanged since `8aff5fb7`). New
tooling: `tool/whatkey/fixture_batch.dart` (engine driver) and
`tool/whatkey/fixture_extract.py` (extractor); mise tasks
`research:whatkey-fixtures-pop-jazz` and
`research:whatkey-fixtures-when-in-rome`.

**What happened.** Generated and committed `data/fixtures/pop-jazz-v1` (8
fixtures, 66 events) from the new hand-authored charts in
`data/sources/pop-jazz/`. Spot checks look right: E7 in the A minor chart comes
through as `dominant7` on E under the neutral context, and Dm7 events carry
their F6 near-tie alternative with the 0.15 cost gap intact, which is exactly
the ambiguity signal detectors are meant to exploit. When in Rome generation is
implemented but not run: no local corpus checkout, and derived fixtures are
license-gated anyway.

**Decisions.**

- **Neutral ranking context.** Fixture candidates are ranked under a fixed
  `C:maj` context (a generator parameter, recorded in the manifest), never the
  annotated key. Ranking tie-breakers are tonality-gated, so ranking under
  ground truth would leak the answer into the observations. Also added to
  PROTOCOL.md (still draft). The cost: fixtures do not model a user whose manual
  tonality happens to match the piece; a context-matched variant set can test
  that later if it matters.
- **Mirror the app capture path.** The batch driver analyzes with voicing
  evidence and default pruning, and emits chosen plus surfaced near-tie
  alternatives (`ChordCandidateRanking.alternatives`), so fixture events carry
  exactly what a recorded `ChordEvent` would.
- **Timing synthesis.** Chart beats and score offsets become wall-clock times at
  a fixed tempo (default 120 BPM, in the manifest). When in Rome event duration
  is the gap to the next annotation; the last event falls back to the piece's
  median gap.
- **Key wire format.** `Tonic:mode` (`C:maj`, `F#:min`) everywhere, matching the
  existing benchmark tooling and `parseTonality`.
- **Ambiguity labels.** `localKey: null` plus `acceptableKeys` marks passages
  where abstention is the best outcome (the Am-F-C-G loop, the dorian vamp),
  which is what abstain calibration scores against.
- **License gating enforced by defaults.** When in Rome fixtures generate into
  `build/`, and their manifests carry an UNVERIFIED license marker; nothing
  corpus-derived is committed until the sub-corpus license is checked.

**Next.** Verify When in Rome sub-corpus licenses, regenerate a corpus set,
freeze the split in `data/splits/`, then build the harness metrics and the
profile-correlation floor.
