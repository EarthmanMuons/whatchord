<p align="center">
  <img width="200" src="https://raw.githubusercontent.com/EarthmanMuons/what_chord/refs/heads/main/docs/images/whatchord_logo.webp" alt="WhatChord logo">
</p>

<h1 align="center">WhatChord</h1>

WhatChord listens to live MIDI input and identifies the most musically plausible
chord as you play. It is optimized for immediacy and correctness, favoring
stable, conventional interpretations over raw pitch-class matches.

---

## Features

- **Real-time MIDI analysis**  
  Connect a Bluetooth MIDI keyboard and see chords update instantly as you play.

- **Musically informed chord detection**  
  Goes beyond simple pitch-class matching by ranking and resolving ambiguous
  interpretations using harmonic heuristics (e.g., inversions, extensions, upper
  structures).

- **Ambiguity-aware UI**  
  When multiple interpretations are plausible, WhatChord surfaces alternative
  candidates rather than hiding uncertainty.

- **Context-aware spelling**  
  Notes and chord symbols are spelled according to the current key signature,
  including correct enharmonic choices.

- **Notation style preferences**  
  Supports multiple chord symbol conventions (e.g., textual vs. symbolic),
  balancing readability with precision.

## Screenshots

![WhatChord screenshot showing the first inversion of a C major chord in light and dark themes][THEMES]

[THEMES]:
  https://raw.githubusercontent.com/EarthmanMuons/what_chord/refs/heads/main/docs/screenshots/theme_modes.webp

## Installation

WhatChord is distributed as a signed Android APK and is **not** currently
published on the Google Play Store. Installation is intended to be handled via a
standard third-party updater workflow.

### Recommended: Obtanium

[Obtanium](https://obtainium.imranr.dev/) allows you to securely track and
install APK releases directly from GitHub while verifying developer signatures.

**Planned workflow:**

1. Install Obtanium on your Android device.
2. Add the WhatChord GitHub repository as an app source.
3. Obtanium will automatically detect new releases and prompt you to update.
4. Verify the APK signature against the published developer key (see below).

> Automated, signed APK builds will be provided as GitHub Releases.

### Developer Signing Key

All official builds will be signed with a consistent developer key.  
You are encouraged to verify this fingerprint using Obtanium's AppVerifier
integration or Android's native tooling.

**SHA-256 Signing Certificate Fingerprint (placeholder):**

```
AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:
AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

> ⚠️ Do not install builds whose signing key does not match the fingerprint
> published here.

## Intended Use

WhatChord is particularly useful for:

- Pianists and keyboardists exploring harmony at the instrument
- Students learning chord construction, extensions, and inversions
- Educators demonstrating harmonic function in real time
- Composers and improvisers sanity-checking dense voicings

It is **not** intended to replace formal analysis tools or notation software,
but to provide immediate, sensible feedback while playing.

## Status

WhatChord is under active development. The app is free to use, contains no
advertisements, and does not collect or transmit any personal data. Scoring
heuristics and UI details may evolve as edge cases and real-world usage inform
improvements.

If you believe a chord has been identified or ranked incorrectly, please open an
issue on the
[GitHub repository](https://github.com/EarthmanMuons/what_chord/issues/new/choose).
When possible, include:

- The notes played (pitch names)
- The selected key signature
- The chord WhatChord reported versus the expected result

Concrete musical examples are especially valuable and help ensure the engine
improves in a principled way.

## License

WhatChord is released under the [Zero Clause BSD License][LICENSE] (SPDX: 0BSD).

Copyright &copy; 2025 [Aaron Bull Schaefer][EMAIL] and contributors

[LICENSE]: https://github.com/EarthmanMuons/what_chord/blob/main/LICENSE
[EMAIL]: mailto:aaron@elasticdog.com
