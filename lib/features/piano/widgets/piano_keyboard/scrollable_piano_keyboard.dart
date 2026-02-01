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

  // Single source of truth for edge behavior.
  static const double _edgeMargin = 12.0;
  static const double _edgeHysteresis = 4.0;
  static double get _edgeHideMargin => _edgeMargin - _edgeHysteresis;

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

    final viewport = context.size;
    if (viewport == null || viewport.width <= 0) return;

    final viewportW = viewport.width;
    final whiteKeyW = viewportW / widget.visibleWhiteKeyCount;

    final geom = PianoGeometry(
      firstWhiteMidi: widget.fullFirstMidiNote,
      whiteKeyCount: widget.fullWhiteKeyCount,
    );

    double xForMidi(int midi) {
      final idx = geom.whiteIndexForMidi(midi);
      return idx * whiteKeyW;
    }

    final sounding = widget.soundingMidiNotes;

    // If notes are sounding, center them; otherwise center middle C (MIDI 60).
    final targetMidi = sounding.isNotEmpty ? null : 60;

    double centerX;
    if (sounding.isNotEmpty) {
      final minMidi = sounding.reduce(math.min);
      final maxMidi = sounding.reduce(math.max);
      centerX =
          (xForMidi(minMidi) + xForMidi(maxMidi)) / 2.0 + (whiteKeyW / 2.0);
    } else {
      centerX = xForMidi(targetMidi!) + (whiteKeyW / 2.0);
    }

    final target = (centerX - (viewportW / 2.0)).clamp(
      0.0,
      _ctl.position.maxScrollExtent,
    );

    _ctl.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollablePianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If notes changed, consider recentering.
    if (!_setEquals(oldWidget.soundingMidiNotes, widget.soundingMidiNotes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recomputeEdgeState(),
      );
    }

    // If visible key count changed (rotation), keep things stable by recentering.
    if (oldWidget.visibleWhiteKeyCount != widget.visibleWhiteKeyCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeFollow(force: true),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recomputeEdgeState(),
      );
    }
  }

  void _onUserScroll() {
    _lastUserScroll = DateTime.now();
  }

  bool get _followSuppressed =>
      DateTime.now().difference(_lastUserScroll) < widget.followCooldown;

  void _recomputeEdgeState() {
    // We need layout constraints; rely on the most recent build’s constraints via context.
    // If size is not available yet, keep prior state.
    final viewport = context.size;
    if (viewport == null || viewport.width <= 0) return;
    if (!_ctl.hasClients) {
      if (_edge != _EdgeState.none) {
        setState(() => _edge = _EdgeState.none);
      }
      return;
    }

    final viewportW = viewport.width;
    final whiteKeyW = viewportW / widget.visibleWhiteKeyCount;
    final contentW = whiteKeyW * widget.fullWhiteKeyCount;

    final geom = PianoGeometry(
      firstWhiteMidi: widget.fullFirstMidiNote,
      whiteKeyCount: widget.fullWhiteKeyCount,
    );

    final sounding = widget.soundingMidiNotes;
    if (sounding.isEmpty) {
      if (_edge != _EdgeState.none) {
        setState(() => _edge = _EdgeState.none);
      }
      return;
    }

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + viewportW;

    // Nearest offscreen candidates (closest to the viewport).
    int? leftMidi;
    double leftBest =
        -double.infinity; // maximize rect.right (closest from left)

    int? rightMidi;
    double rightBest =
        double.infinity; // minimize rect.left (closest from right)

    // Range bounds (useful for debugging and future follow unification).
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
      rightTarget = (r.right - viewportW + _edgeMargin).clamp(
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

  void _scrollToEdgeTarget(double? target) {
    if (!mounted) return;
    if (target == null) return;
    if (!_ctl.hasClients) return;

    final delta = (target - _ctl.offset).abs();
    if (delta < 1.0) return;

    _ctl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
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

    // We need viewport width and derived white key width.
    final viewport = context.size;
    if (viewport == null || viewport.width <= 0) return;

    final viewportW = viewport.width;
    final whiteKeyW = viewportW / widget.visibleWhiteKeyCount;

    final geom = PianoGeometry(
      firstWhiteMidi: widget.fullFirstMidiNote,
      whiteKeyCount: widget.fullWhiteKeyCount,
    );

    double xForMidi(int midi) {
      final idx = geom.whiteIndexForMidi(midi);
      return idx * whiteKeyW;
    }

    final viewLeft = _ctl.offset;
    final viewRight = viewLeft + viewportW;

    // Diff against the last known sounding set.
    final prev = _lastSounding;
    final added = next.difference(prev);
    final removed = prev.difference(next);

    // Update last set now that we’ve captured diffs.
    _lastSounding = Set<int>.from(next);

    // If forced (rotation), ignore diff semantics and use range logic.
    if (force || (added.isEmpty && removed.isEmpty)) {
      _followByRange(
        next,
        xForMidi,
        viewportW,
        _edgeMargin,
        viewLeft,
        viewRight,
        whiteKeyW,
        force: force,
      );
      return;
    }

    // Prefer reacting to newly added notes (most "natural" user intent signal).
    if (added.isNotEmpty) {
      int? targetMidi;

      int minAdded = added.first;
      int maxAdded = added.first;
      for (final m in added) {
        if (m < minAdded) minAdded = m;
        if (m > maxAdded) maxAdded = m;
      }

      final minAddedX = xForMidi(minAdded);
      final maxAddedX = xForMidi(maxAdded) + whiteKeyW;

      final addedOffLeft = minAddedX < (viewLeft + _edgeMargin);
      final addedOffRight = maxAddedX > (viewRight - _edgeMargin);

      if (addedOffLeft) {
        targetMidi = minAdded;
      } else if (addedOffRight) {
        targetMidi = maxAdded;
      } else {
        return;
      }

      final minMidi = next.reduce(math.min);
      final maxMidi = next.reduce(math.max);

      final minX = xForMidi(minMidi);
      final maxX = xForMidi(maxMidi) + whiteKeyW;
      final spreadW = maxX - minX;

      if (spreadW <= (viewportW - 2 * _edgeMargin)) {
        final centerX = (minX + maxX) / 2.0;
        final target = (centerX - viewportW / 2.0).clamp(
          0.0,
          _ctl.position.maxScrollExtent,
        );

        final delta = (target - _ctl.offset).abs();
        if (delta < 12.0) return;

        _ctl.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }

      final tX = xForMidi(targetMidi);
      final tRightX = tX + whiteKeyW;

      final offLeft = tX < (viewLeft + _edgeMargin);
      final offRight = tRightX > (viewRight - _edgeMargin);

      if (!offLeft && !offRight) return;

      double target;
      if (offLeft) {
        target = (tX - _edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
      } else {
        target = (tRightX - viewportW + _edgeMargin).clamp(
          0.0,
          _ctl.position.maxScrollExtent,
        );
      }

      final delta = (target - _ctl.offset).abs();
      if (delta < 12.0) return;

      _ctl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (removed.isNotEmpty) {
      _maybeReanchorAfterRemoval(
        next,
        xForMidi,
        viewportW,
        _edgeMargin,
        viewLeft,
        viewRight,
        whiteKeyW,
      );
    }
  }

  void _followByRange(
    Set<int> sounding,
    double Function(int midi) xForMidi,
    double viewportW,
    double edgeMargin,
    double viewLeft,
    double viewRight,
    double whiteKeyW, {
    required bool force,
  }) {
    if (sounding.isEmpty) return;

    final minMidi = sounding.reduce(math.min);
    final maxMidi = sounding.reduce(math.max);

    final minX = xForMidi(minMidi);
    final maxX = xForMidi(maxMidi) + whiteKeyW;
    final spreadW = maxX - minX;

    final offLeft = minX < (viewLeft + edgeMargin);
    final offRight = maxX > (viewRight - edgeMargin);

    if (!offLeft && !offRight) return;

    if (spreadW <= (viewportW - 2 * edgeMargin)) {
      final centerX = (minX + maxX) / 2.0;
      final target = (centerX - viewportW / 2.0).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );

      final delta = (target - _ctl.offset).abs();
      if (!force && delta < 12.0) return;

      _ctl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (offLeft && offRight) return;

    double target;
    if (offLeft) {
      target = (minX - edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
    } else {
      target = (maxX - viewportW + edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    }

    final delta = (target - _ctl.offset).abs();
    if (!force && delta < 12.0) return;

    _ctl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _maybeReanchorAfterRemoval(
    Set<int> sounding,
    double Function(int midi) xForMidi,
    double viewportW,
    double edgeMargin,
    double viewLeft,
    double viewRight,
    double whiteKeyW,
  ) {
    if (sounding.isEmpty) return;

    int visibleCount = 0;
    for (final midi in sounding) {
      final x = xForMidi(midi);
      final r = x + whiteKeyW;
      final visible =
          r > (viewLeft + edgeMargin) && x < (viewRight - edgeMargin);
      if (visible) visibleCount++;
    }

    final ratio = visibleCount / sounding.length;
    if (ratio >= 0.34) return;

    final minMidi = sounding.reduce(math.min);
    final maxMidi = sounding.reduce(math.max);

    final minX = xForMidi(minMidi);
    final maxX = xForMidi(maxMidi) + whiteKeyW;

    final viewCenter = (viewLeft + viewRight) / 2.0;
    final distToLeft = (viewCenter - (minX + whiteKeyW / 2.0)).abs();
    final distToRight = (viewCenter - (maxX - whiteKeyW / 2.0)).abs();

    double target;
    if (distToRight < distToLeft) {
      target = (maxX - viewportW + edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    } else {
      target = (minX - edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
    }

    final delta = (target - _ctl.offset).abs();
    if (delta < 12.0) return;

    _ctl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
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
              if (_edge.showLeft)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: _EdgeIndicator(
                    direction: AxisDirection.left,
                    onTap: () => _scrollToEdgeTarget(_edge.leftTarget),
                  ),
                ),
              if (_edge.showRight)
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: _EdgeIndicator(
                    direction: AxisDirection.right,
                    onTap: () => _scrollToEdgeTarget(_edge.rightTarget),
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
  const _EdgeIndicator({required this.direction, required this.onTap});

  final AxisDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final icon = direction == AxisDirection.left
        ? Icons.chevron_left
        : Icons.chevron_right;

    return Center(
      child: Material(
        color: cs.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Icon(
              icon,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
