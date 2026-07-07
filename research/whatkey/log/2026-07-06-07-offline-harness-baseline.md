# 2026-07-06: Offline harness and the profile-correlation baseline

**Goal.** Build the offline harness (fixture/split loading, metric scaffolding
per the pinned protocol rules) and put the first number on the board with the
profile-correlation floor.

**Setup.**

- Detector and harness code at the commit following `432c953b` (the working
  change of this session; `lib` was dirty at run time because the detector
  itself was the uncommitted work). Fixture candidates are pinned independently
  by the fixture manifests: `pop-jazz-v1` at engine `349fb2c4`,
  `when-in-rome-v1` at engine `aed5ea8b`, corpus `aa7539f1`, bench `b9e011c8`.
- Split: `data/splits/when-in-rome-v1.json`, development only (59 pieces, 3694
  events). Harness validated split pins against the manifest and exact piece
  coverage before running.
- Detector: `profile-correlation` with `profiles=albrechtShanahan`,
  duration-weighted, decay half-life 30 s, `minEvents=3`, `marginFloor=0.05`
  (all defaults, untuned).
- Commands: `mise research:whatkey-harness-pop-jazz` and
  `mise research:whatkey-harness-dev`; reports under `build/whatkey-harness/`.

**What happened.**

New code: `lib/features/key/` (KeyDetector interface, KeyEstimate/Frame,
ProfileCorrelationKeyDetector with the three published profile pairs) and
`tool/whatkey_harness.dart` with `tool/src/whatkey/` (loader with structural
label isolation, protocol metrics, per-piece aggregation). 18 unit tests cover
the MIREX weighting, selective-prediction scoring, switch and lag rules, and
detector behavior on synthetic cadences.

Behavioral suite (pop-jazz-v1, 8 fixtures, per-fixture outcomes):

- Dorian vamp: abstains on all 7 events (7/7 ok), the designed outcome.
- Am-F-C-G ambiguous loop: 8/8 ok (abstains or stays within acceptable keys).
- C major loop, ii-V-I, blues, harmonic-minor i-iv-V7-i, secondary dominants:
  exact 1.00 on claimed events, zero switches (tonicizations absorbed).
- Modulating ii-V-I chain: exact 0.17, both modulations censored, 2 spurious
  switches. The expected histogram failure: 4-6 s key areas cannot win against a
  30 s half-life, and the profile floor has no notion of cadence.

Development split (when-in-rome-v1, 59 pieces):

- Coverage 0.669 (mean per piece); accuracy on claimed: exact 0.453, MIREX 0.591
  (per-piece means over 56 pieces with claims).
- Global key: final-event MIREX 0.684, duration-weighted majority 0.686
  (near-identical here; the deferred operationalization choice is not yet
  load-bearing).
- Time-to-first-claim: median 2, p90 4 events; 3 pieces never claim (they have
  fewer aligned events than `minEvents`, e.g. WTC I Prelude 02 with 2).
- Switches per piece: median 1, p90 5; spurious: median 0, p90 2.
- Modulation: 399 annotated changes, 116 matched (median lag 0, p90 7), 283
  censored. Local-key tracking through modulations is decisively the floor's
  weak axis, as predicted.

**Plain-English reading.**

- The pop/jazz suite: 7 of 8 probes behaved as hoped, and the 8th failed exactly
  as predicted. Steady-key progressions were named correctly whenever the
  detector spoke, and the two "no right answer" fixtures got silence or an
  acceptable key every time; the detector knew when not to guess. The one
  failure, the chain that changes key every few seconds, is the textbook
  weakness of this algorithm family: a histogram of recent notes turns like a
  supertanker and cannot keep up with fast key changes. Failing there is the
  reason to build the next detector, so the probe did its job.
- 0.45 exact means: of the moments where the detector was willing to name a key,
  it named the analyst's exact local key 45% of the time. The MIREX 0.59
  re-scores the same answers with partial credit for musically close misses (G
  major while in C major scores 0.5, A minor for C major 0.3). The gap between
  the two numbers says the errors are mostly neighboring keys, not random ones:
  usually the right tonal neighborhood, one door off.
- Three independent signals say modulation is the weak axis: the detector
  arrived in a newly annotated key before the next change in only 116 of 399
  cases (71% of journeys missed entirely); its one-key-per-piece score (0.68) is
  well above its moment-to-moment score (0.59), so it finds the key but loses
  the journey between keys; and the behavioral suite showed the same in
  miniature, perfect on everything static and worst on the only modulating
  fixture.

**Decisions.**

- Detectors live in `lib/features/key/` from the start, so the benchmarked code
  is the shippable code; the harness stays in `tool/`.
- Added `history_domain.dart` as a pure-Dart seam (mirroring
  `theory_domain.dart`): the full feature barrels pull Riverpod/Flutter, which a
  `dart run` CLI cannot compile.
- Spurious-switch rule refined while implementing (still provisional): a switch
  is spurious only if the annotation did not change across the window AND the
  switch does not land on the annotated key; without the second condition a
  lagged catch-up switch was charged as spurious. Caught by a unit test.
- Label isolation is structural: the loader returns label-free `ChordEvent`s and
  a parallel scorer-only label list.

**Caveats.**

- `marginFloor` and the decay half-life are untuned defaults; the
  coverage/accuracy numbers move together with them and only the pair is
  meaningful. No CIs yet.
- Modulation lag, spurious-switch alignment, and the global-key choice remain
  provisional pending freeze; the report embeds that notice.
- Tiny pieces (1-3 aligned events) structurally cannot claim under
  `minEvents=3`; whether to exclude them from the split or report them as-is is
  a freeze-time decision.

**Next.** External baselines (music21 Krumhansl variants, justkeydding) on the
same fixtures; then the weighted evidence model (2d), which must beat these
numbers, especially on modulation tracking, to earn its complexity.
