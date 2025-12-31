import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EdgeToEdgeController extends StatefulWidget {
  const EdgeToEdgeController({
    super.key,
    required this.child,
    required this.isLandscape,
  });

  final Widget child;
  final bool isLandscape;

  @override
  State<EdgeToEdgeController> createState() => _EdgeToEdgeControllerState();
}

class _EdgeToEdgeControllerState extends State<EdgeToEdgeController> {
  bool? _wasLandscape;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUiMode(widget.isLandscape);
  }

  @override
  void didUpdateWidget(covariant EdgeToEdgeController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLandscape != widget.isLandscape) {
      _updateSystemUiMode(widget.isLandscape);
    }
  }

  void _updateSystemUiMode(bool isLandscape) {
    if (_wasLandscape == isLandscape) return;
    _wasLandscape = isLandscape;

    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
