import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EdgeToEdgeController extends StatefulWidget {
  const EdgeToEdgeController({super.key, required this.child});

  final Widget child;

  @override
  State<EdgeToEdgeController> createState() => _EdgeToEdgeControllerState();
}

class _EdgeToEdgeControllerState extends State<EdgeToEdgeController> {
  @override
  void initState() {
    super.initState();
    // Idempotent: safe to call; aligns with Android 15+ default.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    // Keep bars transparent so edge-to-edge looks intentional.
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return widget.child;
  }
}
