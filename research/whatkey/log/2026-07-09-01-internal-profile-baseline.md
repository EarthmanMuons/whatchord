# 2026-07-09: Post-hoc internal profile baseline audit

**Goal.** Capture a curiosity result after the paper draft: how much the
selected HMM adds over the raw Albrecht-Shanahan profile-correlation detector it
wraps. This was not included in the paper's external comparison table because it
is not an external system; it is an internal floor/ablation point. The result is
recorded for posterity and product intuition, not as a new frozen-test adoption
decision.

**Setup.** Local Isophonics fixtures regenerated under `build/` from the pinned
ChoCo checkout:

- fixture set: `build/whatkey-fixtures/isophonics-nc-v1`
- split: `research/whatkey/data/splits/isophonics-nc-v1.json`, `test`
- ChoCo commit: `5fe168fd55be5c84512abcfbc4e6f1b1f8f0092a`
- harness engine commit reported by the runs:
  `c841c30d7cc5b85965eae10ae9df4670cd99bec9`

Commands:

```sh
mise research:whatkey-prepare-data -- --headline --yes

dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --split test \
  --detector profile \
  --profiles albrechtShanahan \
  --out build/whatkey-harness-extra/test-iso-profile-albrechtShanahan

dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --split test \
  --detector profile \
  --profiles albrechtShanahan \
  --restrict-to research/whatkey/results/test-split-2026-07-07/test-iso-hmm-shipped/claims.json \
  --out build/whatkey-harness-extra/test-iso-profile-albrechtShanahan-matched
```

**What happened.** Raw profile correlation used the harness defaults:
Albrecht-Shanahan profiles, duration weighting, 30 s decay, `minEvents=3`, and
`marginFloor=0.05`.

| system                               | cov  | exact | MIREX | modulations | spur med/p90 |
| ------------------------------------ | ---- | ----- | ----- | ----------- | ------------ |
| selected HMM, one-shot artifact      | 0.88 | 0.732 | 0.782 | 10/22       | 0/3          |
| raw Albrecht-Shanahan profile        | 0.75 | 0.671 | 0.744 | 9/22        | 1/3          |
| raw profile, HMM-claimed events only | 0.78 | 0.689 | 0.755 | 9/22        | 1/3          |

For comparison, a separate curiosity run of music21 Bellman-Budge on the same
test split gave coverage 1.00, exact 0.532, MIREX 0.688, and 5/22 matched
modulations. That reinforces why it was not missing from the paper's headline
table, but it is not the focus of this entry.

**Plain-English reading.** The simple profile detector is already a strong
baseline: it listens to recent pitch classes and compares them to the
Albrecht-Shanahan major/minor profiles. The HMM still earns its keep. It claims
more often, is more accurate when it claims, catches one more annotated
modulation, and reduces the typical spurious-switch count. The selected result
is therefore not merely the Albrecht-Shanahan profile result repackaged in HMM
language.

**Decisions.**

- Do not revise the paper's external-baseline table. The raw profile detector is
  an internal floor/ablation, not an external baseline like music21.
- Do not treat this as a new model-selection result. The one-shot held-out
  protocol was already spent; this entry is an audit of an omitted internal
  comparison.
- Retain the result as useful product context: most of the selected detector's
  behavior is profile-driven, but the HMM improves the operating point.

**Next.** If a future local-key/product-tuning pass exposes a user-facing
Stable/Balanced/Reactive option, include this profile floor alongside
short-memory HMM and BOCPD variants as an internal reference point.
