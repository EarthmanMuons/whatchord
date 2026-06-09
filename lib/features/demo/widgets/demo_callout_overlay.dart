import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/demo_mode_notifier.dart';
import '../providers/demo_mode_variant_notifier.dart';
import '../providers/demo_sequence_notifier.dart';
import '../providers/demo_tour_targets.dart';

/// Draws a curved arrow from the tour prompt to the element the current step
/// points at. It never dims or blocks the screen: the painter is wrapped in an
/// [IgnorePointer] so the real widgets underneath stay tappable.
class DemoCalloutOverlay extends ConsumerStatefulWidget {
  const DemoCalloutOverlay({super.key});

  @override
  ConsumerState<DemoCalloutOverlay> createState() => _DemoCalloutOverlayState();
}

class _DemoCalloutOverlayState extends ConsumerState<DemoCalloutOverlay>
    with WidgetsBindingObserver {
  Rect? _startRect;
  Rect? _targetRect;
  DemoTarget? _measuredTarget;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleMeasure();

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    // Content can populate a few frames late (the prompt fades in, and a step's
    // alternatives only appear once the demo's notes finish ramping in), so
    // re-measure for a short while until the layout settles.
    _settleTimer?.cancel();
    var ticks = 0;
    _settleTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      _measure();
      if (++ticks >= 8 || !mounted) t.cancel();
    });
  }

  void _measure() {
    if (!mounted) return;

    final keys = ref.read(demoTourKeysProvider);
    final target = ref.read(demoCurrentStepProvider).target;

    final overlayBox = context.findRenderObject();
    Rect? startRect;
    Rect? targetRect;
    if (target != null && overlayBox is RenderBox) {
      startRect = _rectOf(keys.prompt, overlayBox);
      targetRect = _rectOf(keys.forTarget(target), overlayBox);
    }

    if (target == _measuredTarget &&
        _rectsClose(startRect, _startRect) &&
        _rectsClose(targetRect, _targetRect)) {
      return;
    }
    setState(() {
      _measuredTarget = target;
      _startRect = startRect;
      _targetRect = targetRect;
    });
  }

  Rect? _rectOf(GlobalKey key, RenderBox ancestor) {
    final targetContext = key.currentContext;
    final box = targetContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero, ancestor: ancestor);
    return origin & box.size;
  }

  bool _rectsClose(Rect? a, Rect? b) {
    if (a == null || b == null) return a == b;
    const epsilon = 0.5;
    return (a.left - b.left).abs() < epsilon &&
        (a.top - b.top).abs() < epsilon &&
        (a.width - b.width).abs() < epsilon &&
        (a.height - b.height).abs() < epsilon;
  }

  @override
  Widget build(BuildContext context) {
    final isInteractiveDemo =
        ref.watch(demoModeProvider) &&
        ref.watch(demoModeVariantProvider) == DemoModeVariant.interactive;
    final target = ref.watch(
      demoCurrentStepProvider.select((step) => step.target),
    );

    if (!isInteractiveDemo || target == null) {
      _settleTimer?.cancel();
      return const SizedBox.shrink();
    }

    // Schedule a measurement for this step; cheap and idempotent.
    _scheduleMeasure();

    final promptRect = _startRect;
    final targetRect = _targetRect;
    if (promptRect == null || targetRect == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // The standout red from the original coach mark.
    final arrowColor = Color.lerp(
      cs.error,
      const Color(0xFFE53935),
      isDark ? 0.82 : 0.2,
    )!.withValues(alpha: isDark ? 0.94 : 0.84);

    final geometry = _geometryFor(
      target,
      promptRect,
      targetRect,
      isLandscape: MediaQuery.orientationOf(context) == Orientation.landscape,
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CalloutArrowPainter(
            start: geometry.start,
            control: geometry.control,
            end: geometry.end,
            color: arrowColor,
            haloColor: cs.surface.withValues(alpha: isDark ? 0.5 : 0.85),
          ),
        ),
      ),
    );
  }

  /// Per-target arrow routing. The chord card routes up its right side to clear
  /// the centered alternatives; the alternatives use a short horizontal head;
  /// the tonality bar mirrors the generic curve and nudges right; the lookup
  /// button aims a touch lower so the head lands on the icon.
  ({Offset start, Offset control, Offset end}) _geometryFor(
    DemoTarget target,
    Rect prompt,
    Rect targetRect, {
    required bool isLandscape,
  }) {
    if (isLandscape) {
      return _landscapeGeometryFor(target, prompt, targetRect);
    }

    final t = targetRect;
    switch (target) {
      case DemoTarget.chordCard:
        // Keep a gap above the prompt text that mirrors the head's gap below
        // the card, so the tail does not crowd the explanation.
        final end = Offset(t.right - (t.width * 0.22), t.bottom + 12);
        final start = Offset(
          math.max(prompt.left + (prompt.width * 0.55), end.dx - 40),
          prompt.top - 12,
        );
        final control = Offset(
          math.max(start.dx, end.dx) + 30,
          (start.dy + end.dy) / 2,
        );
        return (start: start, control: control, end: end);
      case DemoTarget.alternatives:
        // Short, gentle hook with a horizontal head; swing the tail out to the
        // left rather than dropping straight down, so the head angle stays clean.
        final end = Offset(t.center.dx - (t.width * 0.18), t.top + 12);
        final control = Offset(end.dx - 36, end.dy);
        final start = Offset(end.dx - 66, end.dy + 32);
        return (start: start, control: control, end: end);
      case DemoTarget.tonalityBar:
        return _curved(prompt, t, shiftX: 30, mirror: true);
      case DemoTarget.lookupButton:
        // Aim a little past the icon edge so the head sits on the icon itself.
        return _curved(prompt, t, endInset: 2, endNudge: const Offset(0, 8));
    }
  }

  /// Landscape places the prompt in the right analysis panel, so arrows route
  /// from that panel toward their targets instead of using the portrait hooks.
  ({Offset start, Offset control, Offset end}) _landscapeGeometryFor(
    DemoTarget target,
    Rect prompt,
    Rect t,
  ) {
    switch (target) {
      case DemoTarget.chordCard:
        final geometry = _curved(prompt, t, mirror: true, bowLimit: 64);
        return (
          start: Offset.lerp(geometry.start, geometry.control, 0.14)!,
          control: geometry.control,
          end: geometry.end,
        );
      case DemoTarget.alternatives:
        // The alternatives widget fills the otherwise-empty upper-right panel.
        // Aim at the visible alternative label near its top-left instead of the
        // edge of that large layout box.
        final end = Offset(t.left + 46, t.top + 34);
        final control = Offset(end.dx + 34, end.dy + 18);
        final start = Offset(prompt.left + 72, prompt.top - 14);
        return (start: start, control: control, end: end);
      case DemoTarget.tonalityBar:
        // The scale degrees occupy the right side of the combined tonality bar.
        // Use that narrower region so the arrow does not point at the obvious
        // key-selection button on the left.
        final scaleStrip = Rect.fromLTRB(
          t.left + (t.width * 0.62),
          t.top,
          t.right - 20,
          t.bottom,
        );
        return _curved(
          prompt,
          scaleStrip,
          mirror: true,
          endInset: 2,
          endNudge: const Offset(0, -4),
          bowLimit: 32,
        );
      case DemoTarget.lookupButton:
        // Approach from below with a horizontal head toward the search icon.
        final end = Offset(t.left - 2, t.center.dy + 2);
        final control = Offset(end.dx - 40, end.dy);
        final start = Offset(
          math.min(prompt.right - 24, control.dx - 34),
          prompt.bottom + 8,
        );
        return (start: start, control: control, end: end);
    }
  }

  /// Generic curved arrow from the prompt edge to the target edge, with optional
  /// horizontal [shiftX], a [mirror]ed bow direction, and end-point tuning.
  ({Offset start, Offset control, Offset end}) _curved(
    Rect prompt,
    Rect t, {
    double shiftX = 0,
    bool mirror = false,
    double endInset = 10,
    Offset endNudge = Offset.zero,
    double bowLimit = 48,
  }) {
    final from = _edgePoint(prompt, t.center).translate(shiftX, 0);
    final to = _edgePoint(
      t,
      prompt.center,
      inset: endInset,
    ).translate(shiftX + endNudge.dx, endNudge.dy);
    final delta = to - from;
    final dist = delta.distance;
    final unit = dist < 1 ? const Offset(0, -1) : delta / dist;
    final perp = mirror ? Offset(unit.dy, -unit.dx) : Offset(-unit.dy, unit.dx);
    final bow = math.min(bowLimit, dist * 0.22);
    final control = Offset.lerp(from, to, 0.5)! + (perp * bow);
    return (start: from, control: control, end: to);
  }

  /// The point on [rect]'s edge along the ray from its center toward [toward],
  /// pulled [inset] pixels outside so the arrow sits just off the element.
  Offset _edgePoint(Rect rect, Offset toward, {double inset = 6}) {
    final center = rect.center;
    final dir = toward - center;
    if (dir.distance < 0.001) return center;
    final halfW = rect.width / 2;
    final halfH = rect.height / 2;
    final scaleX = dir.dx == 0 ? double.infinity : halfW / dir.dx.abs();
    final scaleY = dir.dy == 0 ? double.infinity : halfH / dir.dy.abs();
    final scale = math.min(scaleX, scaleY);
    final edge = center + (dir * scale);
    final unit = dir / dir.distance;
    return edge + (unit * inset);
  }
}

