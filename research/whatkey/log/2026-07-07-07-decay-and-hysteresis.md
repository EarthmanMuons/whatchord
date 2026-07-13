# 2026-07-07: Decay sweep and claim hysteresis, a mostly negative result

**Goal.** First post-freeze tuning: attack the modulation weak axis via decay
half-life, then claim-level hysteresis to buy back any stability cost.

**Setup.** New `ClaimHysteresisDetector` in `lib/features/key/`, a decorator
around any detector: a challenger key must win `minStreak` consecutive claiming
frames before the output claim switches; inner abstentions pass through and
reset the streak; the first-ever claim also waits out the streak. Harness flag
`--hysteresis N` (default 1, off); `--sweep-margin-floors` now rejects
hysteresis because the post-hoc floor math is invalid when claims feed back into
streak state. Fixtures, split, and champion config (hybrid, blend 0.1) as in
entries 04-06.

```sh
for hl in 10 15 20 30 45; do
  dart run tool/whatkey/harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hybrid --decay-half-life-seconds "$hl" \
    --out "build/whatkey-harness/wir-dev-hybrid-hl$hl"
done
python3 tool/whatkey/compare.py \
  build/whatkey-harness/wir-dev-hybrid-hl10/report.json \
  build/whatkey-harness/wir-dev-hybrid-hl30/report.json
for cfg in 10:2 10:3 15:2; do
  dart run tool/whatkey/harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hybrid --decay-half-life-seconds "${cfg%:*}" \
    --hysteresis "${cfg#*:}" \
    --out "build/whatkey-harness/wir-dev-hybrid-hl${cfg%:*}-hys${cfg#*:}"
done
```

**Results, decay sweep** (hybrid, development split):

| half-life | coverage | exact | MIREX | spurious p90 | modulations | lag p90 |
| --------- | -------- | ----- | ----- | ------------ | ----------- | ------- |
| 10 s      | 0.75     | 0.56  | 0.67  | 4            | 162/399     | 9       |
| 15 s      | 0.75     | 0.55  | 0.65  | 3            | 144/399     | 9       |
| 20 s      | 0.75     | 0.54  | 0.64  | 2            | 134/399     | 9       |
| 30 s      | 0.74     | 0.54  | 0.64  | 1            | 120/399     | 7       |
| 45 s      | 0.74     | 0.56  | 0.66  | 1            | 121/399     | 5       |

Paired, hl10 vs hl30 on exact: +0.022, CI95 [-0.003, +0.047], p = 0.089,
32/18/7. Not significant. The behavioral suite at hl10 holds (secondary
dominants still 1.00 with zero switches).

**Results, hysteresis** (hybrid, development split):

| config        | coverage | exact | spurious p90 | modulations |
| ------------- | -------- | ----- | ------------ | ----------- |
| hl10, hys 2   | 0.71     | 0.52  | 3            | 131/399     |
| hl10, hys 3   | 0.66     | 0.52  | 3            | 119/399     |
| hl15, hys 2   | 0.71     | 0.51  | 2            | 120/399     |
| hl30 champion | 0.74     | 0.54  | 1            | 120/399     |

**Reading.** Two findings, one useful, one negative:

- **Faster decay really does buy modulation tracking**: 10 s matches 162/399 vs
  120 at 30 s, a 35% improvement, at the cost of stability (spurious p90 1 to 4)
  with no significant accuracy change. This is a genuine
  responsiveness/stability dial, and 27% of segments being 2 events or fewer
  means much of the remaining censoring is structural.
- **Hysteresis costs more than it buys here**: it suppresses some blips, but it
  also delays every real switch past the ends of short key segments (the same
  short segments the fast decay was catching), so modulation matching falls back
  to champion level while accuracy drops below it. Suppressing blips and
  catching 1-2 event key areas are directly opposed at this segment-length
  distribution; no streak length wins both.

**Plain-English reading.** Faster forgetting makes the detector turn quicker, so
it catches far more key changes, but it also gets jumpier between keys the music
never actually left. The steadying rule we added (do not switch until the new
key wins twice in a row) calms the jumpiness a little, but the delay it adds is
exactly long enough to miss the short key areas the fast turning was catching,
and holding the old answer during the wait means it is wrong more often overall.
Since the accuracy difference between fast and slow forgetting is within corpus
noise (p = 0.089 fails our bar), the current champion keeps its settings, and we
keep the fast-forgetting option in our back pocket as a responsiveness dial
rather than an accuracy win.

**Decisions.**

- Champion unchanged (hybrid, blend 0.1, 30 s half-life): nothing cleared the
  paired bar. The hl10 configuration is recorded as the responsiveness operating
  point should the app ever want a dial.
- `ClaimHysteresisDetector` stays in the codebase, tested and composable: the
  mechanism is sound and may pay off over the 2e progression layer, whose claims
  should be less blippy than histogram claims.
- Negative results logged per convention rather than buried.

**Next.** The 2e progression detectors, which attack modulation tracking with
evidence (cadences into the new key) rather than forgetting speed, and should
also be the first mechanism with a real shot at blues (a V7-IV7-I7 loop is a
progression signature, not a histogram or single-chord one).
