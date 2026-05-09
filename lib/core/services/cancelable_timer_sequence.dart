import 'dart:async';

class CancelableTimerSequence {
  final Set<Timer> _timers = <Timer>{};
  int _generation = 0;

  int get generation => _generation;

  bool isCurrent(int generation) => generation == _generation;

  int restart() {
    cancel();
    return _generation;
  }

  void schedule(
    Duration delay,
    void Function(int generation) callback, {
    int? generation,
  }) {
    final scheduledGeneration = generation ?? _generation;
    if (delay <= Duration.zero) {
      if (isCurrent(scheduledGeneration)) {
        callback(scheduledGeneration);
      }
      return;
    }

    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (isCurrent(scheduledGeneration)) {
        callback(scheduledGeneration);
      }
    });
    _timers.add(timer);
  }

  void cancel() {
    _generation++;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void dispose() {
    cancel();
  }
}
