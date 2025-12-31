import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/midi_ui_status.dart';

class WakelockController extends ConsumerStatefulWidget {
  const WakelockController({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WakelockController> createState() => _WakelockControllerState();
}

class _WakelockControllerState extends ConsumerState<WakelockController> {
  bool? _lastWakelockEnabled;

  @override
  void dispose() {
    // Safety: ensure wakelock is off when leaving this subtree.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldEnableWakelock = ref.watch(
      midiUiStatusProvider.select((s) => s.keepAwake),
    );

    if (_lastWakelockEnabled != shouldEnableWakelock) {
      _lastWakelockEnabled = shouldEnableWakelock;

      // Avoid doing platform work in the middle of the build pipeline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WakelockPlus.toggle(enable: shouldEnableWakelock);
      });
    }

    return widget.child;
  }
}
