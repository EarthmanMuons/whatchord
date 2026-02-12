import 'package:flutter/material.dart';

import '../../domain/theory_domain.dart';

class ScaleDegrees extends StatefulWidget {
  final ScaleDegree? current;
  final values = ScaleDegree.values;
  final double? maxHeight;
  final Color? fadeColor;

  const ScaleDegrees({
    super.key,
    required this.current,
    this.maxHeight,
    this.fadeColor,
  });

  @override
  State<ScaleDegrees> createState() => _ScaleDegreesState();
}

class _ScaleDegreesState extends State<ScaleDegrees> {
  static const double _fadeWidth = 24.0;
  static const double _defaultIndicatorHeight = 56.0;

  final ScrollController _scrollController = ScrollController();
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void didUpdateWidget(covariant ScaleDegrees oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFades);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    const epsilon = 0.5;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;

    final nextLeft = maxExtent > epsilon && pixels > epsilon;
    final nextRight = maxExtent > epsilon && pixels < maxExtent - epsilon;

    if (nextLeft == _showLeftFade && nextRight == _showRightFade) return;

    setState(() {
      _showLeftFade = nextLeft;
      _showRightFade = nextRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor =
        widget.fadeColor ?? Theme.of(context).colorScheme.surfaceContainerLow;
    final maxHeight = widget.maxHeight ?? _defaultIndicatorHeight;

    return Semantics(
      container: true,
      label: 'Scale degree',
      value: _semanticsValueForCurrent(widget.current),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());

            final scrollable = SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < widget.values.length; i++) ...[
                    _ScaleDegreeIndicator(
                      label: widget.values[i].romanNumeral,
                      isCurrent: widget.values[i] == widget.current,
                      maxHeight: maxHeight,
                    ),
                    if (i < widget.values.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            );

            return Stack(
              children: [
                scrollable,
                if (_showLeftFade)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _fadeWidth,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_showRightFade)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: _fadeWidth,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _semanticsValueForCurrent(ScaleDegree? degree) {
    if (degree == null) return 'No diatonic match';
    return switch (degree) {
      ScaleDegree.one => 'I, one',
      ScaleDegree.two => 'ii, two',
      ScaleDegree.three => 'iii, three',
      ScaleDegree.four => 'IV, four',
      ScaleDegree.five => 'V, five',
      ScaleDegree.six => 'vi, six',
      ScaleDegree.seven => 'vii diminished, seven',
    };
  }
}

class _ScaleDegreeIndicator extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final double maxHeight;

  const _ScaleDegreeIndicator({
    required this.label,
    required this.isCurrent,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseStyle = theme.textTheme.labelLarge;
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final underlinePadding = maxHeight <= 48
        ? 4.0
        : scale > 1.4
        ? 6.0
        : 8.0;
    const underlineHeight = 3.0;

    final baseFontSize = (baseStyle?.fontSize ?? 14) + 2;
    final baseLineHeight = baseFontSize * (baseStyle?.height ?? 1.2);
    final availableHeight = maxHeight - underlinePadding - underlineHeight;
    final maxScale = (availableHeight / baseLineHeight).clamp(1.0, 3.0);
    final clampedScale = scale.clamp(1.0, maxScale);

    final textStyle = baseStyle?.copyWith(
      fontSize: baseFontSize,
      color: isCurrent
          ? cs.primary
          : cs.onSurfaceVariant.withValues(alpha: 0.65),
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
    );

    return SizedBox(
      height: maxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            label,
            style: textStyle,
            textScaler: TextScaler.linear(clampedScale),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: underlinePadding),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: underlineHeight,
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
