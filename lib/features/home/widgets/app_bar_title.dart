import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/demo/demo.dart';

class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'What'),
          const TextSpan(
            text: 'Chord',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (!kDebugMode) return title;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showDebugDemoMenu(context, ref),
      child: title,
    );
  }
}

void _showDebugDemoMenu(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final demoEnabled = ref.watch(demoModeProvider);
          final modeNotifier = ref.read(demoModeProvider.notifier);
          final seqNotifier = ref.read(demoSequenceProvider.notifier);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Demo Mode'),
                    value: demoEnabled,
                    onChanged: (v) => modeNotifier.setEnabled(v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: demoEnabled
                              ? () {
                                  seqNotifier.prev();
                                  modeNotifier.applyCurrentStep();
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Prev'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: demoEnabled
                              ? () {
                                  seqNotifier.next();
                                  modeNotifier.applyCurrentStep();
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
