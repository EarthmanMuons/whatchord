/// Bluetooth adapter state.
enum BluetoothState {
  /// Bluetooth is powered on and ready.
  poweredOn,

  /// Bluetooth is powered off.
  poweredOff,

  /// Bluetooth state is unknown or unavailable.
  unknown,

  /// Bluetooth permission has not been granted.
  unauthorized,
}

extension BluetoothStateDisplay on BluetoothState {
  String get displayName => switch (this) {
    BluetoothState.poweredOn => 'Bluetooth On',
    BluetoothState.poweredOff => 'Bluetooth Off',
    BluetoothState.unknown => 'Bluetooth Unknown',
    BluetoothState.unauthorized => 'Bluetooth Permission Required',
  };
}
