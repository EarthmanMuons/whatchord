# 2026-07-07: pop-jazz-v2 gives blues a fair test, and the champion still fails it

**Goal.** First protocol amendment: add the two-chorus 12-bar blues fixture so
the blues probe tests the realistic looping case (entry 08 showed the
single-chorus fixture ends on the V7 turnaround, before the loop-seam cadence
that identifies the tonic), then find out whether the champion's blues failure
was a fixture artifact or a real model limitation.

**Setup.** New source chart
`data/sources/pop-jazz/twelve-bar-blues-c-two-chorus.json` (two choruses, final
tonic ending; the seam puts bar 12's G7 against the next chorus's C7). Generated
`pop-jazz-v2` (9 fixtures; v1 stays committed and immutable); PROTOCOL.md
amendment swaps the behavioral-suite pin, with both blues fixtures retained;
mise tasks point at v2.

```sh
python tool/whatkey_fixture_extract.py \
  --set pop-jazz-v2 \
  --out research/whatkey/data/fixtures \
  charts --charts-dir research/whatkey/data/sources/pop-jazz
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v2 \
  --detector hybrid --out build/whatkey-harness/pop-jazz-v2-hybrid
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v2 \
  --detector progression --out build/whatkey-harness/pop-jazz-v2-progression
```

**Results.** The champion (hybrid, functional 0.1, progression 0.02) fails the
two-chorus blues exactly as it failed the single chorus: exact 0.00, MIREX 0.50,
claiming F throughout, at 0.83 coverage. All other fixtures behave as in
entry 08. The standalone progression detector, by contrast, eventually finds C
on the looping form: exact 0.47, MIREX 0.74, with wobble (3 switches).

**Reading.** The failure is not the fixture; it is the blend arithmetic, and the
diagnosis is now precise. The evidence model's dominant-on-V rule votes V-of-F
on every blues I7 (a C7 is, per event, strong F-major evidence to a rule that
has no concept of a dominant-quality tonic), and the histogram leans F as well
(Bb in every tonic chord). Those are per-event pulls, renewed on every chord.
The progression layer's counter-evidence, the seam cadence and plagal returns,
is sparse: a handful of votes per chorus, scaled by blend 0.02. Steady per-event
pressure beats sparse pattern votes at that ratio, and raising the progression
blend to where blues flips costs corpus accuracy (entry 08's blend sweep). The
probe now isolates a genuine model limitation: the evidence model needs a
concept of dominant-quality tonics (the same idea the progression layer's tonic
set already has) before blues can pass through the hybrid.

**Plain-English reading.** We gave the detector the fair version of the test,
where the band plays the twelve bars twice and comes home, and it still calls
the song in F. The reason is a tug-of-war imbalance: every single blues chord
whispers "F" to the note-counting layers (a C7 chord is literally the classic
get-ready-for-F chord in traditional harmony), while the "no, we came home to C"
moments happen only twice a chorus. A steady whisper on every chord outweighs an
occasional clear statement at the volume we currently give it. The one layer
that listens to arrivals rather than notes does eventually get it right on its
own. The fix belongs in the note-counting layer's rules (it needs to know that
blues home chords carry a flat seventh), not in shouting the arrivals louder,
which we measured to hurt everything else.

**Decisions.**

- Behavioral suite pinned to `pop-jazz-v2` via the protocol's first amendment;
  both blues fixtures retained (single-chorus documents the edge, two-chorus is
  the fair test). The suite is per-fixture pass/fail outside all pooled
  statistics, so the amendment cannot contaminate tuning.
- Blues stays failing, now attributed to the evidence model's missing
  dominant-quality-tonic concept rather than to fixture design or blend values.
  A candidate fix (tonic quality set in the evidence model mirroring the
  progression layer's) is future detector work, gated as always by the
  behavioral suite and paired corpus tests.

**Next.** The 2c HMM (forward-algorithm posterior over the hybrid's emissions,
transition matrix as principled hysteresis) and ASAP performed-input fixtures
remain the two big tracks; the evidence-model tonic fix is a smaller targeted
item now unblocked by this diagnosis.
