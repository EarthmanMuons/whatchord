# 2026-07-20: Lever 0 across key-behavior modes; wiring decision

**Goal.** Two follow-ups to the A/B in entry 2026-07-20-02: identify which
key-behavior preset that run corresponded to and measure the other two (could
Balanced or Reactive improve live chord naming, and does this bear on the app's
default-mode question), and record the owner's decision on how the rule reaches
the engine.

**Setup.** The app's presets differ in exactly one detector parameter (emission
half-life: Stable 30 s, Balanced 4 s, Reactive 1 s;
`packages/whatkey/lib/src/models/key_behavior.dart`; the other preset fields are
display-side). The entry -02 run used the package default half life, 30 s, so it
was Stable-mode. `lever0_eval.dart` now takes `--behavior` and constructs the
detector exactly as the app does. Same fixtures, splits, and arms as entry -02.

```sh
for mode in stable balanced reactive; do
  dart run tool/chord-context/lever0_eval.dart \
    --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
    --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
    --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
    --split development --behavior $mode \
    --out build/chord-context/lever0/dcml-dev-$mode
  dart run tool/chord-context/lever0_eval.dart \
    --fixtures research/whatkey/data/fixtures/when-in-rome-v1 \
    --labels build/chord-context/labels/when-in-rome-v1.labels.json \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --split development --behavior $mode \
    --out build/chord-context/lever0/wir-dev-$mode
done
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/lever0/dcml-dev-balanced/report.json \
  --baseline-report build/chord-context/lever0/dcml-dev-stable/report.json
# ... and the reactive/wir variants likewise.
```

**What happened.** Helped/hurt flips per mode (all arms keep zero hurt):

| ruler    | stable | balanced | reactive |
| -------- | ------ | -------- | -------- |
| DCML dev | 544/0  | 541/0    | 539/0    |
| WiR dev  | 17/0   | 16/0     | 14/0     |

Paired mode-vs-mode comparisons of the closed arms are statistically
indistinguishable everywhere: balanced-vs-stable DCML mean delta +0.0004, CI95
[-0.0017, +0.0031], p = 0.93 (63 wins / 56 losses / 804 ties);
reactive-vs-stable DCML +0.0007, p = 0.60; When-in-Rome deltas -0.0004 and
-0.0003, p = 0.79 and 1.00. Claim coverage is mode-invariant (98.3-98.4% DCML,
93.8-93.9% WiR). The win/loss pattern shows the modes trading different pieces
(shorter memory follows mid-piece modulations sooner but re-warms after them;
longer memory is steadier), netting zero.

Timing caveat: fixture timestamps are synthetic musical time (500 ms per
quarterbeat on DCML, chart tempo on When-in-Rome), which is realistic for
moderate tempi but means the seconds-based half-lives were not exercised against
rubato or real performance timing.

**Plain-English reading.** The lever 0 rule is robust to how twitchy the key
detector is: whichever preset the user runs, the renames it makes are right and
it never breaks a correct name. For the separate question of whether Balanced
should become the app default, this data says chord-naming accuracy is not a
differentiator: switching the default would neither help nor hurt the chord
display. That decision can rest on the key-display experience itself (the
stability, lag, and abstention tradeoffs measured in the WhatKey work), with
this result removing one possible objection.

**Decisions.**

- Owner decision on wiring: the prevailing tonality is always treated as
  deliberate, whether manually chosen, the untouched default (C major), or
  auto-adopted. No app-side gating, no key-confidence machinery: the engine rule
  fires under whatever `AnalysisContext.tonality` it is given, like every other
  tonality-gated tie-breaker. The key-confidence question from entries -01 and
  -02 is closed, not deferred: complicated eligibility logic around "did the
  user mean this key" is judged a mistake; the user knows what they are doing.
- Consequence accepted explicitly: an isolated F-A-C-D voicing under the default
  C major key displays Dm7/F, the in-key reading. In-key, that is the convention
  both traditions support; users wanting the bare F6 reading have the near-tie
  alternative on screen and the key picker in hand.
- The lever 0 engine rule needs no mode awareness and no context additions: a
  pure tonality-gated tie-breaker, evaluated identically under any behavior
  preset.

**Next.**

- Implement the engine tie-breaker (family-scoped, tonality-gated, above the
  four existing family rules), with unit tests pinning the decided degree
  conditions and the no-fire cases (borrowed major-key iiø65 stays m6, tonic
  sixths stay 6th).
- Parity re-run of the A/B through the engine implementation, then the benchmark
  gate, then the app-side CHANGELOG entry.
