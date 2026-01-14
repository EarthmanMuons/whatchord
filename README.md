<p align="center">
  <img width="200" src="https://raw.githubusercontent.com/EarthmanMuons/what_chord/refs/heads/main/docs/images/whatchord_logo.webp" alt="WhatChord logo">
</p>

<h1 align="center">WhatChord</h1>

WhatChord listens to live MIDI input and identifies the most musically plausible
chord as you play. It is optimized for speed and accuracy, favoring stable,
conventional interpretations over simple note-matching.

---

## Features

- **Real-time MIDI analysis**  
  Connect a Bluetooth MIDI keyboard and see chords update instantly as you play.

- **Musically informed chord detection**  
  Goes beyond simple note-matching by ranking and resolving ambiguous
  interpretations using smart musical rules (e.g., inversions, extensions, upper
  structures, diatonic preference).

- **Ambiguity-aware user interface**  
  When multiple interpretations are plausible, WhatChord surfaces alternative
  candidates rather than hiding uncertainty.

- **Context-aware spelling**  
  Notes and chord symbols are spelled using the current key signature _and_ the
  identified chord context, producing musically appropriate enharmonic choices.

- **Notation style preferences**  
  Supports multiple chord symbol conventions (e.g., textual vs. symbolic),
  balancing readability with precision.

## Screenshots

Here's WhatChord in action:

![WhatChord identifying the notes F#, C, E, and Bb as C7#11 over F#, in light and dark themes.][THEMES]

[THEMES]:
  https://raw.githubusercontent.com/EarthmanMuons/what_chord/refs/heads/main/docs/screenshots/theme_modes.webp

## Installation

WhatChord is distributed as a signed Android APK (app package) and is **not**
currently published on the Google Play Store. Installation is intended to be
handled via a standard third-party updater workflow.

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

## Who Is This For?

WhatChord is particularly useful for:

- Pianists and keyboardists exploring harmony at the instrument
- Students learning chord construction, extensions, and inversions
- Educators demonstrating harmonic concepts in real time
- Composers and improvisers checking complex voicings

It provides immediate, intelligent feedback while you play. It is **not**
intended to replace formal analysis tools or notation software, but to
complement your practice and exploration.

## Status

WhatChord is under active development. The app is free to use, contains no
advertisements, and does not collect or transmit any personal data. Scoring
heuristics and user interface details may evolve as edge cases and real-world
usage inform improvements.

If you believe a chord has been identified incorrectly, please open an issue on
the
[GitHub repository](https://github.com/EarthmanMuons/what_chord/issues/new/choose).
When possible, include the notes you played, the key signature, and the chord
WhatChord reported versus the expected result. You can also long-press the chord
identity card to access detailed analysis information. Sharing this data helps
diagnose edge cases and improve the engine.

## License

WhatChord is released under the [Zero Clause BSD License][LICENSE] (SPDX: 0BSD).

Copyright &copy; 2025 [Aaron Bull Schaefer][EMAIL] and contributors

[LICENSE]: https://github.com/EarthmanMuons/what_chord/blob/main/LICENSE
[EMAIL]: mailto:aaron@elasticdog.com
