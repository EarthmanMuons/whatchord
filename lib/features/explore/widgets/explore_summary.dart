import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:whatchord/features/theory/theory.dart';

class ExploreSummary extends StatelessWidget {
  const ExploreSummary({super.key, required this.presentation});

  final ChordPresentation presentation;

  @override
  Widget build(BuildContext context) {
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
        '${chordSymbolDisplayLabel(presentation.symbol)}\n'
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
      label: presentation.longLabel,
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
                      text: toSmufl(presentation.symbol.root),
                      style: rootStyle,
                    ),
                    if (presentation.symbol.quality.isNotEmpty) ...[
                      TextSpan(text: '\u2009', style: symbolDetailStyle),
                      TextSpan(
                        text: toSmufl(presentation.symbol.quality),
                        style: symbolDetailStyle,
                      ),
                    ],
                    if (presentation.symbol.hasBass) ...[
                      TextSpan(text: ' / ', style: symbolDetailStyle),
                      TextSpan(
                        text: toSmufl(presentation.symbol.bassRequired),
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
