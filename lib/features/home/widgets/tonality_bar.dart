import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

import 'adaptive_side_sheet.dart';

class TonalityBar extends ConsumerWidget {
  const TonalityBar({
    super.key,
    required this.height,
    this.horizontalInset = 16,
    this.keyTextScaleMultiplier = 1.0,
    this.scaleDegreesTextScaleMultiplier = 1.0,
  });

  final double height;
  final double horizontalInset;
  final double keyTextScaleMultiplier;
  final double scaleDegreesTextScaleMultiplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedTonality = ref.watch(selectedTonalityProvider);
    final degree = ref.watch(detectedScaleDegreeProvider);

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final verticalPadding = textScale > 1.2 ? 4.0 : 12.0;
    final minButtonHeight = textScale > 1.2 ? height : 48.0;
    final effectiveMinButtonHeight = minButtonHeight < 48.0
        ? 48.0
        : minButtonHeight;
    final keyLabel = 'Key: ${selectedTonality.displayName}';

    void openTonalityPicker() {
      if (!context.mounted) return;

      if (useHomeSideSheet(context)) {
        showHomeSideSheet<void>(
          context: context,
          barrierLabel: 'Dismiss key signature picker',
          builder: (_) => const TonalityPickerSheet(
            presentation: TonalityPickerPresentation.sideSheet,
          ),
        );
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        ModalBottomSheetRoute(
          builder: (_) => const TonalityPickerSheet(),
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: cs.surfaceContainerLow,
        ),
      );
    }

    TextStyle? scaledKeyLabelStyle(TextStyle? baseStyle) {
      final fontSize = baseStyle?.fontSize;
      if (fontSize == null) return baseStyle;
      return baseStyle?.copyWith(
        fontSize: fontSize * keyTextScaleMultiplier.clamp(1.0, 1.3),
      );
    }

    TextScaler clampLabelScaler(TextStyle? baseStyle) {
      final scaledBase = scaledKeyLabelStyle(baseStyle);
      final fontSize = scaledBase?.fontSize ?? 14;
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
                  child: FilledButton.tonal(
                    onPressed: openTonalityPicker,
                    style: ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(
                        Size(0, effectiveMinButtonHeight),
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsetsDirectional.fromSTEB(
                          6,
                          verticalPadding,
                          10,
                          verticalPadding,
                        ),
                      ),
                      visualDensity: VisualDensity.standard,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note),
                        const SizedBox(width: 4),
                        Text(
                          keyLabel,
                          style: scaledKeyLabelStyle(textTheme.labelLarge),
                          textScaler: clampLabelScaler(textTheme.labelLarge),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ScaleDegrees(
                    current: degree,
                    mode: selectedTonality.mode,
                    maxHeight: height,
                    fadeColor: cs.surfaceContainerLow,
                    textScaleMultiplier: scaleDegreesTextScaleMultiplier,
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
