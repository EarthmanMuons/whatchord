import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/input.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';
import 'piano_keyboard.dart';

@immutable
class _ScrollIndicatorState {
  final bool showLeft;
  final bool showRight;
  final double? leftTarget;
  final double? rightTarget;

  const _ScrollIndicatorState({
    required this.showLeft,
    required this.showRight,
    this.leftTarget,
    this.rightTarget,
  });

  static const none = _ScrollIndicatorState(showLeft: false, showRight: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ScrollIndicatorState &&
          runtimeType == other.runtimeType &&
          showLeft == other.showLeft &&
          showRight == other.showRight &&
          leftTarget == other.leftTarget &&
          rightTarget == other.rightTarget;

  @override
  int get hashCode => Object.hash(showLeft, showRight, leftTarget, rightTarget);
}

class ScrollablePianoKeyboard extends ConsumerStatefulWidget {
  const ScrollablePianoKeyboard({
    super.key,
    required this.visibleWhiteKeyCount,
    required this.height,
    required this.highlightedNoteNumbers,
    this.autoCenter = true,
    this.autoCenterSuppression = const Duration(seconds: 3),
    this.fullWhiteKeyCount = 52,
    this.lowestNoteNumber = 21, // A0
    this.showMiddleCMarker = true,
    this.middleCLabel = 'C',
    this.middleCLabelTextScale = 1.0,
  }) : assert(visibleWhiteKeyCount > 0);

  /// How many white keys should be visible in the viewport width.
  /// (21 in portrait, 52 in landscape)
  final int visibleWhiteKeyCount;

  final double height;

  final Set<int> highlightedNoteNumbers;

  /// If true, auto-center the viewport to keep highlighted notes visible.
  final bool autoCenter;

  /// When user scrolls manually, suppress follow for this window.
  final Duration autoCenterSuppression;

  /// Full keyboard span rendered into the scroll content.
  final int fullWhiteKeyCount;

  /// First white MIDI note of the full span (A0 = 21 for a standard 88-key).
  final int lowestNoteNumber;

  /// Middle C marker at MIDI 60.
  final bool showMiddleCMarker;
  final String middleCLabel;
  final double middleCLabelTextScale;

  @override
  ConsumerState<ScrollablePianoKeyboard> createState() =>
      _ScrollablePianoKeyboardState();
}

class _ScrollablePianoKeyboardState
    extends ConsumerState<ScrollablePianoKeyboard> {
  final ScrollController _ctl = ScrollController();

  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);
  Set<int> _previousHighlightedNotes = const <int>{};

  ProviderSubscription<bool>? _idleSubscription;

  // Cached scroll indicator state; updated deterministically from scroll + note changes.
  _ScrollIndicatorState _indicatorState = _ScrollIndicatorState.none;

  // Most recent viewport width from LayoutBuilder.
  double? _cachedViewportWidth;

  // True while a programmatic scroll animation is in flight.
  bool _isAutoScrolling = false;

