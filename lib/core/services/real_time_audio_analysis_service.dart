import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real-Time Audio Analysis Service
/// Provides comprehensive audio analysis including pitch detection, tone analysis,
/// dynamic range monitoring, and frequency spectrum visualization for guitar practice
class RealTimeAudioAnalysisService {
  // Analysis state
  bool _isAnalyzing = false;
  AudioAnalysisSettings _settings = AudioAnalysisSettings.defaultSettings();
  
  // Audio parameters
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;
  static const int _hopSize = 512;
  static const double _nyquistFrequency = _sampleRate / 2;
  
  // Analysis results
  PitchDetectionResult? _lastPitchResult;
  ToneAnalysisResult? _lastToneResult;
  DynamicRangeResult? _lastDynamicResult;
  FrequencySpectrumResult? _lastSpectrumResult;
  
  // Buffer management
  final List<double> _audioBuffer = [];
  final List<PitchDetectionResult> _pitchHistory = [];
  final List<ToneAnalysisResult> _toneHistory = [];
  
  // Event streams
  final StreamController<PitchDetectionResult> _pitchController = StreamController.broadcast();
  final StreamController<ToneAnalysisResult> _toneController = StreamController.broadcast();
  final StreamController<DynamicRangeResult> _dynamicController = StreamController.broadcast();
  final StreamController<FrequencySpectrumResult> _spectrumController = StreamController.broadcast();
  final StreamController<TuningFeedback> _tuningController = StreamController.broadcast();
  
  /// Stream of pitch detection results
  Stream<PitchDetectionResult> get pitchResults => _pitchController.stream;
  
  /// Stream of tone analysis results
  Stream<ToneAnalysisResult> get toneResults => _toneController.stream;
  
  /// Stream of dynamic range analysis
  Stream<DynamicRangeResult> get dynamicResults => _dynamicController.stream;
  
  /// Stream of frequency spectrum data
  Stream<FrequencySpectrumResult> get spectrumResults => _spectrumController.stream;
  
  /// Stream of tuning feedback
  Stream<TuningFeedback> get tuningFeedback => _tuningController.stream;
  
  // Getters
  bool get isAnalyzing => _isAnalyzing;
  AudioAnalysisSettings get settings => _settings;
  PitchDetectionResult? get lastPitchResult => _lastPitchResult;
  ToneAnalysisResult? get lastToneResult => _lastToneResult;
  
  /// Start real-time audio analysis
  Future<void> startAnalysis({AudioAnalysisSettings? customSettings}) async {
    if (_isAnalyzing) return;
    
    _settings = customSettings ?? AudioAnalysisSettings.defaultSettings();
    _isAnalyzing = true;
    
    // Clear buffers
    _audioBuffer.clear();
    _pitchHistory.clear();
    _toneHistory.clear();
    
    // Start analysis loop
    _startAnalysisLoop();
  }
  
  /// Stop real-time audio analysis
  Future<void> stopAnalysis() async {
    _isAnalyzing = false;
  }
  
