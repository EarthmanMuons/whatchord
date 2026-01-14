import 'package:flutter/material.dart';

import '../domain/theory_domain.dart';

class ScaleDegrees extends StatelessWidget {
  final ScaleDegree? current;
  final values = ScaleDegree.values;

  const ScaleDegrees({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            _ScaleDegreeIndicator(
              label: values[i].romanNumeral,
              isCurrent: values[i] == current,
            ),
            if (i < values.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _ScaleDegreeIndicator extends StatelessWidget {
  final String label;
  final bool isCurrent;

  const _ScaleDegreeIndicator({required this.label, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseStyle = theme.textTheme.labelLarge;
    final textStyle = baseStyle?.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) + 2,
      color: isCurrent
          ? cs.primary
          : cs.onSurfaceVariant.withValues(alpha: 0.65),
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
    );

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(label, style: textStyle),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 3,
                width: 18,
                decoration: BoxDecoration(
                  color: isCurrent ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
