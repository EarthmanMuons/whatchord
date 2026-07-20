# 2026-07-20: Key-side relabel measured, then reversed under review

**Goal.** Answer the review question raised after entry 2026-07-20-08: would the
cold-start enharmonic-side prior help more universally inside WhatKey's key
space than as an app-side spelling layer? This entry records a measurement, a
briefly adopted relabel, and its reversal when review exposed what the
measurement actually measured. It also corrects entry -08's framing: the
"conventional practice" grounding of the F#-major tie cell was asserted, not
sourced, and turns out to be contested.

**Setup.** A `--static-sides` arm in the spelling harness applies the prior's
side to every claim with no window and no state, which is exactly the semantics
of relabeling the detector's canonical tonalities. Comparing the prior table
against `KeySpace.canonicalTonalities` showed the detector already prefers fewer
accidentals everywhere and matches the table at every ambiguous key except one
cell: the six-accidental major tie, where KeySpace prefers G flat and the table
said F sharp.

```sh
dart run tool/chord-context/spelling_eval.dart \
  --fixtures build/chord-context/fixtures/dcml-distant-listening-v1-span \
  --labels build/chord-context/labels/dcml-distant-listening-v1-span.labels.json \
  --split-file research/chord-context/data/splits/dcml-distant-listening-v1.json \
  --split development --static-sides true \
  --out build/chord-context/spelling/dcml-dev-static
python3 tool/chord-context/lever0_compare.py \
  build/chord-context/spelling/dcml-dev-static/report.json \
  --arm sideChosen --baseline-arm inferred
```

**What happened.** The static arm scored 98.64% tones (baseline 98.04%, v2
window 98.57%), with a paired result that formally clears the bar: mean delta
+0.0051, CI95 [+0.0012, +0.0098], 18 wins / 6 losses / 898 ties, p = 5.8e-03,
all traceable to the one differing cell. The relabel was briefly adopted in
KeySpace, then reversed the same day when review asked the right question:
without any context mechanism, is this not just flipping which side of the coin
loses?

It is. Corpus composition analysis: the DCML dev material contains 22 pieces
with F#-major spans (1,342 labeled spans) against 14 with Gb-major (348 spans),
roughly 4:1 by mass. The paired win is that ratio expressing itself; the 6
losses are the corpus's Gb pieces, exactly the players a fixed F# label would
newly hurt. The p-value therefore measures this classical piano repertoire's
engraving distribution, not a universal convention. Outside sourcing gathered
during review points the other way for the app's declared lead-sheet audience:
classical engraving and jazz/lead-sheet practice lean Gb for standalone
six-accidental keys, with F# favored in sharp-side modulation contexts and
string/guitar-centric settings. The tie cell is genuinely contested; the non-tie
cells (Db over C#, B over Cb) are corpus-confirmed lopsidedly and were already
correct.

**Plain-English reading.** With no context, any fixed label for the
six-accidental key is a bet on which players are more common, and our
measurement only counted the composers in one classical corpus, where F# happens
to dominate four to one. The moment the app's real audience enters the picture,
the sourced practice leans the other way. The review caught a prior being
laundered through a dev-corpus win: the table's F# cell was written down as
"conventional practice" on assertion, and the significant p-value then made it
look like knowledge. The genuinely universal improvements here are contextual,
not fixed: following the modulation context (which both the window mechanism and
the outside sourcing endorse), and honoring explicit user signals.

**Decisions.**

- The KeySpace relabel is reversed; the shipped Gb-side default stands. Changing
  a contested default requires audience-relevant evidence, not
  corpus-composition evidence.
- Entry -08's cold-start prior is re-characterized: its non-tie cells are
  uncontested and match shipped behavior; its F#-major tie cell is a contested
  bet, not established practice. The harness table is kept for reproducibility
  with its comment corrected.
- The adoption-bar lesson is recorded: a statistically significant paired win
  still inherits the corpus's composition; when a mechanism's effect is a fixed
  global choice rather than a per-piece response, the paired test measures
  prevalence, not correctness. Future fixed-choice proposals need either
  multi-genre rulers or explicitly audience-scoped evidence.
- The evidence path that could settle the default for this app's audience: a
  pop/rock spelling ruler from Isophonics, whose Harte chord labels carry
  spelled roots (Gb:maj vs F#:maj) chosen by human annotators of recorded
  repertoire. Until then, the side question stays closed with the status quo.

**Next.**

- Track B's live candidates are unchanged from entry -08's residual:
  context-dependent local-key sides and chromatic lines, now with the explicit
  note that fixed-label bets are off the table.
- Evaluate building the Isophonics spelling ruler if the side question is
  reopened; otherwise proceed to the extra-tones capped-rule market.
