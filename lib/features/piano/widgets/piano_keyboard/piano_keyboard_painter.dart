import 'package:flutter/material.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';

@immutable
class PianoTopEdgeShadowStyle {
  const PianoTopEdgeShadowStyle({
    this.enabled = true,
    this.height = 14.0,
    this.sharedOpacity = 0.14,
    this.whiteKeyExtraOpacity = 0.0,
    this.blackKeyExtraOpacity = 0.06,
    this.color = Colors.black,
  });

  final bool enabled;
  final double height;

  /// Shared band drawn across the full keyboard width for consistent anchoring.
  final double sharedOpacity;

  /// Optional extra depth on white key surfaces only.
  final double whiteKeyExtraOpacity;

  /// Optional extra depth on black key surfaces only.
  final double blackKeyExtraOpacity;

  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PianoTopEdgeShadowStyle &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          height == other.height &&
          sharedOpacity == other.sharedOpacity &&
          whiteKeyExtraOpacity == other.whiteKeyExtraOpacity &&
          blackKeyExtraOpacity == other.blackKeyExtraOpacity &&
          color == other.color;

  @override
  int get hashCode => Object.hash(
    enabled,
    height,
    sharedOpacity,
    whiteKeyExtraOpacity,
    blackKeyExtraOpacity,
    color,
  );
}

class PianoKeyboardPainter extends CustomPainter {
  static const double _pressedBlackBaseLift = 0.08;

  static const double _pressedWhiteDarkenAlpha = 0.050;
  static const double _pressedBlackDarkenAlpha = 0.030;

  static const double _pressedWhiteLeftEdgeAlpha = 0.030;
  static const double _pressedWhiteRightEdgeAlpha = 0.040;
  static const double _pressedBlackLeftEdgeAlpha = 0.050;
  static const double _pressedBlackRightEdgeAlpha = 0.065;

  static const double _whiteTopGradientBlend = 0.84;
  static const double _whiteTopGradientAlpha = 0.76;
  static const double _whiteTopGradientCoverage = 0.42;
  static const double _whiteTopGradientPlateau = 0.24;

  static const double _blackTopGradientLightenFromWhiteTop = 0.14;
  static const double _blackTopGradientSaturationBoost = 0.12;
  static const double _blackTopGradientCoverage = 0.74;
  static const double _blackTopGradientPlateau = 0.22;

  static const double _whiteTopAccentWhiteMix = 0.28;
  static const double _whiteTopAccentOpacity = 0.99;
  static const double _blackTopAccentWhiteMix = 0.12;
  static const double _blackTopAccentOpacity = 0.98;

  PianoKeyboardPainter({
    required this.whiteKeyCount,
    required this.firstMidiNote,
    required this.highlightedNoteNumbers,
    required this.whiteKeyColor,
    required this.pressedKeyHighlightColor,
    required this.whiteKeyBorderColor,
    required this.blackKeyColor,
    required this.backgroundColor,
    this.decorations = const <PianoKeyDecoration>[],
    this.decorationColor,
    this.decorationTextScaleMultiplier = 1.0,
    this.drawBackground = true,
    this.drawFeltStrip = true,
    this.feltColor = const Color(0xFF800020),
    this.feltHeight = 2.0,
    this.topEdgeShadowStyle = const PianoTopEdgeShadowStyle(),
  }) : assert(
         decorationColor != null ||
             !decorations.any((d) => d.style == PianoKeyDecorationStyle.label),
         'decorationTextColor must be provided when label decorations are present',
       ),
       _geometry = PianoGeometry(
         firstWhiteMidi: firstMidiNote,
         whiteKeyCount: whiteKeyCount,
       );

  final int whiteKeyCount;
  final int firstMidiNote;

  /// Highlighted *MIDI note numbers* (e.g., 60 for middle C).
  final Set<int> highlightedNoteNumbers;

  final Color whiteKeyColor;
  final Color pressedKeyHighlightColor;
  final Color whiteKeyBorderColor;
  final Color blackKeyColor;
  final Color backgroundColor;

