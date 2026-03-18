# GuitarrApp — Project Context

> Source: Notion page "🎸 GuitarrApp - Proyecto" (last updated 2026-03-18)

## Vision

App movil para aprender guitarra tocando y recibiendo feedback en tiempo real
de IA.

**Core Value:** El usuario toca un acorde y la app le dice correctamente qué
tocó y con qué precisión. Sin eso, nada más tiene sentido.

## Stack

| Componente | Tecnología |
|-----------|------------|
| Framework | Flutter (Android, iOS, Web) |
| State Management | Riverpod |
| Audio Mobile | flutter_sound |
| Audio Web | Web Audio API (JS) |
| ML Model | TensorFlow Lite (`chord_classifier_int8.tflite`) |
| AI Coaching | Gemini 2.0 Flash |
| Storage | SharedPreferences |
| Pitch Detection | YIN + autocorrelación |
| Chord Detection | Mel spectrogram + TFLite classifier |

## Current State (as of 2026-03-16)

- **Milestone:** v1.0
- **Phases completadas:** 2 de 9
- **Próxima phase:** 3 (Guitar Tuner)

## Roadmap v1.0

| # | Phase | Requirement | Status |
|---|-------|-------------|--------|
| 1 | Audio Detection Pipeline | AUD-01 | ✅ Completada |
| 2 | Device Calibration | AUD-02 | ✅ Completada |
| 3 | Guitar Tuner | TOOL-01 | Pendiente |
| 4 | Chord Sample Expansion | CONT-01 | Pendiente |
| 5 | Skill Tree & Progression | CURR-01 | Pendiente |
| 6 | Song Difficulty Variants | CONT-02 | Pendiente |
| 7 | Adaptive Difficulty | CURR-02 | Pendiente |
| 8 | Practice Engagement | ENG-01, ENG-03 | Pendiente |
| 9 | AI Practice Reports | ENG-02 | Pendiente |

## Features Implementadas

### Audio & Detección
- Detección de acordes con ML (TFLite, mel spectrogram)
- Distingue E major de E minor (no solo single-note pitch)
- Calibración por dispositivo (wizard en onboarding)
- Recalibración manual desde game screens
- Captura de audio mobile (flutter_sound) y web (Web Audio API)

### Contenido & Gameplay
- 10 niveles con un acorde cada uno (E, A, D, G, C, Em, Am, Dm, F, B)
- Gameplay de lección: demo → countdown → play → feedback
- Modo canciones con secuencias de acordes
- Level test (evalúa 5 acordes random)
- 7 cursos con 23 ejercicios (timing, notas, coordinación)
- Chord explorer con preview de samples reales (14 acordes × 2 intensidades)

### UX & Engagement
- Onboarding con test de micrófono y selección de nivel
- Coaching IA con Gemini 2.0 Flash
- Metrónomo con toggle en preview y gameplay
- Tema arcade con estética neon
- Sistema de estrellas y puntuación por nivel

## ML-Relevant Requirements

### v1 (current)
- [x] **AUD-01**: Detección de acordes completos con ML
- [x] **AUD-02**: Wizard de calibración per-device
- [ ] **CONT-01**: Samples de acordes adicionales (menores, 7ths, barre)

### v2 (deferred)
- **AUD-03**: Reemplazar flutter_sound con flutter_audio_capture
- **AUD-04**: Bandpass filter + adaptive noise gate
- **AUD-05**: Detección de patrones de rasgueo

## Completed Phase Details

### Phase 1: Audio Detection Pipeline
- Core detection types, mel spectrogram, ChordMatcher utility
- Python training pipeline + TFLite model export
- TFLite integration en Flutter audio pipeline
- Re-entrenamiento con dataset expandido (WAV+MP3)
- Re-habilitación de ML classification + mic test page update
- **5 plans ejecutados**

### Phase 2: Device Calibration
- CalibrationData model con derivación de thresholds y persistencia
- CalibrationService con medición RMS
- Calibration wizard UI integrado en onboarding
- MobileAudioCaptureService carga thresholds calibrados
- Indicador de recalibración + botón manual
- **3 plans ejecutados**

## Constraints
- **Plataforma**: Android primero, iOS secundario, Web como demo
- **Offline-first**: App funciona 100% local (excepto Gemini API)
- **Audio**: flutter_sound tiene issues conocidos con Flutter 3.16+
- **Assets**: Chord samples grabados manualmente
- **No backend**: Sin auth, sin servidor, sin social features
