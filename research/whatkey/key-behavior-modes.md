# Key behavior modes: stable / balanced / reactive (informal)

2026-07-09. Product exploration, not part of the frozen Phase 1 record: no
frozen artifact, split, fixture, or log entry was modified, and no test-split
run was performed. Everything here uses the existing harness on the two
development rulers, with outputs under `build/whatkey-local/` (regenerable,
untracked). Statistical comparisons use `tool/whatkey_compare.py` (paired
per-piece Wilcoxon on exact-on-claimed).

## Question

After living with the auto key UI, a user-facing "key behavior" setting of
stable / balanced / reactive looks attractive: stable keeps the shipped
section-key reading, reactive leans toward the local-key reading the paper
deliberately declined, and balanced sits between. Before offering that, the
reactive side needed its own pass over accuracy, spurious switches, lag,
ingredient choices, and display calibration, since every shipped constant was
selected under the section-key ruler.

## Recommended presets

All three are the shipped `HmmKeyDetector` with default margin floor 0.3 and
mode tilt 2; the modes differ only in emission half-life and display
temperature. BOCPD and the functional blend were both evaluated and rejected
(below).

| mode     | emission half-life | display temperature   |
| -------- | ------------------ | --------------------- |
| stable   | 30 s (shipped)     | 1.55 (frozen)         |
| balanced | 4 s                | 1.5 (ECE 0.024, Iso)  |
| reactive | 1 s                | 1.75 (ECE 0.035, WiR) |

Development-split behavior (Isophonics dev = section-key ruler, 183 tracks; When
in Rome dev = local-key ruler, 59 pieces; cov / exact-on-claimed / modulations
matched / spurious med/p90):

| mode     | Isophonics dev               | When in Rome dev             |
| -------- | ---------------------------- | ---------------------------- |
| stable   | 0.92 / 0.775 / 94/192 / 0/1  | 0.78 / 0.434 / 120/399 / 0/1 |
| balanced | 0.88 / 0.769 / 141/192 / 1/4 | 0.74 / 0.458 / 139/399 / 1/3 |
| reactive | 0.79 / 0.736 / 150/192 / 2/9 | 0.68 / 0.546 / 184/399 / 1/5 |

Paired evidence:

- Balanced vs stable on the section ruler: exact wash (-0.006, p = 0.92,
  62/59/59) while matching +47 more of 192 modulations. It is "stable but
  faster", not a compromise on section accuracy.
- Reactive vs stable on the local ruler: +0.104 exact, CI95 [+0.041, +0.171], p
  = 0.0089, 33/21/2, with 184 vs 120 of 399 modulations matched and median lag 3
  events. On the section ruler it gives up 0.04 exact and answers less often;
  that is the trade the mode advertises.
- Coverage falls with reactivity (0.92 / 0.88 / 0.79 on Isophonics): shorter
  memory abstains more. Reactive shows more "Listening" gaps by design.

## What was evaluated and rejected

**BOCPD.** Entry 2026-07-07-26 recorded BOCPD dominating the HMM's fast settings
on the section ruler at matched reactivity, which motivated a fresh grid here
(hazard 0.005-0.03125, emission temperature 0.25-1.0) on both rulers. On the
local-key ruler it peaks at 0.436 exact / 186/399 with heavy switching (med 5-6
per piece); every BOCPD setting is dominated by an HMM half-life setting on one
ruler or both once short-memory HMM configs are on the table (e.g. Iso: hl4
0.769/141 vs t=0.5's 0.751/142 with worse spurious; hl8 0.773/119 vs t=1.0's
0.765/121). Its earlier promise was real but narrow: adaptive windowing wins
only against blend-free fast HMMs on the section ruler, and a mode setting has
no reason to switch detector class for that.

**The functional blend.** Factorially load-bearing at reflex scale on the
classical corpus (+0.05-0.06 exact at hl1, frozen entry 2026-07-07-20, and
reproduced here: 0.601 vs 0.546), it fails the product on the behavioral suite:
any blend at short memory breaks the 12-bar blues probes. At hl1, blend 0.1
reads both blues fixtures as the IV key (exact 0.00, MIREX 0.50); blend 0.02
churns (exact 0.40-0.57 with spurious switches); at hl4 blend 0.02 keeps exact
1.00 but collapses coverage (0.25-0.57 vs 0.83-0.91). The dominant-seventh
voting that catches classical excursions is exactly what misreads blues harmony,
and blues-adjacent material is core product input. All three presets therefore
run blend 0. The cost is visible on the descending ii-V-I chain probe (reactive
with blend followed it 1.00; without, 0.20): the reactive preset chases
section-scale modulations, not tonicization chains.

