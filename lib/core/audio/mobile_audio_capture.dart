// Mobile Audio Capture Service using flutter_sound
// This service handles audio capture on iOS and Android platforms

import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

/// Audio capture data with pitch detection results (same interface as web)
class AudioCaptureData {
  final Float32List audioSamples;
  final int sampleRate;
  final double frequency;
  final double confidence;
  final String? noteName;
  final int? octave;
  final int? cents;
  final DateTime timestamp;

  const AudioCaptureData({
    required this.audioSamples,
    required this.sampleRate,
    required this.frequency,
    required this.confidence,
    this.noteName,
    this.octave,
    this.cents,
    required this.timestamp,
  });

  /// Full note name (e.g., "E2", "A4")
  String? get fullNoteName =>
      noteName != null && octave != null ? '$noteName$octave' : null;

  /// Is this a valid pitch detection?
  bool get hasPitch => frequency > 0 && confidence > 0.5;

  @override
  String toString() =>
      'AudioCaptureData(note: $fullNoteName, freq: ${frequency.toStringAsFixed(1)}Hz, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Mobile Audio Capture Service for iOS/Android using flutter_sound
class MobileAudioCaptureService {
  static final MobileAudioCaptureService _instance =
      MobileAudioCaptureService._internal();
  factory MobileAudioCaptureService() => _instance;
  MobileAudioCaptureService._internal();

  // Flutter Sound recorder
  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _recordingDataController;

  // State management
  bool _isInitialized = false;
  bool _isCapturing = false;

  // Audio parameters
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;

  // Audio data stream
  final StreamController<AudioCaptureData> _audioDataController =
      StreamController<AudioCaptureData>.broadcast();

  // Buffer for accumulating audio samples
  final List<double> _audioBuffer = [];

  // Adaptive noise gate
  double _noiseFloor = 0.02;
  int _silenceFrames = 0;
  bool _onsetDetected = false;

  // Temporal smoothing ring buffer (last 3 pitch results)
  static const int _smoothingFrames = 3;
  final List<_PitchResult> _recentPitches = [];

  /// Stream of captured audio data with pitch detection
  Stream<AudioCaptureData> get audioDataStream => _audioDataController.stream;

  bool get isCapturing => _isCapturing;
  bool get isInitialized => _isInitialized;

  /// Initialize the audio capture system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _log('Microphone permission denied');
        return false;
      }

      // Initialize audio session for iOS
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Close previous recorder if exists (clean up stale state)
      if (_recorder != null) {
        try {
          await _recorder!.closeRecorder();
        } catch (_) {}
        _recorder = null;
      }

      // Create and open the recorder
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();

