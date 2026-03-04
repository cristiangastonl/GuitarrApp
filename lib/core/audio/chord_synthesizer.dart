import 'dart:math' as math;
import 'dart:typed_data';

import '../data/chords_data.dart';

/// Generates WAV audio data for chord playback by mixing sine waves
/// at the chord's frequencies.
class ChordSynthesizer {
  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;
  static const int _numChannels = 1;

  final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 10;

  /// Returns a WAV file as bytes for the given chord (~1 second duration).
  Uint8List getChordWav(ChordData chord, {double durationSeconds = 1.0}) {
    if (_cache.containsKey(chord.name)) {
      return _cache[chord.name]!;
    }

    final wav = _synthesize(chord.frequencies, durationSeconds);

    // Evict oldest if cache full
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[chord.name] = wav;

    return wav;
  }

  Uint8List _synthesize(List<double> frequencies, double durationSeconds) {
    final numSamples = (_sampleRate * durationSeconds).round();
    final samples = Float64List(numSamples);

    if (frequencies.isEmpty) return _encodeWav(samples, numSamples);

    final amplitude = 1.0 / frequencies.length;

    // Envelope parameters (in samples)
    final attackSamples = (_sampleRate * 0.05).round(); // 50ms
    final releaseSamples = (_sampleRate * 0.35).round(); // 350ms
    final releaseStart = numSamples - releaseSamples;

    for (final freq in frequencies) {
      final angularFreq = 2.0 * math.pi * freq / _sampleRate;
      for (int i = 0; i < numSamples; i++) {
        // Sine wave
        final sample = math.sin(angularFreq * i) * amplitude;

        // Envelope
        double envelope;
        if (i < attackSamples) {
          envelope = i / attackSamples;
        } else if (i >= releaseStart) {
          final releaseProgress = (i - releaseStart) / releaseSamples;
          envelope = 1.0 - releaseProgress;
        } else {
          // Gentle decay during sustain
          final sustainProgress =
              (i - attackSamples) / (releaseStart - attackSamples);
          envelope = 1.0 - sustainProgress * 0.15;
        }

        samples[i] += sample * envelope;
      }
    }

    return _encodeWav(samples, numSamples);
  }

  Uint8List _encodeWav(Float64List samples, int numSamples) {
    final bytesPerSample = _bitsPerSample ~/ 8;
    final dataSize = numSamples * _numChannels * bytesPerSample;
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
    buffer.setUint32(offset, 16, Endian.little); // chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, _numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(
        offset, _sampleRate * _numChannels * bytesPerSample, Endian.little);
    offset += 4;
    buffer.setUint16(offset, _numChannels * bytesPerSample, Endian.little);
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

    // PCM samples
    for (int i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void clearCache() => _cache.clear();
}
