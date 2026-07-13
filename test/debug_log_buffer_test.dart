import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whatchord/core/core.dart';

void main() {
  final buffer = DebugLogBuffer.instance;

  setUp(buffer.clear);

  test('stamps lines and trims to capacity, oldest first out', () {
    for (var i = 0; i < DebugLogBuffer.capacity + 10; i++) {
      buffer.add('line $i');
    }

    final lines = buffer.snapshot();
    expect(lines, hasLength(DebugLogBuffer.capacity));
    expect(lines.first, endsWith('line 10'));
    expect(lines.last, endsWith('line ${DebugLogBuffer.capacity + 9}'));
    // HH:MM:SS.mmm prefix.
    expect(lines.first, matches(r'^\d{2}:\d{2}:\d{2}\.\d{3} line 10$'));
  });

  test('snapshot is detached from later additions', () {
    buffer.add('one');
    final lines = buffer.snapshot();
    buffer.add('two');

    expect(lines, hasLength(1));
    expect(() => lines.add('nope'), throwsUnsupportedError);
  });

  test('captureUnhandledErrors buffers the error and defers handling', () {
    final dispatcher = PlatformDispatcher.instance;
    final original = dispatcher.onError;
    addTearDown(() => dispatcher.onError = original);
    var previousHandlerCalls = 0;
    dispatcher.onError = (error, stack) {
      previousHandlerCalls++;
      return true;
    };

    buffer.captureUnhandledErrors();

    final handled = dispatcher.onError!(StateError('boom'), StackTrace.current);

    expect(handled, isTrue);
    expect(previousHandlerCalls, 1);
    expect(buffer.snapshot().single, contains('Bad state: boom'));
  });

  test('install tees debugPrint into the buffer, once', () {
    buffer.install();
    buffer.install(); // idempotent: must not double-wrap

    debugPrint('captured message');

    final lines = buffer.snapshot();
    expect(lines, hasLength(1));
    expect(lines.single, endsWith('captured message'));
  });
}
