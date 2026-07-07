# Reproducing WhatKey Data

This document describes how to rebuild the WhatKey Phase 2 data inputs from a
fresh checkout. It covers fixture generation and split regeneration, not
detector results. Generated corpus-derived fixtures stay under `build/` unless a
separate commit explicitly packages them with the required provenance and
notices.

## Required Tools

Use the repository's normal toolchain:

- `git`
- `mise`
- Flutter/Dart, as used by the app
- Python 3.12 and `uv`, both managed by `mise.toml`

From the repository root, make sure the mise environment is active:

```sh
mise install
```

## External Corpus Checkout

WhatKey uses the Contrapunctus benchmark checkout as the prepared access layer
for When-in-Rome. The benchmark provides the pinned When-in-Rome submodule,
piece manifest, common-subset flags, provenance fields, and score-alignment
helpers used by `tool/whatkey_fixture_extract.py`.

Clone the benchmark outside this repository:

```sh
git clone https://github.com/Tomczik76/contrapunctus-bench /private/tmp/contrapunctus-bench
cd /private/tmp/contrapunctus-bench
git checkout b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59
git submodule update --init corpus/When-in-Rome
```

Verify the pins:

```sh
git rev-parse HEAD
git -C corpus/When-in-Rome rev-parse HEAD
```

Expected values:

```text
b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59
aa7539f1cf480997a68998405c0783ebf6339c16
```

If you use another checkout location, export it before running repository tasks:

```sh
export CONTRAPUNCTUS_BENCH_ROOT=/path/to/contrapunctus-bench
```

## Prepare Local Corpus State

Install the optional Python dependency used by the When-in-Rome extraction path:

Run this from the WhatChord repository root:

```sh
mise research:when-in-rome-install
```

The `when-in-rome-v1` fixture set includes TAVERN. TAVERN scores are remote in
When-in-Rome and must be fetched into the benchmark checkout's machine-state
`corpus/scores-local/` directory:

```sh
cd "${CONTRAPUNCTUS_BENCH_ROOT:-/private/tmp/contrapunctus-bench}"
python3 corpus/prep/fetch_tavern_scores.py
```

Expected TAVERN prep result:

```text
Done: 11/11 TAVERN scores fetched + converted.
```

Do not fetch chorales for `when-in-rome-v1`. Chorales are intentionally outside
the committed-fixture gate because their score source is noncommercial-gated.

## Regenerate Fixtures

Return to the WhatChord repository root:

```sh
cd -
```

Regenerate the hand-authored pop/jazz fixtures:

```sh
mise research:whatkey-fixtures-pop-jazz
```

Output:

```text
research/whatkey/data/fixtures/pop-jazz-v1/
```

Regenerate the license-gated When-in-Rome fixtures:

```sh
mise research:whatkey-fixtures-when-in-rome
```

Output:

```text
build/whatkey-fixtures/when-in-rome-v1/
```

Expected sanity result:

```text
77 fixtures -> build/whatkey-fixtures/when-in-rome-v1
```

The upstream manifest selects 79 license-gated pieces, but
`Bach WTC I Prelude 13` and `Schubert Ave Maria` currently produce no fixture
rows through the loader and are not part of the frozen split.

## Regenerate The Frozen Split

The split is frozen before detector tuning. Regenerate it only to verify the
recorded file or before tuning has begun for a new fixture version.

```sh
python3 tool/whatkey_freeze_split.py \
  --bench-root "${CONTRAPUNCTUS_BENCH_ROOT:-/private/tmp/contrapunctus-bench}" \
  --fixtures-manifest build/whatkey-fixtures/when-in-rome-v1/manifest.json
```

Output:

```text
research/whatkey/data/splits/when-in-rome-v1.json
```

Expected split counts:

```text
development: 59 pieces, 3694 events
test:        18 pieces, 1513 events
total:       77 pieces, 5207 events
```

The split seed is recorded in the JSON file:

```text
whatkey-when-in-rome-v1-split-2026-07-06
```

The test split is held out. Tuning, ablation, threshold selection, and detector
selection happen on the development split only.

## Verify Outputs

Validate the split JSON:

```sh
python3 -m json.tool research/whatkey/data/splits/when-in-rome-v1.json > /tmp/whatkey-split-check.json
```

## License Boundaries

Read these files before committing corpus-derived fixtures:

- `research/whatkey/data/NOTICE.md`
- `research/whatkey/data/provenance/when-in-rome-v1.md`

For `when-in-rome-v1`, committed fixtures are limited to these groups:

- `bach-wtc`
- `brahms-lieder`
- `schubert-lieder`
- `tavern`

The fixture extractor rejects unverified When-in-Rome groups by default. Use
`--allow-unverified-license` only for local, uncommitted experiments under
`build/`.