      // Set subscription duration for real-time data
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 50),
      );

      _isInitialized = true;
      _log('Mobile audio initialized successfully');
      return true;
    } catch (e) {
      _log('Error initializing mobile audio: $e');
      return false;
    }
  }

  /// Start capturing audio from microphone
  Future<bool> startCapture() async {
    if (_isCapturing) return true;
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Stop any previous capture cleanly
      if (_recordingDataController != null) {
        try {
          await _recordingDataController!.close();
        } catch (_) {}
        _recordingDataController = null;
      }

      // Clear buffer and smoothing state
      _audioBuffer.clear();
      _recentPitches.clear();
      _noiseFloor = 0.02;
      _silenceFrames = 0;
      _onsetDetected = false;

      // Create stream controller for recording data
      _recordingDataController = StreamController<Uint8List>();

      // Listen to recording data stream
      _recordingDataController!.stream.listen(
        _processAudioData,
        onError: (error) => _log('Recording stream error: $error'),
      );

      // Start recording to stream with PCM format
      await _recorder!.startRecorder(
        toStream: _recordingDataController!.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: _sampleRate,
      );

      _isCapturing = true;
      _log('Mobile audio capture started');
      return true;
    } catch (e) {
      _log('Error starting mobile audio capture: $e');
      return false;
    }
  }

  /// Process raw audio data from the recorder
  void _processAudioData(Uint8List rawData) {
    if (!_isCapturing) return;

    try {
      // Convert PCM16 bytes to normalized float samples
      final samples = _convertPcm16ToFloat(rawData);

      // Add to buffer
      _audioBuffer.addAll(samples);

      // Process when we have enough samples
      if (_audioBuffer.length >= _bufferSize) {
        final bufferToProcess =
            _audioBuffer.sublist(0, _bufferSize).toList();
        _audioBuffer.removeRange(0, _bufferSize ~/ 2); // 50% overlap

        // Calculate RMS for noise gate
        final rms = _calculateRms(bufferToProcess);

        // Adaptive noise gate
        final gateThreshold = math.max(0.02, _noiseFloor * 2.0);

        if (rms < gateThreshold) {
          // Silence: update noise floor with EMA
          _silenceFrames++;
          _noiseFloor = _noiseFloor * 0.95 + rms * 0.05;

          // If we were tracking an onset, clear smoothing buffer
          if (_onsetDetected) {
            _onsetDetected = false;
            _recentPitches.clear();
          }
          return;
        }

        // Onset detection: transition from silence to sound
        if (_silenceFrames > 3 && !_onsetDetected) {
          _onsetDetected = true;
          _recentPitches.clear();
        }
        _silenceFrames = 0;

        // Perform YIN pitch detection
        final pitchResult = _detectPitchYin(bufferToProcess);

        // Add to smoothing buffer
        _recentPitches.add(pitchResult);
        if (_recentPitches.length > _smoothingFrames) {
          _recentPitches.removeAt(0);
        }

        // Check if we have consistent pitches for smoothing
        final smoothed = _getSmoothedPitch();
        if (smoothed == null) return;

        // Get note info
        final noteInfo = _frequencyToNote(smoothed.frequency);

        final captureData = AudioCaptureData(
          audioSamples: Float32List.fromList(
              bufferToProcess.map((e) => e.toDouble()).toList()),
          sampleRate: _sampleRate,
          frequency: smoothed.frequency,
          confidence: smoothed.confidence,
          noteName: noteInfo?.name,
          octave: noteInfo?.octave,
          cents: noteInfo?.cents,
          timestamp: DateTime.now(),
        );

        if (captureData.hasPitch) {
          _audioDataController.add(captureData);
        }
      }
    } catch (e) {
      _log('Error processing audio data: $e');
    }
  }

  /// Get smoothed pitch from recent frames.
  /// Requires [_smoothingFrames] consecutive frames with freq > 0,
  /// confidence > 0.5, and frequencies within 80 cents of each other.
  _PitchResult? _getSmoothedPitch() {
    if (_recentPitches.length < _smoothingFrames) return null;

    // Check all recent pitches are valid
    for (final p in _recentPitches) {
      if (p.frequency <= 0 || p.confidence < 0.5) return null;
    }

    // Check all frequencies are within 80 cents of each other
    for (int i = 0; i < _recentPitches.length; i++) {
      for (int j = i + 1; j < _recentPitches.length; j++) {
        final cents = 1200 *
            (math.log(_recentPitches[i].frequency /
                    _recentPitches[j].frequency) /
                math.ln2)
            .abs();
        if (cents > 80) return null;
      }
    }

    // Return median frequency with average confidence
    final freqs = _recentPitches.map((p) => p.frequency).toList()..sort();
    final medianFreq = freqs[freqs.length ~/ 2];
    final avgConfidence =
        _recentPitches.map((p) => p.confidence).reduce((a, b) => a + b) /
            _recentPitches.length;

    return _PitchResult(frequency: medianFreq, confidence: avgConfidence);
  }

  /// Convert PCM16 raw bytes to normalized float samples (-1.0 to 1.0)
  List<double> _convertPcm16ToFloat(Uint8List rawData) {
    final samples = <double>[];
    final byteData = ByteData.view(rawData.buffer);

    for (var i = 0; i < rawData.length - 1; i += 2) {
      // Read 16-bit signed integer (little-endian)
      final sample = byteData.getInt16(i, Endian.little);
      // Normalize to -1.0 to 1.0
      samples.add(sample / 32768.0);
    }

    return samples;
  }

  /// Detect pitch using YIN algorithm.
  /// YIN finds the first dip in the cumulative mean normalized difference
  /// function below a threshold, which correctly identifies the fundamental
  /// frequency instead of confusing it with harmonics.
  _PitchResult _detectPitchYin(List<double> samples) {
    const yinThreshold = 0.15;
    const minPeriod = 20; // ~2200 Hz
    const maxPeriod = 1000; // ~44 Hz (lowest guitar note E2)

    final maxLag = math.min(maxPeriod, samples.length ~/ 2);

    // Step 1: Difference function
    final diff = List<double>.filled(maxLag, 0.0);
    for (int tau = 1; tau < maxLag; tau++) {
      double sum = 0.0;
      for (int i = 0; i < samples.length - tau; i++) {
        final d = samples[i] - samples[i + tau];
        sum += d * d;
      }
      diff[tau] = sum;
    }

    // Step 2: Cumulative mean normalized difference function (CMNDF)
    final cmndf = List<double>.filled(maxLag, 0.0);
    cmndf[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau < maxLag; tau++) {
      runningSum += diff[tau];
      cmndf[tau] = runningSum > 0 ? diff[tau] * tau / runningSum : 1.0;
    }

    // Step 3: Absolute threshold - find first dip below threshold
    int bestPeriod = -1;
    for (int tau = minPeriod; tau < maxLag - 1; tau++) {
      if (cmndf[tau] < yinThreshold) {
        // Find the local minimum in this dip
        while (tau + 1 < maxLag && cmndf[tau + 1] < cmndf[tau]) {
          tau++;
        }
        bestPeriod = tau;
        break;
      }
    }

    // No period found below threshold
    if (bestPeriod < 0) {
      return _PitchResult(frequency: 0, confidence: 0);
    }

    // Step 4: Parabolic interpolation for sub-sample accuracy
    final refinedPeriod = _refinePeriodParabolicYin(cmndf, bestPeriod);

    // Confidence = 1 - cmndf value at best period
    final confidence = (1.0 - cmndf[bestPeriod]).clamp(0.0, 1.0);

    if (confidence < 0.5) {
      return _PitchResult(frequency: 0, confidence: 0);
    }

    final frequency = _sampleRate / refinedPeriod;
    return _PitchResult(frequency: frequency, confidence: confidence);
  }

  /// Parabolic interpolation on CMNDF for sub-sample period refinement
  double _refinePeriodParabolicYin(List<double> cmndf, int period) {
    if (period <= 1 || period >= cmndf.length - 1) {
      return period.toDouble();
    }

    final alpha = cmndf[period - 1];
    final beta = cmndf[period];
    final gamma = cmndf[period + 1];

    final denom = alpha - 2 * beta + gamma;
    if (denom.abs() < 1e-10) {
      return period.toDouble();
    }

    final delta = 0.5 * (alpha - gamma) / denom;
    return period + delta;
  }

  /// Calculate RMS (Root Mean Square) of samples
  double _calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double sumOfSquares = 0.0;
    for (final sample in samples) {
      sumOfSquares += sample * sample;
    }

    return math.sqrt(sumOfSquares / samples.length);
  }

  /// Convert frequency to musical note information
  _NoteInfo? _frequencyToNote(double frequency) {
    if (frequency <= 0) return null;

    // A4 = 440 Hz reference
    const a4Frequency = 440.0;
    const a4NoteNumber = 69; // MIDI note number for A4

    // Calculate MIDI note number
    final noteNumber =
        (12 * math.log(frequency / a4Frequency) / math.ln2 + a4NoteNumber)
            .round();

    if (noteNumber < 0 || noteNumber > 127) return null;

    // Note names
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final noteName = noteNames[noteNumber % 12];
    final octave = (noteNumber ~/ 12) - 1;

    // Calculate expected frequency for this note
    final expectedFrequency = a4Frequency *
        math.pow(2, (noteNumber - a4NoteNumber) / 12.0);

    // Calculate cents deviation
    final cents =
        (1200 * math.log(frequency / expectedFrequency) / math.ln2).round();

    return _NoteInfo(name: noteName, octave: octave, cents: cents);
  }

  /// Stop capturing audio
  Future<void> stopCapture() async {
    if (!_isCapturing) return;
    _isCapturing = false;

    try {
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
    } catch (e) {
      _log('Error stopping recorder: $e');
    }

    try {
      await _recordingDataController?.close();
    } catch (_) {}
    _recordingDataController = null;
    _audioBuffer.clear();
    _recentPitches.clear();
    _log('Mobile audio capture stopped');
  }

  /// Dispose resources
  void dispose() {
    stopCapture();
    _recorder?.closeRecorder();
    _recorder = null;
    _audioDataController.close();
    _isInitialized = false;
  }

  /// Debug logging (only in debug mode)
  void _log(String message) {
    assert(() {
      // ignore: avoid_print
      print('[MobileAudioCapture] $message');
      return true;
    }());
  }
}

/// Internal class for pitch detection results
class _PitchResult {
  final double frequency;
  final double confidence;

  _PitchResult({required this.frequency, required this.confidence});
}

/// Internal class for note information
class _NoteInfo {
  final String name;
  final int octave;
  final int cents;

  _NoteInfo({required this.name, required this.octave, required this.cents});
}
