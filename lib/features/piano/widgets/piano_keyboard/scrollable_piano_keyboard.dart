import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatchord/features/input/providers/input_idle_notifier.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';
import 'piano_keyboard.dart';

@immutable
class _EdgeState {
  final bool showLeft;
  final bool showRight;
  final double? leftTarget;
  final double? rightTarget;

  const _EdgeState({
    required this.showLeft,
    required this.showRight,
    this.leftTarget,
    this.rightTarget,
  });

  static const none = _EdgeState(showLeft: false, showRight: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EdgeState &&
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
    required this.soundingMidiNotes,
    this.followInput = true,
    this.followCooldown = const Duration(seconds: 3),
    this.fullWhiteKeyCount = 52,
    this.fullFirstMidiNote = 21, // A0
    this.showMiddleCLandmark = true,
    this.middleCLandmarkText = 'C',
  }) : assert(visibleWhiteKeyCount > 0);

  /// How many white keys should be visible in the viewport width.
  /// (21 in portrait, 52 in landscape)
  final int visibleWhiteKeyCount;

  final double height;

  final Set<int> soundingMidiNotes;

  /// If true, auto-center the viewport to keep active notes visible.
  final bool followInput;

  /// When user scrolls manually, suppress follow for this window.
  final Duration followCooldown;

  /// Full keyboard span rendered into the scroll content.
  final int fullWhiteKeyCount;

  /// First white MIDI note of the full span (A0 = 21 for a standard 88-key).
  final int fullFirstMidiNote;

  /// Middle C landmark at MIDI 60.
  final bool showMiddleCLandmark;
  final String middleCLandmarkText;

  @override
  ConsumerState<ScrollablePianoKeyboard> createState() =>
      _ScrollablePianoKeyboardState();
}

