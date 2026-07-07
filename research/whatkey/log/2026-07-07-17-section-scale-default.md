# 2026-07-07: Product decision: the key indicator means the section-scale key

**Goal.** Record and implement the owner's decision on entry 16's question: what
timescale should WhatChord's key indicator mean?

**The decision** (project owner, 2026-07-07): section-level, calm, long
timescale. Temporary excursions matter less than overall accuracy and not
flip-flopping. The indicator should say what key you are playing in, not narrate
every tonicization.

**Implementation.** `HmmKeyDetector.defaultEmissionHalfLifeSeconds` moves from 1
to 30 (margin floor stays 0.3); the shipped defaults now embody the
section-scale reading, and one-second emissions remain a flag away for
tonicization-scale evaluation. Defaults-only parity verified on the Isophonics
development split.

```sh
python3 tool/whatkey_compare.py \
  build/whatkey-harness/iso-dev-hmm-hl30/report.json \
  build/whatkey-harness/iso-dev-hybrid/report.json
python3 tool/whatkey_compare.py \
  build/whatkey-harness/iso-dev-hmm-hl30/report.json \
  build/whatkey-harness/iso-dev-hmm-hl1/report.json
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v2 \
  --detector hmm --decay-half-life-seconds 30 \
  --out build/whatkey-harness/pop-jazz-v2-hmm-hl30
```

**Adoption evidence** (Isophonics development split, the corpus with real
section-scale key labels, 183 tracks):

- Against short memory (the timescale choice itself): +0.099 exact per piece,
  CI95 [+0.059, +0.141], p < 0.0001, 106/51/23. Decisive.
- Against the hybrid (the detector choice at this timescale): exact wash
  (-0.006, p = 0.16), coverage decisively better (+0.039, CI95 [+0.028, +0.050],
  p < 0.0001, 110/28/45), spurious p90 1 vs 4, and posterior confidence is a
  true probability the indicator can display.
- ASAP corroborates at signature scale (entry 13: within-pair 65% at higher
  coverage and fewer switches than the hybrid).

**Behavioral suite at the shipped config**: all steady-key probes exact 1.00
with clean stability, ambiguity handling intact (8/8, 7/7). The modulating
ii-V-I chain reads 0.17: that probe measures tonicization-scale reflexes, which
this configuration intentionally absorbs, so its role shifts from pass/fail to
documenting the trade the product chose. Blues unchanged (an emissions problem,
entries 10-12).

**Disclosure, the other ruler**: on When in Rome's tonicization-scale labels the
shipped config scores 0.49 exact / 116 of 399 modulations (vs 0.59 / 216 for the
one-second config that won that ruler). This is the deliberate, recorded cost of
the product decision, not a regression: the When in Rome protocol remains the
frozen benchmark for reflex-scale work, evaluated with
`--decay-half-life-seconds 1`.

**Plain-English reading.** The app's key light now answers "what key is this
song in right now" the way a bandmate would, staying put through brief detours
and committing confidently to the home key. We measured that this reading is the
one both pop and performed-piano ground truth reward, that it answers more
often, more steadily, and as accurately as any alternative we have, and we wrote
down what it gives up: it will not flag a four-chord excursion into the
dominant, which the classical corpus graded us on and which this product
explicitly does not want.

**Decisions.**

- Shipped default: HMM, 30 s emissions, margin floor 0.3, the section-scale
  configuration. Recorded as a product decision implementing entry 16's finding,
  with paired evidence above.
- The chain probe's interpretation is redefined under the product timescale; the
  fixture stays.
- Mode-resolved ASAP labels are slotted as pre-ship verification (the indicator
  displays mode, relative pairs share every pitch class, and mode accuracy on
  performed input is currently unmeasured), scheduled before the one-shot
  test-split evaluation rather than before the ablation pass.

**Next.** The ablation pass under the shipped default (which ingredients still
earn their keep at section scale), then mode-resolved ASAP labels, then the
one-shot test-split evaluation across all three frozen splits.
