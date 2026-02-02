import 'dart:io' show Platform;

import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/bluetooth_access.dart';

@immutable
class BluetoothPermissionService {
  const BluetoothPermissionService();

  Future<BluetoothAccessResult> ensureBluetoothAccess() async {
    if (Platform.isAndroid) return _ensureAndroid();
    if (Platform.isIOS) return _ensureIos();
    return const BluetoothAccessResult(BluetoothAccessState.ready);
  }

  Future<BluetoothAccessResult> _ensureAndroid() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    if (scan.isGranted && connect.isGranted) {
      return const BluetoothAccessResult(BluetoothAccessState.ready);
    }

    if (_isHardDenied(scan) || _isHardDenied(connect)) {
      return const BluetoothAccessResult(
        BluetoothAccessState.permanentlyDenied,
        message:
            'Nearby devices permission is blocked. Enable it in system settings '
            'to connect to Bluetooth MIDI devices.',
      );
    }

    return const BluetoothAccessResult(
      BluetoothAccessState.denied,
      message:
          'Nearby devices permission is required to discover and connect '
          'to Bluetooth MIDI devices.',
    );
  }

  Future<BluetoothAccessResult> _ensureIos() async {
    final status = await Permission.bluetooth.status;

    if (status.isRestricted) {
      return const BluetoothAccessResult(
        BluetoothAccessState.restricted,
        message: 'Bluetooth access is restricted on this device.',
      );
    }

    if (status.isPermanentlyDenied) {
      return const BluetoothAccessResult(
        BluetoothAccessState.permanentlyDenied,
        message:
            'Bluetooth access for this app is disabled in system settings. '
            'Enable it to connect to Bluetooth MIDI devices.',
      );
    }

    return const BluetoothAccessResult(BluetoothAccessState.ready);
  }

  bool _isHardDenied(PermissionStatus s) =>
      s.isPermanentlyDenied || s.isRestricted;
}
