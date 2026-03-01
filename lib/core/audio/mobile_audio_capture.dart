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
      // Clear buffer
      _audioBuffer.clear();

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

        // Perform pitch detection
        final pitchResult = _detectPitch(bufferToProcess);

        if (pitchResult.frequency > 0 && pitchResult.confidence > 0.3) {
          // Get note info
          final noteInfo = _frequencyToNote(pitchResult.frequency);

          final captureData = AudioCaptureData(
            audioSamples: Float32List.fromList(
                bufferToProcess.map((e) => e.toDouble()).toList()),
            sampleRate: _sampleRate,
            frequency: pitchResult.frequency,
            confidence: pitchResult.confidence,
            noteName: noteInfo?.name,
            octave: noteInfo?.octave,
            cents: noteInfo?.cents,
            timestamp: DateTime.now(),
          );

          if (captureData.hasPitch) {
            _audioDataController.add(captureData);
          }
        }
      }
    } catch (e) {
      _log('Error processing audio data: $e');
    }
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

  /// Detect pitch using autocorrelation (YIN-like algorithm)
  _PitchResult _detectPitch(List<double> samples) {
    // Apply window function
    final windowedSamples = _applyHannWindow(samples);

    // Calculate RMS to check if there's significant audio
    final rms = _calculateRms(windowedSamples);
    if (rms < 0.01) {
      return _PitchResult(frequency: 0, confidence: 0);
    }

    // Autocorrelation-based pitch detection
    const minPeriod = 20; // ~2200 Hz (highest guitar note)
    const maxPeriod = 1000; // ~44 Hz (lowest guitar note E2)

    double bestCorrelation = 0.0;
    int bestPeriod = minPeriod;

    final maxLag = math.min(maxPeriod, samples.length ~/ 2);

    for (int period = minPeriod; period < maxLag; period++) {
      double correlation = 0.0;
      double energyA = 0.0;
      double energyB = 0.0;

      for (int i = 0; i < samples.length - period; i++) {
        correlation += windowedSamples[i] * windowedSamples[i + period];
        energyA += windowedSamples[i] * windowedSamples[i];
        energyB +=
            windowedSamples[i + period] * windowedSamples[i + period];
      }

      // Normalize correlation
      final energy = math.sqrt(energyA * energyB);
      if (energy > 0) {
        correlation /= energy;
      }

      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestPeriod = period;
      }
    }

    // Refine period using parabolic interpolation
    final refinedPeriod = _refinePeriodParabolic(
      windowedSamples,
      bestPeriod,
      bestCorrelation,
    );

    final frequency =
        bestCorrelation > 0.3 ? _sampleRate / refinedPeriod : 0.0;
    final confidence = bestCorrelation.clamp(0.0, 1.0);

    return _PitchResult(frequency: frequency, confidence: confidence);
  }

  /// Apply Hann window to reduce spectral leakage
  List<double> _applyHannWindow(List<double> samples) {
    final windowed = <double>[];
    final n = samples.length;

    for (int i = 0; i < n; i++) {
      final window = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
      windowed.add(samples[i] * window);
    }

    return windowed;
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

  /// Refine period using parabolic interpolation
  double _refinePeriodParabolic(
    List<double> samples,
    int period,
    double correlation,
  ) {
    if (period <= 1 || period >= samples.length ~/ 2 - 1) {
      return period.toDouble();
    }

    // Calculate correlation at adjacent periods
    final corrPrev = _calculateCorrelationAt(samples, period - 1);
    final corrNext = _calculateCorrelationAt(samples, period + 1);

    // Parabolic interpolation
    final denom = corrPrev - 2 * correlation + corrNext;
    if (denom.abs() < 1e-10) {
      return period.toDouble();
    }

    final delta = 0.5 * (corrPrev - corrNext) / denom;
    return period + delta;
  }

  /// Calculate autocorrelation at a specific lag
  double _calculateCorrelationAt(List<double> samples, int lag) {
    if (lag <= 0 || lag >= samples.length ~/ 2) return 0.0;

    double correlation = 0.0;
    double energyA = 0.0;
    double energyB = 0.0;

    for (int i = 0; i < samples.length - lag; i++) {
      correlation += samples[i] * samples[i + lag];
      energyA += samples[i] * samples[i];
      energyB += samples[i + lag] * samples[i + lag];
    }

    final energy = math.sqrt(energyA * energyB);
    return energy > 0 ? correlation / energy : 0.0;
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
  void stopCapture() {
    if (!_isCapturing) return;

    try {
      _recorder?.stopRecorder();
      _recordingDataController?.close();
      _recordingDataController = null;
      _audioBuffer.clear();
      _isCapturing = false;
      _log('Mobile audio capture stopped');
    } catch (e) {
      _log('Error stopping mobile audio capture: $e');
    }
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
