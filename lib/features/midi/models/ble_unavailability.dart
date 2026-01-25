/// Why BLE transport is unavailable for MIDI communication.
enum BleUnavailability {
  /// Runtime Bluetooth permission denied (user can be asked again).
  permissionDenied,

  /// Runtime Bluetooth permission denied permanently (needs Settings).
  permissionPermanentlyDenied,

  /// Bluetooth adapter is powered off.
  adapterOff,

  /// Bluetooth is not supported on this device.
  unsupported,

  /// Bluetooth stack not ready / unknown state.
  notReady,
}