  /// Process audio buffer with comprehensive analysis
  Future<ComprehensiveAnalysisResult> analyzeAudioBuffer(Float32List audioData) async {
    try {
      // Convert to double list for processing
      final audioSamples = audioData.map((sample) => sample.toDouble()).toList();
      
      // Perform all analysis types in parallel
      final futures = await Future.wait([
        _performPitchDetection(audioSamples),
        _performToneAnalysis(audioSamples),
        _performDynamicRangeAnalysis(audioSamples),
        _performFrequencyAnalysis(audioSamples),
      ]);
      
      final pitchResult = futures[0] as PitchDetectionResult;
      final toneResult = futures[1] as ToneAnalysisResult;
      final dynamicResult = futures[2] as DynamicRangeResult;
      final spectrumResult = futures[3] as FrequencySpectrumResult;
      
      // Update last results
      _lastPitchResult = pitchResult;
      _lastToneResult = toneResult;
      _lastDynamicResult = dynamicResult;
      _lastSpectrumResult = spectrumResult;
      
      // Add to history
      if (pitchResult.confidence > 0.5) {
        _pitchHistory.add(pitchResult);
        if (_pitchHistory.length > 100) _pitchHistory.removeAt(0);
      }
      
      _toneHistory.add(toneResult);
      if (_toneHistory.length > 50) _toneHistory.removeAt(0);
      
      // Generate tuning feedback if pitch detection is enabled
      if (_settings.enablePitchDetection && pitchResult.confidence > 0.6) {
        final tuningFeedback = _generateTuningFeedback(pitchResult);
        _tuningController.add(tuningFeedback);
      }
      
      // Emit results to streams
      _pitchController.add(pitchResult);
      _toneController.add(toneResult);
      _dynamicController.add(dynamicResult);
      _spectrumController.add(spectrumResult);
      
      return ComprehensiveAnalysisResult(
        pitch: pitchResult,
        tone: toneResult,
        dynamic: dynamicResult,
        spectrum: spectrumResult,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw AudioAnalysisException('Failed to analyze audio: $e');
    }
  }
  
  /// Detect specific guitar string and fret
  Future<StringFretDetection> detectStringAndFret(Float32List audioData) async {
    final pitchResult = await _performPitchDetection(audioData.map((e) => e.toDouble()).toList());
    
    if (pitchResult.confidence < 0.7) {
      return StringFretDetection.unknown();
    }
    
    final detectedFreq = pitchResult.frequency;
    final stringFret = _mapFrequencyToStringFret(detectedFreq);
    
    return StringFretDetection(
      string: stringFret.string,
      fret: stringFret.fret,
      frequency: detectedFreq,
      confidence: pitchResult.confidence,
      inTune: _isInTune(detectedFreq, stringFret),
      centsOff: _calculateCentsOff(detectedFreq, stringFret),
      timestamp: DateTime.now(),
    );
  }
  
  /// Analyze chord from audio
  Future<ChordAnalysisResult> analyzeChord(Float32List audioData) async {
    final spectrumResult = await _performFrequencyAnalysis(audioData.map((e) => e.toDouble()).toList());
    
    // Extract fundamental frequencies from spectrum
    final fundamentals = _extractFundamentalFrequencies(spectrumResult.magnitudes);
    
    // Map frequencies to notes
    final detectedNotes = fundamentals
        .map((freq) => _frequencyToNote(freq))
        .where((note) => note != null)
        .cast<Note>()
        .toList();
    
    // Identify chord from notes
    final chord = _identifyChordFromNotes(detectedNotes);
    
    return ChordAnalysisResult(
      detectedNotes: detectedNotes,
      identifiedChord: chord,
      confidence: _calculateChordConfidence(detectedNotes, fundamentals),
      fundamentalFrequencies: fundamentals,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get tuning analysis for all strings
  Future<TuningAnalysis> analyzeTuning({
    List<String>? targetTuning,
    Duration? analysisWindow,
  }) async {
    final tuning = targetTuning ?? ['E', 'A', 'D', 'G', 'B', 'E']; // Standard tuning
    final window = analysisWindow ?? const Duration(seconds: 5);
    
    final cutoffTime = DateTime.now().subtract(window);
    final recentPitches = _pitchHistory
        .where((p) => p.timestamp.isAfter(cutoffTime) && p.confidence > 0.6)
        .toList();
    
    if (recentPitches.isEmpty) {
      return TuningAnalysis.noData();
    }
    
    final stringResults = <StringTuningResult>[];
    
    for (int stringNum = 1; stringNum <= 6; stringNum++) {
      final targetNote = tuning[stringNum - 1];
      final targetFreq = _noteToFrequency(targetNote, 0); // Open string
      
      // Find pitches that could belong to this string
      final stringPitches = recentPitches
          .where((p) => _isLikelyString(p.frequency, targetFreq))
          .toList();
      
      if (stringPitches.isNotEmpty) {
        final avgFreq = stringPitches.map((p) => p.frequency).reduce((a, b) => a + b) / stringPitches.length;
        final centsOff = _frequencyToCents(avgFreq / targetFreq);
        
        stringResults.add(StringTuningResult(
          stringNumber: stringNum,
          targetNote: targetNote,
          targetFrequency: targetFreq,
          actualFrequency: avgFreq,
          centsOff: centsOff,
          inTune: centsOff.abs() <= 10, // Within 10 cents
          confidence: stringPitches.map((p) => p.confidence).reduce((a, b) => a + b) / stringPitches.length,
        ));
      }
    }
    
    return TuningAnalysis(
      stringResults: stringResults,
      overallInTune: stringResults.every((s) => s.inTune),
      averageDeviation: stringResults.isEmpty ? 0.0 : 
          stringResults.map((s) => s.centsOff.abs()).reduce((a, b) => a + b) / stringResults.length,
      timestamp: DateTime.now(),
    );
  }
  
  /// Analyze playing dynamics and expression
  Future<ExpressionAnalysis> analyzeExpression(Float32List audioData) async {
    final samples = audioData.map((e) => e.toDouble()).toList();
    
    // Calculate various expression metrics
    final velocity = _calculateVelocity(samples);
    final attack = _analyzeAttack(samples);
    final sustain = _analyzeSustain(samples);
    final decay = _analyzeDecay(samples);
    final vibrato = _analyzeVibrato(samples);
    
    return ExpressionAnalysis(
      velocity: velocity,
      attack: attack,
      sustain: sustain,
      decay: decay,
      vibrato: vibrato,
      overallExpression: _calculateOverallExpression(velocity, attack, sustain, decay, vibrato),
      timestamp: DateTime.now(),
    );
  }
  
  /// Update analysis settings
  void updateSettings(AudioAnalysisSettings newSettings) {
    _settings = newSettings;
  }
  
  /// Get analysis statistics
  AudioAnalysisStatistics getAnalysisStatistics() {
    if (_pitchHistory.isEmpty && _toneHistory.isEmpty) {
      return AudioAnalysisStatistics.empty();
    }
    
    final pitchAccuracy = _pitchHistory.isEmpty ? 0.0 :
        _pitchHistory.map((p) => p.confidence).reduce((a, b) => a + b) / _pitchHistory.length;
    
    final toneConsistency = _calculateToneConsistency();
    final analysisUptime = _isAnalyzing ? 
        DateTime.now().difference(_pitchHistory.isNotEmpty ? _pitchHistory.first.timestamp : DateTime.now()) :
        Duration.zero;
    
    return AudioAnalysisStatistics(
      totalAnalysisTime: analysisUptime,
      pitchDetectionAccuracy: pitchAccuracy,
      toneConsistency: toneConsistency,
      averageConfidence: pitchAccuracy,
      samplesProcessed: _pitchHistory.length + _toneHistory.length,
      lastAnalysisTime: _lastPitchResult?.timestamp ?? DateTime.now(),
    );
  }
  
  // Private methods
  void _startAnalysisLoop() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isAnalyzing) {
        timer.cancel();
        return;
      }
      
      // In a real implementation, this would capture audio from microphone
      // For now, we simulate the analysis loop
    });
  }
  
  Future<PitchDetectionResult> _performPitchDetection(List<double> audioSamples) async {
    if (!_settings.enablePitchDetection) {
      return PitchDetectionResult.silent();
    }
    
    try {
      // Autocorrelation-based pitch detection (simplified YIN algorithm)
      final pitch = _autocorrelationPitchDetection(audioSamples);
      final confidence = _calculatePitchConfidence(audioSamples, pitch);
      
      return PitchDetectionResult(
        frequency: pitch,
        confidence: confidence,
        note: _frequencyToNote(pitch),
        octave: _frequencyToOctave(pitch),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return PitchDetectionResult.silent();
    }
  }
  
  Future<ToneAnalysisResult> _performToneAnalysis(List<double> audioSamples) async {
    if (!_settings.enableToneAnalysis) {
      return ToneAnalysisResult.neutral();
    }
    
    try {
      // Spectral analysis for tone characteristics
      final spectrum = _computeFFT(audioSamples);
      
      final brightness = _calculateBrightness(spectrum);
      final warmth = _calculateWarmth(spectrum);
      final attack = _calculateAttackTime(audioSamples);
      final sustain = _calculateSustainLevel(audioSamples);
      final harmonicContent = _analyzeHarmonicContent(spectrum);
      
      return ToneAnalysisResult(
        brightness: brightness,
        warmth: warmth,
        attack: attack,
        sustain: sustain,
        harmonicContent: harmonicContent,
        overallTone: _calculateOverallTone(brightness, warmth, attack, sustain),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ToneAnalysisResult.neutral();
    }
  }
  
  Future<DynamicRangeResult> _performDynamicRangeAnalysis(List<double> audioSamples) async {
    if (!_settings.enableDynamicAnalysis) {
      return DynamicRangeResult.silent();
    }
    
    try {
      final rms = _calculateRMS(audioSamples);
      final peak = _calculatePeak(audioSamples);
      final dynamicRange = _calculateDynamicRange(audioSamples);
      final loudness = _calculateLoudness(rms);
      
      return DynamicRangeResult(
        rms: rms,
        peak: peak,
        dynamicRange: dynamicRange,
        loudness: loudness,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return DynamicRangeResult.silent();
    }
  }
  
  Future<FrequencySpectrumResult> _performFrequencyAnalysis(List<double> audioSamples) async {
    if (!_settings.enableSpectrumAnalysis) {
      return FrequencySpectrumResult.silent();
    }
    
    try {
      final spectrum = _computeFFT(audioSamples);
      final frequencies = _computeFrequencyBins(spectrum.length);
      
      return FrequencySpectrumResult(
        frequencies: frequencies,
        magnitudes: spectrum,
        dominantFrequency: _findDominantFrequency(frequencies, spectrum),
        spectralCentroid: _calculateSpectralCentroid(frequencies, spectrum),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return FrequencySpectrumResult.silent();
    }
  }
  
  double _autocorrelationPitchDetection(List<double> samples) {
    if (samples.length < 2) return 0.0;
    
    const minPeriod = 20; // ~2200 Hz (highest guitar note)
    const maxPeriod = 1000; // ~44 Hz (lowest guitar note)
    
    double bestCorrelation = 0.0;
    int bestPeriod = minPeriod;
    
    for (int period = minPeriod; period < math.min(maxPeriod, samples.length ~/ 2); period++) {
      double correlation = 0.0;
      
      for (int i = 0; i < samples.length - period; i++) {
        correlation += samples[i] * samples[i + period];
      }
      
      correlation /= (samples.length - period);
      
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestPeriod = period;
      }
    }
    
    return bestCorrelation > 0.3 ? _sampleRate / bestPeriod : 0.0;
  }
  
  double _calculatePitchConfidence(List<double> samples, double pitch) {
    if (pitch <= 0) return 0.0;
    
    final period = (_sampleRate / pitch).round();
    if (period >= samples.length ~/ 2) return 0.0;
    
    double correlation = 0.0;
    int count = 0;
    
    for (int i = 0; i < samples.length - period; i++) {
      correlation += samples[i] * samples[i + period];
      count++;
    }
    
    return count > 0 ? (correlation / count).clamp(0.0, 1.0) : 0.0;
  }
  
  List<double> _computeFFT(List<double> samples) {
    // Simplified FFT implementation
    final n = math.min(samples.length, _bufferSize);
    final magnitudes = <double>[];
    
    for (int k = 0; k < n ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;
      
      for (int n_idx = 0; n_idx < n; n_idx++) {
        final angle = -2.0 * math.pi * k * n_idx / n;
        real += samples[n_idx] * math.cos(angle);
        imag += samples[n_idx] * math.sin(angle);
      }
      
      final magnitude = math.sqrt(real * real + imag * imag);
      magnitudes.add(magnitude);
    }
    
    return magnitudes;
  }
  
  List<double> _computeFrequencyBins(int fftSize) {
    final frequencies = <double>[];
    for (int i = 0; i < fftSize; i++) {
      frequencies.add(i * _sampleRate / (fftSize * 2));
    }
    return frequencies;
  }
  
  double _calculateBrightness(List<double> spectrum) {
    if (spectrum.isEmpty) return 0.5;
    
    final highFreqStart = (spectrum.length * 0.6).round();
    final highFreqEnergy = spectrum.skip(highFreqStart).fold<double>(0.0, (sum, mag) => sum + mag);
    final totalEnergy = spectrum.fold<double>(0.0, (sum, mag) => sum + mag);
    
    return totalEnergy > 0 ? (highFreqEnergy / totalEnergy).clamp(0.0, 1.0) : 0.5;
  }
  
  double _calculateWarmth(List<double> spectrum) {
    if (spectrum.isEmpty) return 0.5;
    
    final lowFreqEnd = (spectrum.length * 0.3).round();
    final lowFreqEnergy = spectrum.take(lowFreqEnd).fold<double>(0.0, (sum, mag) => sum + mag);
    final totalEnergy = spectrum.fold<double>(0.0, (sum, mag) => sum + mag);
    
    return totalEnergy > 0 ? (lowFreqEnergy / totalEnergy).clamp(0.0, 1.0) : 0.5;
  }
  
  double _calculateAttackTime(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    final peak = samples.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    final threshold = peak * 0.9;
    
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].abs() >= threshold) {
        return i / _sampleRate * 1000; // Return in milliseconds
      }
    }
    
    return 0.0;
  }
  
  double _calculateSustainLevel(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    final peak = samples.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    if (peak == 0) return 0.0;
    
    // Find sustain portion (after attack, before decay)
    final start = (samples.length * 0.1).round();
    final end = (samples.length * 0.8).round();
    
    if (start >= end) return 0.0;
    
    final sustainSamples = samples.sublist(start, end);
    final sustainRMS = _calculateRMS(sustainSamples);
    
    return (sustainRMS / peak).clamp(0.0, 1.0);
  }
  
  Map<String, double> _analyzeHarmonicContent(List<double> spectrum) {
    // Simplified harmonic analysis
    return {
      'fundamental': spectrum.isNotEmpty ? spectrum.first : 0.0,
      'second_harmonic': spectrum.length > 1 ? spectrum[1] : 0.0,
      'third_harmonic': spectrum.length > 2 ? spectrum[2] : 0.0,
      'harmonic_ratio': _calculateHarmonicRatio(spectrum),
    };
  }
  
  double _calculateHarmonicRatio(List<double> spectrum) {
    if (spectrum.length < 3) return 0.0;
    
    final fundamental = spectrum[0];
    final harmonics = spectrum.skip(1).take(4).fold<double>(0.0, (sum, mag) => sum + mag);
    
    return fundamental > 0 ? (harmonics / fundamental).clamp(0.0, 1.0) : 0.0;
  }
  
  double _calculateOverallTone(double brightness, double warmth, double attack, double sustain) {
    // Weighted combination of tone characteristics
    return (brightness * 0.3 + warmth * 0.3 + (attack / 100) * 0.2 + sustain * 0.2).clamp(0.0, 1.0);
  }
  
  double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    final sumOfSquares = samples.fold<double>(0.0, (sum, sample) => sum + sample * sample);
    return math.sqrt(sumOfSquares / samples.length);
  }
  
  double _calculatePeak(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    return samples.map((s) => s.abs()).reduce(math.max);
  }
  
  double _calculateDynamicRange(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    final peak = _calculatePeak(samples);
    final rms = _calculateRMS(samples);
    
    return rms > 0 ? (peak / rms) : 0.0;
  }
  
  double _calculateLoudness(double rms) {
    if (rms <= 0) return 0.0;
    
    // Convert RMS to dB
    final dB = 20 * math.log(rms) / math.ln10;
    
    // Normalize to 0-1 range (assuming -60dB to 0dB range)
    return ((dB + 60) / 60).clamp(0.0, 1.0);
  }
  
  double _findDominantFrequency(List<double> frequencies, List<double> magnitudes) {
    if (frequencies.length != magnitudes.length || magnitudes.isEmpty) return 0.0;
    
    int maxIndex = 0;
    for (int i = 1; i < magnitudes.length; i++) {
      if (magnitudes[i] > magnitudes[maxIndex]) {
        maxIndex = i;
      }
    }
    
    return frequencies[maxIndex];
  }
  
  double _calculateSpectralCentroid(List<double> frequencies, List<double> magnitudes) {
    if (frequencies.length != magnitudes.length || magnitudes.isEmpty) return 0.0;
    
    double weightedSum = 0.0;
    double totalMagnitude = 0.0;
    
    for (int i = 0; i < frequencies.length; i++) {
      weightedSum += frequencies[i] * magnitudes[i];
      totalMagnitude += magnitudes[i];
    }
    
    return totalMagnitude > 0 ? weightedSum / totalMagnitude : 0.0;
  }
  
  List<double> _extractFundamentalFrequencies(List<double> spectrum) {
    final fundamentals = <double>[];
    
    // Find peaks in spectrum
    for (int i = 1; i < spectrum.length - 1; i++) {
      if (spectrum[i] > spectrum[i - 1] && spectrum[i] > spectrum[i + 1] && spectrum[i] > 0.1) {
        final frequency = i * _sampleRate / (spectrum.length * 2);
        if (frequency >= 80 && frequency <= 1200) { // Guitar frequency range
          fundamentals.add(frequency);
        }
      }
    }
    
    // Sort by magnitude and return top 6
    fundamentals.sort((a, b) {
      final aIndex = (a * spectrum.length * 2 / _sampleRate).round().clamp(0, spectrum.length - 1);
      final bIndex = (b * spectrum.length * 2 / _sampleRate).round().clamp(0, spectrum.length - 1);
      return spectrum[bIndex].compareTo(spectrum[aIndex]);
    });
    
    return fundamentals.take(6).toList();
  }
  
  Note? _frequencyToNote(double frequency) {
    if (frequency <= 0) return null;
    
    // A4 = 440 Hz
    const a4Frequency = 440.0;
    const a4NoteNumber = 57; // A4 is note number 57 (C0 = 0)
    
    final noteNumber = (12 * math.log(frequency / a4Frequency) / math.ln2 + a4NoteNumber).round();
    
    if (noteNumber < 0 || noteNumber > 127) return null;
    
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = noteNames[noteNumber % 12];
    final octave = (noteNumber ~/ 12) - 1;
    
    return Note(name: noteName, octave: octave, frequency: frequency);
  }
  
  int _frequencyToOctave(double frequency) {
    final note = _frequencyToNote(frequency);
    return note?.octave ?? 0;
  }
  
  StringFret _mapFrequencyToStringFret(double frequency) {
    // Standard tuning frequencies
    final openStringFreqs = [
      82.41,  // E2 (6th string)
      110.00, // A2 (5th string)
      146.83, // D3 (4th string)
      196.00, // G3 (3rd string)
      246.94, // B3 (2nd string)
      329.63, // E4 (1st string)
    ];
    
    double closestDistance = double.infinity;
    int bestString = 1;
    int bestFret = 0;
    
    for (int string = 0; string < 6; string++) {
      for (int fret = 0; fret <= 24; fret++) {
        final fretFreq = openStringFreqs[string] * math.pow(2, fret / 12.0);
        final distance = (frequency - fretFreq).abs();
        
        if (distance < closestDistance) {
          closestDistance = distance;
          bestString = string + 1;
          bestFret = fret;
        }
      }
    }
    
    return StringFret(string: bestString, fret: bestFret);
  }
  
  bool _isInTune(double frequency, StringFret stringFret) {
    final expectedFreq = _getExpectedFrequency(stringFret);
    final centsOff = _frequencyToCents(frequency / expectedFreq);
    return centsOff.abs() <= 10; // Within 10 cents
  }
  
  double _calculateCentsOff(double frequency, StringFret stringFret) {
    final expectedFreq = _getExpectedFrequency(stringFret);
    return _frequencyToCents(frequency / expectedFreq);
  }
  
  double _getExpectedFrequency(StringFret stringFret) {
    final openStringFreqs = [82.41, 110.00, 146.83, 196.00, 246.94, 329.63];
    final openFreq = openStringFreqs[stringFret.string - 1];
    return openFreq * math.pow(2, stringFret.fret / 12.0);
  }
  
  double _frequencyToCents(double ratio) {
    return 1200 * math.log(ratio) / math.ln2;
  }
  
  double _noteToFrequency(String noteName, int fret) {
    final noteFreqs = {
      'C': 261.63, 'C#': 277.18, 'D': 293.66, 'D#': 311.13,
      'E': 329.63, 'F': 349.23, 'F#': 369.99, 'G': 392.00,
      'G#': 415.30, 'A': 440.00, 'A#': 466.16, 'B': 493.88,
    };
    
    final baseFreq = noteFreqs[noteName] ?? 440.0;
    return baseFreq * math.pow(2, fret / 12.0);
  }
  
  bool _isLikelyString(double frequency, double targetFreq) {
    // Check if frequency could belong to this string (considering frets 0-24)
    final minFreq = targetFreq;
    final maxFreq = targetFreq * math.pow(2, 24 / 12.0); // 24 frets up
    
    return frequency >= minFreq * 0.9 && frequency <= maxFreq * 1.1;
  }
  
  String? _identifyChordFromNotes(List<Note> notes) {
    if (notes.length < 3) return null;
    
    // Simplified chord identification
    final noteNames = notes.map((n) => n.name).toSet().toList();
    noteNames.sort();
    
    // Common chord patterns
    final chordPatterns = {
      ['C', 'E', 'G']: 'C',
      ['C', 'E', 'G', 'B']: 'Cmaj7',
      ['C', 'Eb', 'G']: 'Cm',
      ['C', 'E', 'G', 'Bb']: 'C7',
      ['D', 'F#', 'A']: 'D',
      ['D', 'F', 'A']: 'Dm',
      ['E', 'G#', 'B']: 'E',
      ['E', 'G', 'B']: 'Em',
      ['F', 'A', 'C']: 'F',
      ['F', 'Ab', 'C']: 'Fm',
      ['G', 'B', 'D']: 'G',
      ['G', 'Bb', 'D']: 'Gm',
      ['A', 'C#', 'E']: 'A',
      ['A', 'C', 'E']: 'Am',
      ['B', 'D#', 'F#']: 'B',
      ['B', 'D', 'F#']: 'Bm',
    };
    
    return chordPatterns[noteNames];
  }
  
  double _calculateChordConfidence(List<Note> notes, List<double> fundamentals) {
    if (notes.isEmpty || fundamentals.isEmpty) return 0.0;
    
    // Confidence based on note clarity and fundamental strength
    final avgConfidence = fundamentals.map((f) => f > 0.1 ? 1.0 : 0.0).reduce((a, b) => a + b) / fundamentals.length;
    
    return avgConfidence.clamp(0.0, 1.0);
  }
  
  TuningFeedback _generateTuningFeedback(PitchDetectionResult pitchResult) {
    final stringFret = _mapFrequencyToStringFret(pitchResult.frequency);
    final expectedFreq = _getExpectedFrequency(stringFret);
    final centsOff = _frequencyToCents(pitchResult.frequency / expectedFreq);
    
    TuningDirection direction;
    String message;
    
    if (centsOff.abs() <= 5) {
      direction = TuningDirection.inTune;
      message = 'In tune!';
    } else if (centsOff > 0) {
      direction = TuningDirection.sharp;
      message = 'Too sharp - tune down';
    } else {
      direction = TuningDirection.flat;
      message = 'Too flat - tune up';
    }
    
    return TuningFeedback(
      string: stringFret.string,
      fret: stringFret.fret,
      targetFrequency: expectedFreq,
      actualFrequency: pitchResult.frequency,
      centsOff: centsOff,
      direction: direction,
      message: message,
      confidence: pitchResult.confidence,
      timestamp: DateTime.now(),
    );
  }
  
  double _calculateToneConsistency() {
    if (_toneHistory.length < 5) return 0.0;
    
    final recentTones = _toneHistory.takeLast(5).toList();
    
    // Calculate variance in tone characteristics
    final brightnessVariance = _calculateVariance(recentTones.map((t) => t.brightness).toList());
    final warmthVariance = _calculateVariance(recentTones.map((t) => t.warmth).toList());
    
    final avgVariance = (brightnessVariance + warmthVariance) / 2;
    
    // Convert variance to consistency score (lower variance = higher consistency)
    return (1.0 - avgVariance).clamp(0.0, 1.0);
  }
  
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
  
  double _calculateVelocity(List<double> samples) {
    return _calculatePeak(samples);
  }
  
  AttackAnalysis _analyzeAttack(List<double> samples) {
    final time = _calculateAttackTime(samples);
    final intensity = _calculatePeak(samples);
    
    return AttackAnalysis(time: time, intensity: intensity);
  }
  
  SustainAnalysis _analyzeSustain(List<double> samples) {
    final level = _calculateSustainLevel(samples);
    final duration = samples.length / _sampleRate * 1000; // ms
    
    return SustainAnalysis(level: level, duration: duration);
  }
  
  DecayAnalysis _analyzeDecay(List<double> samples) {
    // Simplified decay analysis
    final rate = 0.5; // Mock value
    final curve = 'exponential';
    
    return DecayAnalysis(rate: rate, curve: curve);
  }
  
  VibratoAnalysis _analyzeVibrato(List<double> samples) {
    // Simplified vibrato detection
    final present = false; // Mock value
    final rate = 0.0;
    final depth = 0.0;
    
    return VibratoAnalysis(present: present, rate: rate, depth: depth);
  }
  
  double _calculateOverallExpression(double velocity, AttackAnalysis attack, SustainAnalysis sustain, DecayAnalysis decay, VibratoAnalysis vibrato) {
    // Weighted combination of expression elements
    final expressionScore = (
      velocity * 0.3 +
      (attack.intensity) * 0.2 +
      sustain.level * 0.2 +
      decay.rate * 0.15 +
      (vibrato.present ? 0.15 : 0.0)
    );
    
    return expressionScore.clamp(0.0, 1.0);
  }
  
  void dispose() {
    _pitchController.close();
    _toneController.close();
    _dynamicController.close();
    _spectrumController.close();
    _tuningController.close();
  }
}

