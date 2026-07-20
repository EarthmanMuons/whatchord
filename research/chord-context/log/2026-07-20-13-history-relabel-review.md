# 2026-07-20: History relabeling reviewed, kept open

**Goal.** Record the review of the history-relabel product (the retrospective
front carried since the design doc: applying resolution evidence, Rameau's rule,
to rename already-committed chords).

**What happened.** The review's first instinct was to close the front as an
unintuitive user experience (a history that renames its own past). Examining
where relabeling would actually surface reversed that instinct: committed events
are not a user-facing interaction surface. The only visible place is the passive
chord-history list at the bottom of the auto-key screen, scrolled for context
and never acted on. Everywhere else a relabeled event is upstream information:
the corrected past feeds the key detectors and any future context consumers, so
the product is better described as "the record quietly becomes more accurate and
everything downstream benefits" than as "the UI rewrites itself."

**Decisions.**

- The front stays open; whether it is useful is for data to determine, not
  intuition in either direction. No adoption candidate exists yet.
- The measurable value paths, for when this front is taken up: (a) accuracy of
  the relabeled events themselves against the corpus rulers (the resolution rule
  applied to committed events, scored like any other arm; the 63% of m7/6-family
  cases that resolve directly to a dominant put a floor under what resolution
  evidence can see); (b) downstream effect on key detection when detectors
  consume the relabeled stream, connecting to the closed-loop question WhatKey's
  log already posed (research/whatkey/log/2026-07-08-04). The banked
  appliedTonicization cue (entry -05) retains this front as its potential
  vehicle.
- Product constraint recorded for any eventual integration: relabeling applies
  to committed history only, never the live display (the causality contract of
  the design doc is untouched), and the passive history list simply shows the
  corrected record.

**Next.**

- When this front is taken up: an offline arm that relabels committed events by
  resolution evidence and measures both value paths above.
- Remaining fronts otherwise unchanged: the Track B residual and the Track D
  comping-suite gate.
