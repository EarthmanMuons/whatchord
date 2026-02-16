import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

/// Thin wrapper around dart_melty_soundfont.
class SoundFontSynth {
  SoundFontSynth({required Uint8List soundFontData, required int sampleRate})
    : _synth = Synthesizer.loadByteData(
        ByteData.sublistView(soundFontData),
        SynthesizerSettings(
          sampleRate: sampleRate,
          blockSize: 64,
          maximumPolyphony: 128,
          enableReverbAndChorus: true,
        ),
      ) {
    // Most General MIDI SoundFonts put piano at preset 0.
    _synth.selectPreset(channel: _channel, preset: 0);
  }

  static const int _channel = 0;

  final Synthesizer _synth;
  double _volume = 1.0;

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  void noteOn(int midiNote, {int velocity = 100}) {
    _synth.noteOn(
      channel: _channel,
      key: midiNote.clamp(0, 127),
      velocity: velocity.clamp(0, 127),
    );
  }

  void noteOff(int midiNote) {
    _synth.noteOff(channel: _channel, key: midiNote.clamp(0, 127));
  }

  void noteOffAll({bool immediate = false}) {
    _synth.noteOffAll(channel: _channel, immediate: immediate);
  }

  Uint8List renderFrames(int frameCount) {
    if (frameCount <= 0) return Uint8List(0);

    final pcm = ArrayInt16.zeros(numShorts: frameCount);
    _synth.renderMonoInt16(pcm);

    if (_volume < 1.0) {
      final samples = pcm.bytes.buffer.asInt16List(
        pcm.bytes.offsetInBytes,
        frameCount,
      );
      for (var i = 0; i < samples.length; i++) {
        final scaled = (samples[i] * _volume).round();
        samples[i] = scaled.clamp(-32768, 32767);
      }
    }

    return Uint8List.fromList(
      pcm.bytes.buffer.asUint8List(
        pcm.bytes.offsetInBytes,
        pcm.bytes.lengthInBytes,
      ),
    );
  }
}
