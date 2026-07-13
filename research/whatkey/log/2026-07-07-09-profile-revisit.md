# 2026-07-07: Profile revisit resolved, Albrecht-Shanahan stays

**Goal.** Close the deferred default-profile question from entry 2026-07-06-09:
on the bare profile floor, both Temperley pairs beat Albrecht-Shanahan on
unpaired means, and the matched-coverage run confirmed a real profile-family
effect. Does that still hold inside the current champion?

**Setup.** Champion config (hybrid, functional 0.1, progression 0.02, 30 s
half-life), development split, one run per profile pair, paired against the
Albrecht-Shanahan run.

```sh
for p in temperley temperleyKostkaPayne krumhanslKessler; do
  dart run tool/whatkey/harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hybrid --profiles "$p" \
    --out "build/whatkey-harness/wir-dev-hybrid-p0.02-$p"
done
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-dev-hybrid-p0.02-temperley/report.json \
  build/whatkey-harness/wir-dev-hybrid-p0.02/report.json
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-dev-hybrid-p0.02-temperleyKostkaPayne/report.json \
  build/whatkey-harness/wir-dev-hybrid-p0.02/report.json
```

**Results** (champion config, development split):

| profiles             | coverage | exact | MIREX | modulations |
| -------------------- | -------- | ----- | ----- | ----------- |
| albrechtShanahan     | 0.79     | 0.55  | 0.65  | 133/399     |
| temperleyKostkaPayne | 0.77     | 0.56  | 0.66  | 123/399     |
| temperley (1999)     | 0.75     | 0.55  | 0.65  | 124/399     |
| krumhanslKessler     | 0.75     | 0.50  | 0.60  | 117/399     |

Paired vs Albrecht-Shanahan on exact: TKP +0.006 (CI95 [-0.025, +0.040], p =
0.93, 21/24/12); Temperley +0.003 (CI95 [-0.032, +0.036], p = 0.79, 25/24/8).
Both at lower coverage and fewer modulations matched than AS. Krumhansl-Kessler
remains clearly worst.

**Plain-English reading.** On the bare histogram, the choice of key template
mattered a lot; inside the full champion it no longer does. The functional and
progression layers supply the same kind of information the better templates were
supplying, so once they are present, swapping templates moves nothing that
survives the paired test, and Albrecht-Shanahan actually answers slightly more
often. The lesson: the ingredients were substitutes, not complements, and the
profile question stopped being important the moment function entered the model.

**Decisions.** Default stays `albrechtShanahan`; the candidate change from entry
2026-07-06-09 is resolved with paired evidence rather than left hanging.

**Scope caveat and follow-up grid.** The comparison above held the blends fixed
at the values tuned for Albrecht-Shanahan, ruling out a drop-in swap but not a
joint (profile x blends) optimum: a pair at its own re-tuned blends could in
principle still win. To close that gap, a 3x3 blend grid was run for TKP (the
strongest candidate), functional {0.05, 0.1, 0.15} x progression {0.01, 0.02,
0.05}:

```sh
for fb in 0.05 0.1 0.15; do
  for pb in 0.01 0.02 0.05; do
    dart run tool/whatkey/harness.dart \
      --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
      --split-file research/whatkey/data/splits/when-in-rome-v1.json \
      --detector hybrid --profiles temperleyKostkaPayne \
      --functional-blend "$fb" --progression-blend "$pb" \
      --out "build/whatkey-harness/wir-dev-hybrid-tkp-f$fb-p$pb"
  done
done
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-dev-hybrid-tkp-f0.15-p0.02/report.json \
  build/whatkey-harness/wir-dev-hybrid-p0.02/report.json
```

The grid is flat: exact spans 0.53-0.56 across all nine cells against the
champion's 0.55. Even the best-looking cell (functional 0.15, progression 0.02:
0.56 exact at 0.81 coverage), which as the selected maximum of nine noisy
estimates carries winner's-curse inflation in its favor, is a paired wash
against the champion: exact +0.010 (CI95 [-0.009, +0.032], p = 0.90, 22/24/11),
coverage +0.021 (p = 0.18). The saturation reading stands on evidence now, not
argument: no TKP configuration in the plausible blend range beats
Albrecht-Shanahan once the functional layers are present.

**Next.** Per the agreed ordering: commit the license-verified when-in-rome-v1
fixtures into `data/fixtures/` (the frozen protocol should not depend on a
rebuildable /private/tmp checkout), then the pop-jazz-v2 amendment with the
two-chorus blues.
