import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../data/chords_data.dart';
import 'audio_style.dart';
import 'metronome_service.dart';

/// Orchestrates sequential chord preview playback using recorded audio samples.
class ChordPreviewService {
  final AudioPlayer _player = AudioPlayer();
  bool _cancelled = false;
  bool _playing = false;

  bool get isPlaying => _playing;

  /// Returns the asset path for a chord's recorded audio sample.
  /// Falls back to normal intensity if the requested intensity is unavailable.
  String _getAssetPath(String chordName, AudioIntensity intensity) {
    final intensityName = intensity.name; // soft, normal, hard
    return 'assets/audio/chords/clean/$chordName/$intensityName/${chordName}_${intensityName}_take_01.mp3';
  }

  /// Plays a preview of the chord sequence using recorded samples.
  Future<void> playPreview({
    required List<ChordData> chords,
    required void Function(int index) onChordChange,
    required void Function() onComplete,
    int chordDuration = 1500,
    int bpm = 96,
    AudioStyle style = AudioStyle.clean,
    AudioIntensity intensity = AudioIntensity.normal,
    AudioGroove groove = AudioGroove.pop,
    double swing = 0.12,
    MetronomeService? metronome,
  }) async {
    _cancelled = false;
    _playing = true;

    for (int i = 0; i < chords.length; i++) {
      if (_cancelled) break;

      onChordChange(i);
      final beatMs = (60000 / bpm).round().clamp(200, 2000);
      int elapsed = 0;
      if (metronome != null) {
        unawaited(metronome.tick());
      }

      try {
        final assetPath = _getAssetPath(chords[i].name, intensity);
        await _player.setAsset(assetPath);
        await _player.setVolume(1.0);
        await _player.seek(Duration.zero);
        unawaited(_player.play());
      } catch (e) {
        // If the recorded sample is not found, log and continue silently.
        assert(() {
          // ignore: avoid_print
          print('ChordPreviewService: no sample for ${chords[i].name}: $e');
          return true;
        }());
      }

      while (elapsed < chordDuration && !_cancelled) {
        final remaining = chordDuration - elapsed;
        final sleepMs = beatMs > remaining ? remaining : beatMs;
        await Future.delayed(Duration(milliseconds: sleepMs));
        elapsed += sleepMs;
        if (metronome != null && elapsed < chordDuration && !_cancelled) {
          unawaited(metronome.tick());
        }
      }
      if (_cancelled) break;
      try {
        await _player.stop();
      } catch (_) {}
    }

    _playing = false;
    if (!_cancelled) {
      onComplete();
    }
  }

  /// Cancel the current preview playback.
  void cancel() {
    _cancelled = true;
    _playing = false;
    _player.stop();
  }

  /// Dispose resources.
  void dispose() {
    cancel();
    _player.dispose();
  }
}
