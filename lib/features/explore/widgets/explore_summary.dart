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
    final copyChoices = [
      _ExploreCopyChoice(
        title: 'Chord symbol',
        icon: Icons.music_note,
        value: chordSymbolDisplayLabel(
          presentation.symbol,
          noteNameSystem: noteNameSystem,
          spacing: ChordSymbolDisplaySpacing.plain,
        ),
        copiedLabel: 'chord symbol',
      ),
      _ExploreCopyChoice(
        title: 'Academic name',
        icon: Icons.notes,
        value: presentation.longLabel,
        copiedLabel: 'academic name',
      ),
      _ExploreCopyChoice(
        title: 'Spoken name',
        icon: Icons.record_voice_over,
        value: presentation.spokenLabel,
        copiedLabel: 'spoken name',
      ),
      _ExploreCopyChoice(
        title: 'Harte notation',
        icon: Icons.data_object,
        value: HarteChordFormatter.format(
          presentation.identity,
          rootName: presentation.symbol.root,
        ),
        copiedLabel: 'Harte notation',
      ),
    ];

    Future<void> copyToClipboard(_ExploreCopyChoice choice) async {
      final messenger = Theme.of(context).platform == TargetPlatform.iOS
          ? ScaffoldMessenger.maybeOf(context)
          : null;

      await Clipboard.setData(ClipboardData(text: choice.value));

      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text('Copied ${choice.copiedLabel} to clipboard')),
      );
    }

    Future<void> showCopyDialog() async {
      final choice = await showDialog<_ExploreCopyChoice>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Copy'),
            contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final choice in copyChoices)
                  ListTile(
                    leading: Icon(choice.icon),
                    title: Text(choice.title),
                    subtitle: Text(
                      choice.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.copy),
                    onTap: () => Navigator.of(dialogContext).pop(choice),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      if (choice == null || !context.mounted) return;

      await copyToClipboard(choice);
    }

    return Semantics(
      container: true,
      header: true,
      label: presentation.semanticLabel,
      onTap: showCopyDialog,
      onTapHint: 'Choose chord text to copy',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          excludeFromSemantics: true,
          onTap: showCopyDialog,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  Icons.copy_outlined,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCopyChoice {
  const _ExploreCopyChoice({
    required this.title,
    required this.icon,
    required this.value,
    required this.copiedLabel,
  });

  final String title;
  final IconData icon;
  final String value;
  final String copiedLabel;
}
