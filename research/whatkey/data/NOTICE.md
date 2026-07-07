# NOTICE

This directory contains WhatKey research data definitions, generated fixture
sets, frozen split definitions, and provenance records. Files in this directory
are not all necessarily covered by the repository's top-level 0BSD software
license.

## Hand-Authored Fixtures

The hand-authored pop/jazz sources and generated `pop-jazz-v1` fixtures are
original project content and are distributed under the repository's top-level
license unless a later fixture manifest says otherwise.

## Corpus-Derived Fixtures

Fixture sets derived from external music corpora carry the license and
attribution obligations of their source material. Their generated manifests must
record source repositories, source commits, fixture provenance, and per-fixture
license information before those fixtures are committed.

For `when-in-rome-v1`, the committed-fixture gate is documented in
`provenance/when-in-rome-v1.md`. Generated fixtures from the verified
When-in-Rome groups are data artifacts under CC BY-SA 4.0 provenance, not files
covered only by this repository's 0BSD software license.

Groups or corpora marked as unverified or noncommercial-gated may be used only
for local, uncommitted experiments under `build/` until a dated WhatKey log
entry records a separate redistribution decision. The ASAP dataset (CC BY-NC-SA
4.0), the Isophonics annotations (research use only), and the ASAP plus
When-in-Rome overlap set (ASAP terms plus Beethoven-sonata analyses outside the
verified group set) are all gated this way: `tool/whatkey_asap_extract.py`,
`tool/whatkey_isophonics_extract.py`, and `tool/whatkey_asap_wir_extract.py`
refuse to write under `research/`, and none of their fixtures are committed.

## Results Artifacts

Evaluation outputs committed under `../results/` (harness reports and claims
files) contain piece identifiers and titles, aggregate metrics, and detector
outputs. Where a report records a per-piece summary key label derived from a
gated corpus, the committing log entry records the redistribution decision
(first: the one-shot test-split artifacts, log entry 2026-07-07-27). No
time-aligned annotation content or score content is committed this way.

## Split Files

Files under `splits/` record piece identifiers, counts, grouping metadata, and
the deterministic split method. They do not contain score or analysis excerpts,
but they still record source corpus pins and should be kept with the provenance
notes for reproducibility.
