import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Capped in-memory capture of [debugPrint] output so diagnostics can be
/// read, copied, and shared from a device without a tethered console
/// (profile builds in particular).
///
/// Deliberately a plain singleton rather than a provider: lines arrive from
/// arbitrary contexts (mid-build, mid-refresh-pass), where writing provider
/// state is unsafe. The viewer pulls a snapshot on demand instead of
/// listening.
class DebugLogBuffer {
  DebugLogBuffer._();

  static final DebugLogBuffer instance = DebugLogBuffer._();

  static const int capacity = 2000;

  final ListQueue<String> _lines = ListQueue<String>();
  bool _installed = false;
  bool _capturingUnhandledErrors = false;

  /// Tees the global [debugPrint] into this buffer, preserving the original
  /// console behavior. Call once at startup; later calls are no-ops.
  void install() {
    if (_installed) return;
    _installed = true;

    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) add(message);
      original(message, wrapWidth: wrapWidth);
    };
  }

  /// Also buffers unhandled asynchronous errors, which the engine reports
  /// natively and so bypass [debugPrint]. Framework errors need no hook:
  /// FlutterError's default handler already prints through [debugPrint].
  /// Preserves the engine's default handling. Call once at startup.
  void captureUnhandledErrors() {
    if (_capturingUnhandledErrors) return;
    _capturingUnhandledErrors = true;

    final previous = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      add('Unhandled exception: $error\n$stack');
      return previous?.call(error, stack) ?? false;
    };
  }

  void add(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    _lines.addLast('$timestamp $message');
    while (_lines.length > capacity) {
      _lines.removeFirst();
    }
  }

  /// Buffered lines, oldest first.
  List<String> snapshot() => List.unmodifiable(_lines);

  void clear() => _lines.clear();
}
