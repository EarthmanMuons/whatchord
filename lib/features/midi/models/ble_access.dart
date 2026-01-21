enum BleAccessState { ready, denied, permanentlyDenied, restricted }

class BleAccessResult {
  final BleAccessState state;
  final String? message;
  const BleAccessResult(this.state, {this.message});

  bool get isReady => state == BleAccessState.ready;
}
