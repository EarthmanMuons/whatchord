# 2026-07-20: Historical reproduction contract

**Goal.** Determine whether the evolving codebase still reproduces the WhatKey
paper record associated with release `v2026.7.14`, and add a narrow historical
compatibility boundary where current chord-analysis improvements had changed
freshly generated observations. The release belongs to Zenodo concept DOI
`10.5281/zenodo.21322675`; its version DOI is `10.5281/zenodo.21364341`.

**Motivation.** The committed fixtures and result artifacts still made the
reported detector claims reproducible, but that alone did not prove that a
future reader could regenerate those fixtures with the current engine. An audit
after the engine refactor found that the refactor itself preserved behavior,
while two later intentional chord-naming changes did not:

- Isophonics regeneration under current app behavior reordered candidates in 55
  events across 14 tracks. That moved the fresh headline from the recorded
  `0.88 / 0.732 / 0.782` coverage/exact/MIREX values to `0.89 / 0.731 / 0.782`.
- ASAP regeneration produced 19,545 events rather than the frozen 19,546.
- ASAP/When-in-Rome regeneration reordered candidates in 2 events.

The relevant post-release changes were the altered-major and split-sixth pricing
in `a966f09d` and the key-functional seventh-over-sixth tie-breaker in
`81ec8b77`. Both are useful app improvements and should remain the default.
Reverting them globally would make the product serve the paper rather than
letting the paper remain reproducible inside an improving product.

**Setup.** Base engine commit `bbf61788e28fb4c5b547ddaa947e5792ff95112f`, with
the compatibility changes in this working session. The historical comparison
checkout was the peeled `v2026.7.14` commit
`e8ec90c9c409dec765873284a220a088d22a7cde`. Corpus pins remained unchanged:
contrapunctus-bench `b9e011c8`, When-in-Rome `aa7539f1`, ASAP `afc815c7`, and
ChoCo `5fe168fd`.

The final end-to-end commands were:

```sh
mise research:whatkey-prepare-data -- --all --verify-splits --yes
mise research:whatkey-prepare-data -- --all --verify-only
mise research:whatkey-headline-rerun -- --yes
mise research:whatkey-reproduction-verify
```

The five result directories outside the headline rerun were regenerated with:

```sh
dart run tool/whatkey/harness.dart --fixtures build/whatkey-fixtures/asap-nc-v2 --split-file research/whatkey/data/splits/asap-nc-v2.json --split test --recipe whatKeyPaper2026 --out build/whatkey-reproduction-current/test-asap-hmm-shipped
dart run tool/whatkey/harness.dart --fixtures build/whatkey-fixtures/isophonics-nc-v1 --split-file research/whatkey/data/splits/isophonics-nc-v1.json --split test --recipe whatKeyPaper2026Reflex --out build/whatkey-reproduction-current/test-iso-hmm-reflex
dart run tool/whatkey/harness.dart --fixtures build/whatkey-fixtures/isophonics-nc-v1 --split-file research/whatkey/data/splits/isophonics-nc-v1.json --split test --claims-file build/whatkey-headline-test/baseline-claims/isophonics-nc-v1-test/krumhanslschmuckler.claims.json --restrict-to build/whatkey-headline-test/test-iso-hmm-shipped/claims.json --out build/whatkey-reproduction-current/test-iso-m21-ks-matched
dart run tool/whatkey/harness.dart --fixtures research/whatkey/data/fixtures/when-in-rome-v1 --split-file research/whatkey/data/splits/when-in-rome-v1.json --split test --recipe whatKeyPaper2026Reflex --out build/whatkey-reproduction-current/test-wir-hmm-reflex
dart run tool/whatkey/harness.dart --fixtures research/whatkey/data/fixtures/when-in-rome-v1 --split-file research/whatkey/data/splits/when-in-rome-v1.json --split test --recipe whatKeyPaper2026 --out build/whatkey-reproduction-current/test-wir-hmm-shipped
python tool/whatkey/reproducibility.py verify --fixture when-in-rome-v1 --result test-asap-hmm-shipped --result test-iso-hmm-reflex --result test-iso-m21-ks-matched --result test-wir-hmm-reflex --result test-wir-hmm-shipped --result-root build/whatkey-reproduction-current
```

For the independent release comparison, the three license-gated fixture sets
were also regenerated from a detached `v2026.7.14` worktree using the same
pinned local corpus checkouts. Their canonical fixture JSON was compared with
the current compatibility-profile output.

