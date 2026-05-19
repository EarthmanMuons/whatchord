import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

class ExploreSummary extends ConsumerWidget {
  const ExploreSummary({super.key, required this.presentation});

  final ChordPresentation presentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteNameSystem = ref.watch(noteNameSystemProvider);
    final displaySymbol = chordSymbolDisplayParts(
      presentation.symbol,
      noteNameSystem: noteNameSystem,
    );
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final symbolStyle = textTheme.headlineMedium?.copyWith(
      color: colorScheme.onSurface,
      fontFamilyFallback: const ['Bravura'],
      height: 1.0,
    );
    final symbolDetailStyle = symbolStyle?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.74),
    );
    final rootStyle = symbolStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: (symbolStyle.fontSize ?? 14) + 6,
    );
    final copyText =
        '$displaySymbol\n'
        '${presentation.longLabel}';

    Future<void> copyToClipboard() async {
      final messenger = Platform.isIOS
          ? ScaffoldMessenger.maybeOf(context)
          : null;

      await Clipboard.setData(ClipboardData(text: copyText));

      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }

    return Semantics(
      container: true,
      header: true,
      label: presentation.semanticLongLabel,
      onLongPress: copyToClipboard,
      onLongPressHint: 'Copy chord name to clipboard',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          excludeFromSemantics: true,
          onLongPress: copyToClipboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: toSmufl(displaySymbol.root),
                      style: rootStyle,
                    ),
                    if (displaySymbol.quality.isNotEmpty) ...[
                      TextSpan(
                        text: displaySymbol.rootQualitySeparator,
                        style: symbolDetailStyle,
                      ),
                      TextSpan(
                        text: toSmufl(displaySymbol.quality),
                        style: symbolDetailStyle,
                      ),
                    ],
                    if (displaySymbol.hasBass) ...[
                      TextSpan(text: ' / ', style: symbolDetailStyle),
                      TextSpan(
                        text: toSmufl(displaySymbol.bassRequired),
                        style: symbolDetailStyle,
                      ),
                    ],
                  ],
                ),
                style: symbolStyle,
              ),
              const SizedBox(height: 6),
              Text(
                presentation.longLabel,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
