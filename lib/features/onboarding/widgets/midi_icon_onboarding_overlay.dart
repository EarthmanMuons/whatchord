import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_icon_onboarding_notifier.dart';

class MidiIconOnboardingOverlay extends ConsumerStatefulWidget {
  const MidiIconOnboardingOverlay({
    super.key,
    required this.targetKey,
    required this.onTargetTap,
  });

  final GlobalKey targetKey;
  final VoidCallback onTargetTap;

  @override
  ConsumerState<MidiIconOnboardingOverlay> createState() =>
      _MidiIconOnboardingOverlayState();
}

class _MidiIconOnboardingOverlayState
    extends ConsumerState<MidiIconOnboardingOverlay>
    with WidgetsBindingObserver {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleTargetMeasurement();
  }

  @override
  void didChangeMetrics() {
    _scheduleTargetMeasurement();
  }

  @override
  void didUpdateWidget(covariant MidiIconOnboardingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey) {
      _scheduleTargetMeasurement();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleTargetMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _resolveTargetRect();
      if (next == null) {
        if (_targetRect != null) {
          setState(() => _targetRect = null);
        }
        return;
      }
      if (_targetRect == null || !_approximatelyEqual(_targetRect!, next)) {
        setState(() => _targetRect = next);
      }
    });
  }

  Rect? _resolveTargetRect() {
    final targetContext = widget.targetKey.currentContext;
    final overlayContext = context;
    if (targetContext == null) return null;

    final targetBox = targetContext.findRenderObject();
    final overlayBox = overlayContext.findRenderObject();
    if (targetBox is! RenderBox || overlayBox is! RenderBox) return null;

    final origin = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return origin & targetBox.size;
  }

  bool _approximatelyEqual(Rect a, Rect b) {
    const epsilon = 0.5;
    return (a.left - b.left).abs() < epsilon &&
        (a.top - b.top).abs() < epsilon &&
        (a.width - b.width).abs() < epsilon &&
        (a.height - b.height).abs() < epsilon;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(midiSettingsOnboardingProvider);
    if (!state.shouldShowCoachMark) return const SizedBox.shrink();

    final rect = _targetRect;
    if (rect == null) {
      _scheduleTargetMeasurement();
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: ref
              .read(midiSettingsOnboardingProvider.notifier)
              .markCoachMarkSeen,
          child: const ColoredBox(color: Color(0xA6000000)),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final safeTop = mq.padding.top;
    const horizontalPadding = 12.0;
    final maxBubbleWidth = mq.size.width - (horizontalPadding * 2);
    final bubbleWidth = math.min(320.0, maxBubbleWidth);
    final bubbleLeft = (rect.right - bubbleWidth).clamp(
      horizontalPadding,
      mq.size.width - horizontalPadding - bubbleWidth,
    );
    final bubbleTop = math.max(safeTop + 10, rect.bottom + 30);
    final bubbleRect = Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, 112);

    const spotlightPadding = 14.0;
    final spotlightRect = rect.inflate(spotlightPadding);

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: ref
                .read(midiSettingsOnboardingProvider.notifier)
                .markCoachMarkSeen,
            child: CustomPaint(
              painter: _SpotlightPainter(
                spotlightRect: spotlightRect,
                dimColor: const Color(0xA6000000),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: bubbleRect.left,
            top: bubbleRect.top,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: bubbleRect.width),
              child: Semantics(
                container: true,
                label: 'Connect your MIDI device',
                child: Material(
                  elevation: 8,
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect your MIDI device',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap here to select a Bluetooth or USB controller.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CurvedArrowPainter(
                  color: cs.error.withValues(alpha: 0.84),
                  start: Offset(bubbleRect.right - 44, bubbleRect.top + 24),
                  control: Offset(rect.center.dx + 26, bubbleRect.top - 18),
                  end: Offset(rect.center.dx + 5, rect.center.dy + 16),
                  terminalRightBiasRadians: 0.28,
                  terminalStraightLength: 11,
                  headRightBiasRadians: -0.16,
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: rect.inflate(6),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTargetTap,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.spotlightRect,
    required this.dimColor,
  });

  final Rect spotlightRect;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = dimColor);

    final featherSigma = spotlightRect.shortestSide * 0.11;
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect, const Radius.circular(999)),
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.black
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, featherSigma),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.dimColor != dimColor;
  }
}

class _CurvedArrowPainter extends CustomPainter {
  const _CurvedArrowPainter({
    required this.color,
    required this.start,
    required this.control,
    required this.end,
    this.terminalRightBiasRadians = 0,
    this.terminalStraightLength = 0,
    this.headRightBiasRadians = 0,
  });

  final Color color;
  final Offset start;
  final Offset control;
  final Offset end;
  final double terminalRightBiasRadians;
  final double terminalStraightLength;
  final double headRightBiasRadians;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rawDirection = end - control;
    final rawMagnitude = rawDirection.distance;
    if (rawMagnitude <= 0.001) return;
    final rawUnit = rawDirection / rawMagnitude;
    final terminalUnit = _rotate(rawUnit, terminalRightBiasRadians);
    final c1 = Offset(
      start.dx + ((control.dx - start.dx) * 0.78),
      start.dy + ((control.dy - start.dy) * 0.78),
    );
    final c2 = end - (terminalUnit * terminalStraightLength);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    canvas.drawPath(path, stroke);

    final reverse = _rotate(-terminalUnit, -headRightBiasRadians);
    const headLength = 11.0;
    const headAngle = 0.5;
    final leftDir = _rotate(reverse, headAngle);
    final rightDir = _rotate(reverse, -headAngle);
    final p1 = end + (leftDir * headLength);
    final p2 = end + (rightDir * headLength);

    canvas.drawLine(end, p1, stroke);
    canvas.drawLine(end, p2, stroke);
  }

  Offset _rotate(Offset v, double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset((v.dx * c) - (v.dy * s), (v.dx * s) + (v.dy * c));
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.start != start ||
        oldDelegate.control != control ||
        oldDelegate.end != end ||
        oldDelegate.terminalRightBiasRadians != terminalRightBiasRadians ||
        oldDelegate.terminalStraightLength != terminalStraightLength ||
        oldDelegate.headRightBiasRadians != headRightBiasRadians;
  }
}
