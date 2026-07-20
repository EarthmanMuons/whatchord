# Chord-Context Data

Conventions follow WhatKey (`research/whatkey/data/README.md`): committed
fixture sets are immutable and versioned; license-gated corpora rebuild into
`build/` and are never committed; split files record identifiers and counts
only, so they are committed even when the fixtures they partition cannot be.

- `splits/` — frozen development/test split definitions. Splits are frozen
  before the first experiment on a corpus, and for new corpora from metadata
  alone, before any harmony content is inspected or fixtures are generated.
  When-in-Rome, Isophonics, and ASAP inherit the WhatKey frozen splits in
  `research/whatkey/data/splits/`; splits frozen by this initiative live here.
