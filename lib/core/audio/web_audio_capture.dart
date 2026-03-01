// Web Audio Capture Service
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:async';
import 'dart:typed_data';

// JS Interop definitions - top level functions
@JS('window.audioCapture.initialize')
external JSPromise<JSBoolean> _jsInitialize();

@JS('window.audioCapture.startCapture')
external JSPromise<JSBoolean> _jsStartCapture();

@JS('window.audioCapture.stopCapture')
external void _jsStopCapture();

@JS('window.audioCapture.detectPitch')
external JSObject? _detectPitchJs(JSArray audioData, JSNumber sampleRate);

@JS('window.audioCapture.frequencyToNote')
external JSObject? _frequencyToNoteJs(JSNumber frequency);

// Callback setter
@JS()
external set _audioOnData(JSFunction? callback);

@JS('window.audioCapture')
external JSObject get _audioCapture;

// Extension for accessing JS object properties
extension _JSObjectProps on JSObject {
  external JSAny? operator [](String property);
  external void operator []=(String property, JSAny? value);
}

/// Web Audio Capture Service for Flutter Web
class WebAudioCaptureService {
  static final WebAudioCaptureService _instance = WebAudioCaptureService._internal();
  factory WebAudioCaptureService() => _instance;
  WebAudioCaptureService._internal();

  bool _isInitialized = false;
  bool _isCapturing = false;

  final StreamController<AudioCaptureData> _audioDataController =
      StreamController<AudioCaptureData>.broadcast();

  /// Stream of captured audio data with pitch detection
  Stream<AudioCaptureData> get audioDataStream => _audioDataController.stream;

  bool get isCapturing => _isCapturing;

  /// Initialize the audio context
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _jsInitialize().toDart;
      _isInitialized = result.toDart;
      print('Web audio initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('Error initializing web audio: $e');
      return false;
    }
  }

  /// Start capturing audio from microphone
  Future<bool> startCapture() async {
    if (_isCapturing) return true;

    try {
      final result = await _jsStartCapture().toDart;
      _isCapturing = result.toDart;

      if (_isCapturing) {
        _setupJsCallback();
      }

      print('Web audio capture started: $_isCapturing');
      return _isCapturing;
    } catch (e) {
      print('Error starting audio capture: $e');
      return false;
    }
  }

  /// Set up the JavaScript callback for audio data
  void _setupJsCallback() {
    // Create callback function
    void handleAudioData(JSArray audioDataJs, JSNumber sampleRateJs) {
      _processAudioData(audioDataJs, sampleRateJs);
    }

    // Set callback on audioCapture object
    _audioCapture['onAudioData'] = handleAudioData.toJS;
  }

  /// Process audio data from JavaScript
  void _processAudioData(JSArray audioDataJs, JSNumber sampleRateJs) {
    if (!_isCapturing) return;

    try {
      final sampleRate = sampleRateJs.toDartDouble.toInt();

      // Call JavaScript pitch detection
      final pitchResult = _detectPitchJs(audioDataJs, sampleRateJs);

      double frequency = 0;
      double confidence = 0;

      if (pitchResult != null) {
        final freqVal = pitchResult['frequency'];
        final confVal = pitchResult['confidence'];

        if (freqVal != null) {
          frequency = (freqVal as JSNumber).toDartDouble;
        }
        if (confVal != null) {
          confidence = (confVal as JSNumber).toDartDouble;
        }
      }

      // Get note info if frequency is valid
      String? noteName;
      int? octave;
      int? cents;

      if (frequency > 0 && confidence > 0.3) {
        final noteInfo = _frequencyToNoteJs(frequency.toJS);
        if (noteInfo != null) {
          final nameVal = noteInfo['name'];
          final octaveVal = noteInfo['octave'];
          final centsVal = noteInfo['cents'];

          if (nameVal != null) {
            noteName = (nameVal as JSString).toDart;
          }
          if (octaveVal != null) {
            octave = (octaveVal as JSNumber).toDartInt;
          }
          if (centsVal != null) {
            cents = (centsVal as JSNumber).toDartInt;
          }
        }
      }

      final captureData = AudioCaptureData(
        audioSamples: Float32List(0),
        sampleRate: sampleRate,
        frequency: frequency,
        confidence: confidence,
        noteName: noteName,
        octave: octave,
        cents: cents,
        timestamp: DateTime.now(),
      );

      if (captureData.hasPitch) {
        _audioDataController.add(captureData);
      }
    } catch (e) {
      print('Error processing audio data: $e');
    }
  }

  /// Stop capturing audio
  void stopCapture() {
    if (!_isCapturing) return;

    _audioCapture['onAudioData'] = null;
    _jsStopCapture();
    _isCapturing = false;
    print('Web audio capture stopped');
  }

  /// Dispose resources
  void dispose() {
    stopCapture();
    _audioDataController.close();
  }
}

/// Audio capture data with pitch detection results
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
  String? get fullNoteName => noteName != null && octave != null
      ? '$noteName$octave'
      : null;

  /// Is this a valid pitch detection?
  bool get hasPitch => frequency > 0 && confidence > 0.5;

  @override
  String toString() => 'AudioCaptureData(note: $fullNoteName, freq: ${frequency.toStringAsFixed(1)}Hz, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
