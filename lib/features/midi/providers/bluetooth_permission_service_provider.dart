import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bluetooth_permission_service.dart';

final bluetoothPermissionServiceProvider = Provider<BluetoothPermissionService>(
  (ref) {
    return const BluetoothPermissionService();
  },
);
