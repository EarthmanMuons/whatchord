# 2026-07-07: Exact commands behind the reported numbers

**Goal.** Earlier entries paraphrase their commands ("the standard dev run"),
which makes the reported numbers needlessly hard to reproduce. Record the
verbatim commands for every result reported so far, make exact commands a log
convention, and make future reports self-documenting.

**Setup.** Documentation plus two small tool changes: `report.json` and the text
report now embed the exact generating command (`command` field), as do the
external-baseline claims files. Going forward, Setup sections quote commands
verbatim (convention added to `log/README.md`).

**Commands for previously reported results.** All runs assume the fixture sets
and split of entries 04-05 of 2026-07-06 (pop-jazz-v1 committed; when-in-rome-v1
rebuilt per `../REPRODUCING.md`). Numbers reproduce at each entry's recorded
engine commit; reports embed the commit they ran at.

Entry 2026-07-06-07 (profile floor baselines):

```sh
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v1
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json
```

Entry 2026-07-06-09 (external baselines and profile A/B):

```sh
python tool/whatkey_external_baseline.py \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json
for f in build/whatkey-baselines/when-in-rome-v1-development/*.claims.json; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --claims-file "$f"
done
for p in temperleyKostkaPayne temperley krumhanslKessler; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --profiles "$p" \
    --out "build/whatkey-harness/when-in-rome-v1-development-$p"
done
```

Entry 2026-07-07-01 (matched coverage and sweep; the dev run above must run
first, it writes the `claims.json` the `--restrict-to` runs anchor to):

```sh
for f in build/whatkey-baselines/when-in-rome-v1-development/*.claims.json; do
  name=$(basename "$f" .claims.json)
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --claims-file "$f" \
    --restrict-to build/whatkey-harness/when-in-rome-v1-development/claims.json \
    --out "build/whatkey-harness/when-in-rome-v1-development-$name-matched"
done
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --sweep-margin-floors 0,0.01,0.02,0.05,0.1,0.15,0.2,0.3 \
  --out build/whatkey-harness/when-in-rome-v1-development-sweep
```

Entry 2026-07-07-03 (weighted evidence model):

```sh
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v1 --detector evidence
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --detector evidence --sweep-margin-floors 0,0.1,0.25,0.5,0.75,1,1.5,2
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --detector evidence --confidence-weighting off \
  --out build/whatkey-harness/when-in-rome-v1-development-evidence-nocw
dart run tool/whatkey_harness.dart \
  --fixtures build/whatkey-fixtures/when-in-rome-v1 \
  --split-file research/whatkey/data/splits/when-in-rome-v1.json \
  --detector evidence \
  --restrict-to build/whatkey-harness/when-in-rome-v1-development/claims.json \
  --out build/whatkey-harness/when-in-rome-v1-development-evidence-matched
```

Entry 2026-07-07-04 (hybrid sweep, paired test, behavioral suite; the
`--functional-blend` values were explicit, so the later default change from 0.05
to 0.1 does not affect reproduction):

```sh
for b in 0.01 0.02 0.05 0.1 0.15 0.25; do
  dart run tool/whatkey_harness.dart \
    --fixtures build/whatkey-fixtures/when-in-rome-v1 \
    --split-file research/whatkey/data/splits/when-in-rome-v1.json \
    --detector hybrid --functional-blend "$b" \
    --out "build/whatkey-harness/wir-dev-hybrid-b$b"
done
python3 tool/whatkey_compare.py \
  build/whatkey-harness/wir-dev-hybrid-b0.1/report.json \
  build/whatkey-harness/when-in-rome-v1-development/report.json
dart run tool/whatkey_harness.dart \
  --fixtures research/whatkey/data/fixtures/pop-jazz-v1 \
  --detector hybrid --functional-blend 0.1 \
  --out build/whatkey-harness/pop-jazz-v1-hybrid-b0.1
```

**Decisions.** Exact commands are a log convention from here on; paraphrases do
not qualify. Reports and claims files embed their generating command, so
artifacts in `build/` are self-documenting even when a log entry is not.

**Next.** Unchanged from entry 04.
