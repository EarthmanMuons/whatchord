/// Why MIDI over BLE is currently unavailable.
enum MidiUnavailableReason {
  /// Runtime Bluetooth permission denied (user can be asked again).
  bluetoothPermissionDenied,

  /// Runtime Bluetooth permission denied permanently (needs Settings).
  bluetoothPermissionPermanentlyDenied,

  /// Bluetooth adapter is powered off.
  bluetoothOff,

  /// Bluetooth is not supported on this device.
  bluetoothUnsupported,

  /// Bluetooth stack not ready / unknown state.
  bluetoothNotReady,
}
