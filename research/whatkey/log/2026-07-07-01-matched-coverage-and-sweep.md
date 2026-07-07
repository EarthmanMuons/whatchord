# 2026-07-07: Matched-coverage comparison and the coverage-accuracy sweep

**Goal.** Close the two comparability gaps identified after the external
baselines: accuracy numbers at different coverages are not head-to-head, and a
single abstention operating point hides the calibration behavior.

**Setup.**

- Harness additions: every run now writes a per-event `claims.json` artifact
  next to its report; `--restrict-to <claims.json>` computes coverage and
  accuracy over only the events that run claimed on (streaming metrics stay
  full-stream); `--sweep-margin-floors` derives a coverage-accuracy curve from
  one extra detector pass at margin floor zero, since the floor is a post-hoc
  threshold that never feeds back into the histogram.
- Fixtures `when-in-rome-v1`, development split, defaults as in entry 09.
- Commands: the standard dev run, then per baseline
  `--claims-file <analyzer>.claims.json --restrict-to <our claims.json>`, then
  `--sweep-margin-floors 0,0.01,0.02,0.05,0.1,0.15,0.2,0.3`.

**Results.**

Matched coverage (scored only on the events our default detector claimed on):

| detector                           | exact | MIREX |
| ---------------------------------- | ----- | ----- |
| music21 krumhanslschmuckler        | 0.37  | 0.52  |
| music21 aardenessen                | 0.42  | 0.56  |
| ours (albrechtShanahan, streaming) | 0.45  | 0.59  |
| music21 temperleykostkapayne       | 0.50  | 0.63  |

Coverage-accuracy sweep (ours, default config, floor varied post hoc):

| floor | coverage | exact | MIREX |
| ----- | -------- | ----- | ----- |
| 0.00  | 0.90     | 0.41  | 0.55  |
| 0.02  | 0.81     | 0.42  | 0.56  |
| 0.05  | 0.67     | 0.45  | 0.59  |
| 0.10  | 0.48     | 0.48  | 0.61  |
| 0.20  | 0.23     | 0.53  | 0.65  |
| 0.30  | 0.05     | 0.69  | 0.77  |

**Reading.**

- The matched comparison settles the abstention question from entry 09: on
  exactly the same events, we still beat KrumhanslSchmuckler and Aarden-Essen,
  and TemperleyKostkaPayne still beats us. The TKP gap is a real profile-family
  effect, not an artifact of us abstaining on hard events. This strengthens the
  case from the profile A/B for revisiting the default pair with paired
  statistics.
- The sweep shows the confidence margin is genuinely calibrated: accuracy rises
  monotonically as the floor tightens, so abstention is trading coverage for
  correctness as designed. But the trade is shallow through the useful range
  (0.41 to 0.48 exact between 90% and 48% coverage); big accuracy gains only
  arrive at unusably low coverage. A better detector, not a higher floor, is
  where local accuracy has to come from.
- The floor-zero coverage is 0.90, not 1.00, because warmup abstention
  (`minEvents=3`) is not part of the floor; the external baselines have no
  warmup. And the matched runs show per-piece mean coverage 0.95 rather than
  1.00 because the 3 never-claiming pieces contribute empty subsets.

**Plain-English reading.**

- The margin floor gates every claim, not just key changes: at each chord the
  detector ranks all 24 keys, and if the leader is not ahead of the runner-up by
  at least the floor, it says nothing rather than naming a narrow leader. A
  higher floor means a pickier detector: fewer claims, but more accurate ones.
  The sweep measured exactly that trade, and it works, just weakly: making the
  detector twice as quiet only nudged its accuracy from 0.41 to 0.48. So a
  stricter mouth cannot fix a mediocre ear; the next accuracy gains have to come
  from a smarter detector, not a higher bar for speaking.
- Before this session, TemperleyKostkaPayne's lead over us had two possible
  explanations: its numbers covered every event while ours covered only the 67%
  we chose to answer, so maybe we were comparing different exams. The matched
  comparison graded everyone on the identical exam, only the events we answered,
  and TKP still won while KrumhanslSchmuckler and Aarden-Essen still lost. So
  the differences are real and come from the profile vectors themselves (each
  pair's 12-number template of what a key sounds like), not from who skipped
  which questions.
- "Revisit the default with paired statistics" means: our profile A/B compared
  averages over 59 pieces, and an average can be won by doing great on a few
  long pieces while losing on most. The paired approach asks, piece by piece,
  which profile won on this piece, then checks (Wilcoxon signed-rank) whether
  one wins consistently across pieces. Only that kind of win changes the
  default.

**Decisions.**

- `claims.json` is written unconditionally so any past run can anchor a future
  matched comparison without re-running detectors.
- Restriction deliberately affects only coverage/accuracy/ambiguous metrics;
  restricted streaming metrics have no meaning and would invite misreading.
- The sweep exists to inform the deferred protocol decision (single operating
  point vs. curve for abstain calibration); this data favors reporting the
  curve, to be pinned at freeze.

**Next.** The weighted evidence model (2d). The targets it must beat are now
precise: TKP's 0.50 exact matched, our 0.45 at 0.67 coverage, and above all the
116/399 modulation match rate from entry 07.
