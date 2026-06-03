import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scale_degree.dart';
import '../../domain/models/tonality.dart';
import '../../state/providers/theory_preferences_notifier.dart';
import '../services/note_display_formatter.dart';
import 'scale_degrees.dart';
import 'tonality_picker_sheet.dart';

typedef TonalitySideSheetPresenter =
    void Function({
      required BuildContext context,
      required String barrierLabel,
      required WidgetBuilder builder,
    });

class TonalityBarView extends ConsumerWidget {
  const TonalityBarView({
    super.key,
    required this.height,
    required this.tonality,
    required this.scaleDegreeAnalysis,
    required this.onOpenPicker,
    this.onScaleDegreesTap,
    this.horizontalInset = 16,
    this.keyTextScaleMultiplier = 1.0,
    this.scaleDegreesTextScaleMultiplier = 1.0,
  });

  final double height;
  final Tonality tonality;
  final ScaleDegreeAnalysis? scaleDegreeAnalysis;
  final VoidCallback onOpenPicker;
  final VoidCallback? onScaleDegreesTap;
  final double horizontalInset;
  final double keyTextScaleMultiplier;
  final double scaleDegreesTextScaleMultiplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noteNameSystem = ref.watch(noteNameSystemProvider);

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final verticalPadding = textScale > 1.2 ? 4.0 : 12.0;
    final minButtonHeight = textScale > 1.2 ? height : 48.0;
    final effectiveMinButtonHeight = minButtonHeight < 48.0
        ? 48.0
        : minButtonHeight;
    final keySemanticLabel =
        'Key: ${tonalitySemanticLabel(tonality, noteNameSystem: noteNameSystem)}';
    final keyLabel =
        'Key: ${tonalityDisplayLabel(tonality, noteNameSystem: noteNameSystem)}';

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
                label: keySemanticLabel,
                hint: 'Choose key signature.',
                onTap: onOpenPicker,
                onTapHint: 'Open key signature picker',
                excludeSemantics: true,
                child: Tooltip(
                  message: 'Choose key signature',
                  child: FilledButton.tonal(
                    onPressed: onOpenPicker,
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
                  child: Builder(
                    builder: (context) {
                      final scaleDegrees = ScaleDegrees(
                        current: scaleDegreeAnalysis,
                        mode: tonality.mode,
                        tonalityDisplayName: tonalitySemanticLabel(
                          tonality,
                          noteNameSystem: noteNameSystem,
                        ),
                        maxHeight: height,
                        fadeColor: cs.surfaceContainerLow,
                        textScaleMultiplier: scaleDegreesTextScaleMultiplier,
                      );

                      final onTap = onScaleDegreesTap;
                      if (onTap == null) return scaleDegrees;

                      return Semantics(
                        button: true,
                        onTap: onTap,
                        hint: 'Open scale explorer',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onTap,
                          child: scaleDegrees,
                        ),
                      );
                    },
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

void openTonalityPicker(
  BuildContext context, {
  required bool useSideSheet,
  required TonalitySideSheetPresenter showSideSheet,
}) {
  if (!context.mounted) return;

  if (useSideSheet) {
    showSideSheet(
      context: context,
      barrierLabel: 'Dismiss key signature picker',
      builder: (_) => const TonalityPickerSheet(
        presentation: TonalityPickerPresentation.sideSheet,
      ),
    );
    return;
  }

  unawaited(
    Navigator.of(context, rootNavigator: true).push(
      ModalBottomSheetRoute(
        builder: (_) => const TonalityPickerSheet(),
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
    ),
  );
}
