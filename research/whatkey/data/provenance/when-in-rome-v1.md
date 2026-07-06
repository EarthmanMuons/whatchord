# When-in-Rome v1 Provenance

This note records the license gate for the WhatKey `when-in-rome-v1` corpus
fixture set. It is a project decision record, not legal advice.

## Pins

- Contrapunctus benchmark: `b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59`
- When-in-Rome submodule: `aa7539f1cf480997a68998405c0783ebf6339c16`
- Source manifest: `/private/tmp/contrapunctus-bench/corpus/manifest.json` from
  that benchmark checkout.

## Included Groups

These groups may be used for committed `when-in-rome-v1` fixture artifacts, with
per-fixture provenance retained in generated manifests:

| Group             | Score source               | Analysis source                              | Fixture artifact license |
| ----------------- | -------------------------- | -------------------------------------------- | ------------------------ |
| `bach-wtc`        | When-in-Rome, CC BY-SA 4.0 | When-in-Rome, CC BY-SA 4.0                   | CC BY-SA 4.0             |
| `brahms-lieder`   | OpenScore Lieder, CC0      | When-in-Rome, CC BY-SA 4.0                   | CC BY-SA 4.0             |
| `schubert-lieder` | OpenScore Lieder, CC0      | When-in-Rome, CC BY-SA 4.0                   | CC BY-SA 4.0             |
| `tavern`          | TAVERN, CC BY-SA 4.0       | When-in-Rome/TAVERN conversion, CC BY-SA 4.0 | CC BY-SA 4.0             |

Generated fixtures derived from these groups are data artifacts under CC BY-SA
4.0 provenance. Do not treat those fixture files as covered only by the
repository's software license.

## Excluded Groups

These groups remain excluded from committed fixture artifacts unless a later log
entry records a narrower license decision:

| Group                 | Reason                                                        |
| --------------------- | ------------------------------------------------------------- |
| `mozart-sonatas-dcml` | The DCML source is CC BY-NC-SA 4.0.                           |
| `chorales`            | The Craig Sapp `bach-370-chorales` source is CC BY-NC-SA 4.0. |

Both may still be useful for local, uncommitted experiments under
`build/whatkey-fixtures/` with `--allow-unverified-license`, but they must not
be committed as WhatKey fixtures without revisiting the gate.

## Operational Notes

- `mise research:whatkey-fixtures-when-in-rome` now targets only the included
  groups.
- TAVERN scores are remote in the When-in-Rome checkout. Run
  `corpus/prep/fetch_tavern_scores.py` in the Contrapunctus benchmark checkout
  before expecting the extractor to include all TAVERN pieces.
- A sanity generation run on 2026-07-06 produced 77 fixtures and 5,207 aligned
  events. The upstream manifest selected 79 pieces, but `Bach WTC I Prelude 13`
  and `Schubert Ave Maria` produced no fixture rows through the current
  `load_piece` path and are excluded from the frozen split.
- The frozen split for this fixture set is
  `research/whatkey/data/splits/when-in-rome-v1.json`.
