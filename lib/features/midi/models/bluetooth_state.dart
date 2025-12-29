/// Bluetooth adapter state.
enum BluetoothState {
  /// Bluetooth is powered on and ready.
  on,

  /// Bluetooth is powered off.
  off,

  /// Bluetooth state is unknown or unavailable.
  unknown,

  /// Bluetooth permission has not been granted.
  unauthorized,
}

extension BluetoothStateDisplay on BluetoothState {
  String get displayName => switch (this) {
    BluetoothState.on => 'Bluetooth On',
    BluetoothState.off => 'Bluetooth Off',
    BluetoothState.unknown => 'Bluetooth Unknown',
    BluetoothState.unauthorized => 'Bluetooth Permission Required',
  };
}
