# 2026-07-07: BOCPD measured: adaptive memory improves the reactive regime, not the calm one

**Goal.** The dwell probe (entry 25) dispositioned the changepoint _prior_ but
not BOCPD's genuinely different contribution, the run-length-adaptive evidence
window: pooling evidence back to the inferred section start instead of through a
fixed 30 s decay. That targets the one metric with visible headroom, modulation
catching (shipped: 94/192 matched on Isophonics dev; reflex reference: 140/192
at heavy stability cost). Adoption rule fixed in advance: materially improved
modulation matching with paired non-inferior exact, flat spurious switches, and
a clean behavioral suite.

**Implementation.** `BocpdKeyDetector` (Adams & MacKay 2007, arXiv:0710.3742):
run-length posterior with constant hazard, per-run key posteriors from
accumulated per-event log-likelihoods, claims from the run-marginal posterior
under the usual margin floor. Emission conventions match the shipped HMM exactly
(Albrecht-Shanahan correlation, softmax temperature, adopted mode tilt, duration
weighting), so differences are attributable to the window, not ingredient drift.
Harness `--detector bocpd` with `--hazard` and `--max-run-length`; six unit
tests.

```sh
for hz in 0.005 0.015625 0.03125 0.0625; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
    --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
    --detector bocpd --hazard "$hz" \
    --out "build/whatkey-harness/iso-bocpd-h$hz"
done   # same for when-in-rome-v1; rescue runs add
       # --emission-temperature 0.5|1.0 at hazard 0.005
python3 tool/whatkey_compare.py \
  build/whatkey-harness/iso-bocpd-h0.005-t1.0/report.json \
  build/whatkey-harness/iso-tilt-s2/report.json
```

**Results** (Isophonics dev; shipped HMM baseline first):

| config        | cov  | exact | modulations | spurious med/p90 |
| ------------- | ---- | ----- | ----------- | ---------------- |
| hmm (shipped) | 0.92 | 0.775 | 94/192      | 0/1              |
| bocpd h=.005  | 0.88 | 0.715 | 161/192     | 5/14             |
| bocpd h=.0625 | 0.81 | 0.616 | 164/192     | 10/26            |
| bocpd t=0.5   | 0.89 | 0.765 | 135/192     | 2/7              |
| bocpd t=1.0   | 0.90 | 0.769 | 115/192     | 0/4              |

The adaptive window does exactly what the theory promised: modulation matching
jumps to 161-167/192 across the hazard grid (When in Rome: 183-194 vs 120/399),
because evidence resets at inferred section starts instead of dragging 30 s of
the old key. But the same reactivity destroys the product ruler's stability
(spurious median 5-10 at the shipped temperature), and no setting recovers the
HMM's operating point: softening the per-event evidence walks BOCPD back along
the frontier (t=1.0: exact wash, -0.007 paired, p = 0.51, but spurious p90 still
4 vs 1) without ever reaching it. One genuinely interesting mid-frontier note
for the paper: at matched reactivity BOCPD dominates the HMM's fast settings
(t=0.5: 0.765 exact at 135 modulations vs the HMM hl2's 0.736 at 141), so
adaptive windowing is real value _in the reactive regime_; the calm regime the
product chose simply does not need it.

**On Tsaknaki, Lillo & Mazzarisi (2024)** (Bayesian autoregressive online
change-point detection with time-varying parameters, CNSNS; arXiv:2407.16376),
reviewed for adoptable ideas: its two extensions are an autoregressive
observation model within regimes and score-driven time-varying regime
parameters, aimed at continuous univariate series where within-regime
autocorrelation triggers false changepoints. The diagnosis maps to us precisely,
our spurious switches are within-section harmonic movement violating the
independent-given-key assumption, but the remedies do not: the Gaussian AR
machinery has no analog for categorical chord emissions, and our domain's
version of within-regime dependence modeling is the progression layer, measured
inert twice (entries 20, 24). Our temperature softening acts as a crude
effective-sample-size correction for the same violation. Cited in the design doc
references; nothing further to adopt.

**Plain-English reading.** We built the adaptive-memory detector the future work
list has pointed at all along and it behaves exactly as advertised: it notices
key changes far faster because it figures out where the current section started
and only listens from there. The cost is that it also "notices" changes that are
not real, every colorful patch of harmony tempts it, and no tuning found a
setting that keeps the fast reactions without the false alarms. The steady
detector we ship was chosen precisely because the product values calm over
quick, and on that ruler it remains strictly better. The fast detector is better
at being fast than our fast settings are, which is worth reporting, but being
fast is not the job.

**Decisions.**

- No adoption; the frozen test-split configuration is unchanged from entry 23.
  The detector, tests, and harness support are retained like the other measured
  negatives.
- The reactive-regime dominance note (BOCPD t=0.5 vs HMM hl2) is recorded for
  the paper's frontier discussion, not for the product.
- Pre-test exploration is closed, now including both future-model directions:
  HSMM dispositioned by the dwell probe (entry 25), BOCPD by direct measurement.

**Next.** The one-shot test-split evaluation across the three frozen splits.