**The Temperley profile.** The one exhaustive-sweep surprise: at hl1 on the
local ruler, Temperley scores 0.607 exact vs Albrecht-Shanahan's 0.546 with
fewer switches, and Temperley-Kostka-Payne 0.584 with 191/399 modulations. But
the behavioral suite disqualifies it the same way it disqualified the blend: at
hl1 and hl4 Temperley reads both 12-bar blues probes as the IV key (exact 0.00)
and drops the Dorian vamp to zero coverage. Another classical-corpus win that
core product material vetoes; all presets keep Albrecht-Shanahan.

## Knob-by-knob verdicts (exhaustive pass)

Every remaining harness knob was swept at the reactive (hl1) and balanced (hl4)
bases on both rulers, since the frozen verdicts were established at section
scale or under the retired hybrid.

- **Self-transition (0.9)**: a real reactivity dial, but strictly worse than the
  half-life here. 0.7 at hl1 buys +0.014 local exact and 201/399 modulations at
  a heavy coverage cost (0.68 to 0.60 WiR, 0.79 to 0.61 Iso) with more
  switching. Keep 0.9 for all modes.
- **Emission temperature (0.25)**: the other redundant dial. 0.15 maximizes
  modulation catching (210/399) but wrecks section stability (Iso spurious
  med/p90 5/15); 0.5 is calmer but drops modulations to 150. The half-life spans
  the same frontier with better trades. Keep 0.25.
- **Margin floor (0.3)**: 0.2 buys coverage at accuracy/stability cost, 0.4 the
  reverse; 0.3 sits where claimed-accuracy and coverage cross. Keep.
- **Hysteresis**: re-tested under the HMM at hl1 and confirmed negative, same
  mechanism as the frozen hybrid result (entry 2026-07-07-07): streak 2 drops
  local exact 0.546 to 0.495 and modulations 184 to 149. The delay eats exactly
  the short segments fast memory catches. Closed for good.
- **Progression blend (0)**: at 0.02 it is within noise everywhere (+0.007 local
  exact at hl1, +0.004 at hl4) and starts churning the blues probes at hl1 (0.88
  exact with spurious switches; 0.63 at 0.05). Its original blues promise does
  not materialize as accuracy. Keep 0.
- **Duration weighting (on)**: flat weighting is worse on both rulers at hl1
  (Iso 0.701 vs 0.736 exact). Confirmed universally load-bearing; keep on.
- **Confidence weighting (off)**: byte-identical metrics at hl1. Sixth null
  result; permanently closed.
- **Mode tilt (2)**: 1 and 3 are both equal-or-worse at hl1 on both rulers. The
  adopted value holds at reflex scale. Keep 2.
- **Relative tilt / relative cadence tilt (0)**: inert at hl1 (cadence tilt
  literally identical; relative tilt trades a few modulations for switching).
  Keep 0.
- **Event-count decay**: not re-run; frozen entry 2026-07-07-15 already showed
  it behaves identically to wall-clock decay at matched scale, and live app
  input is wall-clock. Skipped on that evidence.

The net result of the exhaustive pass is that no knob beyond the emission
half-life and the display temperature earns a per-mode value: the presets stay
two-dimensional, and every default is now default for a measured reason at all
three timescales.

## Adoption streak and freshness timers (app layer)

The write-back streak was simulated from the claims artifacts (adoption = a
claim persisting k consecutive claiming events, mirroring KeyModeNotifier):

| config, ruler | streak 1      | streak 2      | streak 3      |
| ------------- | ------------- | ------------- | ------------- |
| stable, Iso   | med 0, max 8  | med 0, max 6  | med 0, max 6  |
| balanced, Iso | med 2, max 17 | med 1, max 14 | med 1, max 14 |
| reactive, Iso | med 5, max 32 | med 2, max 27 | med 1, max 23 |

(adoptions per piece; each streak step costs exactly one event of write-back
delay.) The shipped streak of 2 is well placed for every mode: at reactive it
halves selected-tonality flips for one event of delay, and the posterior wheel
and strip react instantly regardless, since write-back only affects spelling and
scale degrees. Keep 2 in all modes.

