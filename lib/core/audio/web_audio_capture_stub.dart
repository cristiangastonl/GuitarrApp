// Stub for non-web platforms - delegates to MobileAudioCaptureService
// This file is used when the app runs on iOS/Android

import 'dart:async';
import 'dart:typed_data';
import 'mobile_audio_capture.dart' as mobile;

/// WebAudioCaptureService stub that delegates to MobileAudioCaptureService
/// on iOS/Android platforms
class WebAudioCaptureService {
  static final WebAudioCaptureService _instance =
      WebAudioCaptureService._internal();
  factory WebAudioCaptureService() => _instance;
  WebAudioCaptureService._internal();

  // Delegate to mobile implementation
  final mobile.MobileAudioCaptureService _mobileService =
      mobile.MobileAudioCaptureService();

  /// Stream of captured audio data with pitch detection
  Stream<AudioCaptureData> get audioDataStream =>
      _mobileService.audioDataStream.map((data) => AudioCaptureData(
            audioSamples: data.audioSamples,
            sampleRate: data.sampleRate,
            frequency: data.frequency,
            confidence: data.confidence,
            noteName: data.noteName,
            octave: data.octave,
            cents: data.cents,
            timestamp: data.timestamp,
          ));

  bool get isCapturing => _mobileService.isCapturing;

  /// Initialize the audio capture system
  Future<bool> initialize() async {
    return _mobileService.initialize();
  }

  /// Start capturing audio from microphone
  Future<bool> startCapture() async {
    return _mobileService.startCapture();
  }

  /// Stop capturing audio
  void stopCapture() {
    _mobileService.stopCapture();
  }

  /// Dispose resources
  void dispose() {
    _mobileService.dispose();
  }
}

/// Audio capture data with pitch detection results
/// This class mirrors the web version for API compatibility
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
