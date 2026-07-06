# 2026-07-06: Statistical reporting conventions

**Goal.** Decide how WhatKey should summarize uncertainty, distribution shape,
and paired comparisons before the evaluation protocol is frozen.

**Setup.** Protocol draft at commit `5973035d`; no detector experiment or
fixture run. This was a methods decision while tightening
`research/whatkey/PROTOCOL.md`.

**What happened.** Clarified that the protocol should use one confidence level
throughout: CI95. CI99 was considered but rejected as extra clutter rather than
useful evidence. For accuracy-like metrics such as MIREX-weighted key score and
local-key accuracy, the protocol now calls for per-piece means with bootstrap
CI95 and paired A/B comparisons using the Wilcoxon signed-rank test across
pieces. For skewed streaming metrics such as modulation lag,
time-to-first-claim, and spurious-switch counts, the protocol now calls for
median and p90 across pieces rather than means, with bootstrap intervals only
when an interval is needed.

**Decisions.**

- Use CI95 as the single confidence interval convention. If a conclusion is
  marginal, inspect or report the per-piece distribution instead of adding CI99.
- Report median and p90 for latency- and count-like metrics because those
  distributions are expected to be long-tailed.
- Keep per-piece aggregation and paired tests as the default statistical unit;
  pooled event accuracy remains insufficient on its own.
- Always report `n` for pieces and events alongside aggregates.
- Fix and record the RNG seed for bootstrap resampling so reported intervals are
  reproducible.

**Next.** Preserve these conventions when implementing the offline harness
metrics, and revisit only through a protocol amendment after freeze.
