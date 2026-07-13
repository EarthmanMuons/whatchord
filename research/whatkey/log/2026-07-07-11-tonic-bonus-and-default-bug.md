# 2026-07-07: Evidence-model tonic bonus not adopted; harness default bug found and corrected

**Goal.** Implement and evaluate the evidence model's dominant-quality-tonic fix
proposed by entry 2026-07-07-10's blues diagnosis. A parity check during that
work uncovered a harness bug that contaminated parts of entries 09 and 10; this
entry records the bug, the corrected results, and the tonic-bonus verdict on
clean data.

## The bug

`tool/whatkey/harness.dart` defaulted `--progression-blend` to `0` while
`HybridKeyDetector`'s class default was `0.02`: the edit that should have
updated the CLI default when 0.02 was adopted (entry 08) was a multi-line text
replacement that silently failed to match after the formatter reflowed the code.
Because the harness always passes its parsed value, every defaults-only
`--detector hybrid` run between entries 08 and 11 ran without the progression
term. Found when a defaults-only run failed to reproduce the champion's numbers
(0.74/0.54 instead of 0.79/0.55).

**Fix (structural):** the champion blends are now
`HybridKeyDetector.defaultFunctionalBlend` / `defaultProgressionBlend`
constants, referenced by both the class constructor and the harness parse
defaults, so the CLI cannot silently diverge again. Parity re-verified:
defaults-only reproduces the champion exactly.

**Contamination audit.**

- Entry 08 (progression adoption): unaffected; every run passed explicit blend
  flags, including the paired tests behind the adoption.
- Entry 09 (profile revisit): the drop-in swap candidates ran at progression
  blend 0 against a correct-config baseline, a mixed-config comparison. Rerun
  clean below; the 3x3 grid used explicit flags and stands.
- Entry 10 (two-chorus blues): the "champion" runs were functional-only. Rerun
  clean below; the headline survives, the per-fixture numbers in that entry
  describe the wrong configuration.

**Corrected results.**

- Profile drop-ins at the true champion config: temperley -0.001 exact (p =
  1.00, 21/25/11), TKP +0.001 (p = 0.82, 24/21/12). Entry 09's conclusion
  (Albrecht-Shanahan stays) is unchanged and now rests on clean runs.
- Two-chorus blues under the true champion: still exact 0.00, claims F; the
  modulating chain reads 0.43 as entry 08 recorded. Entry 10's headline (fair
  test still fails; failure is in the blend arithmetic) is unchanged.

## The tonic bonus, on clean data

Implementation: `tonicBonusPoints` on `WeightedEvidenceKeyDetector` (points for
a tonic-degree chord with a home quality), with the tonic quality sets shared in
`KeySpace.tonicQualities` and the progression detector refactored to use them.
Dose-response at +4 and +2 on the true champion base:

```sh
# (temporary default edits; the parameter is not CLI-exposed)
dart run tool/whatkey/harness.dart \
  --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --detector hybrid --out build/whatkey-harness/wir-dev-hybrid-true-tonic4
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-dev-hybrid-true-tonic4/report.json \
  build/whatkey-harness/wir-dev-parity-check/report.json
```

| config   | coverage | exact | modulations | two-chorus blues       |
| -------- | -------- | ----- | ----------- | ---------------------- |
| champion | 0.79     | 0.55  | 133/399     | 0.00 exact (F)         |
| tonic +2 | 0.81     | 0.55  | 138/399     | 0.00 exact (F)         |
| tonic +4 | 0.80     | 0.53  | 139/399     | 0.22 exact, 0.61 MIREX |

Paired vs champion: **+4** costs real accuracy (exact -0.015, CI95 [-0.031,
-0.002], 15 wins / 31 losses) for a partial blues fix; **+2** is a wash on
everything (exact p = 0.99, coverage p = 0.10) and leaves blues unflipped. The
contaminated first look had also shown a modulating-chain regression; on clean
data the chain holds at 0.43 at every dose (that regression was the missing
progression term, not the tonic bonus).

**Decision: not adopted.** `tonicBonusPoints` defaults to 0 and stays as a
tested, ablatable parameter with the negative result documented at the
declaration.

**Plain-English reading.** Teaching the note-counting layer that a blues home
chord can carry a flat seventh helps exactly as far as it can: at a gentle
setting it changes nothing, and at a strong setting it starts hearing "home" in
too many places, paying for a partial blues fix with wrong answers on classical
pieces (it lost twice as many pieces as it won). The deeper lesson is that no
per-chord rule can encode "we came back," because coming back is a fact about a
sequence, not a chord. Blues now formally joins the case for the next detector:
a model with memory of which key it believes in (the HMM), where an established
C hypothesis can persist through F-leaning chords instead of being re-argued
from scratch on every event.

**Decisions.**

- Harness/CLI defaults must be shared constants with the detector classes; a
  defaults-only parity run against the recorded champion is now part of changing
  any default.
- Tonic bonus: default 0, parameter retained for ablation.
- Blues stays open, now with two mechanisms tried and precisely rejected
  (progression blend scaling in entry 08, per-event tonic credit here); the
  remaining candidate is stateful sequence modeling (2c HMM).

**Next.** The 2c HMM (forward posterior over the hybrid's emissions,
self-transition prior as the persistence blues and modulation tracking both
want), then ASAP performed-input fixtures.
