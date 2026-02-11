# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to
[Calendar Versioning][2] using `YYYY.MM.DD` release identifiers.

[1]: https://keepachangelog.com/en/1.1.0/
[2]: https://calver.org/

## [Unreleased]

### Changed

- Replaced the MIDI status pill in the home app bar with a compact status icon
  button to improve legibility and avoid layout overflow at large text sizes.
- Clamped the home app bar title text scaling to the toolbar height to keep the
  title visible when system text size is increased.
- Improved large-text layout across the home screen, including input display
  sizing, tonality bar text scaling, and scroll fade affordances to reduce
  clipping and make off-screen content clearer.

## [2026.2.4] - 2026-02-04

This release marks the first general availability (GA) release of WhatChord on
the Apple App Store. Google Play distribution remains in closed testing while
tester requirements are completed.

### Added

- Added a **Support** link in _Settings > About_ for reporting issues or
  contacting support directly.

### Changed

- Significantly improved **piano keyboard auto-scroll behavior** to keep
  sounding notes visible in a more stable, intentional, and predictable way.
- Chevron edge indicators now **animate in and out smoothly** and are
  temporarily disabled during automatic scrolling to reduce visual noise.
- Tapping a chevron will **center all currently sounding notes** when they fit
  within the visible keyboard viewport.
- Refactored the **Analysis Details** view into a dedicated modal sheet with
  pinned action buttons and improved content scrolling.
- Improved **MIDI auto-reconnect behavior** by gating startup and resume
  attempts on actual Bluetooth readiness rather than fixed delays.
- Improved auto-reconnect reliability on iOS by handling **MIDI devices that
  change identifiers** between sessions.

### Fixed

- Fixed cases where piano edge chevrons appeared even though no sounding notes
  were actually off-screen.
- Fixed chevrons occasionally pointing to the wrong notes or failing to reveal
  hidden notes when tapped.
- Fixed unexpected piano auto-scroll "jumps" after manual dragging.
- Fixed inconsistent piano scroll positioning when rotating the device or
  changing the visible key count.
- Fixed an auto-reconnect deadlock where the app could remain stuck in
  **"Reconnecting…"** after resuming due to a canceled backoff delay never
  completing.
- Fixed a leaked MIDI connection listener on the home screen that could cause
  duplicate events or unnecessary resource usage during navigation.

## [2026.1.31] - 2026-01-31

### Changed

- Updated edge-to-edge layout behavior to improve landscape rendering, including
  full-bleed backgrounds, cutout-safe content insets, and more compact app bar
  and tonality bar spacing.
- Prepared the iOS build for App Store submission, including updated Xcode build
  settings and export compliance declarations.
- Replaced the unused "Copy as JSON" action in the analysis details sheet with a
  "Report Issue" link to GitHub.
- Improved internal demo mode tooling, including more reliable state isolation,
  deterministic presentation steps, and cleaner entry/exit behavior for testing
  and screenshots.
- Centralized external URL launching logic in a shared core helper.
- Updated Flutter to v3.38.9, aligned the Dart SDK with the bundled Flutter
  release, and upgraded project dependencies.

### Fixed

- Stabilized MIDI connection state propagation (status pill updates, manual
  reconnect UX, scan lifecycle, and transient empty snapshot handling).

## [2026.1.27] - 2026-01-27

This release marks the first Google Play Store submission for closed testing and
includes several refinements to support testing, diagnostics, and store
compliance. It was also submitted to the Apple App Store and subsequently
approved for public availability.

### Added

- Document a Privacy Policy for app store requirements.
- Add an in-app link to the Privacy Policy from the Settings page.
- Display the app version in Analysis Details to help with accurate bug reports
  when sharing diagnostic output.

### Changed

- Align demo chords with those used in app store screenshots.
- Sustain pedal UI now latches manual pedal toggles while a MIDI sustain pedal
  is held down.

### Fixed

- Fix stale Bluetooth MIDI "Connected" state after returning to the foreground
  by reconciling transport state on app resume.
- Reduce MIDI connection notifications to a single confirmation when a device
  successfully connects.

## [2026.1.23] - 2026-01-23

### Added

- Initial support for running WhatChord on iOS, including required platform
  permissions and launch screen assets.
- Re-architected BLE MIDI connectivity around Riverpod state management for
  improved stability and clarity.
- Improved detection and handling of Bluetooth disconnects, permissions, and
  adapter state changes.
- Switched the project to Calendar Versioning (CalVer) for clearer, date-based
  releases.
- Fully automated release publishing using GitHub Actions.
- Adoption of standardized Toolbox Envy scripts for versioning, changelog
  updates, and release tasks.

### Changed

- Identity card details are now opened with a single tap (previously
  long-press).

## [0.8.0] - 2026-01-16

This is a pre-1.0 release intended as a stable public preview.

### Added

- Initial public release of WhatChord.
- Real-time chord analysis engine with musically informed ranking.
- Context-aware enharmonic note spelling.
- Support for Bluetooth MIDI keyboards.
- Clear chord identity display with ambiguity handling.
- Signed Android APK distribution via GitHub Releases.

[Unreleased]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.2.4...HEAD
[2026.2.4]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.31...v2026.2.4
[2026.1.31]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.27...v2026.1.31
[2026.1.27]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.23...v2026.1.27
[2026.1.23]:
  https://github.com/EarthmanMuons/whatchord/compare/v0.8.0...v2026.1.23
[0.8.0]: https://github.com/EarthmanMuons/whatchord/commits/v0.8.0
