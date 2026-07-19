import 'package:flutter/foundation.dart';

import 'piano_geometry.dart';

/// A snapshot of the scrollable keyboard's layout and scroll position: the
/// inputs every scroll/centering decision is made from.
@immutable
class KeyboardViewport {
  const KeyboardViewport({
    required this.geometry,
    required this.whiteKeyWidth,
    required this.width,
    required this.offset,
    required this.maxScrollExtent,
  });

  final PianoGeometry geometry;
  final double whiteKeyWidth;

  /// Visible viewport width.
  final double width;

  /// Current scroll offset (the viewport's left edge in content space).
  final double offset;

  final double maxScrollExtent;

  double get contentWidth => whiteKeyWidth * geometry.whiteKeyCount;
  double get right => offset + width;

  PianoKeyRect rectFor(int midi) => geometry.keyRectForMidi(
    midi: midi,
    whiteKeyWidth: whiteKeyWidth,
    totalWidth: contentWidth,
  );

  double clampOffset(double target) => target.clamp(0.0, maxScrollExtent);
}

/// Which offscreen-note indicators show, and where tapping them scrolls.
@immutable
class ScrollIndicatorState {
  final bool showLeft;
  final bool showRight;
  final double? leftTarget;
  final double? rightTarget;

  const ScrollIndicatorState({
    required this.showLeft,
    required this.showRight,
    this.leftTarget,
    this.rightTarget,
  });

  static const none = ScrollIndicatorState(showLeft: false, showRight: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollIndicatorState &&
          runtimeType == other.runtimeType &&
          showLeft == other.showLeft &&
          showRight == other.showRight &&
          leftTarget == other.leftTarget &&
          rightTarget == other.rightTarget;

  @override
  int get hashCode => Object.hash(showLeft, showRight, leftTarget, rightTarget);
}

/// Pure scroll and centering policy for the scrollable keyboard.
///
/// Every method takes a [KeyboardViewport] snapshot and returns a decision (a
/// clamped scroll target, or an indicator state); the widget owns timing,
/// animation, suppression, and when to consult the policy. A null target
/// means "do not scroll".
abstract final class PianoScrollPolicy {
  /// Distance from a viewport edge within which a note counts as offscreen
  /// and indicator targets park revealed notes.
  static const double showMargin = 12.0;

  /// Hysteresis between showing and hiding indicators, avoiding flicker when
  /// notes hover near the viewport edge during animated scroll.
  static const double hysteresis = 4.0;

  static double get hideMargin => showMargin - hysteresis;

  /// Edge margin inside which highlighted notes trigger auto-centering.
  static const double autoCenterEdgeMargin = 24.0;

  /// Scroll deltas below this are not worth an animation.
  static const double minMeaningfulDelta = 12.0;

  /// When fewer than this fraction of highlighted notes remain visible after
  /// a removal, the view reanchors to the nearer end of the remaining range.
  static const double reanchorVisibleRatio = 0.34;

  /// Horizontal bounds of the highlighted keys' rects.
  static ({double minX, double maxX}) rangeBounds(
    KeyboardViewport viewport,
    Set<int> highlighted,
  ) {
    var minX = double.infinity;
    var maxX = -double.infinity;
    for (final midi in highlighted) {
      final keyRect = viewport.rectFor(midi);
      if (keyRect.left < minX) minX = keyRect.left;
      if (keyRect.right > maxX) maxX = keyRect.right;
    }
    return (minX: minX, maxX: maxX);
  }

