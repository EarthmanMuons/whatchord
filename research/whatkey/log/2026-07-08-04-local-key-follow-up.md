# 2026-07-08: Local-key follow-up direction

**Goal.** Capture a natural follow-up project suggested by the final paper
draft: optimize and evaluate WhatKey for local-key annotation rather than
section-key stability.

**Context.** The current paper selects a section-key operating point because the
intended product surface is a stable, glanceable key indicator. Late-stage
experiments nevertheless showed that the local-key side is not a failed version
of the same task. Short-memory HMM settings and Bayesian online changepoint
detection both score well when the answer key rewards analyst local-key changes,
and several chord-identity features that were inert or harmful for the
section-key target were more useful in that local-key regime.

The current fixtures also use a neutral analysis context so the chord recognizer
cannot leak ground-truth key information into the detector. That is the correct
choice for the present paper, but it leaves open a different closed-loop
question: if a streaming key detector supplies its current tonality belief back
to chord recognition, do chord identities improve enough to change local-key
tracking? That would need to be evaluated explicitly, because it couples the
recognizer and key detector rather than treating recognition output as a fixed
input stream.

**Plain-English reading.** The current paper answers, "Can a live app show a
calm current key without reading ahead?" A follow-up could ask a different
question: "Can a live or near-live system follow every analyst-marked local key
change, and how does it compare with systems built for local harmonic analysis?"
That is a real research question because the best model choices may change when
the target changes.

**Next.**

- Treat local-key tracking as its own task, not as an ablation of the
  section-key detector.
- Revisit BOCPD and short-memory HMM settings under local-key adoption rules,
  including modulation recall, lag, spurious switches, coverage, and
  accuracy-on-claimed.
- Reattempt comparison against local-analysis systems such as justkeydding, or
  document reproducible build failures and choose another external anchor.
- Add an explicit closed-loop condition where the detector's current tonality
  belief is allowed to condition chord recognition, and compare it against the
  neutral-context fixtures used in the present paper.
- Keep the present section-key paper scoped as-is; cite this only as future work
  if needed.
