import 'package:flutter/foundation.dart';

enum ActivitySource { pointer, keyboard, midi, internal }

@immutable
class ActivityState {
  const ActivityState({
    required this.lastActivityAt,
    required this.isIdle,
    required this.idleAfter,
    required this.lastSource,
  });

  final DateTime lastActivityAt;
  final bool isIdle;
  final Duration idleAfter;
  final ActivitySource? lastSource;

  ActivityState copyWith({
    DateTime? lastActivityAt,
    bool? isIdle,
    Duration? idleAfter,
    ActivitySource? lastSource,
  }) {
    return ActivityState(
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isIdle: isIdle ?? this.isIdle,
      idleAfter: idleAfter ?? this.idleAfter,
      lastSource: lastSource ?? this.lastSource,
    );
  }
}
