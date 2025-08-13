import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;

// Provider para el servicio del metrónomo
final metronomeServiceProvider = Provider<MetronomeService>((ref) {
  return MetronomeService();
});

// Provider para el estado del metrónomo
final metronomeStateProvider = StateNotifierProvider<MetronomeStateNotifier, MetronomeState>((ref) {
  final service = ref.watch(metronomeServiceProvider);
  return MetronomeStateNotifier(service);
});

class MetronomeService {
  Timer? _timer;
  int _currentBeat = 0;
  
  // Configuración del sonido
  static const MethodChannel _audioChannel = MethodChannel('guitarr_app/audio');
  
  void start(int bpm, int timeSignature, List<bool> accents) {
    stop(); // Detener cualquier metrónomo anterior
    
    final interval = Duration(microseconds: (60000000 / bpm).round());
    
    _timer = Timer.periodic(interval, (timer) {
      _currentBeat = (_currentBeat % timeSignature);
      final isAccent = _currentBeat < accents.length && accents[_currentBeat];
      
      _playClick(isAccent);
      _currentBeat++;
    });
  }
  
  void stop() {
    _timer?.cancel();
    _timer = null;
    _currentBeat = 0;
  }
  
  Future<void> _playClick(bool isAccent) async {
    try {
      if (kIsWeb) {
        // Use Web Audio API for web platform
        _playClickWeb(isAccent);
      } else {
        // Use platform channels for mobile
        await _audioChannel.invokeMethod('playClick', {
          'isAccent': isAccent,
          'frequency': isAccent ? 1000.0 : 800.0, // Hz
          'duration': 0.1, // segundos
        });
      }
    } catch (e) {
      // Fallback: usar HapticFeedback (solo en móviles)
      if (!kIsWeb) {
        if (isAccent) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
    }
  }
  
  void _playClickWeb(bool isAccent) {
    if (kIsWeb) {
      try {
        // Dispatch custom event to trigger web audio
        final event = html.CustomEvent('flutter_metronome_play', detail: {
          'isAccent': isAccent,
          'frequency': isAccent ? 1000.0 : 800.0,
          'duration': 0.1,
        });
        html.window.dispatchEvent(event);
      } catch (e) {
        print('Error playing web metronome click: $e');
      }
    }
  }
  
  int get currentBeat => _currentBeat;
  bool get isRunning => _timer?.isActive ?? false;
}

class MetronomeState {
  final int bpm;
  final int timeSignature;
  final List<bool> accents;
  final bool isPlaying;
  final int currentBeat;

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = 4,
    this.accents = const [true, false, false, false],
    this.isPlaying = false,
    this.currentBeat = 0,
  });

  MetronomeState copyWith({
    int? bpm,
    int? timeSignature,
    List<bool>? accents,
    bool? isPlaying,
    int? currentBeat,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      accents: accents ?? this.accents,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBeat: currentBeat ?? this.currentBeat,
    );
  }
}

class MetronomeStateNotifier extends StateNotifier<MetronomeState> {
  final MetronomeService _service;
  Timer? _beatUpdateTimer;

  MetronomeStateNotifier(this._service) : super(const MetronomeState());

  void setBpm(int bpm) {
    state = state.copyWith(bpm: bpm.clamp(40, 200));
    if (state.isPlaying) {
      _restartMetronome();
    }
  }

  void setTimeSignature(int timeSignature) {
    state = state.copyWith(
      timeSignature: timeSignature,
      accents: _generateDefaultAccents(timeSignature),
    );
    if (state.isPlaying) {
      _restartMetronome();
    }
  }

  void setAccents(List<bool> accents) {
    state = state.copyWith(accents: accents);
    if (state.isPlaying) {
      _restartMetronome();
    }
  }

  void togglePlay() {
    if (state.isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    if (!state.isPlaying) {
      _service.start(state.bpm, state.timeSignature, state.accents);
      state = state.copyWith(isPlaying: true);
      _startBeatTracking();
    }
  }

  void stop() {
    if (state.isPlaying) {
      _service.stop();
      _beatUpdateTimer?.cancel();
      state = state.copyWith(isPlaying: false, currentBeat: 0);
    }
  }

  void _restartMetronome() {
    if (state.isPlaying) {
      _service.stop();
      _service.start(state.bpm, state.timeSignature, state.accents);
    }
  }

  void _startBeatTracking() {
    _beatUpdateTimer?.cancel();
    _beatUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (_service.isRunning) {
          state = state.copyWith(currentBeat: _service.currentBeat);
        } else {
          timer.cancel();
        }
      },
    );
  }

  List<bool> _generateDefaultAccents(int timeSignature) {
    switch (timeSignature) {
      case 3:
        return [true, false, false];
      case 2:
        return [true, false];
      default: // 4/4
        return [true, false, false, false];
    }
  }

  @override
  void dispose() {
    _service.stop();
    _beatUpdateTimer?.cancel();
    super.dispose();
  }
}

// Utilidad para generar rampas de tempo
class TempoRamp {
  final int startBpm;
  final int endBpm;
  final Duration totalDuration;
  final Duration stepDuration;

  const TempoRamp({
    required this.startBpm,
    required this.endBpm,
    required this.totalDuration,
    this.stepDuration = const Duration(seconds: 5),
  });

  List<int> generateSteps() {
    final totalSteps = (totalDuration.inMilliseconds / stepDuration.inMilliseconds).round();
    if (totalSteps <= 1) return [endBpm];

    final steps = <int>[];
    for (int i = 0; i < totalSteps; i++) {
      final progress = i / (totalSteps - 1);
      final bpm = (startBpm + (endBpm - startBpm) * progress).round();
      steps.add(bpm);
    }
    return steps;
  }
}