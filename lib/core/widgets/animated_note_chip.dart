import 'dart:math' as math;

import 'package:flutter/material.dart';

enum NoteChipHighlight { none, outline, fill }

/// A note/degree chip that flips between [label] and [alternateLabel] when its
/// primary label changes and animates its width to fit, with three highlight
/// states. Shared by the Explore Chords and Explore Scales tone strips.
class AnimatedNoteChip extends StatelessWidget {
  const AnimatedNoteChip({
    super.key,
    required this.label,
    required this.alternateLabel,
    required this.semanticLabel,
    required this.highlight,
    this.sizeScale = 1.0,
    this.verticalScale = 1.0,
  });

  static const Duration _resizeDuration = Duration(milliseconds: 90);

  final String label;
  final String alternateLabel;
  final String semanticLabel;
  final NoteChipHighlight highlight;
  final double sizeScale;
  final double verticalScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fill = highlight == NoteChipHighlight.fill;
    final outline = highlight == NoteChipHighlight.outline;

    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: fill ? cs.onPrimaryContainer : cs.onSurface,
      fontWeight: fill ? FontWeight.w700 : null,
    );
    final fontSize = labelStyle?.fontSize ?? 16.0;
    final defaultHeight = labelStyle?.height ?? 1.2;
    final extraVertical = ((defaultHeight - 1.0) * fontSize / 2).clamp(
      0.0,
      8.0,
    );
    final labelStrut = StrutStyle(
      fontSize: fontSize,
      height: 1.0,
      forceStrutHeight: true,
    );
    final horizontalPadding = 10 * sizeScale;
    final chipTextWidth = math.max(
      _measureLabelWidth(context, label, labelStyle),
      _measureLabelWidth(context, alternateLabel, labelStyle),
    );

    final borderColor = fill
        ? cs.primary.withValues(alpha: 0.82)
        : outline
        ? cs.primary
        : cs.outlineVariant.withValues(alpha: 0.60);
    final borderWidth = fill
        ? 1.6
        : outline
        ? 1.5
        : 1.0;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AnimatedSize(
          duration: _resizeDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return _CurrentSizeSwitcherLayout(
                currentChild: currentChild,
                previousChildren: previousChildren,
              );
            },
            transitionBuilder: (child, animation) {
              return _ChipFlipTransition(
                animation: animation,
                incoming: child.key == ValueKey(label),
                child: child,
              );
            },
            child: AnimatedContainer(
              key: ValueKey(label),
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: fill ? cs.primaryContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10 * sizeScale),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: (6 * verticalScale) + extraVertical,
              ),
              child: SizedBox(
                width: chipTextWidth,
                child: Text(
                  label,
                  strutStyle: labelStrut,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _measureLabelWidth(
    BuildContext context,
    String text,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }
}

class _ChipFlipTransition extends StatelessWidget {
  const _ChipFlipTransition({
    required this.animation,
    required this.incoming,
    required this.child,
  });

  final Animation<double> animation;
  final bool incoming;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        final angle = (incoming ? 1 - value : value - 1) * (math.pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle),
          child: child,
        );
      },
    );
  }
}

class _CurrentSizeSwitcherLayout extends StatelessWidget {
  const _CurrentSizeSwitcherLayout({
    required this.currentChild,
    required this.previousChildren,
  });

  final Widget? currentChild;
  final List<Widget> previousChildren;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      children: [
        for (final child in previousChildren)
          Positioned.fill(
            child: Align(alignment: Alignment.center, child: child),
          ),
        ?currentChild,
      ],
    );
  }
}
