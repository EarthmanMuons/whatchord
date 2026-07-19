import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord_app/core/core.dart';

void main() {
  test('zero and negative delays run inline for the current generation', () {
    final timers = CancelableTimerSequence();
    final fired = <int>[];
    timers.schedule(Duration.zero, fired.add);
    timers.schedule(const Duration(milliseconds: -5), fired.add);
    expect(fired, [timers.generation, timers.generation]);
    timers.dispose();
  });

  test('scheduled callbacks fire after their delay', () {
    fakeAsync((async) {
      final timers = CancelableTimerSequence();
      final fired = <String>[];
      timers.schedule(const Duration(milliseconds: 100), (_) {
        fired.add('a');
      });
      timers.schedule(const Duration(milliseconds: 200), (_) {
        fired.add('b');
      });

      async.elapse(const Duration(milliseconds: 150));
      expect(fired, ['a']);
      async.elapse(const Duration(milliseconds: 100));
      expect(fired, ['a', 'b']);
      timers.dispose();
    });
  });

  test('restart cancels pending timers and bumps the generation', () {
    fakeAsync((async) {
      final timers = CancelableTimerSequence();
      final fired = <String>[];
      final first = timers.restart();
      timers.schedule(const Duration(milliseconds: 100), (_) {
        fired.add('stale');
      }, generation: first);

      final second = timers.restart();
      expect(second, isNot(first));
      expect(timers.isCurrent(first), isFalse);
      timers.schedule(const Duration(milliseconds: 100), (_) {
        fired.add('fresh');
      }, generation: second);

      async.elapse(const Duration(seconds: 1));
      expect(fired, ['fresh']);
      timers.dispose();
    });
  });

  test('a stale generation suppresses even zero-delay callbacks', () {
    final timers = CancelableTimerSequence();
    final first = timers.restart();
    timers.restart();

    var fired = false;
    timers.schedule(Duration.zero, (_) => fired = true, generation: first);
    expect(fired, isFalse);
    timers.dispose();
  });

  test('cancel stops everything pending', () {
    fakeAsync((async) {
      final timers = CancelableTimerSequence();
      var fired = false;
      timers.schedule(const Duration(milliseconds: 100), (_) => fired = true);
      timers.cancel();
      async.elapse(const Duration(seconds: 1));
      expect(fired, isFalse);
      timers.dispose();
    });
  });
}
