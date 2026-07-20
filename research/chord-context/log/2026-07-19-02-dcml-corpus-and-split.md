# 2026-07-19: DCML corpus investigation and split freeze

**Goal.** Establish whether the DCMLab Distant Listening Corpus (the fourth
candidate ruler, flagged in `research/whatkey/key-behavior-modes.md`) is usable
as chord-identity ground truth, and if so freeze its dev/test split before any
content is inspected or fixtures are generated, per the revised protocol-first
ordering (entry 2026-07-19-01).

**Setup.** Shallow clone of `https://github.com/DCMLab/distant_listening_corpus`
pinned to tag `v3.1` (commit `afe981d988de031bc6e19b8455adcba7b557e20f`, Zenodo
DOI 10.5281/zenodo.15150283). Investigation scope was deliberately limited to
metadata, schema, license, and documentation, not annotation content:

- The superrepo's top-level `distant_listening_corpus.metadata.tsv` (piece list,
  label counts, composers, dates; 1326 pieces, 40 sub-corpora, 1283 with
  annotations).
- One sub-corpus cloned for schema validation only: `debussy_suite_bergamasque`,
  where the harmonies/notes TSV column headers, three harmony rows of one
  menuet, and one note row were read.
- Web documentation: the Scientific Data descriptor
  (10.1038/s41597-025-04976-z), the DCML annotation standard specs, and the ms3
  column reference.

```sh
git clone --depth 1 https://github.com/DCMLab/distant_listening_corpus.git \
  /private/tmp/distant_listening_corpus
cd /private/tmp/distant_listening_corpus
git fetch --depth 1 origin tag v3.1 && git checkout v3.1
cd /Users/abs/src/whatchord
python3 tool/chord-context/freeze_dcml_split.py \
  --corpus-root /private/tmp/distant_listening_corpus
```

**What happened.** The corpus is usable and unusually well suited:

- Harmony TSVs carry the annotation standard's decomposed identity columns
  (`chord_type`, `root`, `bass_note`, `chord_tones`, `added_tones`, `globalkey`,
  `localkey`), so expected identities come straight from the human annotation
  with no realization interpreter. `root`/`bass_note`/ `chord_tones` are
  line-of-fifths integers relative to the local tonic; absolute pitch classes
  are pure fifths arithmetic. The documented `chord_type` vocabulary
  (`M m o + Mm7 mm7 MM7 mM7 o7 %7 +7 +M7`) maps nearly one-to-one onto
  `ChordQuality`; augmented-sixth shorthands live in the `special` column and
  are expanded into exact `chord_tones`.
- Every sub-corpus ships pre-extracted `notes/` TSVs (`midi`, `tpc`, `tied`,
  `quarterbeats`, `duration_qb`), so sounding notes align to harmony spans by
  quarterbeat join with no MuseScore/ms3 toolchain. Caveats recorded for the
  extractor: `quarterbeats` skips first endings (use `quarterbeats_all_endings`
  for voltas), and the maintainers recommend aggregating notes over the label's
  span rather than instantaneous slices, since labels annotate spans that
  legitimately contain passing tones, arpeggiation, and unisons.
- License: CC BY-NC-SA 4.0 uniformly across the superrepo and sub-corpora
  (LICENSE files verified). The Zenodo v3.1 deposit metadata claims CC BY 4.0,
  but the source repositories' embedded licenses govern; treat the Zenodo label
  as an inconsistency. Consequence: derived fixtures are build-only/untracked,
  fetched from the pinned tag, same as ASAP. The split file records identifiers
  only and is committed.
- 1283 of 1326 pieces have annotations (`label_count > 0`); coverage is not
  universal, so the extractor must filter on annotation presence.

Split frozen to `data/splits/dcml-distant-listening-v1.json`
(`chord-context-split/1`), from metadata only, seeded
(`chord-context-dcml-distant-listening-v1-split-2026-07-19`):

- Excluded: `schubert_winterreise` (overlaps when-in-rome-v1, whose frozen split
  already exposes Winterreise on both sides) and `debussy_suite_bergamasque`
  (the schema-validation sub-corpus above; excluded so no ruler material was
  seen pre-freeze). Mozart piano sonatas stay in: they were license-excluded
  from when-in-rome-v1 fixtures and never entered its splits, so there is no
  tuning contact. TAVERN variations and the Bach suites are different works from
  their When-in-Rome namesakes.
- Method: whole sub-corpora held out by seeded hash until they cover 10% of
  annotated pieces (cross-composer test: bach_en_fr_suites,
  frescobaldi_fiori_musicali, peri_euridice, scarlatti_sonatas,
  sweelinck_keyboard), plus a seeded 10% piece-hash holdout inside each
  remaining sub-corpus.
- Result: 935 development / 320 test pieces (184,800 / 53,954 labels).

**Plain-English reading.** This corpus gives us what the When-in-Rome ruler
could not: the analyst's chord already broken down into root, quality, and bass
by the annotation standard itself, so scoring WhatChord against it involves no
third-party naming opinion. The price is a noncommercial license (we rebuild the
data locally and never commit it) and the usual reality that annotations label
spans of music, not instants, which our extractor has to respect. The dev/test
split was decided by hashes from a fixed seed using only the piece list, before
we looked at any annotations, so the held-out pieces stay genuinely unseen.

**Decisions.**

- Adopt DCML distant listening v3.1 as a ruler; fixtures build-only from the
  pinned tag; extractor to aggregate notes over harmony spans and to also emit
  an onset-instant view so the span-vs-instant choice can be measured rather
  than assumed.
- Freeze splits from metadata alone for every new corpus, with any
  schema-validation material excluded from the ruler; this entry is the
  precedent.
- Keep the two exclusions permanent for v1 of this split.

**Next.**

- Draft `PROTOCOL.md` naming all four rulers (When-in-Rome, DCML, Isophonics via
  ChoCo in Harte space, ASAP) plus the behavioral suites, with per-corpus
  ground-truth rules and the adoption bar; freeze after review.
- Write the DCML extractor (fifths arithmetic to pitch classes, span
  aggregation, chord_type mapping) and generate build-only fixtures for the
  development split only.
- Verify the count of numeral-only rows (no chord_type) and `special`-column
  cases on the development split once fixtures exist, and fold them into the
  category taxonomy.
