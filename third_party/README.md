# Vendored packages

Copies of upstream pub.dev packages carried here via `dependency_overrides`
until upstream ships equivalent fixes.

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

Patches (merged upstream in 1.0.3; these copies match the PR branch, plus one
local debug diagnostic noted below):

- `flutter_midi_command_ble`: when `isPaired` returns null, read the MIDI
  characteristic once (per the BLE MIDI spec; also triggers OS pairing when
  encryption is required) and subscribe to notifications directly. Also swallow
  async subscribe errors that upstream's sync try/catch missed.
- `flutter_midi_command`: with the BLE path live, a handed-off device would
  deliver every message twice, so BLE transport packets are suppressed for
  devices routed to the platform backend, keeping the handed-off CoreMIDI
  endpoint authoritative. The handoff also now connects the endpoint even when a
  concurrent `devices()` refresh already flipped the route, since routing alone
  never opens the endpoint.

Local debug diagnostic (not part of the upstream PR):
`flutter_midi_command_ble` logs `UniversalBle.onConnectionChange` events in
debug and profile builds, including the OS-provided disconnect reason, which
nothing else in the stack records.

Note on upstream 1.0.3: it merged both patches but also made the CoreMIDI
handoff required on iOS/macOS (`connectToDevice` throws when no CoreMIDI
counterpart appears), which breaks never-bonding peripherals again. Do not
upgrade to 1.0.3; wait for a release where the handoff falls back to the BLE
data path.

To update: diff these copies against the matching version in
`~/.pub-cache/hosted/pub.dev/`, re-vendor `lib/`, `pubspec.yaml`, and `LICENSE`,
and re-apply the patches. Remove the overrides in `pubspec.yaml` once upstream
resolves the iOS BLE data path.
