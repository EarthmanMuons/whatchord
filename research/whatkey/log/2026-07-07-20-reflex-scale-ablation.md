# 2026-07-07: The reflex-scale ablation completes the crossover story

**Goal.** Close the last ablation gap for the paper: the functional layers were
validated at reflex scale under the hybrid (entries 04, 08) but never ablated
under the HMM at one-second emissions. Run the full 16-cell factorial on When in
Rome's tonicization-scale ruler, mirroring entry 18's section-scale factorial.

```sh
for f in 0 0.1; do for p in 0 0.02; do
  for w in duration flat; do for c in on off; do
    dart run tool/whatkey/harness.dart \
      --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
      --split-file research/whatkey/data/splits/when-in-rome-v1.json \
      --detector hmm --decay-half-life-seconds 1 \
      --functional-blend "$f" --progression-blend "$p" \
      --weighting "$w" --confidence-weighting "$c" \
      --out "build/whatkey-harness/wir-abl1-f$f-p$p-$w-$c"
done; done; done; done
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-abl1-f0.1-p0-duration-on/report.json \
  build/whatkey-harness/wir-abl1-f0-p0-duration-on/report.json
```

**Results** (When in Rome dev, 1 s emissions; full table in the reports):

- **The functional blend flips sign with the ruler.** At reflex scale it is
  decisively load-bearing: +0.061 exact paired (CI95 [+0.019, +0.108], p =
  0.010), +0.086 coverage (p < 0.0001, 43/9/7), and 207 vs 169 of 399
  modulations. At section scale (entry 18) removing it was a significant win.
  One ingredient, two rulers, opposite signs, both ends now paired- tested: the
  crossover is the paper's cleanest single exhibit that the functional layers
  are excursion detectors, valuable exactly when excursions are the question.
- **The progression blend's earlier value was architecture-specific.** Under the
  HMM it is a wash even at reflex scale (-0.004 exact, p = 0.10; modulations 207
  both ways). Its entry-08 paired coverage win was real but belonged to the
  hybrid, whose margin-based abstention the sparse cadence votes could tip; the
  HMM's posterior margins do not need the help.
- **Duration weighting helps at both scales** (+0.02-0.03 here), the one
  universally load-bearing ingredient.
- **Confidence weighting is inert at both scales** (fifth null, and the last
  planned test of it).

**Plain-English reading.** We reran the strip-down experiment on the other
ruler, the one that grades quick reflexes, and got the mirror image: the
chord-function rules that hurt the calm product configuration are genuinely
valuable when the job is catching brief key excursions, and that value is now
established with the same statistical standard used to remove them. The
progression rules turned out to have been propping up a weakness of the older
detector rather than adding information of their own, and the
recognizer-confidence idea is now conclusively a no-op everywhere we could test
it. For the paper this is the tidy ending: every ingredient has a measured
domain where it helps, hurts, or does nothing, on both rulers.

**Decisions.**

- No configuration changes: the shipped section-scale config and the
  tonicization-scale toolkit (hybrid with blends, or HMM at 1 s with the
  functional blend) are both now factorial-validated on their home rulers.
- The tonicization-scale HMM reference config for the paper is functional 0.1,
  progression 0, duration on: simpler than the hybrid-era stack and equal or
  better on every reflex-scale metric measured.
- Confidence weighting: investigation closed at 0-for-5.

**Next.** Unchanged: mode-resolved ASAP labels, the one-shot test-split
evaluation, then Phase 2 product work. Future model directions (HSMM, BOCPD, the
information ceiling) are recorded in the design doc.
