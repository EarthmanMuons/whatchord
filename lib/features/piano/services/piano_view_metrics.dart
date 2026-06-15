import 'package:flutter/foundation.dart';

import '../models/piano_view_settings.dart';
import 'piano_geometry.dart';

/// Resolved keyboard dimensions for a viewport, after applying the user's
/// [PianoViewSettings]. Shared by every page that renders the keyboard so the
/// sizing math (previously copy-pasted) lives in one place.
@immutable
class PianoViewMetrics {
  const PianoViewMetrics({
    required this.visibleWhiteKeyCount,
    required this.height,
    required this.baseHeight,
    required this.maxHeight,
  });

  /// Number of white keys to show across the viewport (drives key width).
  final int visibleWhiteKeyCount;

  /// Resolved keyboard height after applying the height scale and clamping.
  final double height;

  /// The unscaled (default) height: the minimum the keyboard can shrink to and
  /// the basis for converting a dragged pixel height back into a height scale.
  final double baseHeight;

  /// The largest height the keyboard may occupy on this page right now.
  final double maxHeight;
}

/// Smallest viewport-visible white key count when zoomed in. Keeps keys from
/// becoming so wide that almost nothing is on screen (a bit over one octave).
const int _minVisibleWhiteKeyCount = 8;

const double _baseHeightFloor = 90.0;
const double _baseHeightCeil = 200.0;

PianoViewMetrics resolvePianoViewMetrics({
  required double viewportWidth,
  required int baseWhiteKeyCount,
  required double baseAspectRatio,
  required bool tightenForStatusBar,
  required double maxHeight,
  required PianoViewSettings settings,
}) {
  // Width zoom: wider keys means fewer of them fit, so reduce the visible count.
  final zoomedVisible = (baseWhiteKeyCount / settings.widthScale).round();
  final visibleWhiteKeyCount = zoomedVisible.clamp(
    _minVisibleWhiteKeyCount,
    baseWhiteKeyCount,
  );

  // Base height matches the pre-zoom layout and is derived from the unzoomed
  // key width so the floor stays stable as the user zooms horizontally.
  final baseWhiteKeyWidth = PianoGeometry.whiteKeyWidthForViewport(
    viewportWidth: viewportWidth,
    visibleWhiteKeyCount: baseWhiteKeyCount,
  );
  var baseHeight = baseWhiteKeyWidth * baseAspectRatio;
  if (tightenForStatusBar) baseHeight -= 4;
  baseHeight = baseHeight.clamp(_baseHeightFloor, _baseHeightCeil);

  final ceiling = maxHeight > baseHeight ? maxHeight : baseHeight;
  final height = (baseHeight * settings.heightScale).clamp(baseHeight, ceiling);

  return PianoViewMetrics(
    visibleWhiteKeyCount: visibleWhiteKeyCount,
    height: height,
    baseHeight: baseHeight,
    maxHeight: ceiling,
  );
}

/// Converts a target keyboard height (e.g. from a drag) into the height scale
/// to persist, clamped to the allowed scale range.
double heightScaleForHeight({
  required double height,
  required double baseHeight,
}) {
  if (baseHeight <= 0) return PianoViewSettings.minScale;
  return PianoViewSettings.clampScale(height / baseHeight);
}
