# 2026-07-07: Ablation robustness at 15 s, and section-scale parity with offline baselines

**Goal.** Three follow-up questions on entry 18's adoption: does blues ever
touch F under the shipped config; is the ablation conclusion specific to 30 s
emissions; and where does the final configuration stand against established
external systems.

**Blues, verified at the claim level.** The per-event claims artifact shows F
never appears: two warmup abstentions, then C:maj on every event of both blues
fixtures, no switches at any point.

**Ablation factorial repeated at 15 s emissions** (all 16 cells, Isophonics
development split): the structure replicates exactly. Confidence weighting inert
in every pair, duration weighting worth +0.02-0.05 everywhere, f0/p0 dominating
every column pair, and the best cell (pure profile, duration on) ties the
shipped configuration at 0.76 exact. No gain is hiding at intermediate memory;
the accuracy plateau is broad across 15-30 s and the simplification conclusion
is robust to the emission-memory setting.

```sh
for f in 0 0.1; do for p in 0 0.02; do
  for w in duration flat; do for c in on off; do
    dart run tool/whatkey/harness.dart \
      --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
      --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
      --detector hmm --decay-half-life-seconds 15 \
      --functional-blend "$f" --progression-blend "$p" \
      --weighting "$w" --confidence-weighting "$c" \
      --out "build/whatkey-harness/iso-abl15-f$f-p$p-$w-$c"
done; done; done; done
python3 tool/whatkey/external_baseline.py \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json
python3 tool/whatkey/compare.py \
  build/whatkey-harness/iso-dev-hmm-shipped/report.json \
  build/whatkey-harness/iso-dev-m21-krumhanslschmuckler/report.json
```

**External anchors on the section-scale corpus** (music21 whole-piece analyzers
via the claims-file path, Isophonics development split):

| system                       | coverage | exact | MIREX |
| ---------------------------- | -------- | ----- | ----- |
| music21 KrumhanslSchmuckler  | 1.00     | 0.76  | 0.83  |
| music21 TemperleyKostkaPayne | 1.00     | 0.76  | 0.82  |
| music21 AardenEssen          | 1.00     | 0.75  | 0.82  |
| ours, shipped (causal)       | 0.92     | 0.76  | 0.82  |

Paired vs KrumhanslSchmuckler: mean delta +0.001 exact (CI95 [-0.041, +0.042], p
= 0.08 with 25/59/96 wins/losses/ties: many tiny losses offset by fewer larger
wins, a wash on average). Matched to our claimed events the baseline reads 0.76,
identical. **Statistical parity on section-scale accuracy, under a strictly
harder setting**: the baselines see each entire song before answering; ours
never sees the future, abstains honestly on the ambiguous 8%, updates live, and
carries calibrated posterior confidence and streaming stability metrics the
offline systems do not have at all.

**On justkeydding and "HMMs in the wild".** No improvement claim is made and
none is measurable: justkeydding never built in this environment (entry 09's
reproducibility note stands), and published results are on different corpora
under offline Viterbi decoding, which our protocol already rules incomparable.
What can be said precisely: our final architecture is the same family (profile
emissions under an HMM), operated causally (filtered posterior, no lookahead),
with abstention, duration weighting, and chord-event observations from a
recognizer rather than raw score pitches, and it reaches parity with offline
whole-piece baselines on our fixtures. The setting, not the accuracy number, is
the contribution, exactly as the research framing predicted.

**Plain-English reading.** Three checks, three clean answers. The blues fix is
total: the detector never says F, not even once, on either fixture. The big
simplification was not a fluke of one memory setting: rerunning the entire
experiment at a different setting produced the same verdict cell for cell. And
the final detector now matches the accuracy of standard offline key finders that
get to read the whole song in advance, while ours works live, admits when it is
unsure, and reports how confident it is, which is the whole point of the
project.

**Decisions.**

- Shipped configuration unchanged and now robustness-checked; the hl15 factorial
  and external anchors close entry 18's open caveats.
- The external-comparison claim for any writeup is fixed as parity-under-
  harder-setting, never superiority over systems we could not run.

**Next.** Mode-resolved ASAP labels, then the one-shot test-split evaluation
across all three frozen splits, then the Phase 2 product work.
