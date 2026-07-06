# 2026-07-06: When-in-Rome license gate and frozen split

**Goal.** Clear the license gate for the first corpus-derived WhatKey fixture
set and freeze the development/test split before detector tuning begins.

**Setup.** Engine at commit `aed5ea8b`. Contrapunctus benchmark checkout at
`b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59`; When-in-Rome submodule at
`aa7539f1cf480997a68998405c0783ebf6339c16`. TAVERN remote scores were fetched
into `/private/tmp/contrapunctus-bench/corpus/scores-local/` with
`corpus/prep/fetch_tavern_scores.py`.

**What happened.** Audited the intended When-in-Rome groups and narrowed
`when-in-rome-v1` to groups whose committed fixture artifacts can carry clear CC
BY-SA 4.0 provenance: `bach-wtc`, `brahms-lieder`, `schubert-lieder`, and
`tavern`. Excluded `mozart-sonatas-dcml` and `chorales` because their score
sources are CC BY-NC-SA 4.0. Updated the extractor to reject unverified
When-in-Rome groups unless `--allow-unverified-license` is passed for local
`build/` output. A sanity generation run produced 77 fixtures and 5,207 aligned
events under `build/whatkey-fixtures/when-in-rome-v1`; `Bach WTC I Prelude 13`
and `Schubert Ave Maria` produced no fixture rows through the current loader.

**Decisions.**

- Treat generated When-in-Rome fixture files as CC BY-SA 4.0 data artifacts with
  explicit provenance, not as files covered only by the repository's software
  license.
- Keep non-commercial source groups out of committed WhatKey fixtures unless a
  later decision records a narrower license path.
- Freeze `research/whatkey/data/splits/when-in-rome-v1.json` from the generated
  fixture manifest rather than the upstream corpus manifest, so the split only
  references actual harness inputs.
- Use the existing 20% target: piece-hash selection within single-composer
  groups, and composer holdout for the multi-composer TAVERN group.

**Next.** Build the offline harness against the frozen split and keep generated
When-in-Rome fixtures in `build/` until committed fixture packaging and
attribution are finalized.
