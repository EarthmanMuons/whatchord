# 2026-07-07: Pin the abstain-calibration presentation early

**Goal.** Resolve one of the three deferred protocol items ahead of the full
freeze, now that the sweep provides decisive data.

**Setup.** Documentation only. Data: the coverage-accuracy sweep in entry
2026-07-07-01.

**What happened.** PROTOCOL.md now pins abstain calibration as a
coverage-accuracy curve (swept over the detector's confidence threshold, with
the shipped operating point marked), not a single operating point. The sweep
showed why a single point misleads: the same detector reads as 0.41, 0.45, or
0.69 exact depending on an arbitrary threshold choice, while the curve is the
threshold-free description. The harness already implements the curve
(`--sweep-margin-floors`), so this pin costs nothing and constrains no detector
design.

**Decisions.** Deferred items may be pinned individually before the full freeze
when decisive data arrives; the remaining two (modulation-lag censoring,
global-key operationalization) stay open pending theirs. The full freeze still
gates any test-split evaluation and serious tuning.

**Next.** Unchanged: the weighted evidence model.