**What happened.** A `whatKeyPaper2026` chord-analysis profile now freezes only
the two post-release ranking/pricing changes. Current app analysis remains the
default. All WhatKey fixture extractors explicitly request the paper profile,
and their manifests record it. The batch drivers (`fixture_batch.dart` and
`replay_batch.dart`) require that field and reject any request that omits it, so
a caller cannot silently inherit a profile; the chord-context extractor, which
studies current app naming, pins itself to `current` for the same reason.

The `whatKeyPaper2026` and `whatKeyPaper2026Reflex` detector recipes separately
pin the complete shipped and faster-decay HMM configurations, so a future change
to a detector default cannot silently alter a paper rerun. The headline workflow
invokes the shipped recipe.

Canonical JSON SHA-256 hashes now cover every fixture file and the stable scored
contents of each result directory. The lock is
`results/reproduction-v2026.7.14.json`. It covers both committed behavioral
fixture versions, all four corpus fixture sets, and all nine committed
test-result directories. Result hashes cover `claims.json` and the scored
`report.json` fields; timestamps, commands, engine commit metadata, and additive
diagnostics are deliberately excluded.

The regenerated corpus fixture hashes were:

| Fixture set        | Pieces | Events | Canonical SHA-256                                                  |
| ------------------ | -----: | -----: | ------------------------------------------------------------------ |
| `when-in-rome-v1`  |     77 |  5,207 | `0bc6551265f15bc397fa5cece06a909349ac35e27d3ff2891a3dc0e721bba224` |
| `asap-nc-v2`       |     60 | 19,546 | `c56ac7bf2eb24a9af94980d40b49b1c3189171b7c256f0df98333208fbff21d1` |
| `isophonics-nc-v1` |    224 | 19,062 | `68e2394dd196aa999473772c73a9ade8fcea33b1aa2511bff6e61d49940d3337` |
| `asap-wir-nc-v1`   |     36 | 10,395 | `068683ab490dc8457de788172288590c0577f2c4724978d363a801cf02ba402d` |

Each gated fixture hash exactly matched the output independently regenerated
from `v2026.7.14`. All nine result directories regenerated with the current code
matched their locked claims and stable scored data. The complete
reproduction-lock verifier also passed all six fixture sets and all nine
committed result directories.

The headline rerun again produced:

| System                         | Coverage | Exact | MIREX |
| ------------------------------ | -------: | ----: | ----: |
| WhatKey (causal, abstaining)   |     0.88 | 0.732 | 0.782 |
| music21 Temperley-Kostka-Payne |     1.00 | 0.637 | 0.740 |
| music21 Krumhansl-Schmuckler   |     1.00 | 0.624 | 0.726 |
| music21 Aarden-Essen           |     1.00 | 0.558 | 0.690 |

Its HMM `claims.json` canonical hash was
`e01408a6d92ee96408ba495a9d14fbe65dcebb803ac22e2eb99437be098b1633`, identical to
the committed paper result.

**Plain-English reading.** Someone using the current repository can regenerate
the observations that the paper actually evaluated, then produce the same claims
and numbers. Meanwhile, ordinary app users continue to receive newer
chord-naming improvements. The hashes turn this from a rounded-number spot check
into a precise pass/fail test: any future drift in a candidate list, claim, or
scored field is visible immediately.

**Decisions.** Keep one narrowly named paper profile and fully pinned recipes
for the two reported detector configurations rather than freezing the whole
application or branching the engine. Treat the version DOI as the immutable
historical record and the concept DOI as the evolving project identity. Do not
change the frozen research numbers or documents merely because the production
analyzer improves.

Hash semantic JSON rather than file bytes so formatting and object-key order do
not create false failures. The same canonical hash is computed in both Dart (the
harness that writes the hashes) and Python (the verifier), so both encoders
reject non-integer numbers outside `[1e-4, 1e16)`, the range where the two
languages format floats identically. A value that would hash differently across
the two implementations fails loudly at generation time rather than silently
producing a set that later cannot reproduce; every current fixture and result
falls well inside that range. Exclude additive report diagnostics from the
stable result-data hash because the release code may legitimately calculate new
diagnostics without changing any claim or scored paper datum; lock those fields
separately if a future publication relies on them.

**Next.** Keep `ChordAnalysisProfile.current` as the app default. Any future
engine change that affects fixture generation should be checked against
`mise research:whatkey-reproduction-verify`; extend the historical profile only
when needed to preserve `v2026.7.14`, never to freeze unrelated implementation
details. A future paper revision may receive its own named recipe and lock, but
does not overwrite this one.
