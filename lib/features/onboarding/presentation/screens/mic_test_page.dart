import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/audio/mobile_audio_capture.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class MicTestPage extends StatefulWidget {
  final VoidCallback onNext;
  final ValueChanged<bool> onTestResult;

  const MicTestPage({
    super.key,
    required this.onNext,
    required this.onTestResult,
  });

  @override
  State<MicTestPage> createState() => _MicTestPageState();
}

class _MicTestPageState extends State<MicTestPage> {
  final _audioService = MobileAudioCaptureService();
  StreamSubscription<AudioCaptureData>? _subscription;
  bool _isListening = false;
  bool _noteDetected = false;
  bool _hasError = false;
  String? _detectedNote;
  int? _detectedOctave;

  @override
  void dispose() {
    _subscription?.cancel();
    _audioService.stopCapture();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _noteDetected = false;
      _hasError = false;
      _detectedNote = null;
    });

    try {
      final initialized = await _audioService.initialize();
      if (!initialized) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _hasError = true;
          });
        }
        return;
      }

      final started = await _audioService.startCapture();
      if (!started) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _hasError = true;
          });
        }
        return;
      }

      _subscription = _audioService.audioDataStream.listen((data) {
        if (data.hasPitch && data.noteName != null) {
          setState(() {
            _noteDetected = true;
            _detectedNote = data.noteName;
            _detectedOctave = data.octave;
          });
          widget.onTestResult(true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _hasError = true;
        });
      }
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _audioService.stopCapture();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const NeonText(
            text: 'PRUEBA DE SONIDO',
            fontSize: 28,
            color: ArcadeColors.neonGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Toca una cuerda de tu guitarra\npara verificar que todo funciona.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArcadeColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),

          // Note display
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _noteDetected
                    ? ArcadeColors.neonGreen
                    : _isListening
                        ? ArcadeColors.neonCyan
                        : ArcadeColors.textMuted,
                width: 3,
              ),
              boxShadow: _noteDetected
                  ? NeonEffects.glow(ArcadeColors.neonGreen)
                  : _isListening
                      ? NeonEffects.glow(ArcadeColors.neonCyan, intensity: 0.3)
                      : null,
            ),
            child: Center(
              child: _noteDetected
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NeonText(
                          text: _detectedNote ?? '',
                          fontSize: 48,
                          color: ArcadeColors.neonGreen,
                        ),
                        if (_detectedOctave != null)
                          Text(
                            'Octava $_detectedOctave',
                            style: const TextStyle(
                              color: ArcadeColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    )
                  : Icon(
                      _isListening ? Icons.hearing : Icons.music_note,
                      size: 48,
                      color: _isListening
                          ? ArcadeColors.neonCyan
                          : ArcadeColors.textMuted,
                    ),
            ),
          ),

          if (_isListening && !_noteDetected) ...[
            const SizedBox(height: 24),
            Text(
              'Escuchando...',
              style: TextStyle(
                color: ArcadeColors.neonCyan,
                fontSize: 16,
                shadows: NeonEffects.textGlow(
                    ArcadeColors.neonCyan, intensity: 0.5),
              ),
            ),
          ],

          if (_hasError) ...[
            const SizedBox(height: 24),
            const Text(
              'No se pudo acceder al microfono.\nVerifica los permisos e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcadeColors.neonRed,
                fontSize: 14,
              ),
            ),
          ],

          if (_noteDetected) ...[
            const SizedBox(height: 24),
            Text(
              'Microfono funcionando!',
              style: TextStyle(
                color: ArcadeColors.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: NeonEffects.textGlow(
                    ArcadeColors.neonGreen, intensity: 0.5),
              ),
            ),
          ],

          const Spacer(),

          if (!_isListening && !_noteDetected)
            ArcadeButton(
              text: _hasError ? 'REINTENTAR' : 'PROBAR MICROFONO',
              icon: Icons.mic,
              color: ArcadeColors.neonCyan,
              onPressed: _startListening,
            ),

          if (_isListening && !_noteDetected)
            ArcadeButton.outline(
              text: 'CANCELAR',
              onPressed: () {
                _stopListening();
              },
            ),

          if (_noteDetected) ...[
            ArcadeButton(
              text: 'CONTINUAR',
              icon: Icons.arrow_forward,
              onPressed: () {
                _stopListening();
                widget.onNext();
              },
            ),
          ],

          const SizedBox(height: 12),
          if (!_noteDetected)
            ArcadeButton.outline(
              text: 'SALTAR',
              onPressed: () {
                _stopListening();
                widget.onNext();
              },
            ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