class _CalloutArrowPainter extends CustomPainter {
  const _CalloutArrowPainter({
    required this.start,
    required this.control,
    required this.end,
    required this.color,
    required this.haloColor,
  });

  final Offset start;
  final Offset control;
  final Offset end;
  final Color color;
  final Color haloColor;

  @override
  void paint(Canvas canvas, Size size) {
    if ((end - start).distance < 1) return;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = haloColor;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawPath(path, halo);
    canvas.drawPath(path, stroke);
    _drawArrowHead(canvas, end, end - control, color, haloColor);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset direction,
    Color color,
    Color haloColor,
  ) {
    final mag = direction.distance;
    if (mag < 0.001) return;
    final unit = direction / mag;
    const headLength = 14.0;
    const headAngle = 0.5;
    final back = -unit;
    final left = _rotate(back, headAngle);
    final right = _rotate(back, -headAngle);
    final p1 = tip + (left * headLength);
    final p2 = tip + (right * headLength);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = haloColor;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final paint in [halo, stroke]) {
      canvas.drawLine(tip, p1, paint);
      canvas.drawLine(tip, p2, paint);
    }
  }

  Offset _rotate(Offset v, double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset((v.dx * c) - (v.dy * s), (v.dx * s) + (v.dy * c));
  }

  @override
  bool shouldRepaint(covariant _CalloutArrowPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.control != control ||
        oldDelegate.end != end ||
        oldDelegate.color != color ||
        oldDelegate.haloColor != haloColor;
  }
}
