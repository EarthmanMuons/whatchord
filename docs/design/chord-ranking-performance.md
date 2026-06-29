# Chord Ranking Performance: a Designed n^2 Cost

## What this is

A record of the performance work on the chord analysis engine: how a benchmark
harness exposed that ranking is `O(n^2)` by design, what we shipped to reduce
the constant factor, what we tried and reverted, and why the `O(n^2)` itself
cannot be reduced safely (so the only available wins are constant-factor). It
exists so the shape of the code (and the things deliberately _not_ done) is
recoverable later.

The headline: the cost is real even for common chords, it lives almost entirely
in `ChordCandidateRanking.rank`, and it cannot be reduced by dropping or
score-pruning candidates without changing musician-facing output. The reasons
are specific and worth keeping.

---

## Background: ranking is intentionally non-transitive

`ChordAnalyzer.analyze` generates candidate interpretations and ranks them.
Generation (`_evaluateAll`) emits one candidate per
`(root present in the voicing) x (template that scores non-null)`, so the
candidate count grows with note count:

| voicing       | notes | candidates |
| ------------- | ----- | ---------- |
| C major triad | 3     | 25         |
| Cmaj7         | 4     | 43         |
| Cm7           | 4     | 46         |
| C7            | 4     | 48         |
| Cmaj9         | 5     | 67         |
| 6-note        | 6     | 90         |
| 7-note dense  | 7     | 131        |

The reviewed-oracle corpus (intentionally adversarial voicings) has a median of
~75 candidates and a max of 143.

`rank` then orders them with a comparator (`_decide`) that is deliberately **not
transitive**. Most pairs are decided by score, but two narrow sources override
score order:

