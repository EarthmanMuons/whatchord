# Chord engine benchmark

An offline performance baseline for the pure analysis engine
(`ChordAnalyzer.analyze`). It exists so the time and memory impact of future
engine changes (temporal context, key detection) can be measured reproducibly,
independent of the machine it runs on.

## Run

```bash
tool/benchmark.sh
```

This writes `benchmark/last_run.json` and prints a summary. For benchmark runs,
the wrapper enables the VM service (needed for allocation measurement) and the
counters define. Pass `-h`/`--help` for usage.

To print the committed baseline in the same summary format as a new benchmark
run:

```bash
tool/benchmark.sh --show-baseline
```

Unless `--out` points at the baseline, the run also prints a delta against
`benchmark/baseline.json` when it exists, so you can see at a glance whether a
change moved anything. The counters are exact, so any counter delta on the same
corpus is a real algorithmic change; a normalized-time delta inside its reported
CI is just noise.

## What it measures

Two corpora are replayed through `analyze()`:

- the **oracle corpus** -- every voicing in `tool/chord_oracle_reviewed.json`,
  deliberately adversarial edge cases;
- the **common voicing pool** (`src/common_voicings.dart`) -- the common chord
  qualities with inversions, approximating real-playing structures.

**Time** is reported for both corpora; **memory and counters** are reported for
the oracle corpus only, since it is the adversarial stress case and therefore
the most sensitive regression signal. The two corpora differ a lot in time (the
oracle corpus is the worst case), so do not judge a change by the oracle numbers
alone.

- **Time, normalized to a fixed reference workload.** Absolute wall-clock time
  is hardware-dependent and noisy on shared CI runners, so it is not comparable
  across runs. The harness also times a fixed, allocation-free integer workload
  (`referenceWork`) on the same machine and reports
  `engineTime / referenceTime`. A slower runner slows both, so the ratio stays
  roughly constant. **Compare the normalized numbers across runs, not the raw
  microseconds.** Cold (every call a cache miss) and warm (every call a cache
  hit) are reported separately.

  Each timing is **sampled adaptively** (like hyperfine/Criterion): after a few
  warmups the harness keeps sampling until the 95% confidence interval on the
  mean is within `targetRelCi95` (1.5%), bounded by a run cap and a wall-clock
  budget so the expensive cold pass still terminates. It reports mean, median,
  stddev, min/max, sample count, and the achieved CI, plus whether it converged
  or hit the budget. The warm pass is batched per sample so its sub-microsecond
  cost clears the timer's resolution. The normalized CI is the two component CIs
  propagated in quadrature.

- **Memory (VM-observed).** Allocation counts are useful for spotting memory
  movement, but small byte-level differences can come from runtime, VM-service,
  alignment, or GC effects.
  - `churn`: bytes/objects allocated during the measured cold pass, after
    resetting the VM allocation accumulator. This is the driver of GC pressure
    and the relevant number while the engine is mostly stateless.
  - `retained`: the post-GC heap growth from before the cold pass to after it.
    This approximates what the pass caused the isolate to keep alive, mostly the
    analyzer cache today.
  - `live heap`: the whole isolate's post-GC heap usage after the cold pass.
    This is useful context for process footprint, but it includes runtime and
    benchmark harness state, not only analyzer-owned memory.
- **Algorithmic operation counters (deterministic).** Cache hits/misses, roots
  considered, templates evaluated, candidates produced. These are integers that
  depend only on input and code, so they catch algorithmic regressions (e.g. a
  history scan that stops being incremental) with zero hardware noise. They are
  gated behind the `whatchord.counters` compile-time define and are dead-code
  eliminated in normal builds (see `EngineCounters`).

## Tracking a baseline

`benchmark/last_run.json` is the latest run and is not committed. To track a
baseline for regression comparison, copy a known-good run to a committed file:

```bash
tool/benchmark.sh --out=benchmark/baseline.json
```

and diff future runs against it. Because of timing noise, gate regressions on
counters, meaningful memory movement, and normalized time, not raw
microseconds.
