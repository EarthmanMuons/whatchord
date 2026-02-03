<p align="center">
  <img width="200" src="docs/images/whatchord_logo.webp" alt="WhatChord logo">
</p>

<h1 align="center">WhatChord</h1>

<p align="center">
  <a href="https://apps.apple.com/us/app/whatchord-midi/id6758409779">
    <img
      src="docs/images/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg"
      alt="Download on the App Store"
      style="height: 60px"
      hspace="15"
  /></a>
  <a
    href="https://play.google.com/store/apps/details?id=com.earthmanmuons.whatchord"
  >
    <img
      src="docs/images/GetItOnGooglePlay_Badge_Web_color_English.svg"
      alt="Get it on Google Play"
      style="height: 60px"
      hspace="15"
  /></a>
</p>

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
  identified chord context, producing appropriate enharmonic spellings.

- **Notation style preferences**  
  Supports multiple chord symbol conventions (e.g., textual vs. symbolic),
  balancing readability with precision.

## Screenshots

Here's WhatChord in action:

![WhatChord identifying the notes F#, C, E, and Bb as C7#11 over F#, in light and dark themes.][THEMES]

[THEMES]:
  https://raw.githubusercontent.com/EarthmanMuons/whatchord/refs/heads/main/docs/screenshots/theme_modes.webp

## Installation

WhatChord is available through multiple official distribution channels. Choose
the option that best fits your platform and update preferences.

### iOS (App Store)

WhatChord is available on the App Store for iPhone and iPad.

<p>
  <a href="https://apps.apple.com/us/app/whatchord-midi/id6758409779">
    <img
      src="docs/images/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg"
      alt="Download on the App Store"
      style="height:60px; width:auto; margin:15px; vertical-align:middle;"
    >
  </a>
</p>

### Android (Google Play)

WhatChord is available on the Google Play Store for supported Android devices.

<p>
  <a href="https://play.google.com/store/apps/details?id=com.earthmanmuons.whatchord">
    <img
      src="docs/images/GetItOnGooglePlay_Badge_Web_color_English.svg"
      alt="Get it on Google Play"
      style="height:60px; width:auto; margin:15px; vertical-align:middle;"
    >
  </a>
</p>

> Google Play availability may vary by region during staged rollouts.

### Android (Direct APK via GitHub)

For advanced users who prefer direct distribution or third-party updater
workflows, WhatChord also publishes **signed Android APKs** as GitHub Releases.

#### Recommended: Obtanium

[Obtanium](https://obtainium.imranr.dev/) allows you to securely track and
install APK releases directly from GitHub while verifying developer signatures.

**Workflow:**

1. Install Obtanium on your Android device.
2. Add the WhatChord [GitHub repository][REPO] as an _App source URL_.
3. Obtanium will automatically detect new releases and prompt you to update.
4. Verify the APK signature against the published developer key (see below).

> Automated, signed APK builds are published with every official GitHub Release.

[REPO]: https://github.com/EarthmanMuons/whatchord

### Developer Signing Key (Android)

All official Android builds distributed via Google Play and GitHub are signed
with the same developer key. You are encouraged to verify the signing
certificate fingerprint for this key using [AppVerifier] or Android's native
package verification tooling.

**Signing Certificate Fingerprint (SHA-256)**

```
com.earthmanmuons.whatchord
E8:21:56:94:BA:A2:E0:A3:48:E6:97:49:3E:8B:A9:92:94:93:5E:46:DD:17:03:2C:3C:67:F3:63:9F:A1:3E:F8
```

> ⚠️ Do not install builds whose signing key does not match the fingerprint
> published here.

[AppVerifier]: https://github.com/soupslurpr/AppVerifier

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

If you believe a chord has been identified incorrectly, please [open an
issue][ISSUE] on the GitHub repository. When possible, include the notes you
played, the key signature, and the chord WhatChord reported versus the expected
result. You can also tap on the chord identity card to access detailed analysis
information. Sharing this data helps diagnose edge cases and improve the engine.

[ISSUE]: https://github.com/EarthmanMuons/whatchord/issues/new/choose

---

Apple, the Apple logo, and App Store are trademarks of Apple Inc., registered in
the U.S. and other countries and regions.

Google Play and the Google Play logo are trademarks of Google LLC.

## License

WhatChord is released under the [Zero Clause BSD License](LICENSE) (SPDX: 0BSD).

Copyright &copy; 2025 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
