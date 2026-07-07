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
4.0) is noncommercial-gated: `tool/whatkey_asap_extract.py` refuses to write
under `research/`, and no ASAP-derived fixture is committed.

## Split Files

Files under `splits/` record piece identifiers, counts, grouping metadata, and
the deterministic split method. They do not contain score or analysis excerpts,
but they still record source corpus pins and should be kept with the provenance
notes for reproducibility.
