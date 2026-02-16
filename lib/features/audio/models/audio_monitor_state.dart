import 'package:meta/meta.dart';

import 'audio_monitor_status.dart';

@immutable
class AudioMonitorState {
  const AudioMonitorState({required this.status, this.errorMessage});

  const AudioMonitorState.disabled()
    : this(status: AudioMonitorStatus.disabled);

  final AudioMonitorStatus status;
  final String? errorMessage;

  AudioMonitorState copyWith({
    AudioMonitorStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioMonitorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
