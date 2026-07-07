# 2026-07-07: The relative tilt fails adoption: a predicted negative result

**Goal.** Attempt the relative-pair analog of the adopted mode tilt (entry 23)
before the test-split freeze. Two cue variants from the design doc's
mode-disambiguation analysis, each a zero-sum tilt within the relative pair
(same key signature) of the event chord's home key: `relativeTilt`, gated on the
chord's root also being its bass, and `relativeCadenceTilt`, gated on the
previous event being a dominant-quality chord a fifth above (a cadential
resolution). Adoption rule fixed before results: significant paired exact win on
Isophonics dev with the mode-confusion relative row improving, no significant
When in Rome regression, behavioral suite intact, spurious switches flat.

**Implementation.** Both parameters on `HmmKeyDetector`, default 0; harness
flags `--relative-tilt` and `--relative-cadence-tilt`;
`KeySpace.dominantQualities` promoted from the evidence detector's private set.
Unit tests pin both mechanisms and the trajectory invariant. One honest subtlety
surfaced by a failing first draft of that test: the pair-sum invariant is exact
for emissions, but posterior near-tie crossings between signatures can shift by
an event because priors differ within a pair (in the observed case the tilt
accelerated a genuine modulation by one event). The test asserts the meaningful
property, an unchanged signature trajectory. Defaults parity verified after
adding the parameters.

```sh
for s in 0.5 1 2; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
    --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
    --detector hmm --relative-tilt "$s" \
    --out "build/whatkey-harness/iso-relbass-s$s"
done   # same for when-in-rome-v1, and both corpora with
       # --relative-cadence-tilt 1|2|4 (dirs *-relcad-s*)
python3 tool/whatkey_compare.py \
  build/whatkey-harness/iso-relbass-s1/report.json \
  build/whatkey-harness/iso-tilt-s2/report.json
python3 tool/whatkey_compare.py \
  build/whatkey-harness/wir-relbass-s1/report.json \
  build/whatkey-harness/wir-tilt-s2/report.json
```

**Results** (exact on claimed; baseline is the shipped config with mode tilt 2):

| variant    | Isophonics dev | When in Rome dev | iso spurious p90 |
| ---------- | -------------- | ---------------- | ---------------- |
| baseline   | 0.775          | 0.434            | 1                |
| bass s=0.5 | 0.782          | 0.425            | 2                |
| bass s=1   | 0.782          | 0.425            | 2                |
| bass s=2   | 0.766          | 0.435            | 4                |
| cad s=1-4  | 0.775-0.776    | 0.434-0.436      | 1-2              |

- **The cadence variant is inert everywhere**, echoing entry 20's progression
  finding: under the HMM, sparse cadence votes add nothing the posterior margins
  need.
- **The bass variant is real but too weak to adopt.** The mechanism works as
  designed: relative confusion falls 832 to 616 events (6% to 4% of claims) at
  s=1 with exact pooled accuracy up. But the paired test on the primary ruler
  misses significance (+0.0070, CI95 [-0.0058, +0.0193], p = 0.055, 46/29/105),
  the tonicization ruler trends negative almost symmetrically (-0.0088, CI95
  [-0.0201, +0.0014], p = 0.056, 9/22/25), and iso spurious p90 doubles.
  Strength 2 is outright harmful (accuracy down, spurious p90 4): unlike the
  parallel tilt's broad plateau, this dial has a narrow sweet spot, the
  signature of a weak signal.

**Plain-English reading.** The twin-key trick that worked so well for
major-versus-minor twins does not carry over to the other kind of twin, and for
the reason the analysis predicted before running anything: with parallel twins,
hearing the rival's home chord is rare and dramatic evidence, but with relative
twins the rival's home chord is one of the most ordinary chords in the music, so
each firing says almost nothing. The bass-note filter sharpens it enough to
visibly shrink the targeted error, but what it gives with one hand it takes with
the other, more indecision and slightly worse behavior on classical excursions,
and the net effect is too small to pass our adoption bar. The cadence version,
resolving dominant chords, turned out to add nothing at all, confirming for the
second time that this detector's probability machinery already extracts
everything sparse chord patterns can offer.

**Decisions.**

- No adoption: both parameters stay at default 0. The code and tests are
  retained (the ClaimHysteresisDetector precedent: built, validated, unused), so
  the paper can cite an implemented, measured negative.
- The frozen test-split configuration is unchanged from entry 23.
- The relative-error residual (4-6% of claims, MIREX's most forgivable miss) is
  accepted as near-ceiling for chord-level evidence; the design doc's remaining
  candidates (mode as a slow latent variable, product-level hedging) are the
  future path if it ever matters.

**Next.** The one-shot test-split evaluation across the three frozen splits;
nothing further is planned before it.
