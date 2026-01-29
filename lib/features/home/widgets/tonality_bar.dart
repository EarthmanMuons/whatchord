import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({
    super.key,
    required this.height,
    this.insetLeft = 16,
    this.insetRight = 16,
  });

  final double height;
  final double insetLeft;
  final double insetRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedTonality = ref.watch(selectedTonalityProvider);
    final degree = ref.watch(detectedScaleDegreeProvider);

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(left: insetLeft, right: insetRight),
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
                  child: ScaleDegrees(current: degree),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
