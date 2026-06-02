# WhatChord Symbols tooling

This folder contains the scripts used to regenerate the bundled WhatChord
Symbols fonts from local copies of the Leland font files.

The upstream source fonts are not committed. Download `LelandText.otf` and
`Leland.otf` from the Leland project and place them in this folder:

- <https://github.com/MuseScoreFonts/Leland>

Regenerate the app font assets:

```sh
mise run symbols:build
```

Generate a local SVG specimen sheet for inspecting sidebearings and bold weight:

```sh
mise run symbols:specimen
```

Generated outputs:

- `../../assets/fonts/WhatChordSymbols-Regular.otf`
- `../../assets/fonts/WhatChordSymbols-Bold.otf`
- `specimen.svg`

`LelandText.otf`, `Leland.otf`, and `specimen.svg` are intentionally ignored by
git.
