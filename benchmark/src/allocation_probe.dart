import 'dart:developer' as developer;

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Deterministic allocation measurement via the VM service.
///
/// Allocation byte/object counts depend only on input and code, not on the
/// machine, so they are a reproducible memory signal. We read two distinct
/// things from one API:
///
/// - **churn**: bytes/objects allocated since the last reset. The driver of GC
///   pressure; the relevant number while the engine is stateless.
/// - **live**: bytes/objects still reachable after a forced GC, i.e. retained
///   footprint. Mostly the LRU cache today; the number that starts to matter
///   once temporal history becomes retained state.
///
/// Requires the VM service, so the program must run with `--enable-vm-service`.
class AllocationProbe {
  AllocationProbe._(this._service, this._isolateId);

  final VmService _service;
  final String _isolateId;

  static Future<AllocationProbe> connect() async {
    final info = await developer.Service.getInfo();
    final uri = info.serverUri;
    if (uri == null) {
      throw StateError(
        'VM service is not enabled. Run with `--enable-vm-service`, e.g.\n'
        '  dart run --enable-vm-service --define=whatchord.counters=true \\\n'
        '    benchmark/analyze_benchmark.dart',
      );
    }
    final wsUri = uri
        .replace(
          scheme: 'ws',
          pathSegments: [...uri.pathSegments.where((s) => s.isNotEmpty), 'ws'],
        )
        .toString();
    final service = await vmServiceConnectUri(wsUri);
    final vm = await service.getVM();
    final isolateId = vm.isolates!.first.id!;
    return AllocationProbe._(service, isolateId);
  }

  /// Reset the allocation accumulator and collect garbage so the next [sample]
  /// reflects only work done in between.
  Future<void> resetAndGc() =>
      _service.getAllocationProfile(_isolateId, reset: true, gc: true);

  Future<AllocationSnapshot> sample() async {
    final profile = await _service.getAllocationProfile(_isolateId, gc: true);
    var churnBytes = 0;
    var churnObjects = 0;
    for (final m in profile.members ?? const <ClassHeapStats>[]) {
      churnBytes += _nonNeg(m.accumulatedSize);
      churnObjects += _nonNeg(m.instancesAccumulated);
    }
    // heapUsage is the authoritative post-GC live heap for the whole isolate.
    // Per-class bytesCurrent/instancesCurrent are NOT summed here: they cover
    // every runtime object, not just analysis output, so they overstate what
    // the engine retains. Retained-by-engine is derived as a before/after
    // heapUsage delta by the caller instead.
    return AllocationSnapshot(
      churnBytes: churnBytes,
      churnObjects: churnObjects,
      heapUsage: _nonNeg(profile.memoryUsage?.heapUsage),
    );
  }

  Future<void> dispose() => _service.dispose();

  static int _nonNeg(int? value) => (value == null || value < 0) ? 0 : value;
}

class AllocationSnapshot {
  const AllocationSnapshot({
    required this.churnBytes,
    required this.churnObjects,
    required this.heapUsage,
  });

  /// Bytes allocated since the last reset (allocation churn / GC pressure).
  final int churnBytes;

  /// Objects allocated since the last reset.
  final int churnObjects;

  /// Whole-isolate live heap after a forced GC.
  final int heapUsage;
}