// Data Models
class AudioAnalysisSettings {
  final bool enablePitchDetection;
  final bool enableToneAnalysis;
  final bool enableDynamicAnalysis;
  final bool enableSpectrumAnalysis;
  final double sensitivity;
  final int bufferSize;
  final double noiseThreshold;
  
  const AudioAnalysisSettings({
    required this.enablePitchDetection,
    required this.enableToneAnalysis,
    required this.enableDynamicAnalysis,
    required this.enableSpectrumAnalysis,
    required this.sensitivity,
    required this.bufferSize,
    required this.noiseThreshold,
  });
  
  factory AudioAnalysisSettings.defaultSettings() {
    return const AudioAnalysisSettings(
      enablePitchDetection: true,
      enableToneAnalysis: true,
      enableDynamicAnalysis: true,
      enableSpectrumAnalysis: true,
      sensitivity: 0.7,
      bufferSize: 2048,
      noiseThreshold: 0.01,
    );
  }
}

class PitchDetectionResult {
  final double frequency;
  final double confidence;
  final Note? note;
  final int octave;
  final DateTime timestamp;
  
  const PitchDetectionResult({
    required this.frequency,
    required this.confidence,
    this.note,
    required this.octave,
    required this.timestamp,
  });
  
  factory PitchDetectionResult.silent() {
    return PitchDetectionResult(
      frequency: 0.0,
      confidence: 0.0,
      octave: 0,
      timestamp: DateTime.now(),
    );
  }
}

