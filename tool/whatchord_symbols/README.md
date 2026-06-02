# WhatChord Symbols tooling

This folder contains the scripts used to regenerate the bundled WhatChord
Symbols fonts from a local copy of `LelandText.otf`.

The upstream source font is not committed. Download `LelandText.otf` from the
Leland project and place it in this folder:

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

`LelandText.otf` and `specimen.svg` are intentionally ignored by git.
