import 'package:flutter/material.dart';

class ExploreFadedScrollView extends StatefulWidget {
  const ExploreFadedScrollView({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<ExploreFadedScrollView> createState() => _ExploreFadedScrollViewState();
}

class _ExploreFadedScrollViewState extends State<ExploreFadedScrollView> {
  static const _fadeHeight = 24.0;

  final ScrollController _controller = ScrollController();
  bool _showTopFade = false;
  bool _showBottomFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void didUpdateWidget(covariant ExploreFadedScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFades);
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (!position.hasContentDimensions) return;

    const epsilon = 0.5;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final nextTop = maxExtent > epsilon && pixels > epsilon;
    final nextBottom = maxExtent > epsilon && pixels < maxExtent - epsilon;

    if (nextTop == _showTopFade && nextBottom == _showBottomFade) return;

    setState(() {
      _showTopFade = nextTop;
      _showBottomFade = nextBottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateFades();
        });

        return Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              padding: widget.padding,
              child: widget.child,
            ),
            if (_showTopFade)
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showBottomFade)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