class ToneAnalysisResult {
  final double brightness;
  final double warmth;
  final double attack;
  final double sustain;
  final Map<String, double> harmonicContent;
  final double overallTone;
  final DateTime timestamp;
  
  const ToneAnalysisResult({
    required this.brightness,
    required this.warmth,
    required this.attack,
    required this.sustain,
    required this.harmonicContent,
    required this.overallTone,
    required this.timestamp,
  });
  
  factory ToneAnalysisResult.neutral() {
    return ToneAnalysisResult(
      brightness: 0.5,
      warmth: 0.5,
      attack: 0.0,
      sustain: 0.5,
      harmonicContent: {},
      overallTone: 0.5,
      timestamp: DateTime.now(),
    );
  }
}

class DynamicRangeResult {
  final double rms;
  final double peak;
  final double dynamicRange;
  final double loudness;
  final DateTime timestamp;
  
  const DynamicRangeResult({
    required this.rms,
    required this.peak,
    required this.dynamicRange,
    required this.loudness,
    required this.timestamp,
  });
  
  factory DynamicRangeResult.silent() {
    return DynamicRangeResult(
      rms: 0.0,
      peak: 0.0,
      dynamicRange: 0.0,
      loudness: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class FrequencySpectrumResult {
  final List<double> frequencies;
  final List<double> magnitudes;
  final double dominantFrequency;
  final double spectralCentroid;
  final DateTime timestamp;
  
  const FrequencySpectrumResult({
    required this.frequencies,
    required this.magnitudes,
    required this.dominantFrequency,
    required this.spectralCentroid,
    required this.timestamp,
  });
  
  factory FrequencySpectrumResult.silent() {
    return FrequencySpectrumResult(
      frequencies: [],
      magnitudes: [],
      dominantFrequency: 0.0,
      spectralCentroid: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class ComprehensiveAnalysisResult {
  final PitchDetectionResult pitch;
  final ToneAnalysisResult tone;
  final DynamicRangeResult dynamic;
  final FrequencySpectrumResult spectrum;
  final DateTime timestamp;
  
  const ComprehensiveAnalysisResult({
    required this.pitch,
    required this.tone,
    required this.dynamic,
    required this.spectrum,
    required this.timestamp,
  });
}

class StringFretDetection {
  final int string;
  final int fret;
  final double frequency;
  final double confidence;
  final bool inTune;
  final double centsOff;
  final DateTime timestamp;
  
  const StringFretDetection({
    required this.string,
    required this.fret,
    required this.frequency,
    required this.confidence,
    required this.inTune,
    required this.centsOff,
    required this.timestamp,
  });
  
  factory StringFretDetection.unknown() {
    return StringFretDetection(
      string: 0,
      fret: 0,
      frequency: 0.0,
      confidence: 0.0,
      inTune: false,
      centsOff: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class ChordAnalysisResult {
  final List<Note> detectedNotes;
  final String? identifiedChord;
  final double confidence;
  final List<double> fundamentalFrequencies;
  final DateTime timestamp;
  
  const ChordAnalysisResult({
    required this.detectedNotes,
    this.identifiedChord,
    required this.confidence,
    required this.fundamentalFrequencies,
    required this.timestamp,
  });
}

class TuningAnalysis {
  final List<StringTuningResult> stringResults;
  final bool overallInTune;
  final double averageDeviation;
  final DateTime timestamp;
  
  const TuningAnalysis({
    required this.stringResults,
    required this.overallInTune,
    required this.averageDeviation,
    required this.timestamp,
  });
  
  factory TuningAnalysis.noData() {
    return TuningAnalysis(
      stringResults: [],
      overallInTune: false,
      averageDeviation: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class StringTuningResult {
  final int stringNumber;
  final String targetNote;
  final double targetFrequency;
  final double actualFrequency;
  final double centsOff;
  final bool inTune;
  final double confidence;
  
  const StringTuningResult({
    required this.stringNumber,
    required this.targetNote,
    required this.targetFrequency,
    required this.actualFrequency,
    required this.centsOff,
    required this.inTune,
    required this.confidence,
  });
}

class ExpressionAnalysis {
  final double velocity;
  final AttackAnalysis attack;
  final SustainAnalysis sustain;
  final DecayAnalysis decay;
  final VibratoAnalysis vibrato;
  final double overallExpression;
  final DateTime timestamp;
  
  const ExpressionAnalysis({
    required this.velocity,
    required this.attack,
    required this.sustain,
    required this.decay,
    required this.vibrato,
    required this.overallExpression,
    required this.timestamp,
  });
}

class AttackAnalysis {
  final double time;
  final double intensity;
  
  const AttackAnalysis({required this.time, required this.intensity});
}

class SustainAnalysis {
  final double level;
  final double duration;
  
  const SustainAnalysis({required this.level, required this.duration});
}

class DecayAnalysis {
  final double rate;
  final String curve;
  
  const DecayAnalysis({required this.rate, required this.curve});
}

class VibratoAnalysis {
  final bool present;
  final double rate;
  final double depth;
  
  const VibratoAnalysis({required this.present, required this.rate, required this.depth});
}

class TuningFeedback {
  final int string;
  final int fret;
  final double targetFrequency;
  final double actualFrequency;
  final double centsOff;
  final TuningDirection direction;
  final String message;
  final double confidence;
  final DateTime timestamp;
  
  const TuningFeedback({
    required this.string,
    required this.fret,
    required this.targetFrequency,
    required this.actualFrequency,
    required this.centsOff,
    required this.direction,
    required this.message,
    required this.confidence,
    required this.timestamp,
  });
}

class AudioAnalysisStatistics {
  final Duration totalAnalysisTime;
  final double pitchDetectionAccuracy;
  final double toneConsistency;
  final double averageConfidence;
  final int samplesProcessed;
  final DateTime lastAnalysisTime;
  
  const AudioAnalysisStatistics({
    required this.totalAnalysisTime,
    required this.pitchDetectionAccuracy,
    required this.toneConsistency,
    required this.averageConfidence,
    required this.samplesProcessed,
    required this.lastAnalysisTime,
  });
  
  factory AudioAnalysisStatistics.empty() {
    return AudioAnalysisStatistics(
      totalAnalysisTime: Duration.zero,
      pitchDetectionAccuracy: 0.0,
      toneConsistency: 0.0,
      averageConfidence: 0.0,
      samplesProcessed: 0,
      lastAnalysisTime: DateTime.now(),
    );
  }
}

class Note {
  final String name;
  final int octave;
  final double frequency;
  
  const Note({required this.name, required this.octave, required this.frequency});
  
  @override
  String toString() => '$name$octave';
}

class StringFret {
  final int string;
  final int fret;
  
  const StringFret({required this.string, required this.fret});
}

// Enums
enum TuningDirection {
  flat,
  inTune,
  sharp,
}

class AudioAnalysisException implements Exception {
  final String message;
  
  const AudioAnalysisException(this.message);
  
  @override
  String toString() => 'AudioAnalysisException: $message';
}

// Riverpod providers
final realTimeAudioAnalysisServiceProvider = Provider<RealTimeAudioAnalysisService>((ref) {
  return RealTimeAudioAnalysisService();
});

final pitchDetectionProvider = StreamProvider<PitchDetectionResult>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.pitchResults;
});

final toneAnalysisProvider = StreamProvider<ToneAnalysisResult>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.toneResults;
});

final dynamicRangeProvider = StreamProvider<DynamicRangeResult>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.dynamicResults;
});

final frequencySpectrumProvider = StreamProvider<FrequencySpectrumResult>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.spectrumResults;
});

final tuningFeedbackProvider = StreamProvider<TuningFeedback>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.tuningFeedback;
});

final audioAnalysisStatsProvider = Provider<AudioAnalysisStatistics>((ref) {
  final service = ref.read(realTimeAudioAnalysisServiceProvider);
  return service.getAnalysisStatistics();
});