  /// The offscreen highlighted key nearest each viewport edge, if any.
  static ({int? leftMidi, int? rightMidi}) nearestOffscreen(
    KeyboardViewport viewport,
    Set<int> highlighted,
  ) {
    int? leftMidi;
    var leftBest = -double.infinity; // maximize rect.right (closest from left)

    int? rightMidi;
    var rightBest = double.infinity; // minimize rect.left (closest from right)

    for (final midi in highlighted) {
      final keyRect = viewport.rectFor(midi);

      final offLeft = keyRect.right < (viewport.offset + showMargin);
      if (offLeft && keyRect.right > leftBest) {
        leftBest = keyRect.right;
        leftMidi = midi;
      }

      final offRight = keyRect.left > (viewport.right - showMargin);
      if (offRight && keyRect.left < rightBest) {
        rightBest = keyRect.left;
        rightMidi = midi;
      }
    }

    return (leftMidi: leftMidi, rightMidi: rightMidi);
  }

  /// Next indicator state, using [previous] for show/hide hysteresis.
  static ScrollIndicatorState indicatorState(
    KeyboardViewport viewport, {
    required Set<int> highlighted,
    required ScrollIndicatorState previous,
  }) {
    if (highlighted.isEmpty) return ScrollIndicatorState.none;

    final bounds = rangeBounds(viewport, highlighted);
    final nearest = nearestOffscreen(viewport, highlighted);
    final leftMidi = nearest.leftMidi;
    final rightMidi = nearest.rightMidi;

    final showLeft = previous.showLeft
        ? (leftMidi != null && bounds.minX < (viewport.offset + hideMargin))
        : (leftMidi != null && bounds.minX < (viewport.offset + showMargin));

    final showRight = previous.showRight
        ? (rightMidi != null && bounds.maxX > (viewport.right - hideMargin))
        : (rightMidi != null && bounds.maxX > (viewport.right - showMargin));

    double? leftTarget;
    if (showLeft) {
      leftTarget = viewport.clampOffset(
        viewport.rectFor(leftMidi).left - showMargin,
      );
    }

    double? rightTarget;
    if (showRight) {
      rightTarget = viewport.clampOffset(
        viewport.rectFor(rightMidi).right - viewport.width + showMargin,
      );
    }

    return ScrollIndicatorState(
      showLeft: showLeft,
      showRight: showRight,
      leftTarget: leftTarget,
      rightTarget: rightTarget,
    );
  }

  /// Explicit centering target: the highlighted range's midpoint, or middle C
  /// when nothing is highlighted.
  static double centerTarget(KeyboardViewport viewport, Set<int> highlighted) {
    final double centerX;
    if (highlighted.isNotEmpty) {
      final bounds = rangeBounds(viewport, highlighted);
      centerX = (bounds.minX + bounds.maxX) / 2.0;
    } else {
      final keyRect = viewport.rectFor(60);
      centerX = (keyRect.left + keyRect.right) / 2.0;
    }
    return viewport.clampOffset(centerX - viewport.width / 2.0);
  }

