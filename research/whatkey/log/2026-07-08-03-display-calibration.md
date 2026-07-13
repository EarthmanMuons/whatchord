# 2026-07-08: Display-layer temperature scaling fixes the posterior's honesty

**Goal.** Entry 2026-07-08-01 measured the raw posterior as overconfident
(claimed mean 0.93 against 0.77 exact on the Isophonics development split),
which blocks showing a literal confidence number in the auto-key UI. Fit the
post-hoc calibrator that entry proposed, as a pure display transform: the
detector's frozen configuration, claims, and internal margins are untouched, and
only probabilities shown to a user pass through it. Result set declared in
advance: fit a single temperature on the Isophonics development split by
negative log-likelihood argmin over exact-labeled events; report the When in
Rome development split as a transfer diagnostic; then one Isophonics test-split
run with the frozen temperature whose claims must be byte-identical to the
committed one-shot artifacts.

**Implementation.** `posteriorCalibration` in the harness scoring gains a
`temperature` parameter (temperature scaling: each probability raised to 1/T,
renormalized; monotone, so ranking and claims cannot change), plus harness flags
`--calibration-temperature` and `--sweep-calibration-temperatures` that reuse
one detector pass. The frozen constant ships as `DisplayCalibration.temperature`
in the key domain with unit tests.

```sh
dart run tool/whatkey/harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --detector hmm \
  --sweep-calibration-temperatures 1,1.25,1.5,1.75,2,2.25,2.5,2.75,3,3.5,4,5 \
  --out build/whatkey-harness/iso-dev-calfit
# refined with 1.35..1.7 in steps of 0.05 (iso-dev-calfit2)
dart run tool/whatkey/harness.dart \
  --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --detector hmm --calibration-temperature 1.55 \
  --out build/whatkey-harness/wir-dev-caltransfer
dart run tool/whatkey/harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --split test --detector hmm --calibration-temperature 1.55 \
  --sweep-calibration-temperatures 1 \
  --out build/whatkey-harness/test-iso-calibration
cmp build/whatkey-harness/test-iso-calibration/claims.json \
  research/whatkey/results/test-split-2026-07-07/test-iso-hmm-shipped/claims.json
```

**Fit.** Negative log-likelihood over all exact-labeled development events is
smooth with a single minimum: coarse grid 1 to 5, refined 1.35 to 1.7 in steps
of 0.05, argmin at **T = 1.55** (the surface is flat within 0.004 NLL from 1.45
to 1.65, so the display is insensitive to the exact choice). Development-split
effect at T = 1.55: ECE 0.151 to 0.061, claimed mean confidence 0.93 to 0.785
against 0.772 accuracy, NLL 1.120 to 0.946, Brier 0.408 to 0.374.

**Held-out verification** (single declared run, Isophonics test):

| view                | mean conf | accuracy | ECE   | NLL   | Brier |
| ------------------- | --------- | -------- | ----- | ----- | ----- |
| raw, claimed        | 0.910     | 0.721    | 0.192 | 1.816 | 0.496 |
| calibrated, claimed | 0.759     | 0.721    | 0.041 | 1.395 | 0.458 |

The run's claims are **byte-identical** to the committed one-shot artifacts,
which simultaneously proves the calibration pass took nothing from test data
(the detector never changed) and re-validates the committed artifacts. The
dev-fit temperature generalizes: held-out ECE 0.041 means the displayed number
can honestly be read as a probability.

**Scope of the claim.** Calibration is ruler-relative, exactly like accuracy: on
the When in Rome development split the same temperature leaves conf 0.763
against 0.524 accuracy (ECE 0.240), because the section-scale detector is
deliberately not tracking local-scale labels. The displayed number is calibrated
to section-scale correctness on pop material, which is the question the key
indicator answers.

**Plain-English reading.** The detector's raw percentage overstated itself,
saying 93 when it deserved 77, because nothing in tuning ever rewarded the
number for being literal. We fitted the one-knob correction on practice data and
checked it once on the sealed exam data: after correction, when the display says
76 it is right 72 percent of the time, close enough to take the number at face
value. The detector itself was never touched, and we can prove it: the corrected
run's answers match the sealed evaluation's committed answers byte for byte.

**Decisions.**

- `DisplayCalibration.temperature = 1.55` frozen; applied to every probability
  the UI shows (headline confidence and the key heatmap alike), never to the
  detector's internal margins.
- Isotonic regression, the documented fallback, is not needed at ECE 0.04.
- The paper's limitations paragraph is updated from "not yet empirically
  calibrated" to the measured post-hoc result.

**Next.** The auto-key product integration proper: `inferredKeyProvider`, the
four-state key button, and the Manual | Auto picker modal, per the locked
interaction spec.
