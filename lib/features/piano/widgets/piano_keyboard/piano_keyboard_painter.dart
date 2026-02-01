import 'package:flutter/material.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';

class PianoKeyboardPainter extends CustomPainter {
  PianoKeyboardPainter({
    required this.whiteKeyCount,
    required this.firstMidiNote,
    required this.soundingMidiNotes,
    required this.whiteKeyColor,
    required this.whiteKeyActiveColor,
    required this.whiteKeyBorderColor,
    required this.blackKeyColor,
    required this.blackKeyActiveColor,
    required this.backgroundColor,
    this.decorations = const <PianoKeyDecoration>[],
    this.decorationTextColor,
    this.drawBackground = true,
    this.drawFeltStrip = true,
    this.feltColor = const Color(0xFF800020),
    this.feltHeight = 2.0,
  }) : assert(
         decorations.isEmpty || decorationTextColor != null,
         'decorationTextColor must be provided when decorations are present',
       ),
       _geometry = PianoGeometry(
         firstWhiteMidi: firstMidiNote,
         whiteKeyCount: whiteKeyCount,
       );

  final int whiteKeyCount;
  final int firstMidiNote;

  /// Sounding *MIDI note numbers* (e.g., 60 for middle C).
  final Set<int> soundingMidiNotes;

  final Color whiteKeyColor;
  final Color whiteKeyActiveColor;
  final Color whiteKeyBorderColor;
  final Color blackKeyColor;
  final Color blackKeyActiveColor;
  final Color backgroundColor;

  /// Key decorations (e.g., middle C landmark, scale markers).
  final List<PianoKeyDecoration> decorations;
  final Color? decorationTextColor;

  final bool drawBackground;

  final bool drawFeltStrip;
  final Color feltColor;
  final double feltHeight;

  final PianoGeometry _geometry;

  static const List<int> _whitePitchClassesInOctave = <int>[
    0,
    2,
    4,
    5,
    7,
    9,
    11,
  ];

  int _whitePcForIndex(int whiteIndex) {
    final startPc = firstMidiNote % 12;
    final startPos = _whitePitchClassesInOctave.indexOf(startPc);
    final normalizedStartPos = startPos < 0 ? 0 : startPos;
    return _whitePitchClassesInOctave[(normalizedStartPos + whiteIndex) % 7];
  }

  int _whiteMidiForIndex(int whiteIndex) =>
      _geometry.whiteMidiForIndex(whiteIndex);

  bool _isSounding(int midi) => soundingMidiNotes.contains(midi);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (whiteKeyCount <= 0 || w <= 0 || h <= 0) return;

    if (drawBackground) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    final whiteKeyW = w / whiteKeyCount;
    final whiteKeyH = h;
    final blackKeyW = whiteKeyW * PianoGeometry.blackKeyWidthRatio;
    final blackKeyH = whiteKeyH * PianoGeometry.blackKeyHeightRatio;

    final whiteFillPaint = Paint()..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = whiteKeyBorderColor;

    // White keys
    for (int i = 0; i < whiteKeyCount; i++) {
      final x = i * whiteKeyW;
      final rect = Rect.fromLTWH(x, 0, whiteKeyW, whiteKeyH);

      final midi = _whiteMidiForIndex(i);

      whiteFillPaint.color = _isSounding(midi)
          ? whiteKeyActiveColor
          : whiteKeyColor;

      canvas.drawRect(rect, whiteFillPaint);
      canvas.drawRect(rect, whiteBorderPaint);
    }

    // Black keys
    final blackFillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < whiteKeyCount - 1; i++) {
      final whitePc = _whitePcForIndex(i);
      if (!PianoGeometry.hasBlackAfterWhitePc(whitePc)) continue;

      final whiteMidi = _whiteMidiForIndex(i);
      final blackMidi = whiteMidi + 1;
      final blackPc = blackMidi % 12;

      final boundaryX = (i + 1) * whiteKeyW;
      final centerX =
          boundaryX + PianoGeometry.blackCenterBiasForPc(blackPc, whiteKeyW);

      double blackLeft = centerX - (blackKeyW / 2.0);
      blackLeft = blackLeft.clamp(0.0, w - blackKeyW);

      final rect = Rect.fromLTWH(blackLeft, 0, blackKeyW, blackKeyH);

      blackFillPaint.color = _isSounding(blackMidi)
          ? blackKeyActiveColor
          : blackKeyColor;
      canvas.drawRect(rect, blackFillPaint);
    }

    // Felt strip LAST so it stays visible.
    if (drawFeltStrip && feltHeight > 0) {
      final feltPaint = Paint()..color = feltColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, feltHeight), feltPaint);
    }

    // Decorations (e.g., middle C landmark).
    if (decorations.isNotEmpty) {
      _paintDecorations(canvas, size, whiteKeyW);
    }
  }

  void _paintDecorations(Canvas canvas, Size size, double whiteKeyW) {
    final color = decorationTextColor;
    if (color == null) return;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Place near the bottom of the white key, but leave a small margin.
    const baseBottomPad = 6.0;

    for (final d in decorations) {
      final whiteIndex = _geometry.whiteIndexForMidi(d.midiNote);
      if (whiteIndex < 0 || whiteIndex >= whiteKeyCount) continue;

      textPainter.text = TextSpan(
        text: d.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout(minWidth: whiteKeyW, maxWidth: whiteKeyW);

      final dx = whiteIndex * whiteKeyW;

      final bottomPad = baseBottomPad + d.bottomLift;
      final dy = size.height - textPainter.height - bottomPad;

      textPainter.paint(canvas, Offset(dx, dy));
    }
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
        oldDelegate.whiteKeyActiveColor != whiteKeyActiveColor ||
        oldDelegate.whiteKeyBorderColor != whiteKeyBorderColor ||
        oldDelegate.blackKeyColor != blackKeyColor ||
        oldDelegate.blackKeyActiveColor != blackKeyActiveColor ||
        oldDelegate.decorationTextColor != decorationTextColor ||
        !_listEquals(oldDelegate.decorations, decorations) ||
        !_setEquals(oldDelegate.soundingMidiNotes, soundingMidiNotes);
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
