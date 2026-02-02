enum BluetoothAccessState { ready, denied, permanentlyDenied, restricted }

class BluetoothAccessResult {
  final BluetoothAccessState state;
  final String? message;
  const BluetoothAccessResult(this.state, {this.message});

  bool get isReady => state == BluetoothAccessState.ready;
}