- **Hard rules**: score-independent structural overrides (e.g. "prefer an
  altered dominant7 over a dim7 slash"). A hard rule can promote a lower-scoring
  reading over a higher-scoring one at _any_ score gap. A unit test pins this on
  purpose: a hard rule must win even across a score gap of 9 (scores 1 vs 10).
- **Tie-breaker rules**: engaged only when two candidates are within
  `nearTieWindow` (0.20) of each other.

Because the relation can contain cycles (a > b > c > a), `rank` cannot use a
plain sort. It builds the full pairwise relation and linearizes it: repeatedly
extract a maximal element (beaten by no remaining candidate), and where a cycle
blocks that, break it with a Copeland win-count (how many others each candidate
beats) plus a hard-rule "held back" guard. **The Copeland count is global**: it
sums wins over the entire remaining set. This single fact is why several
otherwise-appealing optimizations are unsafe (see below).

---

## The benchmark harness

To measure engine changes reproducibly without being at the mercy of CI
hardware, `benchmark/` replays the reviewed-oracle corpus through `analyze` and
reports:

- **Time, normalized to a fixed allocation-free reference workload**. Absolute
  wall-clock time is hardware-dependent and noisy on shared runners, so we
  divide engine time by the time a fixed integer workload takes on the same
  machine. A slower runner inflates both, so the ratio holds. Sampling is
  adaptive (keep sampling until the 95% CI on the mean is tight), and stddev is
  reported.
- **Memory**: deterministic allocation churn plus a before/after live-heap
  delta. Allocation counts depend only on input and code, not hardware.
- **Operation counters**: cache hits/misses, roots considered, templates
  evaluated, candidates produced. Integers that depend only on input and code,
  gated behind a compile-time define and dead-code eliminated in normal builds.

A run prints a delta against `benchmark/baseline.json`. The counters are exact,
so any counter change on the same corpus is a real algorithmic change; a
normalized-time delta inside its CI is noise. Compare runs on the same corpus
only (per-call values are not comparable across corpus versions); regenerate the
baseline when the corpus changes. See `benchmark/README.md`.

---

## Finding: ranking dominates, and the cost is real

Isolating `rank` (by re-ranking the candidate sets `analyze` returns) showed
**ranking is ~99% of cold analysis time**; scoring is ~1%. The cost is `n^2`
pairwise `_decide` calls, each historically scanning all 21 hard rules. It is
not VM overhead: the warm (cache-hit) path is ~0.1us while a cold full
evaluation of a common seventh chord is ~2-3ms, and that gap is entirely our
ranking code. So it matters for live play, not just the adversarial corpus.

---

## Shipped: hard-rule precondition gates (the "gate masks")

Each hard rule fires only for a specific structural pairing, and that condition
is **candidate-local**: it depends only on a single candidate's quality,
extensions, or precomputed `CandidateFeatures`, never on the candidate it is
compared against. For example, "prefer altered dominant7 over dim7 slash" needs
one operand to be a dominant7 and the other a diminished-family chord.

So each `NamedRule` carries an optional `gate`: a candidate-local predicate that
is a _superset_ of the rule's real firing precondition. In `rank` we precompute,
once per candidate (`O(n * rules)`), a bitmask of which rules it could
participate in. For a pair we then evaluate only the rules in
`gateMasks[i] & gateMasks[j]` instead of all 21. A rule needs one operand in
each role, so it can only fire when both candidates pass its gate; skipped rules
would have returned null, which makes this **provably output-identical**.

Validation is the safety net: candidate generation and scoring are untouched
(the `candidatesProduced` / `templatesEvaluated` counters stay byte-identical),
and the ranking golden plus cycle/hard-rule unit tests pass unchanged. A
too-narrow gate would silently drop a decision, so the golden + oracle suites
are the guard.

Result: cold analysis of the adversarial oracle corpus dropped ~27%; typical
voicings improved ~1.2-1.7x. This is a constant-factor win; it does not change
the `O(n^2)`.

(Rule count stays well under 32 so the mask is safe even under dart2js 32-bit
bitwise semantics.)

---

## Tried and reverted: the role-A/B split

The single union gate is broad for rules whose "other" role is common (any slash
chord, any seventh-family chord). The natural refinement is to split each gate
into two role predicates (role A and role B) and fire a rule for a pair only
when the two candidates fill _opposite_ roles, via
`(maskA[i] & maskB[j]) | (maskB[i] & maskA[j])`.

It was implemented across all 21 rules, stayed output-identical (counters
unchanged, all tests pass), and delivered **~1-3% on typical voicings and ~0% on
the dense corpus**, within benchmark noise. Reverted.

Why it did not help: the big win was already captured by skipping pairs where
_neither_ candidate is eligible, which the union gate did. Refining which role
each eligible candidate fills only trims pairs where both are eligible in the
same role, a small slice, and the second mask doubles the precompute, which
roughly cancels the saving. The lesson recorded: after the union gate, the
bottleneck is no longer the hard-rule scan. It is the `n^2` infrastructure
itself (the pairwise matrix, the linearization, and `CandidateFeatures`).

---

## Dead end: candidate-count reduction

Generation produces 25 candidates even for a plain triad, so shrinking the
candidate set looks like a direct attack on `n^2`. It is not safe:

- **Pre-ranking "keep the top N by score" is the margin-pruning we already
  proved unsafe.** Removing lower-scoring candidates before the re-order changes
  the global Copeland win-counts, which reordered surfaced near-tie alternatives
  (three ranking golden cases regressed). This is true for any N and any
  threshold; it is not about how many you keep, it is that you removed
  candidates the others were compared against.
- **Generation-time reduction has the same problem.** Dropping a candidate at
  generation removes it from everyone's win-count just the same.
- The only provably-safe drop is a Condorcet loser (beaten by all, beats none,
  no hard-rule wins), and identifying one requires the `n^2` comparison we are
  trying to avoid.

So candidate reduction is validatable-but-not-provable. Set aside in favor of a
redesign that keeps every candidate.

---

## Tried and abandoned: sorted-rank with a fast path and exact fallback

The redesign keeps the exact output (every candidate, identical order) and only
computes it faster, so it is provably output-identical rather than
empirically-validated. The design is kept below for context, but **it does not
work in practice**: see "Result (step 2)" after the algorithm. Both the binary
fast path and the localized variant are dead because the candidate scores are
too dense to give any locality to exploit.

### The structure it exploits

The seed order is `(score desc, rootPc asc)`. The comparator agrees with seed
order on every pair _except_:

- **H-edges**: a hard rule fired. These occur only between two gate-eligible
  candidates (call that set `HE`, already identified by the masks).
- **T-edges**: a tie-breaker decided against score order. These occur only
  between candidates within 0.20 of each other.

Every other pair is in seed order by construction. (Both the score-decides case
and the `rootPc` fallback match seed order.)

### The algorithm

1. Sort by seed order: `O(n log n)`.
2. Detect inversions (pairs where the comparator contradicts seed order) only
   where one can exist:
   - **Near-window**: for each candidate, `_decide` against the following
     candidates within 0.20 score.
   - **HE x HE**: `_decide` for gate-eligible pairs, `|HE|^2` rather than `n^2`.
   - A hard rule that fires but agrees with seed order is not an inversion and
     does not force fallback.
3. No inversions: return seed order. Provably identical (the linearizer
   reproduces a consistent order exactly), and the common case for simple
   voicings.
4. Inversions exist: fall back to the current unchanged `rank` for a
   guaranteed-correct result.

### Why "no inversions implies seed order"

If `beats` agrees with seed order on every pair, the first remaining seed
element is always maximal, so the linearizer returns seed order and the
cycle-break never runs. The detection step proves agreement everywhere, because
every pair that _could_ invert is either within 0.20 (near-window) or a possible
hard-rule pair (HE x HE); all others are score-decided and therefore agree.

### Where it can go wrong

1. **A missed inversion is a silent wrong answer.** An off-by-one in the
   near-window or HE enumeration drops an inversion and returns a subtly wrong
   order with no error. Mitigation: golden + oracle + transposition property
   tests, plus a debug mode that runs both paths and asserts they match.
2. **Localized fallback is not safe in v1.** The cycle-break Copeland count is
   global, so re-ranking only the affected candidates can change a tie-break
   (the same trap that broke pruning). v1 must fall back to the full unchanged
   algorithm. A localized fallback is a possible v2 only with a proof that the
   affected component is closed under the relation.
3. **Degenerate clusters erase the win.** Dense voicings with many near-ties or
   a large `HE` push the near-window or `|HE|^2` work toward `n^2` and fall back
   anyway. Acceptable (those are rare in live play), but it means the dense
   corpus will show less improvement than typical voicings. Measure both; do not
   judge by the dense corpus alone.
4. **Feature cost is untouched.** `CandidateFeatures.from` runs for all `n`
   regardless (the gates need features). If profiling shows features, not the
   matrix, are the residual cost, this redesign will not help much.
5. **Seed and fallback tie-break must match exactly.** The fast path relies on
   the `rootPc` fallback and score direction matching seed order precisely. This
   holds today; a future ranking change could break it silently, so it deserves
   an invariant comment and a test.

### Sequencing

1. Profile the post-index ranking to confirm the `n^2` matrix/linearization is
   the residual cost (not `CandidateFeatures`). If features dominate, this
   redesign is the wrong attack.
2. Build the fast-path / exact-fallback with a dual-run assert mode on in tests.
3. Validate: full test suite + zero-diff oracle + benchmark typical and dense
   voicings separately.
4. Only if needed, consider the localized-fallback v2.

### Profiling result (step 1)

Done. Temporary phase timers inside `rank`, run over the oracle corpus,
confirmed the redesign targets the right cost:

| phase        | share of ranking |
| ------------ | ---------------- |
| matrix build | 97.0%            |
| linearize    | 2.1%             |
| features     | 0.4%             |
| gate-masks   | 0.4%             |
| seed-sort    | 0.1%             |

Splitting the matrix build further: the `n^2` `_decide` loop is **99.8%** of it
and the `List<List<bool>>` allocation only 0.2%. Conclusions:

- Doing fewer `_decide` calls is the only meaningful lever, which is exactly the
  fast-path premise. GO for the redesign.
- Risk 4 is dispelled: `CandidateFeatures.from` is 0.4%, not the bottleneck.
- No cheap shortcut exists: a flat `Uint8List` matrix would save the 0.2%
  allocation only, so it is not worth doing. Linearize and masks are not worth
  touching either.

### Result (step 2): the redesign does not work

Built the fast path with a dual-run `assert` (runs in `flutter test`, stripped
from release). It is **correct** (all tests pass, byte-identical to the full
algorithm) but **never triggers**:

- Fast-path hit rate: **0 of every voicing measured**, including a plain C major
  triad. Every voicing has at least one inversion somewhere in its candidate
  list (some near-tie pair a tie-breaker reorders), and one inversion forces
  full fallback. Net effect: detection cost for no benefit (~+1%). Reverted.

The localized variant (re-rank only the entangled components) was then checked
by measuring component sizes (union-find over near-tie and shared-hard-rule
edges):

| set           | n (median/max) | max component / n     |
| ------------- | -------------- | --------------------- |
| oracle corpus | 75 / 143       | median 0.99, max 1.00 |
| C major triad | 25             | 25 (one component)    |
| Cm7 / C7      | 46 / 48        | 46 / 48               |
| Cmaj9 / Cm11  | 67 / 90        | 66 / 90               |

The entangled component is essentially the whole candidate set. Scores are dense
enough that the within-0.20 near-tie edges chain through almost everything (the
single-linkage risk, fully realized), so a localized re-rank would re-rank ~all
of `n`. There is no locality to exploit. Both variants are dead.

---

## Shipped: per-pair fast paths (score short-circuit + set-bit iteration)

Since `n^2` is intrinsic (candidates cannot be safely dropped, and the relation
has no locality), the only remaining lever is the cost of each `_decide` call.
Measuring where that goes, over a corpus pass:

| pairs                       | share           |
| --------------------------- | --------------- |
| skippable (score decides)   | 20%             |
| call `_decide`              | 80%             |
| ...of which reach tie-break | 5% of all pairs |

So the tie-break scan is _not_ the cost. The bulk is the ~75% of pairs that are
hard-rule-eligible but beyond the tie window: they call `_decide`, run the gated
hard-rule loop, and score-decide. That loop iterated all 21 rules checking the
mask bit even when one or two bits were set (~18M wasted iterations per pass).

Two output-identical fast paths address this:

- **Score short-circuit** (in the matrix loop): when the shared gate mask is
  empty (no hard rule can fire) and the score gap exceeds `nearTieWindow`, set
  `beats` directly from score and skip `_decide` entirely (and its allocation).
- **Set-bit iteration** (in `_decide`): walk only the set bits of the shared
  mask, lowest first to preserve rule order, instead of scanning all 21 rules.

Both are provably output-identical (the skipped work would have returned the
same result) and carry none of the Copeland-locality risk that sank pruning and
the redesign. Result: **~4%** on the adversarial corpus (short-circuit ~3%,
set-bit iteration ~1%), counters byte-identical, all tests pass.

The allocation hypothesis was **wrong**: churn was flat after the short-circuit
removed ~20% of `RankingDecision` allocations, so per-pair allocation is
negligible and an allocation-free decision core is not worth building.

This is the end of the safe, worthwhile per-pair wins. The residual is the
intrinsic `n^2` iteration over densely-scored candidates, each doing small real
work; there is no further lever that is both safe and meaningful.

---

## Status

The performance arc is complete. Bankable wins: the gate-mask index (~27%) and
the per-pair fast paths (~4%), both provably output-identical. The `O(n^2)` is
intrinsic and cannot be reduced safely; this is documented above so the dead
ends are not re-explored.

- Benchmark harness: shipped (`benchmark/`, `tool/benchmark.sh`).
- Hard-rule gate masks (union gate): shipped.
- Role-A/B split: tried, reverted (negative result recorded above).
- Candidate-count reduction: rejected (Copeland trap).
- Profiling (step 1): done; the `n^2` `_decide` loop is 97% of ranking.
- Sorted-rank redesign (step 2): tried, abandoned. Fast path never triggers (0
  hits) and the entangled component is ~all of `n`, so there is no locality.
- Per-pair fast paths (score short-circuit + set-bit iteration): shipped, ~4%.
- Allocation-free decision core: rejected (per-pair allocation is negligible).
