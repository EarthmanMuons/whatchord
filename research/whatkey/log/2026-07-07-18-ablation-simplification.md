# 2026-07-07: The ablation removes the functional layers and blues falls out fixed

**Goal.** The post-architecture ablation pass entry 12 deferred weight tuning
behind: under the shipped section-scale default, which ingredients still earn
their keep? Run the full 2^4 factorial rather than one-factor-at-a-time, since
this project has repeatedly hit interaction and substitution effects.

**Setup.** Four binary ingredients on the HMM's emissions: functional blend (0
vs 0.1), progression blend (0 vs 0.02), duration weighting (on vs flat),
confidence weighting (on vs off). All 16 combinations on the Isophonics
development split; OFAT secondary on ASAP; behavioral suite and When in Rome
disclosure for the adopted config. Removal criterion pre-stated before looking:
an ingredient is removable only if dropping it shows a CI95 for exact-accuracy
harm within +/-0.02 and no significant coverage or stability loss.

```sh
for f in 0 0.1; do for p in 0 0.02; do
  for w in duration flat; do for c in on off; do
    dart run tool/whatkey/harness.dart \
      --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
      --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
      --detector hmm --functional-blend "$f" --progression-blend "$p" \
      --weighting "$w" --confidence-weighting "$c" \
      --out "build/whatkey-harness/iso-abl-f$f-p$p-$w-$c"
done; done; done; done
python3 tool/whatkey/compare.py \
  build/whatkey-harness/iso-abl-f0-p0-duration-off/report.json \
  build/whatkey-harness/iso-abl-f0.1-p0.02-duration-on/report.json
```

**Factorial results** (Isophonics dev, exact on claimed; full table in the run
reports): the structure is clean, not a noisy maximum.

- **Confidence weighting: numerically identical in every one of the eight on/off
  pairs.** Fourth and final null result; switched off in the shipped emissions
  (dead computation).
- **Duration weighting: load-bearing**, +0.02 to +0.05 exact consistently across
  all cells. Kept.
- **Functional and progression blends: removing them helps.** f0/p0 rows
  dominate their counterparts in every column pair; the best cell is the
  simplest (0.76 exact / 0.92 coverage vs the champion's 0.71 / 0.94).

**Paired adoption evidence.** Pure-profile emissions vs the full stack: **+0.053
exact, CI95 [+0.014, +0.094], p = 0.016** (65/38/77), coverage -0.013 (p = 0.09,
marginal). Multiplicity honesty: the candidate is the best of sixteen cells, so
the p-value carries selection pressure; the adoption rests on the conjunction of
the consistent factorial structure (f0 dominated in all four column pairs, not
one lucky cell), the direction being simplification rather than addition, and
two independent corroborations: ASAP shows no harm (within-pair 67% vs 68%,
fewer switches), and the behavioral suite delivered the strongest external
validation this project has produced:

**Blues is fixed. Both fixtures, exact 1.00, zero switches.** The flagship probe
that survived three targeted fixes (entries 08, 10, 11) is resolved by deletion:
the evidence model's dominant-on-V rule voted V-of-F on every blues I7, and that
pull was the whole problem. The pure histogram at 30 s through the HMM's
persistence reads both choruses as C, exactly as entry 07 recorded for the
original profile floor. The remaining suite is consistent with the product
timescale: steady-key probes 1.00, ambiguity intact, the tonicization-scale
chain fully absorbed (0.00, the chosen trade at full expression).

**Adopted: the HMM's shipped emissions are pure profile correlation**
(functional 0, progression 0, confidence weighting off, duration weighting on),
as `HmmKeyDetector.defaultEmission*` constants; the harness resolves blend
defaults per detector, so the hybrid keeps its validated nonzero blends as the
tonicization-scale detector. When in Rome disclosure at the shipped defaults:
0.40 exact, 110/399 modulations (the reflex-scale cost grows; that ruler is
served by `--decay-half-life-seconds 1` plus the hybrid blends).

**Plain-English reading.** We built three clever layers on top of note counting:
rules about chord functions, rules about chord progressions, and a distrust dial
for uncertain chords. Under the question the product actually asks ("what key is
this song in"), the honest measurement is that all three either do nothing or
get in the way, because what they add is sensitivity to brief harmonic detours,
which is precisely what the app decided not to report. Removing them made the
detector simpler, slightly more accurate, steadier, and, as a bonus nobody
engineered, finally correct about the blues: the layer that kept hearing every
blues chord as "get ready for F" is gone. The clever layers were not wasted
work; they were how we learned which question they answer, and they remain the
right tools for the fast-reflex setting the classical benchmark measures.

**Decisions.**

- Shipped emissions: pure profile correlation as above. The hybrid, evidence,
  and progression detectors remain in the codebase as the tonicization-scale
  toolkit and ablation baselines.
- **The deferred point-weight tuning is resolved by elimination**: the weights
  in question no longer participate in the shipped path, so there is nothing to
  tune for the product. Tuning them for the tonicization-scale configuration
  stays possible but unscheduled.
- Confidence weighting closes at 0-for-4, off by default in emissions; parameter
  retained.
- Blues probes: passing, at last.

**Next.** Mode-resolved ASAP labels as pre-ship verification of mode accuracy on
performed input, then the one-shot test-split evaluation across all three frozen
splits with the shipped configuration, then Phase 2's remaining product work
(the inferred-key provider and home-screen indicator, plus the
debug/profile-build panel).
