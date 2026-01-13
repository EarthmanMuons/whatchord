import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/piano_key_decoration.dart';
import '../../services/piano_geometry.dart';
import 'piano_keyboard.dart';

class ScrollablePianoKeyboard extends StatefulWidget {
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
  State<ScrollablePianoKeyboard> createState() =>
      _ScrollablePianoKeyboardState();
}

class _ScrollablePianoKeyboardState extends State<ScrollablePianoKeyboard> {
  final ScrollController _ctl = ScrollController();

  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);
  Set<int> _lastSounding = const <int>{};

  @override
  void initState() {
    super.initState();

    // Initial viewport: center on middle C (or sounding notes if already present).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerNow();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  bool get _followSuppressed =>
      DateTime.now().difference(_lastUserScroll) < widget.followCooldown;

  @override
  void didUpdateWidget(covariant ScrollablePianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If notes changed, consider recentering.
    if (!_setEquals(oldWidget.soundingMidiNotes, widget.soundingMidiNotes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
    }

    // If visible key count changed (rotation), keep things stable by recentering.
    if (oldWidget.visibleWhiteKeyCount != widget.visibleWhiteKeyCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeFollow(force: true),
      );
    }
  }

  void _onUserScroll() {
    _lastUserScroll = DateTime.now();
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

    const edgeMargin = 12.0;

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
        edgeMargin,
        viewLeft,
        viewRight,
        whiteKeyW,
        force: force,
      );
      return;
    }

    // Prefer reacting to newly added notes (most "natural" user intent signal).
    if (added.isNotEmpty) {
      // Pick the most extreme newly added note relative to the current viewport:
      // - if any added note is offscreen left, prioritize the leftmost added
      // - else if offscreen right, prioritize the rightmost added
      // - else if all are onscreen, do nothing
      int? targetMidi;

      // Compute added note extents.
      int minAdded = added.first;
      int maxAdded = added.first;
      for (final m in added) {
        if (m < minAdded) minAdded = m;
        if (m > maxAdded) maxAdded = m;
      }

      final minAddedX = xForMidi(minAdded);
      final maxAddedX = xForMidi(maxAdded) + whiteKeyW;

      final addedOffLeft = minAddedX < (viewLeft + edgeMargin);
      final addedOffRight = maxAddedX > (viewRight - edgeMargin);

      if (addedOffLeft) {
        targetMidi = minAdded;
      } else if (addedOffRight) {
        targetMidi = maxAdded;
      } else {
        // Added notes are already visible; no follow needed.
        return;
      }

      // Now decide *how* to scroll:
      // - If full range fits, we can show everything (center range).
      // - If it doesn't, only reveal the target note side minimally.
      final minMidi = next.reduce(math.min);
      final maxMidi = next.reduce(math.max);

      final minX = xForMidi(minMidi);
      final maxX = xForMidi(maxMidi) + whiteKeyW;
      final spreadW = maxX - minX;

      if (spreadW <= (viewportW - 2 * edgeMargin)) {
        // Fit: center entire range.
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

      // Not fit: reveal the specific added note side minimally.
      final tX = xForMidi(targetMidi);
      final tRightX = tX + whiteKeyW;

      final offLeft = tX < (viewLeft + edgeMargin);
      final offRight = tRightX > (viewRight - edgeMargin);

      // If, oddly, it’s not offscreen anymore, do nothing.
      if (!offLeft && !offRight) return;

      double target;
      if (offLeft) {
        target = (tX - edgeMargin).clamp(0.0, _ctl.position.maxScrollExtent);
      } else {
        target = (tRightX - viewportW + edgeMargin).clamp(
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

    // No additions; only removals. Avoid jumping, but optionally "unstick"
    // if the viewport contains almost none of the remaining active notes.
    if (removed.isNotEmpty) {
      _maybeReanchorAfterRemoval(
        next,
        xForMidi,
        viewportW,
        edgeMargin,
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

    // If both sides offscreen and it doesn't fit, don't move; chevrons handle it.
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
    // Heuristic: if fewer than 1/3 of remaining active keys are within viewport,
    // re-anchor to the densest side by revealing the nearest extreme.
    //
    // This fixes "played a low outlier, viewport moved left, released outlier,
    // now everything is on the right but we stay left."
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

    // Reveal whichever extreme is closer to the current viewport center.
    final minMidi = sounding.reduce(math.min);
    final maxMidi = sounding.reduce(math.max);

    final minX = xForMidi(minMidi);
    final maxX = xForMidi(maxMidi) + whiteKeyW;

    final viewCenter = (viewLeft + viewRight) / 2.0;
    final distToLeft = (viewCenter - (minX + whiteKeyW / 2.0)).abs();
    final distToRight = (viewCenter - (maxX - whiteKeyW / 2.0)).abs();

    double target;
    if (distToRight < distToLeft) {
      // Reveal right side
      target = (maxX - viewportW + edgeMargin).clamp(
        0.0,
        _ctl.position.maxScrollExtent,
      );
    } else {
      // Reveal left side
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final whiteKeyW = viewportW / widget.visibleWhiteKeyCount;
        final contentW = whiteKeyW * widget.fullWhiteKeyCount;

        final geom = PianoGeometry(
          firstWhiteMidi: widget.fullFirstMidiNote,
          whiteKeyCount: widget.fullWhiteKeyCount,
        );

        final decorations = <PianoKeyDecoration>[
          if (widget.showMiddleCLandmark)
            PianoKeyDecoration(midiNote: 60, label: widget.middleCLandmarkText),
        ];

        // Offscreen indicators.
        double minX = double.infinity;
        double maxX = -double.infinity;

        if (widget.soundingMidiNotes.isNotEmpty) {
          for (final midi in widget.soundingMidiNotes) {
            final idx = geom.whiteIndexForMidi(midi);
            final x = idx * whiteKeyW;
            minX = math.min(minX, x);
            maxX = math.max(maxX, x + whiteKeyW);
          }
        }

        final viewLeft = _ctl.hasClients ? _ctl.offset : 0.0;
        final viewRight = viewLeft + viewportW;

        final showLeft =
            widget.soundingMidiNotes.isNotEmpty && minX < (viewLeft - 1.0);
        final showRight =
            widget.soundingMidiNotes.isNotEmpty && maxX > (viewRight + 1.0);

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _centerNow,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // Only treat direct user interaction as suppression.
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

              // Left/right indicators (subtle).
              if (showLeft)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: _EdgeIndicator(
                    direction: AxisDirection.left,
                    onTap: () {
                      final target = (_ctl.offset - (viewportW * 0.65)).clamp(
                        0.0,
                        _ctl.position.maxScrollExtent,
                      );
                      _ctl.animateTo(
                        target,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              if (showRight)
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: _EdgeIndicator(
                    direction: AxisDirection.right,
                    onTap: () {
                      final target = (_ctl.offset + (viewportW * 0.65)).clamp(
                        0.0,
                        _ctl.position.maxScrollExtent,
                      );
                      _ctl.animateTo(
                        target,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    },
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
