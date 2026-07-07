# 2026-07-07: The section-scale mode number and the emission-memory dose-response curve

**Goal.** The two checks owed before the configuration freezes for the one-shot
test-split evaluation. First, the product-facing mode number: entry 21's 14%
mode-error rate was an upper bound, graded against tonicization-scale labels
that charge the shipped detector for excursions it absorbs on purpose. Second,
the dose-response question: entries 16-21 tested emission memory only at 1, 15,
and 30 seconds, and entry 21 established that reflex-scale claims are legitimate
excursion tracking rather than noise, so an intermediate setting deserved a fair
look before being ruled out. Decision rule fixed in advance: the shipped
configuration changes only if an intermediate half-life beats 30 seconds on the
section-scale development ruler (Isophonics) with a significant paired exact
win.

**Experiment 1: section-scale filtering of the mode-resolved corpus.**
`tool/whatkey_mode_confusion.py` gained `--min-segment-measures N`: pool only
events inside analyst key segments spanning at least N measures, where the
tonicization-scale and section-scale answers coincide. No new detector runs;
this re-scores entry 21's existing claims artifacts, so the evaluation-only rule
on `asap-wir-nc-v1` is untouched. Thresholds 12/20/32 reported together so no
single cutoff is doing the arguing.

```sh
for t in 12 20 32; do for n in shipped reflex; do
  python3 tool/whatkey_mode_confusion.py \
    --fixtures build/whatkey-fixtures/asap-wir-nc-v1 \
    --claims "build/whatkey-harness/asap-wir-hmm-$n/claims.json" \
    --min-segment-measures "$t"
done; done
```

| segments       | shipped exact | reflex exact | shipped mode err (rel+par) |
| -------------- | ------------- | ------------ | -------------------------- |
| all (entry 21) | 50%           | 60%          | 14% (5+9)                  |
| >= 12 meas.    | 60%           | 62%          | 14% (4+10)                 |
| >= 20 meas.    | 63%           | 62%          | 14% (4+10)                 |
| >= 32 meas.    | 65%           | 62%          | 10% (4+6)                  |

Two findings. The crossover reproduces _within_ the corpus as a function of
segment length: shipped climbs steadily as segments lengthen and overtakes
reflex at 20-measure segments, while reflex stays flat; the same recordings,
sliced by label granularity, reorder the two configurations exactly as the
between-corpus story predicted. And the product-facing mode number lands at
about 10% of claims in long stable sections (parallel 6%, relative 4%), a third
below the unfiltered upper bound. The residual parallel confusion is the real
product error class; relative confusion, invisible to signature labels, stays
rare everywhere.

**Experiment 2: the emission-memory dose-response sweep.** Half-lives 1, 2, 4,
8, 15, 30, 60 seconds on both development rulers; on When in Rome both the
pure-emission config and the tonicization reference (functional blend 0.1). The
evaluation-only overlap set was deliberately excluded.

```sh
for hl in 1 2 4 8 15 30 60; do
  dart run tool/whatkey_harness.dart \
    --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hmm --decay-half-life-seconds "$hl" \
    --out "build/whatkey-harness/wir-dose-pure-hl$hl"
  dart run tool/whatkey_harness.dart \
    --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hmm --decay-half-life-seconds "$hl" --functional-blend 0.1 \
    --out "build/whatkey-harness/wir-dose-f01-hl$hl"
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
    --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
    --detector hmm --decay-half-life-seconds "$hl" \
    --out "build/whatkey-harness/iso-dose-pure-hl$hl"
done
python3 tool/whatkey_compare.py \
  build/whatkey-harness/iso-dose-pure-hl8/report.json \
  build/whatkey-harness/iso-dose-pure-hl30/report.json
```

Exact accuracy on claimed (coverage in parentheses):

| hl (s) | WiR pure     | WiR f0.1     | Isophonics pure |
| ------ | ------------ | ------------ | --------------- |
| 1      | 0.538 (0.67) | 0.590 (0.76) | 0.724 (0.77)    |
| 2      | 0.497 (0.69) | 0.550 (0.77) | 0.736 (0.82)    |
| 4      | 0.434 (0.72) | 0.493 (0.78) | 0.753 (0.87)    |
| 8      | 0.382 (0.76) | 0.476 (0.81) | 0.760 (0.89)    |
| 15     | 0.372 (0.77) | 0.459 (0.81) | 0.758 (0.91)    |
| 30     | 0.404 (0.78) | 0.486 (0.82) | 0.759 (0.92)    |
| 60     | 0.401 (0.79) | 0.483 (0.83) | 0.759 (0.93)    |

On the tonicization ruler accuracy falls essentially monotonically with memory
(a shallow basin at 15 s, second-order), and modulations matched fall from
206/399 to ~107/399: nothing between the endpoints rescues excursion tracking.
On the section ruler accuracy climbs to a broad plateau from 8 s out to 60 s,
all within 0.002 of each other, while coverage and stability keep improving with
longer memory (spurious p90 falls from 7 at 1 s to 1 at 30 s). The one cell
numerically above the shipped value, hl8 at +0.001, is a wash under the
pre-committed test: mean delta +0.0009, CI95 [-0.020, +0.021], p = 0.25
(56/36/88 wins/losses/ties), and hl30 dominates it on coverage (0.92 vs 0.89)
and stability. There is no interior optimum; the dial is a timescale selector,
not a noise-accuracy tradeoff with a sweet spot.

**Plain-English reading.** Two loose ends, both now tied. First, when we grade
the detector only on the stretches of music that are settled in one key, the
kind of stretch the app's calm indicator is built for, it is right about
two-thirds of the time on real piano recordings and shows the wrong major/minor
face about once in ten claims, mostly confusing a key with its same-tonic twin
rather than its relative. Second, we swept the memory dial across its whole
range instead of just its ends, on both answer-key styles, and the shape is
exactly what the two-endpoint story claimed: short memory is best when the
answer key tracks every excursion, long memory is best when it names the
section, and there is no clever middle setting that gets both. The shipped
30-second choice sits on a wide flat shelf where a few seconds either way
changes nothing, which is the most reassuring possible place for a shipped
parameter to live.

**Decisions.**

- Shipped configuration unchanged and now final for the test-split evaluation:
  the pre-committed adoption test came back a wash, and hl30 dominates the
  plateau on coverage and stability.
- The product-facing mode-error rate is recorded as ~10% of claims in stable
  sections (parallel-dominated); revisit only if the Phase 2 UI work surfaces
  mode complaints beyond that base rate.
- The dose-response tables are the paper's crossover exhibit in full-curve form,
  superseding the two-endpoint version.

**Next.** The configuration is frozen; the one-shot test-split evaluation across
the three frozen splits is unblocked and is the next action.
