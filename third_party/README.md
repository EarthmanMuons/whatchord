# Vendored packages

Copies of upstream pub.dev packages carried here via `dependency_overrides`
until upstream ships equivalent fixes. Keep diffs minimal; every deliberate
change is marked with a `WhatChord patch` comment.

## flutter_midi_command 1.0.2 and flutter_midi_command_ble 1.0.2

Upstream: <https://github.com/InvisibleWrench/FlutterMidiCommand>

Problem: on iOS, a BLE MIDI peripheral that CoreMIDI never surfaces (typically
one whose MIDI characteristic does not require encryption, so iOS never bonds
it) connects successfully but delivers no MIDI data at all.

Two upstream defects combine:

1. `flutter_midi_command_ble` only subscribes to MIDI notifications after a
   pairing confirmation, but on Apple `universal_ble` has no system pairing API:
   `isPaired` returns null and `onPairingStateChange` never fires, so the
   subscribe is unreachable and the BLE data path is dead code on iOS.
2. `flutter_midi_command` works around that with a BLE-to-CoreMIDI handoff after
   connecting, which requires the peripheral to appear in CoreMIDI within 20s.
   For never-bonded peripherals it never appears, the handoff times out, and no
   data path remains.

Patches:

- `flutter_midi_command_ble`: when `isPaired` returns null, read the MIDI
  characteristic once (BLE MIDI spec behavior; also triggers OS pairing when
  encryption is required) and subscribe to notifications directly. Also swallow
  async subscribe errors that upstream's sync try/catch missed.
- `flutter_midi_command`: remove the CoreMIDI handoff, since the patched BLE
  transport is now the data path on every platform and a CoreMIDI counterpart
  would deliver every message a second time.

To update: diff these copies against the matching version in
`~/.pub-cache/hosted/pub.dev/`, re-vendor `lib/`, `pubspec.yaml`, and `LICENSE`,
and re-apply the marked patches. Remove the overrides in `pubspec.yaml` once
upstream resolves the iOS BLE data path.
