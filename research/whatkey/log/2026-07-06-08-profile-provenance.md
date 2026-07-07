# 2026-07-06: Key-profile provenance and the Kostka-Payne pair

**Goal.** Verify that the profile vectors hardcoded in
`lib/features/key/domain/detectors/key_profiles.dart` match the published
values, using independent reference implementations, and record the sources.

**Setup.** Verification against music21 10.1.0 (local, live
`getWeights('major'/'minor')` calls) and the justkeydding repository
(`optimizer/key_profiles.py`).

**What happened.** All pairs verified; one naming trap found and defused; a
fourth pair added.

- **Krumhansl-Kessler**: matches music21's `KrumhanslSchmuckler` weights
  digit-for-digit, major and minor.
- **Albrecht-Shanahan**: matches justkeydding's `albrecht_shanahan1` (the
  paper's published table) exactly. justkeydding also carries a higher-precision
  `albrecht_shanahan2` variant; ours is the citable paper version.
- **Temperley (1999)**: matches the modified profiles from "What's Key for Key?"
  as reproduced (as Temperley 2001) in
  [Lieck & Rohrmeier's PULSE paper](https://arxiv.org/pdf/1709.08842)
  (arXiv:1709.08842), major (5, 2, 3.5, 2, 4.5, 4, 2, 4.5, 2, 3.5, 1.5, 4) and
  minor (5, 2, 3.5, 4.5, 2, 4, 2, 4.5, 3.5, 2, 1.5, 4).
- **The naming trap**: justkeydding's profile named "temperley" and music21's
  `TemperleyKostkaPayne` are a different profile set, the Kostka-Payne
  probability profiles from _Music and Probability_ (2007), not the 1999
  revision. Confirmed by arithmetic: justkeydding's "temperley" values are
  exactly the 2007 vectors normalized to sum to 1. Noted in the enum docs so
  external-baseline comparisons name the pair precisely.
- **Added `temperleyKostkaPayne`** as a fourth enum entry, since modern
  implementations settled on it as the refined Temperley pair. Values match
  music21 10.1.0's `TemperleyKostkaPayne` weights digit-for-digit and
  justkeydding's normalized copy.

Pearson correlation is invariant to scaling and offset of the profile vector, so
normalized vs. unnormalized copies of the same profile rank identically in our
detector; only genuinely different profile sets (1999 vs. 2007 Temperley) change
results.

**Decisions.** Every profile pair we ship must be verified against at least one
independent reference implementation before use, with the source recorded here;
the enum doc links back to this entry.

**Next.** Nothing blocking; the harness A/B over all four pairs is available via
`--profiles` whenever profile comparison becomes the experiment.
