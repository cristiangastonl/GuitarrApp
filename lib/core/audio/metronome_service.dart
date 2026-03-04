import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Synthesizes and plays a short click sound for metronome beats.
class MetronomeService {
  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;
  static const double _clickDuration = 0.12; // 120ms — audible on phone speakers
  static const double _clickFrequency = 880.0; // A5 — cuts through well

  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;

  /// Pre-generate and load the click file so tick() is instant.
  Future<void> init() async {
    final wav = _synthesizeClick();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/metronome_click.wav');
    await file.writeAsBytes(wav, flush: true);
    await _player.setFilePath(file.path);
    await _player.setVolume(1.0);
    _loaded = true;
  }

  /// Play a single metronome click.
  Future<void> tick() async {
    try {
      if (!_loaded) await init();
      await _player.seek(Duration.zero);
      _player.play();
    } catch (e) {
      // Silent fail — don't break gameplay
    }
  }

  Uint8List _synthesizeClick() {
    final numSamples = (_sampleRate * _clickDuration).round();
    final samples = Float64List(numSamples);
    final angularFreq = 2.0 * math.pi * _clickFrequency / _sampleRate;

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Sharp attack + exponential decay over 120ms
      final envelope = math.exp(-t * 40);
      samples[i] = math.sin(angularFreq * i) * envelope;
    }

    return _encodeWav(samples, numSamples);
  }

  Uint8List _encodeWav(Float64List samples, int numSamples) {
    final bytesPerSample = _bitsPerSample ~/ 8;
    final dataSize = numSamples * bytesPerSample;
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, _sampleRate * bytesPerSample, Endian.little);
    offset += 4;
    buffer.setUint16(offset, bytesPerSample, Endian.little);
    offset += 2;
    buffer.setUint16(offset, _bitsPerSample, Endian.little);
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (int i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player.dispose();
  }
}