class _ScrollablePianoKeyboardState
    extends ConsumerState<ScrollablePianoKeyboard> {
  final ScrollController _ctl = ScrollController();

  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);
  Set<int> _lastSounding = const <int>{};

  ProviderSubscription<bool>? _idleSubscription;

  // Cached edge indicator state; updated deterministically from scroll + note changes.
  _EdgeState _edge = _EdgeState.none;

  // Most recent viewport width from LayoutBuilder.
  double? _lastViewportW;

  // True while a programmatic scroll animation is in flight.
  bool _isAutoScrolling = false;

  // Single source of truth for edge behavior.
  static const double _edgeMargin = 12.0;
  static const double _edgeHysteresis = 4.0;
  static double get _edgeHideMargin => _edgeMargin - _edgeHysteresis;
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
    _recomputeEdgeState();
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
        _recomputeEdgeState();
      }
      _recomputeEdgeState();
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

    final double? viewportW = _lastViewportW ?? context.size?.width;
    if (viewportW == null || viewportW <= 0) return;

    final whiteKeyW = _whiteKeyWForViewport(viewportW);
    final contentW = _contentWForWhiteKeyW(whiteKeyW);
    final geom = _buildGeometry();

    final sounding = widget.soundingMidiNotes;

    if (sounding.isNotEmpty) {
      double minX = double.infinity;
      double maxX = -double.infinity;

      for (final midi in sounding) {
        final r = geom.keyRectForMidi(
          midi: midi,
          whiteKeyW: whiteKeyW,
          totalWidth: contentW,
        );
        minX = math.min(minX, r.left);
        maxX = math.max(maxX, r.right);
      }

      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - (viewportW / 2.0)).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );

      _animateTo(target, duration: const Duration(milliseconds: 240));
      return;
    } else {
      // Center Middle C (MIDI 60) when idle.
      final r = geom.keyRectForMidi(
        midi: 60,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      final centerX = (r.left + r.right) / 2.0;
      final target = (centerX - (viewportW / 2.0)).clamp(
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
    if (!_setEquals(oldWidget.soundingMidiNotes, widget.soundingMidiNotes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recomputeEdgeState();
      });
    }

    // If visible key count changed (rotation), keep things stable by recentering.
    if (oldWidget.visibleWhiteKeyCount != widget.visibleWhiteKeyCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeFollow(force: true),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recomputeEdgeState();
      });
    }
  }

  void _onUserScroll() {
    _lastUserScroll = DateTime.now();
  }

  bool get _followSuppressed =>
      DateTime.now().difference(_lastUserScroll) < widget.followCooldown;

  PianoGeometry _buildGeometry() {
    return PianoGeometry(
      firstWhiteMidi: widget.fullFirstMidiNote,
      whiteKeyCount: widget.fullWhiteKeyCount,
    );
  }

  double _whiteKeyWForViewport(double viewportW) =>
      viewportW / widget.visibleWhiteKeyCount;

  double _contentWForWhiteKeyW(double whiteKeyW) =>
      whiteKeyW * widget.fullWhiteKeyCount;

  ({double minX, double maxX}) _rangeBoundsForSounding({
    required Set<int> sounding,
    required PianoGeometry geom,
    required double whiteKeyW,
    required double contentW,
  }) {
    double minX = double.infinity;
    double maxX = -double.infinity;

    for (final midi in sounding) {
      final r = geom.keyRectForMidi(
        midi: midi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      minX = math.min(minX, r.left);
      maxX = math.max(maxX, r.right);
    }

    return (minX: minX, maxX: maxX);
  }

  ({int? leftMidi, int? rightMidi}) _nearestOffscreenCandidates({
    required Set<int> sounding,
    required PianoGeometry geom,
    required double whiteKeyW,
    required double contentW,
    required double viewLeft,
    required double viewRight,
  }) {
    int? leftMidi;
    double leftBest =
        -double.infinity; // maximize rect.right (closest from left)

    int? rightMidi;
    double rightBest =
        double.infinity; // minimize rect.left (closest from right)

    for (final midi in sounding) {
      final r = geom.keyRectForMidi(
        midi: midi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );

      final offLeft = r.right < (viewLeft + _edgeMargin);
      if (offLeft && r.right > leftBest) {
        leftBest = r.right;
        leftMidi = midi;
      }

      final offRight = r.left > (viewRight - _edgeMargin);
      if (offRight && r.left < rightBest) {
        rightBest = r.left;
        rightMidi = midi;
      }
    }

    return (leftMidi: leftMidi, rightMidi: rightMidi);
  }

  void _recomputeEdgeState({double? viewportW}) {
    final double? w = viewportW ?? _lastViewportW;
    if (w == null || w <= 0) return;
    if (!_ctl.hasClients) {
      if (_edge != _EdgeState.none) {
        setState(() => _edge = _EdgeState.none);
      }
      return;
    }

    final whiteKeyW = _whiteKeyWForViewport(w);
    final contentW = _contentWForWhiteKeyW(whiteKeyW);
    final geom = _buildGeometry();

    final sounding = widget.soundingMidiNotes;
    if (sounding.isEmpty) {
      if (_edge != _EdgeState.none) {
        setState(() => _edge = _EdgeState.none);
      }
      return;
    }

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + w;

    final bounds = _rangeBoundsForSounding(
      sounding: sounding,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
    );
    final minX = bounds.minX;
    final maxX = bounds.maxX;

    final nearest = _nearestOffscreenCandidates(
      sounding: sounding,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
      viewLeft: viewLeft,
      viewRight: viewRight,
    );
    final leftMidi = nearest.leftMidi;
    final rightMidi = nearest.rightMidi;

    // Hysteresis: use a wider threshold to turn indicators on, and a slightly
    // tighter threshold to turn them off. This avoids flicker when notes hover
    // near the viewport edge during animated scroll.
    final showLeft = _edge.showLeft
        ? (leftMidi != null && minX < (viewLeft + _edgeHideMargin))
        : (leftMidi != null && minX < (viewLeft + _edgeMargin));

    final showRight = _edge.showRight
        ? (rightMidi != null && maxX > (viewRight - _edgeHideMargin))
        : (rightMidi != null && maxX > (viewRight - _edgeMargin));

    double? leftTarget;
    if (showLeft) {
      final r = geom.keyRectForMidi(
        midi: leftMidi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      leftTarget = (r.left - _edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    double? rightTarget;
    if (showRight) {
      final r = geom.keyRectForMidi(
        midi: rightMidi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      rightTarget = (r.right - w + _edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    final next = _EdgeState(
      showLeft: showLeft,
      showRight: showRight,
      leftTarget: leftTarget,
      rightTarget: rightTarget,
    );

    if (next != _edge) {
      setState(() => _edge = next);
    }
  }

  void _maybeFollow({bool force = false}) {
    if (!mounted) return;
    if (!widget.followInput && !force) return;
    if (_followSuppressed && !force) return;

    final next = widget.soundingMidiNotes;
    if (next.isEmpty) {
      _lastSounding = const <int>{};
      return;
    }

    final viewport = context.size;
    if (viewport == null || viewport.width <= 0) return;

    final viewportW = viewport.width;
    final whiteKeyW = _whiteKeyWForViewport(viewportW);
    final contentW = _contentWForWhiteKeyW(whiteKeyW);
    final geom = _buildGeometry();

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + viewportW;

    // Diff against the last known sounding set.
    final prev = _lastSounding;
    final added = next.difference(prev);
    final removed = prev.difference(next);

    // Update last set now that we’ve captured diffs.
    _lastSounding = Set<int>.from(next);

    // Decide whether anything is actually offscreen.
    final bounds = _rangeBoundsForSounding(
      sounding: next,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
    );

    final minX = bounds.minX;
    final maxX = bounds.maxX;
    final spreadW = maxX - minX;

    final offLeft = minX < (viewLeft + _edgeMargin);
    final offRight = maxX > (viewRight - _edgeMargin);

    if (!offLeft && !offRight && !force) return;

    // If the full range fits within the viewport (minus margins), center it.
    if (spreadW <= (viewportW - 2 * _edgeMargin)) {
      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - viewportW / 2.0).clamp(
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
          geom,
          viewportW,
          whiteKeyW,
          contentW,
          viewLeft,
          viewRight,
        );
      }
      return;
    }

    // Prefer reacting to newly added notes if they are offscreen.
    if (added.isNotEmpty && !force) {
      final addedNearest = _nearestOffscreenCandidates(
        sounding: added,
        geom: geom,
        whiteKeyW: whiteKeyW,
        contentW: contentW,
        viewLeft: viewLeft,
        viewRight: viewRight,
      );

      final addedLeft = addedNearest.leftMidi;
      final addedRight = addedNearest.rightMidi;

      if (addedLeft != null) {
        final r = geom.keyRectForMidi(
          midi: addedLeft,
          whiteKeyW: whiteKeyW,
          totalWidth: contentW,
        );
        final target = (r.left - _edgeMargin).clamp(
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
        final r = geom.keyRectForMidi(
          midi: addedRight,
          whiteKeyW: whiteKeyW,
          totalWidth: contentW,
        );
        final target = (r.right - viewportW + _edgeMargin).clamp(
          0.0,
          _ctl.position.maxScrollExtent,
        );
        final delta = (target - _ctl.offset).abs();
        if (delta >= _minMeaningfulDelta) {
          _animateTo(target);
        }
        return;
      }
    }

    // Otherwise reveal the nearest offscreen sounding key on the side that is offscreen.
    final nearest = _nearestOffscreenCandidates(
      sounding: next,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
      viewLeft: viewLeft,
      viewRight: viewRight,
    );

    double? target;
    if (offLeft && nearest.leftMidi != null) {
      final int midi = nearest.leftMidi!;
      final r = geom.keyRectForMidi(
        midi: midi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      target = (r.left - _edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
    } else if (offRight && nearest.rightMidi != null) {
      final int midi = nearest.rightMidi!;
      final r = geom.keyRectForMidi(
        midi: midi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      target = (r.right - viewportW + _edgeMargin).clamp(
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
    Set<int> sounding,
    PianoGeometry geom,
    double viewportW,
    double whiteKeyW,
    double contentW,
    double viewLeft,
    double viewRight,
  ) {
    if (sounding.isEmpty) return;

    int visibleCount = 0;
    for (final midi in sounding) {
      final rect = geom.keyRectForMidi(
        midi: midi,
        whiteKeyW: whiteKeyW,
        totalWidth: contentW,
      );
      final visible =
          rect.right > (viewLeft + _edgeMargin) &&
          rect.left < (viewRight - _edgeMargin);
      if (visible) visibleCount++;
    }

    final ratio = visibleCount / sounding.length;
    if (ratio >= 0.34) return;

    final bounds = _rangeBoundsForSounding(
      sounding: sounding,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
    );
    final minX = bounds.minX;
    final maxX = bounds.maxX;

    final viewCenter = (viewLeft + viewRight) / 2.0;
    final distToLeft = (viewCenter - (minX + whiteKeyW / 2.0)).abs();
    final distToRight = (viewCenter - (maxX - whiteKeyW / 2.0)).abs();

    double target;
    if (distToRight < distToLeft) {
      target = (maxX - viewportW + _edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    } else {
      target = (minX - _edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
    }

    final delta = (target - _ctl.offset).abs();
    if (delta < _minMeaningfulDelta) return;

    _animateTo(target);
  }

  Future<void> _handleChevronTap(AxisDirection direction) async {
    if (!mounted) return;
    if (_isAutoScrolling) return;
    if (!_ctl.hasClients) return;

    final sounding = widget.soundingMidiNotes;
    if (sounding.isEmpty) return;

    final double? viewportW = _lastViewportW ?? context.size?.width;
    if (viewportW == null || viewportW <= 0) return;

    final whiteKeyW = _whiteKeyWForViewport(viewportW);
    final contentW = _contentWForWhiteKeyW(whiteKeyW);
    final geom = _buildGeometry();

    final bounds = _rangeBoundsForSounding(
      sounding: sounding,
      geom: geom,
      whiteKeyW: whiteKeyW,
      contentW: contentW,
    );

    final minX = bounds.minX;
    final maxX = bounds.maxX;
    final spreadW = maxX - minX;

    // First preference: if the sounding range fits, center it.
    if (spreadW <= (viewportW - 2 * _edgeMargin)) {
      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - viewportW / 2.0).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
      await _animateTo(target);
      return;
    }

    // Otherwise: reveal the nearest hidden note on the tapped side.
    final fallbackTarget = direction == AxisDirection.left
        ? _edge.leftTarget
        : _edge.rightTarget;
    if (fallbackTarget == null) return;
    await _animateTo(fallbackTarget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;

        // Capture the latest viewport width for deterministic edge-state computation.
        // If it changes (rotation / resize), recompute after this frame.
        final prevW = _lastViewportW;
        if (prevW != viewportW) {
          _lastViewportW = viewportW;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _recomputeEdgeState(viewportW: viewportW);
          });
        }

        final whiteKeyW = viewportW / widget.visibleWhiteKeyCount;
        final contentW = whiteKeyW * widget.fullWhiteKeyCount;

        // Lift decorations enough to get above the nav indicator.
        final gesture = MediaQuery.viewPaddingOf(context).bottom;
        final base = (widget.height * 0.05).clamp(0.0, 5.0);
        final lift = gesture > 0 ? (gesture * 0.3).clamp(0.0, 9.0) : 0.0;
        final landmarkLift = base + lift;

        final decorations = <PianoKeyDecoration>[
          if (widget.showMiddleCLandmark)
            PianoKeyDecoration(
              midiNote: 60,
              label: widget.middleCLandmarkText,
              bottomLift: landmarkLift,
            ),
        ];

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _centerNow,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification && n.dragDetails != null) {
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
                      width: contentW,
                      height: widget.height,
                      child: PianoKeyboard(
                        whiteKeyCount: widget.fullWhiteKeyCount,
                        firstMidiNote: widget.fullFirstMidiNote,
                        soundingMidiNotes: widget.soundingMidiNotes,
                        height: widget.height,
                        decorations: decorations,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: _EdgeIndicator(
                  direction: AxisDirection.left,
                  visible: _edge.showLeft,
                  enabled: !_isAutoScrolling,
                  onTap: () => _handleChevronTap(AxisDirection.left),
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: _EdgeIndicator(
                  direction: AxisDirection.right,
                  visible: _edge.showRight,
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

class _EdgeIndicator extends StatelessWidget {
  const _EdgeIndicator({
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
              color: cs.surface.withValues(alpha: enabled ? 0.55 : 0.40),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? onTap : null,
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
    );
  }
}
