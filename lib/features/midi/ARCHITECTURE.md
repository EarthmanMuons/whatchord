# MIDI Architecture

This document explains how the MIDI feature is structured and why key defensive
behaviors exist.

## Goals

- Keep BLE transport logic isolated from UI.
- Keep reconnect behavior deterministic and cancelable.
- Ensure lifecycle transitions (foreground/background) do not leave stale
  connected state.
- Prefer explicit state transitions over implicit side effects.

## Provider Responsibilities

### `midiConnectionStateProvider` (`MidiConnectionNotifier`)

High-level connection orchestration and UI-facing connection state machine.

- Owns `MidiConnectionState` phases (`idle`, `connecting`, `retrying`,
  `connected`, `bluetoothUnavailable`, `deviceUnavailable`, `error`).
- Runs auto-reconnect flows and backoff.
- Handles cancel semantics and reconnect single-flight guard.
- Publishes state changes for UI.
- Persists last-connected device on confirmed connect.

It does not directly talk to the plugin.

### `midiDeviceManagerProvider` (`MidiDeviceManager`)

Transport and device graph manager.

- Starts and primes Bluetooth central lazily.
- Starts/stops scanning and refreshes device snapshots.
- Performs connect/disconnect/reconnect operations.
- Reconciles stale connection snapshots against plugin truth.
- Watches setup and Bluetooth state streams and keeps transport state updated.
- Runs connected-device watchdog in foreground.

It does not own user-facing reconnect policy.

### `midiBleServiceProvider` (`MidiBleService`)

Thin plugin boundary around `flutter_midi_command`.

- Maps plugin types to app models.
- Adds hard timeouts around plugin calls that can hang.
- Exposes streams and low-level connect/disconnect/device APIs.

No policy decisions live here.

## State And Event Flow

### Startup flow

1. `appMidiLifecycleProvider` attaches lifecycle observer.
2. `midiDeviceManagerProvider` is created early to install listeners.
3. If auto-reconnect is enabled and last-connected device is known, call
   `tryAutoReconnect(reason: 'startup')`.

### Resume flow

1. Set manager and connection layers to foreground (`setBackgrounded(false)`).
2. Reconcile current connected snapshot with plugin (`reconcileConnectedDevice`)
   to clear stale "connected" state after background.
3. Attempt reconnect (`tryAutoReconnect(reason: 'resume')`).

### Background flow

1. Set manager and connection layers to background.
2. Cancel reconnect/backoff work.
3. Stop scanning (best effort).

## Connection State Machine Notes

- `connected` is driven from manager connected-device stream.
- `connecting` and `retrying` are transient reconnect phases.
- `bluetoothUnavailable` is used for permission/adapter/not-ready states.
- `deviceUnavailable` is terminal after max reconnect attempts.
- `error` is used for explicit connect failures.

UI should consume `midiConnectionStatusProvider` for presentation strings.

## Cancellation And Single-Flight Contract

`MidiConnectionNotifier` enforces a strict reconnect contract:

- `_attemptInFlight` allows only one reconnect run at a time.
- `cancel()` sets `_cancelRequested = true` and cancels active backoff delay.
- `cancel()` does not clear `_attemptInFlight`; the active reconnect run clears
  it in `tryAutoReconnect` `finally` after all async work unwinds.
- `_reconnectWithBackoff()` checks cancellation/background at loop boundaries
  and after long awaits (`findReconnectTarget`, reconnect attempt, publish wait,
  backoff sleep).

This prevents overlapping reconnect runs and stale retry UI after cancel.

## Defensive Mechanisms And Why They Exist

### Timeout wrappers

Plugin and BLE operations can hang or stall on some devices/platform states.
Hard timeouts keep state transitions bounded and prevent indefinite
"Connecting...".

### Reconcile-on-resume

iOS can drop BLE links while backgrounded without timely setup events.
Foreground reconciliation ensures stale connected snapshots are corrected before
reconnect decisions.

### Watchdog

Foreground periodic reconciliation catches silent disconnect drift while the app
remains open and not scanning.

### Reconnect target remap

Some platforms can expose the same physical device with a changed id or
transport across sessions. Name/transport hint matching allows reconnect to
recover and updates persisted last-connected id.

### Backoff

Exponential delays reduce retry thrash and battery churn while still giving fast
early recovery attempts.
