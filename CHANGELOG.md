# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to
[Calendar Versioning][2] using `YYYY.MM.DD` release identifiers.

[1]: https://keepachangelog.com/en/1.1.0/
[2]: https://calver.org/

## [Unreleased]

### Fixed

- Properly dispose the home page's MIDI connection listener to prevent duplicate
  events and potential memory leaks during navigation.

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
compliance.

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
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.31...HEAD
[2026.1.31]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.27...v2026.1.31
[2026.1.27]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.23...v2026.1.27
[2026.1.23]:
  https://github.com/EarthmanMuons/whatchord/compare/v0.8.0...v2026.1.23
[0.8.0]: https://github.com/EarthmanMuons/whatchord/commits/v0.8.0
