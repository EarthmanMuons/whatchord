# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to
[Calendar Versioning][2] using `YYYY.MM.DD` release identifiers.

[1]: https://keepachangelog.com/en/1.1.0/
[2]: https://calver.org/

## [Unreleased]

## [2026.1.27] - 2026-01-27

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
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.27...HEAD
[2026.1.27]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.23...v2026.1.27
[2026.1.23]:
  https://github.com/EarthmanMuons/whatchord/compare/v0.8.0...v2026.1.23
[0.8.0]: https://github.com/EarthmanMuons/whatchord/commits/v0.8.0
