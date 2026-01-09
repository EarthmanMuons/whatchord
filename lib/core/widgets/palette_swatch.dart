import 'package:flutter/material.dart';

class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.seedColor, this.size = 18});

  final Color seedColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.outlineVariant),
      ),
    );
  }
}
