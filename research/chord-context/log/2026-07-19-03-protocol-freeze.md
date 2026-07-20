# 2026-07-19: Protocol freeze

**Goal.** Record the owner decision freezing `../PROTOCOL.md`.

**Setup.** The protocol as committed alongside this entry, drafted earlier today
(entries 2026-07-19-01 and -02 record the work that shaped it).

**What happened.** The owner reviewed the protocol and froze it as written. Two
points were examined explicitly during review. First, the performance budget: it
is normative and expressed in the engine benchmark harness's own terms
(`tool/benchmark.sh --check` green; a contextual layer adds at most 5% to the
snapshot baseline's cold normalized time, judged outside the combined
uncertainty window; a no-dropped-frames device gate at app integration;
analyze-call count and operation counters unchanged), deliberately avoiding
raw-microsecond thresholds the harness refuses to gate on. Second, its
amendability: the budget is a policy threshold, not a measurement definition, so
it can be raised by amendment if a cue ever earns more than its cost, with the
usual ordering: amend on development-split evidence first, then spend held-out
data under the amended budget, never the reverse.

**Decisions.**

- `PROTOCOL.md` status set to FROZEN 2026-07-19.
- Normativity handover: the scoring implementation under `tool/chord-context/`
  becomes the normative definition of each metric as its code lands (each
  landing recorded in a dated log entry); prose governs until then. The existing
  headroom tooling predates the freeze and is not yet normative.
- Outstanding preconditions the freeze does not waive: the When-in-Rome
  realization and quality mapping must pass the stratified hand-audit with a
  recorded error rate before the first frozen When-in-Rome result, and
  acceptable-answer sets must exist before contestable categories are scored.
- Stability metrics remain to be defined by amendment once frame-accurate replay
  fixtures exist.

**Next.**

- Build the DCML extractor and generate development-split fixtures (build-only),
  including the span and onset-instant views.
- Prepare the When-in-Rome audit sample and acceptable-answer sets.
- Re-establish the headroom results under the frozen protocol, ruler by ruler,
  as scoring code lands.