The freshness timers cannot be evaluated by the harness: they govern silence
behavior, and fixtures are continuous. One principled observation: the stale
timer's original rationale ("matches the detector's emission half-life") holds
only for the stable preset. Under reactive, evidence has genuinely half-faded
after 1 s of silence, so a claim still shown bold at 25 s overstates support.
The shipped presets therefore scale the stale window (stable 30 s, balanced 20
s, reactive 10 s), a feel compromise rather than literal half-life honesty,
which would dim during ordinary phrase breaks (4 s / 1 s). The 2 min full reset
stays shared across modes. The exact faster-mode values remain an on-device feel
decision.

## Calibration

Method mirrors the frozen display-calibration entry: NLL argmin over
exact-labeled development events, fit per mode on the ruler the mode's claims
are supposed to mean, transfer reported on the other ruler.

- Reactive, fit on When in Rome dev: T = 1.75, conf 0.615 vs acc 0.590, ECE
  0.035 (raw ECE 0.265). Iso transfer argmin is 1.5, so 1.75 slightly
  over-softens on pop material; acceptable for the mode whose claims mean local
  keys.
- Balanced, fit on Isophonics dev: T = 1.5, conf 0.757 vs acc 0.780, ECE 0.024.
  The NLL basin is flat through 1.55, so reusing the shipped constant would also
  be defensible.
- Stable keeps the frozen 1.55; nothing here re-fits it.

The shipped 1.55 must not be reused for reactive: it leaves the reactive config
at ECE ~0.12 on its home ruler.

## Behavioral suite (pop-jazz-v2)

All steady-key probes exact 1.00 in all three modes; ambiguity handling intact
(8/8 and 7/7 everywhere). Blues clean in all three modes (the blend rejection
above is what preserved this). The modulating chain probe remains a documented
miss in every preset (0.00-0.20 exact); following it requires the blend that
breaks blues. The Dorian vamp abstains more as memory shortens (stable 0.29
coverage, reactive 0.57 but claim-free; both handled acceptably).

## Closed loop (write-back feeding recognition)

The temporary closed-loop probe (`test/_whatkey_closed_loop_probe_test.dart`,
run with `--run-skipped`) re-ranks each fixture event's candidates from its raw
voicing under the tonality the write-back engine would have adopted, then feeds
the detector, versus the neutral-context recorded candidates. Re-run under all
three mode presets, since reactive adopts a new context several times per piece
where stable rarely moves:

- Identity churn is ~0.4% of events (14-16 of 3694) in every mode, both under
  streak-2 adoption and instant adoption, and none of it moves any summary
  metric; the single per-piece change anywhere is one Bach prelude at -0.02
  exact under stable.
- The feedback path is inert at all three timescales: the ranking's
  tonality-gated tie-breakers almost never flip a top identity, so the detector
  effectively sees the same stream regardless of what the app adopted. Offering
  the mode setting does not open a feedback-stability risk.

## Caveats before shipping

- Development splits only. If a mode setting ships and we want headline claims
  about it, the reactive/balanced presets deserve their own one-shot test-split
  entry under the protocol; this document is not that.
- The local ruler is classical (When in Rome); reactive's +0.10 exact may not
  transfer to pop excursions, where no local-key labels exist.
- The adoption streak was simulated from claims artifacts (keep 2, above), but
  the freshness timers remain untestable offline; the shipped stale windows
  (30/20/10 s) are a feel compromise and may need on-device adjustment.
- ASAP fixtures were not regenerated for this pass (license-gated, build-only);
  Isophonics dev + When in Rome dev + the behavioral suite were judged
  sufficient for a product-default decision.

## Reproduction

```sh
# Presets (swap --decay-half-life-seconds 30|4|1):
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --detector hmm --decay-half-life-seconds 4 \
  --out build/whatkey-local/iso-hmm-hl4-f0
# Same for when-in-rome-v1 and pop-jazz-v2 (no split file).
# Calibration fits add:
#   --sweep-calibration-temperatures 1,1.25,1.5,1.75,2,2.25,2.5,2.75,3,3.5,4
# Paired tests:
python3 tool/whatkey_compare.py <candidate>/report.json <baseline>/report.json
```
