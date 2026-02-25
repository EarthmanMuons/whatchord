import 'package:flutter/material.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';

class PianoKeyboardPainter extends CustomPainter {
  PianoKeyboardPainter({
    required this.whiteKeyCount,
    required this.firstMidiNote,
    required this.highlightedNoteNumbers,
    required this.whiteKeyColor,
    required this.whiteKeyHighlightColor,
    required this.whiteKeyBorderColor,
    required this.blackKeyColor,
    required this.blackKeyHighlightColor,
    required this.backgroundColor,
    this.decorations = const <PianoKeyDecoration>[],
    this.decorationColor,
    this.decorationTextScaleMultiplier = 1.0,
    this.drawBackground = true,
    this.drawFeltStrip = true,
    this.feltColor = const Color(0xFF800020),
    this.feltHeight = 2.0,
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
  final Color whiteKeyHighlightColor;
  final Color whiteKeyBorderColor;
  final Color blackKeyColor;
  final Color blackKeyHighlightColor;
  final Color backgroundColor;

  /// Key decorations (e.g., middle C marker, scale markers).
  final List<PianoKeyDecoration> decorations;
  final Color? decorationColor;
  final double decorationTextScaleMultiplier;

  final bool drawBackground;

  final bool drawFeltStrip;
  final Color feltColor;
  final double feltHeight;

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

    final whiteFillPaint = Paint()..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = whiteKeyBorderColor;

    // White keys
    for (int i = 0; i < whiteKeyCount; i++) {
      final x = i * whiteKeyWidth;
      final rect = Rect.fromLTWH(x, 0, whiteKeyWidth, whiteKeyHeight);

      final midi = _whiteMidiForIndex(i);

      whiteFillPaint.color = _isHighlighted(midi)
          ? whiteKeyHighlightColor
          : whiteKeyColor;

      canvas.drawRect(rect, whiteFillPaint);
      canvas.drawRect(rect, whiteBorderPaint);
    }

    // Black keys
    final blackFillPaint = Paint()..style = PaintingStyle.fill;

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

      blackFillPaint.color = _isHighlighted(blackMidi)
          ? blackKeyHighlightColor
          : blackKeyColor;
      canvas.drawRect(rect, blackFillPaint);
    }

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

  void _paintDecorations(
    Canvas canvas,
    Size size, {
    required double whiteKeyWidth,
    required double blackKeyHeight,
  }) {
    final totalWidth = size.width;
    final topCapPaint = Paint()..style = PaintingStyle.fill;
    final topInset = (drawFeltStrip ? feltHeight : 0.0).clamp(0.0, size.height);
    final blackKeyWidth = whiteKeyWidth * PianoGeometry.blackKeyWidthRatio;
    final minRenderableMidi = _geometry.whiteMidis.first;
    final maxRenderableMidi = _geometry.whiteMidis.last;
    final topCapRadius = (blackKeyWidth * 0.336).clamp(3.0, 10.0).toDouble();

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
      if ((cy + topCapRadius) >= keyBottom) continue;

      topCapPaint.color = _resolvedTopCapColor(isBlackKey: isBlackKey);

      final clipRect = Rect.fromLTRB(
        lane.left,
        topInset,
        lane.right,
        keyBottom,
      );
      canvas.save();
      canvas.clipRect(clipRect);
      canvas.drawCircle(Offset(cx, cy), topCapRadius, topCapPaint);
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
    final hsl = HSLColor.fromColor(feltColor);
    final adjusted = isBlackKey
        ? hsl
              .withSaturation((hsl.saturation * 0.32).clamp(0.06, 0.18))
              .withLightness((hsl.lightness + 0.46).clamp(0.72, 0.86))
              .toColor()
        : hsl
              .withSaturation((hsl.saturation * 0.26).clamp(0.05, 0.14))
              .withLightness((hsl.lightness + 0.22).clamp(0.38, 0.52))
              .toColor();

    return adjusted.withValues(alpha: isBlackKey ? 0.64 : 0.46);
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
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.whiteKeyColor != whiteKeyColor ||
        oldDelegate.whiteKeyHighlightColor != whiteKeyHighlightColor ||
        oldDelegate.whiteKeyBorderColor != whiteKeyBorderColor ||
        oldDelegate.blackKeyColor != blackKeyColor ||
        oldDelegate.blackKeyHighlightColor != blackKeyHighlightColor ||
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
