import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ble_permission_service.dart';

final blePermissionServiceProvider = Provider<BlePermissionService>((ref) {
  return const BlePermissionService();
});
