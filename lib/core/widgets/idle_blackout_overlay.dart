import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_activity_state.dart';
import '../providers/app_activity_notifier.dart';

class IdleBlackoutOverlay extends ConsumerWidget {
  const IdleBlackoutOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIdle = ref.watch(appActivityProvider.select((s) => s.isIdle));

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref
          .read(appActivityProvider.notifier)
          .markActivity(AppActivitySource.pointer),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // IMPORTANT: keep the routed child as a normal Stack child.
          child,

          // Only the overlay is positioned to fill.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: isIdle ? 1.0 : 0.0,
                duration: isIdle
                    ? const Duration(milliseconds: 420)
                    : const Duration(milliseconds: 180),
                curve: Curves.easeInOutCubic,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
