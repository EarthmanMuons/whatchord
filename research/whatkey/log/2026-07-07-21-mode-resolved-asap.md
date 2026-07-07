# 2026-07-07: Mode-resolved ASAP labels close the last blind spot and the last confound

**Goal.** Build the ASAP/When-in-Rome overlap corpus (entry 17's pre-ship
verification): real tonic-and-mode analyst keys on performed input, measuring
the app's most user-visible error class (displayed mode) where it was previously
unmeasurable, and running the controlled same-input timescale experiment.

**Setup.** `tool/whatkey_asap_wir_extract.py`: ASAP's performed Beethoven piano
sonatas labeled with When in Rome's analyst local keys, transferred through
ASAP's performance-to-score downbeat alignment (`downbeats_score_map`, with span
entries and inconsistent measure bases handled, and a per-piece offset
self-calibrated against the analysis's measure range; unaligned performances
skipped). Sonata-number-to-opus mapping covers all 32 sonatas; events replay
through the real capture path via the existing ASAP tooling. Verification: every
generated piece's opening key matches the known sonata key (1-1 F minor, 14-3
C-sharp minor, 23-1 F minor, 10-1 G major under ASAP's sonata numbering, and so
on). License: doubly gated (ASAP CC BY-NC-SA; the Beethoven-sonata analyses are
outside our verified When in Rome groups); `build/` only. Corpus
`asap-wir-nc-v1`: 36 performances, 10,395 events, evaluation-only (no tuning,
both configurations pre-committed, so no split is required).

```sh
python3 tool/whatkey_asap_wir_extract.py \
  --asap-root /private/tmp/asap-dataset \
  --bench-root /private/tmp/contrapunctus-bench
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/asap-wir-nc-v1 --detector hmm \
  --out build/whatkey-harness/asap-wir-hmm-shipped
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/asap-wir-nc-v1 --detector hmm \
  --decay-half-life-seconds 1 --functional-blend 0.1 \
  --out build/whatkey-harness/asap-wir-hmm-reflex
python3 tool/whatkey_mode_confusion.py \
  --fixtures build/whatkey-fixtures/asap-wir-nc-v1 \
  --claims build/whatkey-harness/asap-wir-hmm-shipped/claims.json
```

**The controlled timescale experiment** (identical performances, analyst
tonicization-scale labels, both configurations):

| config             | coverage | exact | MIREX | modulations | spurious |
| ------------------ | -------- | ----- | ----- | ----------- | -------- |
| shipped (30 s)     | 0.91     | 0.47  | 0.60  | 126/459     | 1, 4     |
| reflex (1 s, f0.1) | 0.85     | 0.59  | 0.69  | 305/459     | 11, 28   |

On the same performed input, the tonicization-scale ruler decisively prefers the
reflex configuration, with reflex exact accuracy on performed input (0.59)
matching its clean-score value (0.57-0.59 on When in Rome). This settles the
last confound from entry 13: the emission dial tracks the label timescale even
on noisy performed input, and entry 13's apparent noise-punishes-quickness
effect was the signature-scale labels speaking, not the noise. The two-ruler
crossover now stands demonstrated within a single corpus on identical
audio-derived input, which is the airtight version for the paper.

**Mode accuracy, measured at last** (pooled claims against analyst labels):

| config  | exact | fifth | relative (mode) | parallel (mode) | other |
| ------- | ----- | ----- | --------------- | --------------- | ----- |
| shipped | 50%   | 17%   | 5%              | 9%              | 18%   |
| reflex  | 60%   | 14%   | 6%              | 6%              | 15%   |

Mode errors (relative plus parallel) are 14% of the shipped configuration's
claims on this ruler, with relative confusion, the case the signature labels
could never see, at just 5%. Caveat for reading the shipped column: these labels
are tonicization-scale, so much of its "fifth" and "other" mass is the
deliberate timescale trade (reporting the home key while the analyst is inside
an excursion) rather than product-level error; a section-scale filtered variant
(scoring only within long analyst segments) would give the sharper product
number and is noted as a refinement, not run today.

**Plain-English reading.** We finally graded the detector on real piano playing
with real answer keys, including the major-versus-minor distinction the user
actually sees. Two findings. First, the reflexes-versus-calm story survived its
hardest test: on the very same recordings, the fast configuration wins when the
answer key tracks every excursion, exactly as it did on clean scores, so the
choice we made is about what to report, not about hiding from messy input.
Second, the error the user would notice most, showing minor when the song is
major or the reverse, happens on about one in seven claims when graded against
excursion-level answers, and confusing a key with its relative, the specific
mistake we could never measure before, is rare at one in twenty.

**Decisions.**

- Pre-ship mode verification: done; no configuration change indicated.
- The section-scale filtered variant of this corpus is the remaining refinement
  if a sharper product-facing mode number is wanted; low priority.
- This corpus completes the evidence set for the paper: the crossover is now
  demonstrated between corpora, between rulers, and within one corpus on
  identical input.

**Next.** The one-shot test-split evaluation across the three frozen splits with
the shipped configuration, then Phase 2 product work.
