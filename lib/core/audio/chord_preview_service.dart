import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../data/chords_data.dart';
import 'chord_synthesizer.dart';
import 'metronome_service.dart';

/// Orchestrates sequential chord preview playback using synthesized audio.
class ChordPreviewService {
  final AudioPlayer _player = AudioPlayer();
  final ChordSynthesizer _synthesizer = ChordSynthesizer();
  bool _cancelled = false;
  bool _playing = false;
  String? _tempDir;

  bool get isPlaying => _playing;

  Future<String> _getTempDir() async {
    if (_tempDir != null) return _tempDir!;
    final dir = await getTemporaryDirectory();
    _tempDir = dir.path;
    return _tempDir!;
  }

  /// Writes WAV bytes to a temp file and returns the path.
  Future<String> _writeWavFile(String chordName, Uint8List wav) async {
    final dir = await _getTempDir();
    final file = File('$dir/chord_preview_$chordName.wav');
    await file.writeAsBytes(wav, flush: true);
    return file.path;
  }

  /// Plays a preview of the chord sequence.
  Future<void> playPreview({
    required List<ChordData> chords,
    required void Function(int index) onChordChange,
    required void Function() onComplete,
    int chordDuration = 1500,
    MetronomeService? metronome,
  }) async {
    _cancelled = false;
    _playing = true;

    for (int i = 0; i < chords.length; i++) {
      if (_cancelled) break;

      onChordChange(i);
      metronome?.tick();

      final wav = _synthesizer.getChordWav(
        chords[i],
        durationSeconds: chordDuration / 1000.0,
      );

      try {
        final path = await _writeWavFile(chords[i].name, wav);
        await _player.setFilePath(path);
        await _player.setVolume(1.0);
        await _player.seek(Duration.zero);
        unawaited(_player.play());
      } catch (e) {
        print('ChordPreviewService playback error: $e');
      }

      await Future.delayed(Duration(milliseconds: chordDuration));
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
    _synthesizer.clearCache();
    _player.dispose();
  }
}
