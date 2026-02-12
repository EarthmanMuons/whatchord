import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({
    super.key,
    required this.height,
    this.horizontalInset = 16,
  });

  final double height;
  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedTonality = ref.watch(selectedTonalityProvider);
    final degree = ref.watch(detectedScaleDegreeProvider);

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final verticalPadding = textScale > 1.2 ? 4.0 : 12.0;
    final minButtonHeight = textScale > 1.2 ? height : 40.0;
    final keyLabel = 'Key: ${selectedTonality.displayName}';

    void openTonalityPicker() {
      if (!context.mounted) return;

      final navigator = Navigator.of(context, rootNavigator: true);

      navigator.push(
        ModalBottomSheetRoute(
          builder: (_) => TonalityPickerSheet(),
          isScrollControlled: true,
          showDragHandle: true,
        ),
      );
    }

    TextScaler clampLabelScaler(TextStyle? baseStyle) {
      final fontSize = baseStyle?.fontSize ?? 14;
      final lineHeight = fontSize * (baseStyle?.height ?? 1.2);
      final availableHeight = height - (verticalPadding * 2);
      final maxScale = (availableHeight / lineHeight).clamp(1.0, 2.8);
      return TextScaler.linear(textScale.clamp(1.0, maxScale));
    }

    return Material(
      color: cs.surfaceContainerLow,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalInset),
          child: Row(
            children: [
              Semantics(
                container: true,
                button: true,
                label: keyLabel,
                hint: 'Choose key signature.',
                onTap: openTonalityPicker,
                onTapHint: 'Open key signature picker',
                excludeSemantics: true,
                child: Tooltip(
                  message: 'Choose key signature',
                  child: FilledButton.tonalIcon(
                    onPressed: openTonalityPicker,
                    icon: const Icon(Icons.music_note),
                    label: Text(
                      keyLabel,
                      style: textTheme.labelLarge,
                      textScaler: clampLabelScaler(textTheme.labelLarge),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, minButtonHeight),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: verticalPadding,
                      ),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ScaleDegrees(
                    current: degree,
                    maxHeight: height,
                    fadeColor: cs.surfaceContainerLow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