  /// Follow target when the highlighted set changes, or null to stay put.
  ///
  /// Centers the range when it fits; otherwise prefers revealing newly
  /// [added] notes, reanchors after removals that leave most of the range
  /// offscreen, and falls back to revealing the nearest offscreen note on an
  /// offscreen side. [force] centers regardless of margins and deltas.
  static double? autoCenterTarget(
    KeyboardViewport viewport, {
    required Set<int> highlighted,
    required Set<int> added,
    required Set<int> removed,
    bool force = false,
  }) {
    if (highlighted.isEmpty) return null;

    final bounds = rangeBounds(viewport, highlighted);
    final minX = bounds.minX;
    final maxX = bounds.maxX;
    final spreadW = maxX - minX;

    final offLeft = minX < (viewport.offset + autoCenterEdgeMargin);
    final offRight = maxX > (viewport.right - autoCenterEdgeMargin);

    if (!offLeft && !offRight && !force) return null;

    // If the full range fits within the viewport (minus margins), center it.
    if (spreadW <= (viewport.width - 2 * autoCenterEdgeMargin)) {
      final target = viewport.clampOffset(
        (minX + maxX) / 2.0 - viewport.width / 2.0,
      );
      final delta = (target - viewport.offset).abs();
      if (!force && delta < minMeaningfulDelta) return null;
      return target;
    }

    // If both sides are offscreen and the range doesn't fit, don't chase the
    // range. Prefer newly-added notes; otherwise stay stable (unless forced).
    if (offLeft && offRight && !force) {
      if (added.isEmpty && removed.isNotEmpty) {
        return _reanchorAfterRemoval(viewport, highlighted, minX, maxX);
      }
      return null;
    }

    // Prefer reacting to newly added notes if they are offscreen.
    if (added.isNotEmpty && !force) {
      final addedNearest = nearestOffscreen(viewport, added);

      final addedLeft = addedNearest.leftMidi;
      if (addedLeft != null) {
        final target = viewport.clampOffset(
          viewport.rectFor(addedLeft).left - showMargin,
        );
        final delta = (target - viewport.offset).abs();
        return delta >= minMeaningfulDelta ? target : null;
      }

      final addedRight = addedNearest.rightMidi;
      if (addedRight != null) {
        final target = viewport.clampOffset(
          viewport.rectFor(addedRight).right - viewport.width + showMargin,
        );
        final delta = (target - viewport.offset).abs();
        return delta >= minMeaningfulDelta ? target : null;
      }
    }

    // Otherwise reveal the nearest offscreen highlighted key on the side that
    // is offscreen.
    final nearest = nearestOffscreen(viewport, highlighted);

    double? target;
    if (offLeft && nearest.leftMidi != null) {
      target = viewport.clampOffset(
        viewport.rectFor(nearest.leftMidi!).left - showMargin,
      );
    } else if (offRight && nearest.rightMidi != null) {
      target = viewport.clampOffset(
        viewport.rectFor(nearest.rightMidi!).right -
            viewport.width +
            showMargin,
      );
    }

    if (target == null) return null;
    final delta = (target - viewport.offset).abs();
    if (!force && delta < minMeaningfulDelta) return null;
    return target;
  }

  /// Reanchor to the nearer end of the remaining range when a removal leaves
  /// less than [reanchorVisibleRatio] of the highlighted notes visible.
  static double? _reanchorAfterRemoval(
    KeyboardViewport viewport,
    Set<int> highlighted,
    double minX,
    double maxX,
  ) {
    var visibleCount = 0;
    for (final midi in highlighted) {
      final rect = viewport.rectFor(midi);
      final visible =
          rect.right > (viewport.offset + showMargin) &&
          rect.left < (viewport.right - showMargin);
      if (visible) visibleCount++;
    }

    if (visibleCount / highlighted.length >= reanchorVisibleRatio) return null;

    final viewCenter = (viewport.offset + viewport.right) / 2.0;
    final half = viewport.whiteKeyWidth / 2.0;
    final distToLeft = (viewCenter - (minX + half)).abs();
    final distToRight = (viewCenter - (maxX - half)).abs();

    final target = distToRight < distToLeft
        ? viewport.clampOffset(maxX - viewport.width + showMargin)
        : viewport.clampOffset(minX - showMargin);

    final delta = (target - viewport.offset).abs();
    if (delta < minMeaningfulDelta) return null;
    return target;
  }

  /// Chevron tap target: center the range when it fits, else the indicator's
  /// stored reveal target for the tapped side.
  static double? chevronTarget(
    KeyboardViewport viewport, {
    required Set<int> highlighted,
    required bool towardLeft,
    required ScrollIndicatorState indicator,
  }) {
    if (highlighted.isEmpty) return null;

    final bounds = rangeBounds(viewport, highlighted);
    final spreadW = bounds.maxX - bounds.minX;

    if (spreadW <= (viewport.width - 2 * showMargin)) {
      return viewport.clampOffset(
        (bounds.minX + bounds.maxX) / 2.0 - viewport.width / 2.0,
      );
    }

    return towardLeft ? indicator.leftTarget : indicator.rightTarget;
  }
}