  // Single source of truth for scroll indicator behavior.
  static const double _indicatorShowMargin = 12.0;
  static const double _indicatorHysteresis = 4.0;
  static double get _indicatorHideMargin =>
      _indicatorShowMargin - _indicatorHysteresis;
  static const double _minMeaningfulDelta = 12.0;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onScrollOffsetChanged);

    _idleSubscription = ref.listenManual<bool>(inputIdleEligibleProvider, (
      prev,
      next,
    ) {
      final becameEligible = next == true && prev != true;
      if (!becameEligible) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryCenterWhenReady(retries: 8);
      });
    });

    _scheduleInitialCenter();
  }

  @override
  void dispose() {
    _idleSubscription?.close();
    _ctl.removeListener(_onScrollOffsetChanged);
    _ctl.dispose();
    super.dispose();
  }

  void _onScrollOffsetChanged() {
    if (!mounted) return;
    _updateIndicatorState();
  }

  Future<void> _animateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!mounted) return;
    if (!_ctl.hasClients) return;

    final clamped = target.clamp(0.0, _ctl.position.maxScrollExtent);
    final delta = (clamped - _ctl.offset).abs();
    if (delta < 1.0) return;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    if (disableAnimations) {
      _ctl.jumpTo(clamped);
      _updateIndicatorState();
      return;
    }

    if (!_isAutoScrolling) {
      setState(() => _isAutoScrolling = true);
    }

    try {
      await _ctl.animateTo(clamped, duration: duration, curve: curve);
    } finally {
      if (mounted) {
        if (_isAutoScrolling) {
          setState(() => _isAutoScrolling = false);
        }
        _updateIndicatorState();
      }
    }
  }

  void _scheduleInitialCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryCenterWhenReady(retries: 8);
    });
  }

  void _tryCenterWhenReady({required int retries}) {
    if (!mounted) return;

    // Controller not attached yet.
    if (!_ctl.hasClients) {
      _retry(retries);
      return;
    }

    final pos = _ctl.position;

    // Layout not settled / no extents yet.
    if (!pos.hasContentDimensions || pos.maxScrollExtent == 0.0) {
      _retry(retries);
      return;
    }

    _centerNow();
  }

  void _retry(int retries) {
    if (retries <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryCenterWhenReady(retries: retries - 1);
    });
  }

  void _centerNow() {
    if (!mounted) return;
    _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(
      0,
    ); // allow follow immediately

    final double? viewportWidth = _cachedViewportWidth ?? context.size?.width;
    if (viewportWidth == null || viewportWidth <= 0) return;

    final whiteKeyWidth = _whiteKeyWidthForViewport(viewportWidth);
    final contentWidth = _contentWidthForWhiteKeyWidth(whiteKeyWidth);
    final geometry = _buildGeometry();

    final highlighted = widget.highlightedNoteNumbers;

    if (highlighted.isNotEmpty) {
      double minX = double.infinity;
      double maxX = -double.infinity;

      for (final midi in highlighted) {
        final keyRect = geometry.keyRectForMidi(
          midi: midi,
          whiteKeyWidth: whiteKeyWidth,
          totalWidth: contentWidth,
        );
        minX = math.min(minX, keyRect.left);
        maxX = math.max(maxX, keyRect.right);
      }

      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - (viewportWidth / 2.0)).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );

      _animateTo(target);
      return;
    } else {
      // Center Middle C (MIDI 60) when idle.
      final keyRect = geometry.keyRectForMidi(
        midi: 60,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      final centerX = (keyRect.left + keyRect.right) / 2.0;
      final target = (centerX - (viewportWidth / 2.0)).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );

      _animateTo(target);
    }
  }

  @override
  void didUpdateWidget(covariant ScrollablePianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If notes changed, consider recentering.
    if (!_setEquals(
      oldWidget.highlightedNoteNumbers,
      widget.highlightedNoteNumbers,
    )) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoCenterIfNeeded(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIndicatorState();
      });
    }

    // If visible key count changed (rotation), keep things stable by recentering.
    if (oldWidget.visibleWhiteKeyCount != widget.visibleWhiteKeyCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoCenterIfNeeded(force: true),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIndicatorState();
      });
    }
  }

  void _onUserScroll() {
    _lastUserScroll = DateTime.now();
    // Reset diff baseline so follow logic doesn't interpret changes during the
    // cooldown as a large "added" burst once suppression ends.
    _previousHighlightedNotes = Set<int>.from(widget.highlightedNoteNumbers);
  }

  bool get _isAutoCenterSuppressed =>
      DateTime.now().difference(_lastUserScroll) < widget.autoCenterSuppression;

  PianoGeometry _buildGeometry() {
    return PianoGeometry(
      firstWhiteMidi: widget.lowestNoteNumber,
      whiteKeyCount: widget.fullWhiteKeyCount,
    );
  }

  double _whiteKeyWidthForViewport(double viewportWidth) =>
      viewportWidth / widget.visibleWhiteKeyCount;

  double _contentWidthForWhiteKeyWidth(double whiteKeyWidth) =>
      whiteKeyWidth * widget.fullWhiteKeyCount;

  ({double minX, double maxX}) _rangeBoundsForHighlighted({
    required Set<int> highlighted,
    required PianoGeometry geometry,
    required double whiteKeyWidth,
    required double contentWidth,
  }) {
    double minX = double.infinity;
    double maxX = -double.infinity;

    for (final midi in highlighted) {
      final keyRect = geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      minX = math.min(minX, keyRect.left);
      maxX = math.max(maxX, keyRect.right);
    }

    return (minX: minX, maxX: maxX);
  }

  ({int? leftMidi, int? rightMidi}) _nearestOffscreenCandidates({
    required Set<int> highlighted,
    required PianoGeometry geometry,
    required double whiteKeyWidth,
    required double contentWidth,
    required double viewLeft,
    required double viewRight,
  }) {
    int? leftMidi;
    double leftBest =
        -double.infinity; // maximize rect.right (closest from left)

    int? rightMidi;
    double rightBest =
        double.infinity; // minimize rect.left (closest from right)

    for (final midi in highlighted) {
      final keyRect = geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );

      final offLeft = keyRect.right < (viewLeft + _indicatorShowMargin);
      if (offLeft && keyRect.right > leftBest) {
        leftBest = keyRect.right;
        leftMidi = midi;
      }

      final offRight = keyRect.left > (viewRight - _indicatorShowMargin);
      if (offRight && keyRect.left < rightBest) {
        rightBest = keyRect.left;
        rightMidi = midi;
      }
    }

    return (leftMidi: leftMidi, rightMidi: rightMidi);
  }

  void _updateIndicatorState({double? viewportWidth}) {
    final double? width = viewportWidth ?? _cachedViewportWidth;
    if (width == null || width <= 0) return;
    if (!_ctl.hasClients) {
      if (_indicatorState != _ScrollIndicatorState.none) {
        setState(() => _indicatorState = _ScrollIndicatorState.none);
      }
      return;
    }

    final whiteKeyWidth = _whiteKeyWidthForViewport(width);
    final contentWidth = _contentWidthForWhiteKeyWidth(whiteKeyWidth);
    final geometry = _buildGeometry();

    final highlighted = widget.highlightedNoteNumbers;
    if (highlighted.isEmpty) {
      if (_indicatorState != _ScrollIndicatorState.none) {
        setState(() => _indicatorState = _ScrollIndicatorState.none);
      }
      return;
    }

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + width;

    final bounds = _rangeBoundsForHighlighted(
      highlighted: highlighted,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
    );
    final minX = bounds.minX;
    final maxX = bounds.maxX;

    final nearest = _nearestOffscreenCandidates(
      highlighted: highlighted,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
      viewLeft: viewLeft,
      viewRight: viewRight,
    );
    final leftMidi = nearest.leftMidi;
    final rightMidi = nearest.rightMidi;

    // Hysteresis: use a wider threshold to turn indicators on, and a slightly
    // tighter threshold to turn them off. This avoids flicker when notes hover
    // near the viewport edge during animated scroll.
    final showLeft = _indicatorState.showLeft
        ? (leftMidi != null && minX < (viewLeft + _indicatorHideMargin))
        : (leftMidi != null && minX < (viewLeft + _indicatorShowMargin));

    final showRight = _indicatorState.showRight
        ? (rightMidi != null && maxX > (viewRight - _indicatorHideMargin))
        : (rightMidi != null && maxX > (viewRight - _indicatorShowMargin));

    double? leftTarget;
    if (showLeft) {
      final keyRect = geometry.keyRectForMidi(
        midi: leftMidi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      leftTarget = (keyRect.left - _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    double? rightTarget;
    if (showRight) {
      final keyRect = geometry.keyRectForMidi(
        midi: rightMidi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      rightTarget = (keyRect.right - width + _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    final next = _ScrollIndicatorState(
      showLeft: showLeft,
      showRight: showRight,
      leftTarget: leftTarget,
      rightTarget: rightTarget,
    );

    if (next != _indicatorState) {
      setState(() => _indicatorState = next);
    }
  }

  void _autoCenterIfNeeded({bool force = false}) {
    if (!mounted) return;
    if (!widget.autoCenter && !force) return;
    if (_isAutoCenterSuppressed && !force) return;

    final next = widget.highlightedNoteNumbers;
    if (next.isEmpty) {
      _previousHighlightedNotes = const <int>{};
      return;
    }

    final double? viewportWidth = _cachedViewportWidth ?? context.size?.width;
    if (viewportWidth == null || viewportWidth <= 0) return;

    final whiteKeyWidth = _whiteKeyWidthForViewport(viewportWidth);
    final contentWidth = _contentWidthForWhiteKeyWidth(whiteKeyWidth);
    final geometry = _buildGeometry();

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + viewportWidth;

    // Diff against the last known highlighted set.
    final prev = _previousHighlightedNotes;
    final added = next.difference(prev);
    final removed = prev.difference(next);

    // Update the set now that we've captured diffs.
    _previousHighlightedNotes = Set<int>.from(next);

    // Decide whether anything is actually offscreen.
    final bounds = _rangeBoundsForHighlighted(
      highlighted: next,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
    );

    final minX = bounds.minX;
    final maxX = bounds.maxX;
    final spreadW = maxX - minX;

    final offLeft = minX < (viewLeft + _indicatorShowMargin);
    final offRight = maxX > (viewRight - _indicatorShowMargin);

    if (!offLeft && !offRight && !force) return;

    // If the full range fits within the viewport (minus margins), center it.
    if (spreadW <= (viewportWidth - 2 * _indicatorShowMargin)) {
      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - viewportWidth / 2.0).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );

      final delta = (target - _ctl.offset).abs();
      if (!force && delta < _minMeaningfulDelta) return;

      _animateTo(target);
      return;
    }

    // If both sides are offscreen and the range doesn't fit, don't chase the range.
    // Prefer newly-added notes; otherwise stay stable (unless forced).
    if (offLeft && offRight && !force) {
      if (added.isEmpty && removed.isNotEmpty) {
        _maybeReanchorAfterRemoval(
          next,
          geometry,
          viewportWidth,
          whiteKeyWidth,
          contentWidth,
          viewLeft,
          viewRight,
        );
      }
      return;
    }

    // Prefer reacting to newly added notes if they are offscreen.
    if (added.isNotEmpty && !force) {
      final addedNearest = _nearestOffscreenCandidates(
        highlighted: added,
        geometry: geometry,
        whiteKeyWidth: whiteKeyWidth,
        contentWidth: contentWidth,
        viewLeft: viewLeft,
        viewRight: viewRight,
      );

      final addedLeft = addedNearest.leftMidi;
      final addedRight = addedNearest.rightMidi;

      if (addedLeft != null) {
        final keyRect = geometry.keyRectForMidi(
          midi: addedLeft,
          whiteKeyWidth: whiteKeyWidth,
          totalWidth: contentWidth,
        );
        final target = (keyRect.left - _indicatorShowMargin).clamp(
          0.0,
          _ctl.position.maxScrollExtent,
        );
        final delta = (target - _ctl.offset).abs();
        if (delta >= _minMeaningfulDelta) {
          _animateTo(target);
        }
        return;
      }

      if (addedRight != null) {
        final keyRect = geometry.keyRectForMidi(
          midi: addedRight,
          whiteKeyWidth: whiteKeyWidth,
          totalWidth: contentWidth,
        );
        final target = (keyRect.right - viewportWidth + _indicatorShowMargin)
            .clamp(0.0, _ctl.position.maxScrollExtent);
        final delta = (target - _ctl.offset).abs();
        if (delta >= _minMeaningfulDelta) {
          _animateTo(target);
        }
        return;
      }
    }

    // Otherwise reveal the nearest offscreen highlighted key on the side that is offscreen.
    final nearest = _nearestOffscreenCandidates(
      highlighted: next,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
      viewLeft: viewLeft,
      viewRight: viewRight,
    );

    double? target;
    if (offLeft && nearest.leftMidi != null) {
      final int midi = nearest.leftMidi!;
      final keyRect = geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      target = (keyRect.left - _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    } else if (offRight && nearest.rightMidi != null) {
      final int midi = nearest.rightMidi!;
      final keyRect = geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      target = (keyRect.right - viewportWidth + _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    if (target == null) return;
    final delta = (target - _ctl.offset).abs();
    if (!force && delta < _minMeaningfulDelta) return;

    _animateTo(target);
  }

  void _maybeReanchorAfterRemoval(
    Set<int> highlighted,
    PianoGeometry geometry,
    double viewportWidth,
    double whiteKeyWidth,
    double contentWidth,
    double viewLeft,
    double viewRight,
  ) {
    if (highlighted.isEmpty) return;

    int visibleCount = 0;
    for (final midi in highlighted) {
      final rect = geometry.keyRectForMidi(
        midi: midi,
        whiteKeyWidth: whiteKeyWidth,
        totalWidth: contentWidth,
      );
      final visible =
          rect.right > (viewLeft + _indicatorShowMargin) &&
          rect.left < (viewRight - _indicatorShowMargin);
      if (visible) visibleCount++;
    }

    final ratio = visibleCount / highlighted.length;
    if (ratio >= 0.34) return;

    final bounds = _rangeBoundsForHighlighted(
      highlighted: highlighted,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
    );
    final minX = bounds.minX;
    final maxX = bounds.maxX;

    final viewCenter = (viewLeft + viewRight) / 2.0;
    final distToLeft = (viewCenter - (minX + whiteKeyWidth / 2.0)).abs();
    final distToRight = (viewCenter - (maxX - whiteKeyWidth / 2.0)).abs();

    double target;
    if (distToRight < distToLeft) {
      target = (maxX - viewportWidth + _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    } else {
      target = (minX - _indicatorShowMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    final delta = (target - _ctl.offset).abs();
    if (delta < _minMeaningfulDelta) return;

    _animateTo(target);
  }

  Future<void> _handleChevronTap(AxisDirection direction) async {
    if (!mounted) return;
    if (_isAutoScrolling) return;
    if (!_ctl.hasClients) return;

    final highlighted = widget.highlightedNoteNumbers;
    if (highlighted.isEmpty) return;

    final double? viewportWidth = _cachedViewportWidth ?? context.size?.width;
    if (viewportWidth == null || viewportWidth <= 0) return;

    final whiteKeyWidth = _whiteKeyWidthForViewport(viewportWidth);
    final contentWidth = _contentWidthForWhiteKeyWidth(whiteKeyWidth);
    final geometry = _buildGeometry();

    final bounds = _rangeBoundsForHighlighted(
      highlighted: highlighted,
      geometry: geometry,
      whiteKeyWidth: whiteKeyWidth,
      contentWidth: contentWidth,
    );

    final minX = bounds.minX;
    final maxX = bounds.maxX;
    final spreadW = maxX - minX;

    // First preference: if the highlighted range fits, center it.
    if (spreadW <= (viewportWidth - 2 * _indicatorShowMargin)) {
      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - viewportWidth / 2.0).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
      await _animateTo(target);
      return;
    }

    // Otherwise: reveal the nearest hidden note on the tapped side.
    final fallbackTarget = direction == AxisDirection.left
        ? _indicatorState.leftTarget
        : _indicatorState.rightTarget;
    if (fallbackTarget == null) return;
    await _animateTo(fallbackTarget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;

        // Capture the latest viewport width for deterministic indicator state computation.
        // If it changes (rotation / resize), recompute after this frame.
        final previousWidth = _cachedViewportWidth;
        if (previousWidth != viewportWidth) {
          _cachedViewportWidth = viewportWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateIndicatorState(viewportWidth: viewportWidth);
          });
        }

        final whiteKeyWidth = viewportWidth / widget.visibleWhiteKeyCount;
        final contentWidth = whiteKeyWidth * widget.fullWhiteKeyCount;

        // Lift decorations enough to get above the nav indicator.
        final systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;
        final base = (widget.height * 0.05).clamp(0.0, 5.0);
        final lift = systemBottomInset > 0
            ? (systemBottomInset * 0.3).clamp(0.0, 9.0)
            : 0.0;
        final decorationLift = base + lift;

        final decorations = <PianoKeyDecoration>[
          if (widget.showMiddleCMarker)
            PianoKeyDecoration(
              midiNote: 60,
              label: widget.middleCLabel,
              bottomLift: decorationLift,
            ),
        ];

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Semantics(
                container: true,
                label: 'Piano keyboard',
                hint:
                    'Horizontally scrollable. Use the center keyboard action to recenter on active notes.',
                customSemanticsActions: {
                  const CustomSemanticsAction(
                    label: 'Center keyboard on active notes',
                  ): _centerNow,
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _centerNow,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification &&
                          n.dragDetails != null) {
                        _onUserScroll();
                      }
                      if (n is ScrollUpdateNotification &&
                          n.dragDetails != null) {
                        _onUserScroll();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _ctl,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: contentWidth,
                        height: widget.height,
                        child: PianoKeyboard(
                          whiteKeyCount: widget.fullWhiteKeyCount,
                          firstMidiNote: widget.lowestNoteNumber,
                          highlightedNoteNumbers: widget.highlightedNoteNumbers,
                          height: widget.height,
                          decorations: decorations,
                          decorationTextScaleMultiplier:
                              widget.middleCLabelTextScale,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: _OffscreenNoteCue(
                  direction: AxisDirection.left,
                  visible: _indicatorState.showLeft,
                  enabled: !_isAutoScrolling,
                  onTap: () => _handleChevronTap(AxisDirection.left),
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: _OffscreenNoteCue(
                  direction: AxisDirection.right,
                  visible: _indicatorState.showRight,
                  enabled: !_isAutoScrolling,
                  onTap: () => _handleChevronTap(AxisDirection.right),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}

class _OffscreenNoteCue extends StatelessWidget {
  const _OffscreenNoteCue({
    required this.direction,
    required this.visible,
    required this.enabled,
    required this.onTap,
  });

  final AxisDirection direction;
  final bool visible;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final directionLabel = direction == AxisDirection.left ? 'left' : 'right';
    final semanticsLabel = 'Reveal notes to the $directionLabel';

    final icon = direction == AxisDirection.left
        ? Icons.chevron_left
        : Icons.chevron_right;

    final showOpacity = visible ? 1.0 : 0.0;
    final showScale = visible ? 1.0 : 0.92;

    return IgnorePointer(
      ignoring: !visible || !enabled,
      child: AnimatedOpacity(
        opacity: showOpacity,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: showScale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                container: true,
                label: semanticsLabel,
                hidden: !visible,
                button: true,
                enabled: visible && enabled,
                onTapHint: semanticsLabel,
                child: Tooltip(
                  message: semanticsLabel,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: enabled ? onTap : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(
                              alpha: enabled ? 0.55 : 0.40,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: cs.onSurfaceVariant.withValues(
                                alpha: enabled ? 0.85 : 0.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
