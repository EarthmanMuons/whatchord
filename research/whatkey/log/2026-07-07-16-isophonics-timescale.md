# 2026-07-07: Isophonics arrives, and the emission dial tracks label timescale, not noise

**Goal.** Add the clean-pop corpus that breaks the noise/genre confound (entries
13-15) and adjudicate what the emission-memory dial actually tracks, before
building anything adaptive on the wrong premise.

**Setup.**

- **`tool/whatkey_isophonics_extract.py`**: fixtures from ChoCo's normalized
  Isophonics partition (sparse clone of `smashub/choco`). Harte chord labels are
  parsed to interval sets (shorthand table plus degree lists) and rendered to
  voicings with the annotated bass honored (inversions survive); events come
  straight from annotation segments like the When in Rome path, no capture
  segmenter. Key labels carry tonic AND mode, including mid-song changes ("I'll
  Be Back" alternates A major and A minor in the labels), the first real key
  ground truth on non-classical music in this project. Known label quirks exist
  upstream ("Here Comes The Sun" is annotated A:minor in the raw Isophonics
  files; annotations are treated as ground truth, as with When in Rome's
  analysts). Modal annotations become unlabeled events.
- **License gate**: the Isophonics reference annotations are
  research-distributed without an explicit redistribution license, so the set is
  gated like ASAP: `build/` only, extractor refuses `research/`, manifest
  carries the marker.
- **Corpus**: `isophonics-nc-v1`, 224 tracks (179 Beatles, 20 Queen, 18 Zweieck,
  7 Carole King); 76 meta rows skipped for missing JAMS, chords, or keys. Split
  frozen before any run: 183 development / 41 test, album-level units hashed
  within performer (`data/splits/isophonics-nc-v1.json`; the ASAP splitter is
  generalized to any slash-titled manifest and records all source commit pins).

```sh
git clone --filter=blob:none --sparse https://github.com/smashub/choco.git \
  /private/tmp/choco
cd /private/tmp/choco && git sparse-checkout set partitions/isophonics
python3 tool/whatkey_isophonics_extract.py --choco-root /private/tmp/choco \
  --set isophonics-nc-v1
python3 tool/whatkey_asap_split.py \
  --fixtures-manifest build/whatkey-fixtures/isophonics-nc-v1/manifest.json \
  --seed whatkey-isophonics-nc-v1-split-2026-07-07
for hl in 1 5 30; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
    --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
    --detector hmm --decay-half-life-seconds "$hl" \
    --out "build/whatkey-harness/iso-dev-hmm-hl$hl"
done
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/isophonics-nc-v1 \
  --split-file research/whatkey/data/splits/isophonics-nc-v1.json \
  --detector hybrid --out build/whatkey-harness/iso-dev-hybrid
```

**Results** (development split, 183 tracks, 192 annotated key changes):

| config    | coverage | exact | MIREX | modulations | spurious |
| --------- | -------- | ----- | ----- | ----------- | -------- |
| hmm, 1 s  | 0.82     | 0.61  | 0.73  | 150/192     | 4, 11    |
| hmm, 5 s  | 0.89     | 0.68  | 0.79  | 133/192     | 1, 4     |
| hmm, 30 s | 0.94     | 0.71  | 0.80  | 95/192      | 0, 1     |
| hybrid    | 0.90     | 0.71  | 0.81  | 112/192     | 1, 4     |

**The noise hypothesis is refuted; the timescale hypothesis replaces it.** This
corpus is clean (annotation-derived voicings, no segmenter, no pedal blur), yet
exact accuracy prefers long memory, like noisy ASAP and unlike clean When in
Rome. What actually separates the corpora is the granularity of their ground
truth:

- **When in Rome**: analyst local keys, ~7 changes per piece, 27% of segments 2
  events or fewer. Tonicization-scale labels. Short memory wins accuracy AND
  modulation matching, because accuracy there IS rapid tracking.
- **Isophonics**: song-level keys, ~1 change per track. Section-scale labels.
  Long memory wins accuracy and stability (0.71 exact, spurious p90 = 1); short
  memory still wins change-catching (150 vs 95 of 192) at a heavy stability and
  accuracy cost.
- **ASAP**: signature-level labels, rarest changes, plus real input noise that
  further punishes short memory.

One dial, three corpora, one consistent reading: the emission memory selects
WHICH timescale of key structure the detector reports, and each corpus's labels
reward the timescale that matches their annotation granularity. Input noise is a
second-order penalty on short memory, not the organizing variable.

Also settled here: pop harmonic vocabulary is not a problem (0.71 exact on pop
exceeds anything we score on classical), so the genre arm of the confound is
closed along with the noise arm.

**Plain-English reading.** We finally have three different rulers, and they
explain the mystery. The classical corpus grades the detector on noticing every
brief tonal excursion, so quick reflexes win there. The pop and performance
corpora grade it on knowing what key the song is in, so a calm, settled judgment
wins there. The knob we have been trying to "fix" was never broken: it chooses
between reflexes and calm, and each test rewarded a different choice. That turns
an algorithm question into a product question: what should the app's key
indicator mean? Almost certainly "the key of what you are playing" at the
settled, section level, with quick excursions absorbed rather than reported,
which points the shipped configuration toward calm (long memory), while the
classical corpus remains the right ruler for reflex development.

**Decisions.**

- Champion unchanged pending the product-level timescale decision, which this
  entry hands to the project owner in sharper form than entry 15's "deployment
  domain" framing: the choice is display timescale, not corpus loyalty. A
  long-memory default (30 s emissions) is supported by both non-classical
  corpora and by the app's likely intent; the When in Rome protocol remains the
  tonicization-scale benchmark.
- Noise-adaptive emissions are demoted: the premise they would be built on did
  not survive the third corpus. If both timescales matter to the product, the
  principled shape is two posteriors (fast and slow) rather than one adaptive
  one, noted as future work, not scheduled.
- Isophonics fixtures stay gated in `build/`; the split file is committed.

**Next.** The product timescale decision (owner call), then the ablation pass
under whatever default it produces, mode-resolved ASAP labels if
tonicization-scale evaluation on performed input is still wanted, and the
one-shot test-split evaluation when the generation stabilizes.
