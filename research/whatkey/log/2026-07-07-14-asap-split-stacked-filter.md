# 2026-07-07: ASAP split frozen; segmentation does not substitute for emission memory

**Goal.** Freeze the ASAP development/test split entry 13 required before any
ASAP-informed tuning, expand the set, and run the stacked-filter experiment:
does capture-side debounce absorb the performed-input noise that sank memoryless
emissions?

**Setup.**

- Expanded set `asap-nc-v2`: 60 performances, one per piece folder, round-robin
  across 16 composers (still noncommercial-gated in `build/`).
- Split frozen in `data/splits/asap-nc-v2.json` (committable: piece identifiers
  and counts only, not corpus content): 50 development / 10 test performances,
  piece folders hashed within composer so every performance of a piece lands on
  one side. Seed `whatkey-asap-nc-v2-split-2026-07-07`; generator
  `tool/whatkey/asap_split.py`.
- Harness split validation generalized: every `*Commit` pin the split file
  records must match the fixture manifest (previously only the When in Rome pin
  names were checked, which would have passed vacuously for ASAP).
- Segmenter knob: `--segmenter-min-ms` on the replay tool and extractor (default
  200, the app's live value). Any adopted change must ship in the app's
  segmenter, not fork the fixture pipeline.

```sh
python3 tool/whatkey/asap_extract.py --asap-root /private/tmp/asap-dataset \
  --set asap-nc-v2 --max-performances 60
python3 tool/whatkey/asap_split.py
for seg in 50 100 400 800; do
  python3 tool/whatkey/asap_extract.py --asap-root /private/tmp/asap-dataset \
    --set "asap-nc-v2-seg$seg" --max-performances 60 \
    --segmenter-min-ms "$seg"
done
for cfg in asap-nc-v2:1 asap-nc-v2:30 asap-nc-v2-seg50:1 \
    asap-nc-v2-seg50:30 asap-nc-v2-seg100:1 asap-nc-v2-seg100:30 \
    asap-nc-v2-seg400:1 asap-nc-v2-seg400:30 asap-nc-v2-seg800:1 \
    asap-nc-v2-seg800:30; do
  dart run tool/whatkey/harness.dart \
    --fixtures "build/whatkey-fixtures/${cfg%:*}" \
    --split-file research/whatkey/data/splits/asap-nc-v2.json \
    --detector hmm --decay-half-life-seconds "${cfg#*:}" \
    --out "build/whatkey-harness/${cfg%:*}-dev-hmm-hl${cfg#*:}"
done
dart run tool/whatkey/harness.dart \
  --fixtures build/whatkey-fixtures/asap-nc-v2 \
  --split-file research/whatkey/data/splits/asap-nc-v2.json \
  --detector hybrid --out build/whatkey-harness/asap-nc-v2-dev-hybrid
```

**Results** (development split, 50 performances; within-pair over claimed
events; switches summed; the sub-200 ms rows complete the curve in the other
direction):

| segmenter min | events | hmm 1 s emissions | hmm 30 s emissions |
| ------------- | ------ | ----------------- | ------------------ |
| 50 ms         | 31,107 | 52%, 2090 sw      | 67%, 291 sw        |
| 100 ms        | 23,334 | 53%, 1778 sw      | 68%, 265 sw        |
| 200 ms (app)  | 15,407 | 55%, 1448 sw      | 68%, 249 sw        |
| 400 ms        | 8,216  | 57%, 999 sw       | 69%, 200 sw        |
| 800 ms        | 3,699  | 55%, 574 sw       | 63%, 156 sw        |

Hybrid reference at 200 ms: 71% within-pair, 328 switches, coverage 0.85.

**The hypothesis is refuted.** Longer capture debounce does not rescue
memoryless emissions: within-pair stays flat at 55-57% from 200 to 800 ms while
the event count halves at each step, meaning the debounce discards material
without cleaning what remains. The noise that hurts memoryless emissions is not
sub-800 ms transients; it is committed, longer-lived ambiguous sonorities
(pedal-merged harmonies that persist as real events), which only cross-event
smoothing handles. Capture-side and detector-side filtering operate on different
bands and are not interchangeable, so the emission-memory reconciliation must
happen detector-side. The sub-200 ms rows validate the app's value from the
other direction: halving the debounce doubles the committed events (31k at 50 ms
vs 15k at 200 ms) with no within-pair change for the smoothed detector (67-68%),
because duration weighting already discounts brief events, while the memoryless
detector degrades monotonically as transition noise floods in (52% at 50 ms).
The material the 200 ms debounce discards is material the smoothed detector does
not need. Segmentation stays at the app's 200 ms, comfortably on the flat part
of the curve in both directions; 400 ms showed a marginal hl30 gain (69% vs 68%)
at half the events, noted as diagnostic only, with no paired test and no
adoption case.

**Plain-English reading.** We asked whether being stricter about which chords
count as "really played" (waiting longer before believing a chord) could
substitute for the detector averaging its evidence. It cannot: the strictness
just throws away more of the performance without making the survivors more
trustworthy, because the confusing moments on a real piano are not quick flubs
but genuinely sustained blurs, a pedal wash that holds four harmonies at once is
a long, confidently wrong chord, and no waiting period filters it. So the
detector's own averaging has to do that job, and the open question from entry 13
(one smoothing knob, two corpora, opposite answers) stays a detector-side
question.

**Decisions.**

- ASAP tuning discipline now matches When in Rome: frozen split, dev-only
  experiments, test side untouched.
- Segmenter parameters stay at the app's live values; the stacked-filter path is
  closed with data.
- Champion unchanged.

**Next.** Detector-side reconciliation of the emission-memory dial, with
event-count-based decay as the first candidate (it normalizes the dial across
event-rate differences between corpora); then mode-resolved ASAP labels via the
When in Rome overlap; then the ablation pass.
