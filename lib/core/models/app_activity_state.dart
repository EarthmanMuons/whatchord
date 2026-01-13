import 'package:flutter/foundation.dart';

enum AppActivitySource { pointer, keyboard, midi, internal }

@immutable
class AppActivityState {
  const AppActivityState({
    required this.lastActivityAt,
    required this.isIdle,
    required this.idleAfter,
    required this.lastSource,
  });

  final DateTime lastActivityAt;
  final bool isIdle;
  final Duration idleAfter;
  final AppActivitySource? lastSource;

  AppActivityState copyWith({
    DateTime? lastActivityAt,
    bool? isIdle,
    Duration? idleAfter,
    AppActivitySource? lastSource,
  }) {
    return AppActivityState(
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isIdle: isIdle ?? this.isIdle,
      idleAfter: idleAfter ?? this.idleAfter,
      lastSource: lastSource ?? this.lastSource,
    );
  }
}
