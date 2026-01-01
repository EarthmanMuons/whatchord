import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_chord/features/theory/theory.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedTonality = ref.watch(selectedTonalityProvider);
    final active = ref.watch(activeScaleDegreeProvider);

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (!context.mounted) return;

                  final navigator = Navigator.of(context, rootNavigator: true);

                  navigator.push(
                    ModalBottomSheetRoute(
                      builder: (_) => TonalityPickerSheet(),
                      isScrollControlled: true,
                      showDragHandle: true,
                    ),
                  );
                },
                icon: const Icon(Icons.music_note),
                label: Text('Key: ${selectedTonality.displayName}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ScaleDegrees(active: active),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
