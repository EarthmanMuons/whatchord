import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'soundfont_synth.dart';

class SoundFontSynthIsolateClient {
  SoundFontSynthIsolateClient._({
    required Isolate isolate,
    required SendPort sendPort,
    required ReceivePort responses,
    required StreamSubscription<dynamic> responsesSub,
  }) : _isolate = isolate,
       _sendPort = sendPort,
       _responses = responses,
       _responsesSub = responsesSub;

  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _responses;
  final StreamSubscription<dynamic> _responsesSub;

  final Map<int, Completer<Object?>> _pending = <int, Completer<Object?>>{};
  int _nextRequestId = 1;
  bool _disposed = false;

  static Future<SoundFontSynthIsolateClient> spawn({
    required Uint8List soundFontData,
    required int sampleRate,
  }) async {
    final ready = ReceivePort();
    final responses = ReceivePort();

    final isolate = await Isolate.spawn<_SoundFontSynthInit>(
      _soundFontSynthIsolateMain,
      _SoundFontSynthInit(
        readyPort: ready.sendPort,
        responsePort: responses.sendPort,
        soundFontData: soundFontData,
        sampleRate: sampleRate,
      ),
    );

    final sendPort = await ready.first as SendPort;
    ready.close();

    late final SoundFontSynthIsolateClient client;
    final responsesSub = responses.listen((message) {
      client._handleResponse(message);
    });
    client = SoundFontSynthIsolateClient._(
      isolate: isolate,
      sendPort: sendPort,
      responses: responses,
      responsesSub: responsesSub,
    );
    return client;
  }

  Future<void> setVolume(double volume) async {
    _sendWithoutResponse(<String, Object>{
      'command': 'setVolume',
      'volume': volume.clamp(0.0, 1.0),
    });
  }

  Future<void> noteOn(int midiNote) async {
    _sendWithoutResponse(<String, Object>{
      'command': 'noteOn',
      'midiNote': midiNote,
    });
  }

  Future<void> noteOff(int midiNote) async {
    _sendWithoutResponse(<String, Object>{
      'command': 'noteOff',
      'midiNote': midiNote,
    });
  }

  Future<void> noteOffAll() async {
    _sendWithoutResponse(<String, Object>{'command': 'noteOffAll'});
  }

  Future<Int16List> renderFrames(int frameCount) async {
    final response = await _request(<String, Object>{
      'command': 'render',
      'frameCount': frameCount,
    });
    final bytes = response as Uint8List;
    return bytes.buffer.asInt16List(
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ Int16List.bytesPerElement,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _sendWithoutResponse(<String, Object>{'command': 'dispose'});
    await _responsesSub.cancel();
    _responses.close();

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('SoundFont synth isolate disposed'));
      }
    }
    _pending.clear();

    _isolate.kill(priority: Isolate.immediate);
  }

  void _sendWithoutResponse(Map<String, Object> message) {
    if (_disposed) return;
    _sendPort.send(message);
  }

  Future<Object?> _request(Map<String, Object> message) {
    if (_disposed) {
      return Future<Object?>.error(
        StateError('SoundFont synth isolate already disposed'),
      );
    }

    final id = _nextRequestId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _sendPort.send(<String, Object>{'id': id, ...message});
    return completer.future;
  }

  void _handleResponse(dynamic message) {
    if (message is! Map<Object?, Object?>) return;
    final id = message['id'];
    if (id is! int) return;

    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;

    final error = message['error'];
    if (error is String) {
      completer.completeError(StateError(error));
      return;
    }

    completer.complete(message['result']);
  }
}

class _SoundFontSynthInit {
  const _SoundFontSynthInit({
    required this.readyPort,
    required this.responsePort,
    required this.soundFontData,
    required this.sampleRate,
  });

  final SendPort readyPort;
  final SendPort responsePort;
  final Uint8List soundFontData;
  final int sampleRate;
}

void _soundFontSynthIsolateMain(_SoundFontSynthInit init) {
  final synth = SoundFontSynth(
    soundFontData: init.soundFontData,
    sampleRate: init.sampleRate,
  );

  final commands = ReceivePort();
  init.readyPort.send(commands.sendPort);

  commands.listen((dynamic message) {
    if (message is! Map<Object?, Object?>) return;
    final command = message['command'];
    final id = message['id'];

    try {
      switch (command) {
        case 'setVolume':
          synth.setVolume((message['volume'] as num).toDouble());
          break;
        case 'noteOn':
          synth.noteOn(message['midiNote'] as int);
          break;
        case 'noteOff':
          synth.noteOff(message['midiNote'] as int);
          break;
        case 'noteOffAll':
          synth.noteOffAll();
          break;
        case 'render':
          final bytes = synth.renderFrames(message['frameCount'] as int);
          if (id is int) {
            init.responsePort.send(<String, Object?>{
              'id': id,
              'result': bytes,
            });
          }
          break;
        case 'dispose':
          synth.noteOffAll(immediate: true);
          commands.close();
          Isolate.exit();
      }
    } catch (e) {
      if (id is int) {
        init.responsePort.send(<String, Object?>{
          'id': id,
          'error': e.toString(),
        });
      }
    }
  });
}
