import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/theory/theory.dart';

import '../domain/detectors/display_calibration.dart';
import '../domain/detectors/key_space.dart';
import '../domain/models/key_estimate.dart';

/// The circle of fifths unrolled for height-constrained layouts: one column
/// per pitch class in fifths order, major above its relative minor, so the
/// adjacency story survives (fifth neighbors touch, relative pairs stack).
/// Same single-hue calibrated ramp as the wheel; the claim carries a border
/// so it is never marked by color alone. Cells grow with the available width.
/// Touching scrubs across cells, floating that key's calibrated probability
/// over the top row, offset left of the finger so it stays visible; the
/// readout lingers briefly after release.
class KeyPosteriorStrip extends ConsumerStatefulWidget {
  const KeyPosteriorStrip({super.key, required this.ranked, this.claim});

  /// Raw posterior from the detector; calibrated internally for display.
  final List<KeyEstimate> ranked;
  final Tonality? claim;

  @override
  ConsumerState<KeyPosteriorStrip> createState() => _KeyPosteriorStripState();
}

class _KeyPosteriorStripState extends ConsumerState<KeyPosteriorStrip> {
  static const _gap = 2.0;

  int? _inspectedIndex;
  double _fingerX = 0;
  Timer? _lingerTimer;

  @override
  void dispose() {
    _lingerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final noteNameSystem = ref.watch(noteNameSystemProvider);
    final calibrated = DisplayCalibration.calibrate(widget.ranked);

    final byIndex = <int, double>{
      for (final estimate in calibrated)
        KeySpace.index(estimate.tonality): estimate.confidence,
    };
    final claimIndex = widget.claim == null
        ? null
        : KeySpace.index(widget.claim!);

    String percentLabel(int index) {
      final percent = (byIndex[index] ?? 0.0) * 100;
      return percent >= 0.5 ? '${percent.round()}%' : '<1%';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cellWidth = (width - 11 * _gap) / 12;
        final cellHeight = (cellWidth * 0.72).clamp(30.0, 48.0);
        final fontSize = (cellWidth * 0.34).clamp(12.0, 15.0);

        Widget cell(Tonality tonality, {required bool isMajor}) {
          final index = KeySpace.index(tonality);
          final confidence = byIndex[index] ?? 0.0;
          final t = math.sqrt(confidence).clamp(0.0, 1.0);
          final fill = Color.lerp(cs.surfaceContainerHighest, cs.primary, t)!;
          final tonic = tonalityPickerTonicLabel(
            tonality,
            noteNameSystem: noteNameSystem,
          );

          return Semantics(
            label:
                '${tonalitySemanticLabel(tonality, noteNameSystem: noteNameSystem)}'
                ' ${percentLabel(index)}',
            child: Container(
              height: cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: index == claimIndex
                    ? Border.all(color: cs.onSurface, width: 2)
                    : index == _inspectedIndex
                    ? Border.all(color: cs.tertiary, width: 2)
                    : null,
              ),
              child: Text(
                isMajor ? tonic : '${tonic}m',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: fontSize,
                  fontWeight: index == claimIndex
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: t > 0.45 ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final rows = Row(
          children: [
            for (var i = 0; i < 12; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  children: [
                    cell(
                      KeySpace.canonicalTonalities[((7 * i) % 12) * 2],
                      isMajor: true,
                    ),
                    const SizedBox(height: _gap),
                    cell(
                      KeySpace.canonicalTonalities[(((7 * i) % 12 + 9) % 12) *
                              2 +
                          1],
                      isMajor: false,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

        final inspected = _inspectedIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _scrub(details.localPosition, cellWidth, cellHeight),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          onPanStart: (details) =>
              _scrub(details.localPosition, cellWidth, cellHeight),
          onPanUpdate: (details) =>
              _scrub(details.localPosition, cellWidth, cellHeight),
          onPanEnd: (_) => _release(),
          onPanCancel: _release,
          child: Stack(
            children: [
              rows,
              if (inspected != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: cellHeight,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment(
                        (2 * (_fingerX - 56) / width - 1).clamp(-1.0, 1.0),
                        0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.inverseSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tonalityDisplayLabel(KeySpace.canonicalTonalities[inspected], noteNameSystem: noteNameSystem)}'
                          ' · ${percentLabel(inspected)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onInverseSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _scrub(Offset position, double cellWidth, double cellHeight) {
    _lingerTimer?.cancel();
    final column = (position.dx / (cellWidth + _gap)).floor().clamp(0, 11);
    final pc = (7 * column) % 12;
    final index = position.dy < cellHeight + _gap / 2
        ? pc * 2
        : ((pc + 9) % 12) * 2 + 1;
    if (index == _inspectedIndex && position.dx == _fingerX) return;
    setState(() {
      _inspectedIndex = index;
      _fingerX = position.dx;
    });
  }

  void _release() {
    _lingerTimer?.cancel();
    _lingerTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _inspectedIndex = null);
    });
  }
}
