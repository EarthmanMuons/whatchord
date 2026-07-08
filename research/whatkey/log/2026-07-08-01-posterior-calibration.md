# 2026-07-08: Posterior reliability diagnostics

**Goal.** Check whether the HMM's probability numbers mean what they look like.
It is one thing for abstention to work (the detector is more accurate when it
chooses to speak) and another for a displayed probability to be literal. If the
detector says "80%" many times, it should be right about 80% of those times
before we call that number calibrated. We had measured the abstention behavior;
we had not measured this probability-reading question directly.

**Setup.** Reporting-only harness change, no detector parameter change and no
new model-selection rule. The diagnostic applies only when a detector's ranked
frame is a probability distribution over keys (HMM, BOCPD). It skips
acceptable-key-only events because they do not define a single probability
target.

```sh
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --detector hmm \
  --out build/whatkey-harness/iso-calibration-dev
```

**What happened.** The harness now writes `posteriorCalibration` into
`report.json` and summarizes it in `report.txt`. It looks only at events with
one exact answer key, then asks:

- When the detector's top key has a given probability, how often is that top key
  actually right?
- How large is the average gap between probability and accuracy across
  confidence bands (ECE)?
- How much probability did the detector put on the true key (NLL)?
- How far was the whole 24-key probability distribution from the one-hot correct
  answer (Brier)?

Each number is reported twice: once over all exact-labeled events, including
events where the detector abstained, and once over the exact-labeled events
where the detector made a claim.

Isophonics development, selected HMM:

| subset  | events | mean posterior | exact |   ECE |   NLL | Brier |
| ------- | -----: | -------------: | ----: | ----: | ----: | ----: |
| all     | 15,234 |          0.902 | 0.751 | 0.151 | 1.120 | 0.408 |
| claimed | 14,123 |          0.929 | 0.772 | 0.157 | 1.077 | 0.388 |

Skipped: 263 events without an exact local-key label; 0 non-probabilistic
frames.

**Plain-English reading.** The abstention mechanism is still doing useful work,
but the raw probability numbers are too confident. On claimed events the
detector's top key averages about 93% probability, while the top key is exactly
right about 77% of the time. So the detector is useful for ranking keys and for
deciding when to abstain, but its probability should not yet be displayed as a
literal "93% chance this is the key." The paper should say posterior
probability, selective-prediction behavior, and abstention; it should not call
the confidence calibrated.

**Decisions.**

- Add posterior reliability as a protocol diagnostic, not a replacement for the
  coverage-accuracy abstention sweep.
- Do not retune the selected detector from this result. A future calibration
  pass should fit a post-hoc calibrator on development data and evaluate that
  frozen calibrator on a declared held-out result set.
- Update the paper's limitations to state that posterior probabilities are not
  yet empirically calibrated.

**Next.** If product UI wants numeric confidence, fit a simple post-hoc
translator from raw posterior to displayed confidence on development data, then
evaluate that frozen translator on a declared held-out run. Candidate tools:
[temperature scaling](https://proceedings.mlr.press/v70/guo17a.html) or
[isotonic regression](https://en.wikipedia.org/wiki/Isotonic_regression) over
the top posterior and possibly the top-two margin.