  /// Key decorations (e.g., middle C marker, scale markers).
  final List<PianoKeyDecoration> decorations;
  final Color? decorationColor;
  final double decorationTextScaleMultiplier;

  final bool drawBackground;

  final bool drawFeltStrip;
  final Color feltColor;
  final double feltHeight;
  final PianoTopEdgeShadowStyle topEdgeShadowStyle;

  final PianoGeometry _geometry;

  int _whiteMidiForIndex(int whiteIndex) =>
      _geometry.whiteMidiForIndex(whiteIndex);

  bool _isHighlighted(int midi) => highlightedNoteNumbers.contains(midi);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (whiteKeyCount <= 0 || width <= 0 || height <= 0) return;

    if (drawBackground) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    final whiteKeyWidth = width / whiteKeyCount;
    final whiteKeyHeight = height;
    final blackKeyWidth = whiteKeyWidth * PianoGeometry.blackKeyWidthRatio;
    final blackKeyHeight = whiteKeyHeight * PianoGeometry.blackKeyHeightRatio;
    final topInset = (drawFeltStrip ? feltHeight : 0.0).clamp(0.0, height);

    final whiteVisibleTop = topInset;
    final whiteVisibleHeight = (whiteKeyHeight - whiteVisibleTop).clamp(
      0.0,
      whiteKeyHeight,
    );
    final blackVisibleTop = topInset.clamp(0.0, blackKeyHeight);
    final blackVisibleHeight = (blackKeyHeight - blackVisibleTop).clamp(
      0.0,
      blackKeyHeight,
    );

    final whiteFillPaint = Paint()..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = whiteKeyBorderColor;
    final blackFillPaint = Paint()..style = PaintingStyle.fill;
    final pressedBlackBaseColor = Color.lerp(
      blackKeyColor,
      Colors.white,
      _pressedBlackBaseLift,
    )!;

