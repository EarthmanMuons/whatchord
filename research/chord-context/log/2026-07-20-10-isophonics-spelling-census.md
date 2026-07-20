# 2026-07-20: Isophonics spelling census

**Goal.** Bring audience-relevant evidence to the key-side question entry
2026-07-20-09 left open: how do human annotators of recorded pop/rock actually
spell the enharmonically ambiguous tonics and chord roots?

**Setup.** The ChoCo Isophonics partition at the WhatKey pin
(`5fe168fd55be5c84512abcfbc4e6f1b1f8f0092a`), 225 tracks (Beatles, Queen, Carole
King, Zweieck), fetched as a sparse blob-less checkout; census over the raw JAMS
key and chord annotations by `tool/chord-context/isophonics_spelling_census.py`.
This is descriptive evidence, not a harness run: no engine, no split, no tuning
surface.

```sh
git clone --filter=blob:none --sparse --no-checkout \
  https://github.com/smashub/choco.git /private/tmp/choco-sparse
git -C /private/tmp/choco-sparse sparse-checkout set \
  partitions/isophonics/choco/jams
git -C /private/tmp/choco-sparse checkout \
  5fe168fd55be5c84512abcfbc4e6f1b1f8f0092a
python3 tool/chord-context/isophonics_spelling_census.py \
  --choco-root /private/tmp/choco-sparse
```

**What happened.**

Key annotations on ambiguous tonics, by mode and distinct tracks:

| cell        | shipped side | evidence                          |
| ----------- | ------------ | --------------------------------- |
| pc 1 major  | Db           | Db 3 tracks vs C# 1               |
| pc 3 minor  | Eb           | Eb 1 vs D# 0                      |
| pc 6 major  | Gb           | F# 1 vs Gb 0 (the contested cell) |
| pc 8 minor  | G#           | no minor-key tracks at pc 8       |
| pc 10 minor | Bb           | Bb 2 vs A# 0                      |
| pc 11 major | B            | B 7 vs Cb 1                       |

Chord-root spellings, the display-relevant quantity, are decisive where keys are
thin. Overall: pc 6 roots F# 745 labels across 90 tracks vs Gb 58 across 11
(13:1); pc 1 C# 355/50 vs Db 195/16; pc 8 Ab 416/32 vs G# 153/26; pc 3 Eb 487/39
vs D# 48/10; pc 10 Bb only; pc 11 B only (Cb 4). Conditioned on the ambient
annotated key's side, the choice is nearly categorical context-following: in
flat-side keys pc 6 reads Gb 48 vs F# 6; in sharp-side keys F# 175 vs Gb 0; and
in neutral (natural-tonic) keys, the cold-start-like case, F# 562 vs Gb 10, a
56:1 sharp preference.

**Plain-English reading.** These annotators confirm both halves of the earlier
analysis. Context rules when it exists: inside a flat key they write Gb, inside
a sharp key F#, almost without exception, which is the strongest audience
evidence yet for the contextual mechanism. And when there is no side context,
which is the cold-start case, pop/rock practice is emphatically sharp-side at pc
6: F# beats Gb fifty-six to one on chord roots, and Gb never appears as a key in
the corpus at all. This contradicts the generic opinion (entry -09) that
lead-sheet practice leans Gb, at least for this guitar-centric repertoire, and
it agrees in direction with the classical corpus (F# pieces outnumber Gb four to
one by span mass). Every uncontested cell independently confirms the shipped
sides.

**Decisions.**

- The evidence base for the contested pc 6 major cell now spans two genres and
  points the same way: classical DCML 4:1 F# by span mass (18/6 paired, p =
  5.8e-03, entry -09), pop/rock Isophonics 13:1 F# on chord roots overall and
  56:1 in neutral contexts, with zero Gb keys in 225 tracks. This meets the
  standard entry -09 set (multi-genre or audience-scoped evidence) for
  re-proposing the F# major cold-start relabel; the decision to adopt is held
  for review given the same-day reversal.
- The conditioned table is recorded as the design target for the eventual
  contextual mechanism: annotators follow the ambient side nearly categorically,
  so a context-following side layer has a measured, audience-validated ceiling
  on both corpora now.
- All other cells: no action, shipped sides confirmed by both corpora.

**Next.**

- Review decision on the F# major cold-start relabel with both corpora's
  evidence in hand.
- If adopted, the KeySpace change from entry -09 applies as measured there, with
  the CHANGELOG entry restored.
