# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to
[Calendar Versioning][2] using `YYYY.MM.DD` release identifiers.

[1]: https://keepachangelog.com/en/1.1.0/
[2]: https://calver.org/

## [Unreleased]

### Added

- Added Demo Mode in Settings so you can explore guided chord examples without
  connecting a MIDI device.
- Added a first-launch MIDI coach mark that highlights where to connect and how
  to get started.
- Added mode-aware scale degree numerals (major and natural minor) with
  contextual tooltips that explain each degree's function.

### Changed

- Improved inline onboarding prompts so next-step guidance is clearer during
  setup and connection.
- Key signature selection now persists between app launches.
- Refined copy and spacing across the app for a clearer, more consistent
  experience.
- Upgraded Flutter to `3.41.2` (Dart `3.11.0`) with refreshed locked
  dependencies.

### Fixed

- Fixed Reset to Defaults during active MIDI reconnect attempts so retries are
  canceled immediately and connection status returns to Not connected.

## [2026.2.18] - 2026-02-18

### Added

- Added explicit support for wired USB MIDI connections, with transport-aware
  connection flows in MIDI settings and device selection.
- Added Audio Monitor in Input settings so you can hear incoming MIDI notes with
  built-in SoundFont playback, plus persisted enable/disable and precise volume
  control.
- Added chord degree display in Analysis Details relative to the detected root.

### Changed

- Updated MIDI wording and status indicators to more clearly reflect Bluetooth,
  USB, and network transports.
- Refined sheets and pickers across analysis and MIDI flows with more consistent
  headers, insets, spacing, and divider treatment, including landscape behavior.
- Stabilized persisted settings mappings for theme and chord notation values.

### Fixed

- Fixed wired and other non-Bluetooth manual MIDI connection flows so they no
  longer require Bluetooth permission.
- Fixed MIDI transport mapping so plugin `native` devices are labeled and shown
  as USB transport in app UI.
- Fixed reconnect behavior when forgetting the last device so active retries are
  canceled immediately and status returns cleanly to Not connected.
- Fixed MIDI note-state handling for `All Notes Off` (CC 123) and sustain-safe
  restrike behavior.

## [2026.2.15] - 2026-02-15

### Changed

- Improved accessibility across the app with clearer VoiceOver/TalkBack
  announcements for identity states, MIDI status, and key selection, plus better
  semantic headers and action hints in sheets and modals.
- Increased tap targets across home and MIDI controls, and improved reduced
  motion support by skipping auto-scroll transitions and idle pulse animations
  when animations are disabled.
- Added size-class-aware layouts on larger screens, including a larger identity
  card and improved typography/spacing for near-tie candidates and input
  note/pedal controls.
- Updated portrait tablet keyboard scaling to show more visible keys as screen
  width increases, while preserving a minimum white-key width for readability.
- Updated key signature and analysis details to use adaptive right-side sheets
  on larger layouts with consistent styling, unified headers, and
  swipe-to-dismiss.
- Refined key signature picker wording and layout with a persistent "Key
  Signature" title, a clearer "Accidentals" column label, and better spacing and
  height behavior.
- Updated the Settings color palette picker to adapt by size class, keep the
  picker open for live preview, and improve accessibility with clearer
  selected-state semantics and explicit hints.
- Improved MIDI reconnect reliability on iOS with operation timeouts, and
  post-reconnect confirmation.
- Upgraded Flutter to `3.41.1` (Dart `3.11.0`) with refreshed locked
  dependencies.
- Migrated iOS lifecycle wiring to Apple's `UIScene` model
  (`FlutterSceneDelegate`) to stay aligned with UIKit requirements.

### Fixed

- Fixed settings pages in landscape orientation so list content now respects
  device safe-area insets and avoids camera cutout occlusion.
- Fixed MIDI device picker filtering/deduplication to keep Bluetooth devices
  visible when transport labels vary by platform and collapse duplicate rows
  where the same device appears with a trailing "Bluetooth"/"BLE" name suffix.
- Fixed a last-connected-device state bug where forgetting a device and then
  reconnecting it could leave the card showing a disabled "Reconnect" action
  instead of "Disconnect".
- Fixed `MidiConnectionState.copyWith` so nullable fields can be explicitly
  cleared, preventing stale reconnect messages, retry delays, and Bluetooth
  unavailability details from leaking across connection phases.
- Fixed reconnect edge cases that could leave MIDI stuck on "Connecting..." or
  "Reconnecting..." after app resume or canceled attempts by enforcing strict
  single-flight reconnect ownership and post-await cancellation checks so
  canceled attempts stop cleanly without extra retry UI states.

## [2026.2.12] - 2026-02-12

### Changed

- Refined the home app bar for large text sizes by replacing the MIDI status
  pill with a compact status icon button and clamping title scaling to the
  toolbar height to prevent overflow.
- Smoothed large-text rendering across the home screen with updated input
  display sizing, identity card spacing, tonality bar text scaling, and
  scroll-fade affordances to reduce clipping and make off-screen content
  clearer.
- Let the near-tie chord candidates list grow taller in portrait layouts and
  added a landscape overflow scrollbar to better handle large text sizes.

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
  https://github.com/EarthmanMuons/whatchord/compare/v2026.2.18...HEAD
[2026.2.18]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.2.15...v2026.2.18
[2026.2.15]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.2.12...v2026.2.15
[2026.2.12]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.2.4...v2026.2.12
[2026.2.4]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.31...v2026.2.4
[2026.1.31]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.27...v2026.1.31
[2026.1.27]:
  https://github.com/EarthmanMuons/whatchord/compare/v2026.1.23...v2026.1.27
[2026.1.23]:
  https://github.com/EarthmanMuons/whatchord/compare/v0.8.0...v2026.1.23
[0.8.0]: https://github.com/EarthmanMuons/whatchord/commits/v0.8.0