    final pressedWhiteDarkenPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedWhiteDarkenAlpha);
    final pressedBlackDarkenPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedBlackDarkenAlpha);

    final pressedWhiteLeftEdgePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedWhiteLeftEdgeAlpha);
    final pressedWhiteRightEdgePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedWhiteRightEdgeAlpha);
    final pressedBlackLeftEdgePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedBlackLeftEdgeAlpha);
    final pressedBlackRightEdgePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: _pressedBlackRightEdgeAlpha);
    final whitePressedTopGradientColor = Color.lerp(
      whiteKeyColor,
      pressedKeyHighlightColor,
      _whiteTopGradientBlend,
    )!.withValues(alpha: _whiteTopGradientAlpha);
    final blackPressedTopGradientBaseColor = Color.lerp(
      whitePressedTopGradientColor,
      Colors.white,
      _blackTopGradientLightenFromWhiteTop,
    )!.withValues(alpha: 0.88);
    final blackPressedTopGradientColor = _boostSaturation(
      blackPressedTopGradientBaseColor,
      amount: _blackTopGradientSaturationBoost,
    );
    final pressedWhiteAccentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _pressedTopAccentFromGradientTopColor(
        whitePressedTopGradientColor,
        whiteMix: _whiteTopAccentWhiteMix,
        opacity: _whiteTopAccentOpacity,
      );
    final pressedBlackAccentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _pressedTopAccentFromGradientTopColor(
        blackPressedTopGradientColor,
        whiteMix: _blackTopAccentWhiteMix,
        opacity: _blackTopAccentOpacity,
      );

    final whitePressedTopGradientPaint = _buildPressedTopGradientPaint(
      keyWidth: whiteKeyWidth,
      visibleTop: whiteVisibleTop,
      visibleHeight: whiteVisibleHeight,
      baseKeyColor: whiteKeyColor,
      topOpacity: _whiteTopGradientAlpha,
      blendFactor: _whiteTopGradientBlend,
      coverageFraction: _whiteTopGradientCoverage,
      plateauFraction: _whiteTopGradientPlateau,
      topColorOverride: whitePressedTopGradientColor,
    );
    final blackPressedTopGradientPaint = _buildPressedTopGradientPaint(
      keyWidth: blackKeyWidth,
      visibleTop: blackVisibleTop,
      visibleHeight: blackVisibleHeight,
      baseKeyColor: blackKeyColor,
      topOpacity: 0.96,
      blendFactor: 0.94,
      coverageFraction: _blackTopGradientCoverage,
      plateauFraction: _blackTopGradientPlateau,
      topColorOverride: blackPressedTopGradientColor,
    );

    // White keys
    for (int i = 0; i < whiteKeyCount; i++) {
      final x = i * whiteKeyWidth;
      final rect = Rect.fromLTWH(x, 0, whiteKeyWidth, whiteKeyHeight);

      final midi = _whiteMidiForIndex(i);
      final isHighlighted = _isHighlighted(midi);

      whiteFillPaint.color = whiteKeyColor;

      canvas.drawRect(rect, whiteFillPaint);
      if (isHighlighted) {
        _paintPressedKeySurface(
          canvas,
          rect,
          topInset: topInset,
          darkenPaint: pressedWhiteDarkenPaint,
          topGradientPaint: whitePressedTopGradientPaint,
          topGradientCoverageFraction: _whiteTopGradientCoverage,
          topAccentPaint: pressedWhiteAccentPaint,
          leftEdgeShadowPaint: pressedWhiteLeftEdgePaint,
          rightEdgeShadowPaint: pressedWhiteRightEdgePaint,
        );
      }
      canvas.drawRect(rect, whiteBorderPaint);
      if (isHighlighted && topInset < rect.bottom) {
        // Redraw after the border stroke so the pressed accent stays visible.
        canvas.drawRect(
          Rect.fromLTWH(rect.left, topInset, rect.width, 1.0),
          pressedWhiteAccentPaint,
        );
      }
    }

    // Black keys
    final blackKeyRects = <Rect>[];

    for (int i = 0; i < whiteKeyCount - 1; i++) {
      final whitePc = _geometry.whitePitchClassForIndex(i);
      if (!PianoGeometry.hasBlackAfterWhitePc(whitePc)) continue;

      final whiteMidi = _whiteMidiForIndex(i);
      final blackMidi = whiteMidi + 1;
      final blackPc = blackMidi % 12;

      final boundaryX = (i + 1) * whiteKeyWidth;
      final centerX =
          boundaryX +
          PianoGeometry.blackCenterBiasForPc(blackPc, whiteKeyWidth);

      double blackLeft = centerX - (blackKeyWidth / 2.0);
      blackLeft = blackLeft.clamp(0.0, width - blackKeyWidth);

      final rect = Rect.fromLTWH(blackLeft, 0, blackKeyWidth, blackKeyHeight);
      blackKeyRects.add(rect);

      final isHighlightedBlack = _isHighlighted(blackMidi);
      blackFillPaint.color = isHighlightedBlack
          ? pressedBlackBaseColor
          : blackKeyColor;
      canvas.drawRect(rect, blackFillPaint);
      if (isHighlightedBlack) {
        _paintPressedKeySurface(
          canvas,
          rect,
          topInset: topInset,
          darkenPaint: pressedBlackDarkenPaint,
          topGradientPaint: blackPressedTopGradientPaint,
          topGradientCoverageFraction: _blackTopGradientCoverage,
          topAccentPaint: pressedBlackAccentPaint,
          leftEdgeShadowPaint: pressedBlackLeftEdgePaint,
          rightEdgeShadowPaint: pressedBlackRightEdgePaint,
        );
      }
    }

    _paintTopEdgeShadow(canvas, size, blackKeyRects: blackKeyRects);

    // Felt strip LAST so it stays visible.
    if (drawFeltStrip && feltHeight > 0) {
      final feltPaint = Paint()..color = feltColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, feltHeight), feltPaint);
    }

    if (decorations.isNotEmpty) {
      _paintDecorations(
        canvas,
        size,
        whiteKeyWidth: whiteKeyWidth,
        blackKeyHeight: blackKeyHeight,
      );
    }
  }

  void _paintTopEdgeShadow(
    Canvas canvas,
    Size size, {
    required List<Rect> blackKeyRects,
  }) {
    if (!topEdgeShadowStyle.enabled) return;

    final topInset = (drawFeltStrip ? feltHeight : 0.0).clamp(0.0, size.height);
    final maxHeight = (size.height - topInset).clamp(0.0, size.height);
    if (maxHeight <= 0) return;

    final shadowHeight = topEdgeShadowStyle.height.clamp(0.0, maxHeight);
    if (shadowHeight <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final baseColor = topEdgeShadowStyle.color;

    Shader shaderForOpacity(Rect rect, double opacity) {
      final alpha = opacity.clamp(0.0, 1.0);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          baseColor.withValues(alpha: alpha),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    }

    void drawGradientRect(Rect rect, double opacity) {
      if (opacity <= 0) return;
      paint.shader = shaderForOpacity(rect, opacity);
      canvas.drawRect(rect, paint);
      paint.shader = null;
    }

    final sharedRect = Rect.fromLTWH(0, topInset, size.width, shadowHeight);
    drawGradientRect(sharedRect, topEdgeShadowStyle.sharedOpacity);

    if (topEdgeShadowStyle.whiteKeyExtraOpacity > 0) {
      final whiteRect = Rect.fromLTWH(0, topInset, size.width, shadowHeight);
      final blackOverlapPath = Path();
      for (final rect in blackKeyRects) {
        final overlap = Rect.fromLTRB(
          rect.left.clamp(whiteRect.left, whiteRect.right),
          rect.top.clamp(whiteRect.top, whiteRect.bottom),
          rect.right.clamp(whiteRect.left, whiteRect.right),
          rect.bottom.clamp(whiteRect.top, whiteRect.bottom),
        );
        if (!overlap.isEmpty) {
          blackOverlapPath.addRect(overlap);
        }
      }

      canvas.save();
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(whiteRect),
          blackOverlapPath,
        ),
      );
      drawGradientRect(whiteRect, topEdgeShadowStyle.whiteKeyExtraOpacity);
      canvas.restore();
    }

    if (topEdgeShadowStyle.blackKeyExtraOpacity > 0) {
      for (final rect in blackKeyRects) {
        final clippedTop = rect.top < topInset ? topInset : rect.top;
        final clippedHeight = (rect.bottom - clippedTop).clamp(
          0.0,
          shadowHeight,
        );
        if (clippedHeight <= 0) continue;
        drawGradientRect(
          Rect.fromLTWH(rect.left, clippedTop, rect.width, clippedHeight),
          topEdgeShadowStyle.blackKeyExtraOpacity,
        );
      }
    }
  }

  Paint? _buildPressedTopGradientPaint({
    required double keyWidth,
    required double visibleTop,
    required double visibleHeight,
    required Color baseKeyColor,
    required double topOpacity,
    required double blendFactor,
    required double coverageFraction,
    required double plateauFraction,
    Color? topColorOverride,
  }) {
    if (keyWidth <= 0 || visibleHeight <= 0) return null;

    final gradientHeight = (visibleHeight * coverageFraction).clamp(
      0.0,
      visibleHeight,
    );
    if (gradientHeight <= 0) return null;

    final topColor =
        topColorOverride ??
        Color.lerp(
          baseKeyColor,
          pressedKeyHighlightColor,
          blendFactor.clamp(0.0, 1.0),
        )!.withValues(alpha: topOpacity.clamp(0.0, 1.0));

    final shaderRect = Rect.fromLTWH(0, visibleTop, keyWidth, gradientHeight);
    final plateauStop = plateauFraction.clamp(0.0, 0.95);
    return Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[topColor, topColor, topColor.withValues(alpha: 0.0)],
        stops: <double>[0.0, plateauStop, 1.0],
      ).createShader(shaderRect);
  }

  Color _boostSaturation(Color color, {required double amount}) {
    final base = color.withValues(alpha: 1.0);
    final hsl = HSLColor.fromColor(base);
    final boosted = hsl.withSaturation(
      (hsl.saturation + amount).clamp(0.0, 1.0),
    );
    return boosted.toColor().withValues(alpha: color.a);
  }

  Color _pressedTopAccentFromGradientTopColor(
    Color gradientTopColor, {
    required double whiteMix,
    required double opacity,
  }) {
    final accent = Color.lerp(
      gradientTopColor.withValues(alpha: 1.0),
      Colors.white,
      whiteMix.clamp(0.0, 1.0),
    )!;
    return accent.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  void _paintPressedKeySurface(
    Canvas canvas,
    Rect rect, {
    required double topInset,
    required Paint darkenPaint,
    required Paint? topGradientPaint,
    required double topGradientCoverageFraction,
    required Paint topAccentPaint,
    required Paint leftEdgeShadowPaint,
    required Paint rightEdgeShadowPaint,
  }) {
    if (rect.isEmpty) return;

    final visibleTop = rect.top < topInset ? topInset : rect.top;
    final visibleHeight = rect.bottom - visibleTop;
    if (visibleHeight <= 0) return;

    canvas.drawRect(rect, darkenPaint);

    if (topGradientPaint != null) {
      final gradientHeight = (visibleHeight * topGradientCoverageFraction)
          .clamp(0.0, visibleHeight);
      if (gradientHeight > 0) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left, visibleTop, rect.width, gradientHeight),
          topGradientPaint,
        );
      }
    }

    final accentHeight = visibleHeight >= 1.0 ? 1.0 : visibleHeight;
    if (accentHeight > 0) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, visibleTop, rect.width, accentHeight),
        topAccentPaint,
      );
    }

    if (rect.width >= 4.0) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 1.0, visibleTop, 1.0, visibleHeight),
        leftEdgeShadowPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.right - 2.0, visibleTop, 1.0, visibleHeight),
        rightEdgeShadowPaint,
      );
    }
  }

  void _paintDecorations(
    Canvas canvas,
    Size size, {
    required double whiteKeyWidth,
    required double blackKeyHeight,
  }) {
    final totalWidth = size.width;
    final topCapPaint = Paint()..style = PaintingStyle.fill;
    final topCapStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final topInset = (drawFeltStrip ? feltHeight : 0.0).clamp(0.0, size.height);
    final blackKeyWidth = whiteKeyWidth * PianoGeometry.blackKeyWidthRatio;
    final minRenderableMidi = _geometry.whiteMidis.first;
    final maxRenderableMidi = _geometry.whiteMidis.last;
    final baseTopCapRadius = (blackKeyWidth * 0.35).clamp(3.0, 10.0).toDouble();

    for (final d in decorations) {
      if (d.style != PianoKeyDecorationStyle.topCap) continue;

      final keyRect = _geometry.keyRectForMidi(
        midi: d.midiNote,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: totalWidth,
      );
      final isBlackKey = PianoGeometry.isBlackMidi(d.midiNote);

      final lane = isBlackKey
          ? (left: keyRect.left, right: keyRect.right)
          : _whiteTopLaneBounds(
              midi: d.midiNote,
              keyRect: keyRect,
              whiteKeyWidth: whiteKeyWidth,
              totalWidth: totalWidth,
              minRenderableMidi: minRenderableMidi,
              maxRenderableMidi: maxRenderableMidi,
            );
      if (lane.right <= lane.left) continue;

      final cx = (lane.left + lane.right) / 2.0;
      final cy = topInset;
      final keyBottom = isBlackKey ? blackKeyHeight : size.height;
      final topCapRadius = isBlackKey
          ? baseTopCapRadius
          : (baseTopCapRadius * 1.05).clamp(3.0, 10.5).toDouble();
      if ((cy + topCapRadius) >= keyBottom) continue;

      topCapPaint.color = _resolvedTopCapColor(isBlackKey: isBlackKey);
      topCapStrokePaint.color = _resolvedTopCapStrokeColor(
        isBlackKey: isBlackKey,
      );

      final clipRect = Rect.fromLTRB(
        lane.left,
        topInset,
        lane.right,
        keyBottom,
      );
      canvas.save();
      canvas.clipRect(clipRect);
      canvas.drawCircle(Offset(cx, cy), topCapRadius, topCapPaint);
      canvas.drawCircle(Offset(cx, cy), topCapRadius, topCapStrokePaint);
      canvas.restore();
    }

    final color = decorationColor;
    if (color == null) return;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Place near the bottom of the white key, but leave a small margin.
    final baseBottomPad = (whiteKeyWidth * 0.18).clamp(4.0, 8.0);

    for (final d in decorations) {
      if (d.style != PianoKeyDecorationStyle.label) continue;
      final label = d.label;
      if (label == null || label.isEmpty) continue;

      final whiteIndex = _geometry.whiteIndexForMidi(d.midiNote);
      if (whiteIndex < 0 || whiteIndex >= whiteKeyCount) continue;
      final fontSize = (whiteKeyWidth * 0.52 * decorationTextScaleMultiplier)
          .clamp(9.0, 16.0)
          .toDouble();

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout(minWidth: whiteKeyWidth, maxWidth: whiteKeyWidth);

      final dx = whiteIndex * whiteKeyWidth;

      final bottomPad = baseBottomPad + d.bottomLift;
      final dy = size.height - textPainter.height - bottomPad;

      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  Color _resolvedTopCapColor({required bool isBlackKey}) {
    return whiteKeyColor.withValues(alpha: isBlackKey ? 0.92 : 0.82);
  }

  Color _resolvedTopCapStrokeColor({required bool isBlackKey}) {
    return (isBlackKey ? const Color(0xFFE0E0E0) : const Color(0xFF4A4A4A))
        .withValues(alpha: isBlackKey ? 0.40 : 0.60);
  }

  ({double left, double right}) _whiteTopLaneBounds({
    required int midi,
    required PianoKeyRect keyRect,
    required double whiteKeyWidth,
    required double totalWidth,
    required int minRenderableMidi,
    required int maxRenderableMidi,
  }) {
    double left = keyRect.left;
    double right = keyRect.right;

    final leftBlackMidi = midi - 1;
    if (leftBlackMidi >= minRenderableMidi &&
        leftBlackMidi <= maxRenderableMidi &&
        PianoGeometry.isBlackMidi(leftBlackMidi)) {
      final leftBlackRect = _geometry.keyRectForMidi(
        midi: leftBlackMidi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: totalWidth,
      );
      left = leftBlackRect.right.clamp(keyRect.left, keyRect.right);
    }

    final rightBlackMidi = midi + 1;
    if (rightBlackMidi >= minRenderableMidi &&
        rightBlackMidi <= maxRenderableMidi &&
        PianoGeometry.isBlackMidi(rightBlackMidi)) {
      final rightBlackRect = _geometry.keyRectForMidi(
        midi: rightBlackMidi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: totalWidth,
      );
      right = rightBlackRect.left.clamp(keyRect.left, keyRect.right);
    }

    if (right <= left) return (left: keyRect.left, right: keyRect.right);
    return (left: left, right: right);
  }

  @override
  bool shouldRepaint(covariant PianoKeyboardPainter oldDelegate) {
    return oldDelegate.whiteKeyCount != whiteKeyCount ||
        oldDelegate.firstMidiNote != firstMidiNote ||
        oldDelegate.drawBackground != drawBackground ||
        oldDelegate.drawFeltStrip != drawFeltStrip ||
        oldDelegate.feltColor != feltColor ||
        oldDelegate.feltHeight != feltHeight ||
        oldDelegate.topEdgeShadowStyle != topEdgeShadowStyle ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.whiteKeyColor != whiteKeyColor ||
        oldDelegate.pressedKeyHighlightColor != pressedKeyHighlightColor ||
        oldDelegate.whiteKeyBorderColor != whiteKeyBorderColor ||
        oldDelegate.blackKeyColor != blackKeyColor ||
        oldDelegate.decorationColor != decorationColor ||
        oldDelegate.decorationTextScaleMultiplier !=
            decorationTextScaleMultiplier ||
        !_listEquals(oldDelegate.decorations, decorations) ||
        !_setEquals(oldDelegate.highlightedNoteNumbers, highlightedNoteNumbers);
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  bool _listEquals(List<Object> a, List<Object> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
