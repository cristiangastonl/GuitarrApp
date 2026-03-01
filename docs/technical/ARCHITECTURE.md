# 🏗️ Arquitectura Técnica - GuitarrApp MVP

## Visión General

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              USUARIO                                     │
│                          🎸 Toca guitarra                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ Audio
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER APP                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    PRESENTATION LAYER                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   Screens    │  │   Widgets    │  │  Animations  │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    ▼ Riverpod                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    APPLICATION LAYER                             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │  Providers   │  │  Use Cases   │  │   States     │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      DOMAIN LAYER                                │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   Entities   │  │ Repositories │  │   Services   │          │   │
│  │  │   (Note,     │  │  (Abstract)  │  │  Interfaces  │          │   │
│  │  │   Exercise)  │  │              │  │              │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                 INFRASTRUCTURE LAYER                             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │    Audio     │  │   TFLite     │  │   SQLite     │          │   │
│  │  │   Capture    │  │   Model      │  │   Storage    │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  │                          │                                       │   │
│  │                          ▼ (fallback)                           │   │
│  │                   ┌──────────────┐                               │   │
│  │                   │  Claude API  │                               │   │
│  │                   │  (Feedback)  │                               │   │
│  │                   └──────────────┘                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Stack Tecnológico

### Frontend (Flutter)

| Componente | Tecnología | Justificación |
|------------|------------|---------------|
| Framework | Flutter 3.x | Cross-platform, ya en uso |
| State Management | Riverpod | Ya implementado, reactivo |
| Audio Capture | flutter_sound | Soporte real-time, bien mantenido |
| ML On-Device | tflite_flutter | TensorFlow Lite para modelos |
| Local DB | sqflite | SQLite para persistencia |
| HTTP | dio | Robusto, interceptors |

### Backend/AI

| Componente | Tecnología | Justificación |
|------------|------------|---------------|
| Detección Notas | Basic Pitch (TFLite) | Spotify, preciso, convertible |
| Feedback IA | Claude API | Natural, contextual |
| Cache | En memoria + SQLite | Reduce llamadas API |

### Infraestructura (MVP)

| Componente | Tecnología | Justificación |
|------------|------------|---------------|
| Backend | No requerido | Todo on-device para MVP |
| Analytics | Firebase Analytics | Gratis, fácil |
| Crash Reporting | Firebase Crashlytics | Estándar industria |
| CI/CD | GitHub Actions | Ya integrado |

## Flujo de Datos: Detección de Nota

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│Micrófono │────▶│AudioCapture  │────▶│ Preprocessor │────▶│ TFLite   │
│          │     │Service       │     │ (FFT, etc)   │     │ Model    │
└──────────┘     └──────────────┘     └──────────────┘     └────┬─────┘
                                                                 │
                                                                 ▼
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│   UI     │◀────│  Provider    │◀────│NoteDetection │◀────│Frequency │
│  Update  │     │  (Riverpod)  │     │   Service    │     │ to Note  │
└──────────┘     └──────────────┘     └──────────────┘     └──────────┘

Latencia total objetivo: <300ms
```

### Detalle del Pipeline de Audio

```dart
// 1. Captura de audio (cada 50ms)
AudioCaptureService
  → Stream<Uint8List> audioChunks
  
// 2. Preprocesamiento
AudioPreprocessor
  → Convertir a Float32
  → Aplicar ventana Hanning
  → Calcular magnitud FFT
  
// 3. Inferencia del modelo
TFLiteModel
  → Input: [1, 1024] float32 (espectrograma)
  → Output: [1, 88] float32 (probabilidad por nota de piano)
  
// 4. Post-procesamiento
NoteDetectionService
  → Encontrar nota con mayor probabilidad
  → Filtrar por umbral de confianza (>0.5)
  → Convertir índice a nombre de nota
  
// 5. Actualización de estado
RiverpodProvider
  → detectedNoteProvider.state = Note(...)
  → UI se actualiza automáticamente
```

## Estructura de Carpetas Propuesta

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── music_constants.dart      # Frecuencias, nombres de notas
│   │
│   ├── services/
│   │   ├── audio_capture_service.dart
│   │   ├── note_detection_service.dart
│   │   ├── feedback_service.dart
│   │   └── exercise_service.dart
│   │
│   ├── models/
│   │   ├── note.dart
│   │   ├── exercise.dart
│   │   ├── feedback.dart
│   │   └── session.dart
│   │
│   ├── providers/
│   │   ├── audio_providers.dart
│   │   ├── exercise_providers.dart
│   │   └── session_providers.dart
│   │
│   └── utils/
│       ├── audio_utils.dart
│       └── music_utils.dart
│
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │
│   ├── practice/
│   │   ├── practice_screen.dart       # Pantalla principal de práctica
│   │   ├── free_practice_screen.dart  # Modo libre
│   │   └── widgets/
│   │       ├── listening_indicator.dart
│   │       ├── note_display.dart
│   │       ├── feedback_overlay.dart
│   │       └── progress_bar.dart
│   │
│   ├── exercises/
│   │   ├── exercise_list_screen.dart
│   │   ├── exercise_detail_screen.dart
│   │   └── widgets/
│   │
│   ├── progress/
│   │   ├── progress_screen.dart
│   │   └── widgets/
│   │
│   └── onboarding/
│       ├── onboarding_screen.dart
│       └── widgets/
│
├── shared/
│   ├── theme/
│   │   ├── guitarr_colors.dart
│   │   ├── guitarr_typography.dart
│   │   └── guitarr_theme.dart
│   │
│   └── widgets/
│       ├── glass_card.dart
│       ├── primary_button.dart
│       └── loading_indicator.dart
│
└── data/
    ├── repositories/
    │   ├── exercise_repository.dart
    │   └── session_repository.dart
    │
    ├── datasources/
    │   ├── local/
    │   │   ├── exercise_local_datasource.dart
    │   │   └── session_local_datasource.dart
    │   │
    │   └── remote/
    │       └── feedback_remote_datasource.dart  # Claude API
    │
    └── models/
        ├── exercise_dto.dart
        └── session_dto.dart
```

## Modelos de Datos

### Note

```dart
class Note {
  final String name;        // "E", "A", "D", etc.
  final int octave;         // 2, 3, 4, etc.
  final double frequency;   // 329.63 Hz
  final double confidence;  // 0.0 - 1.0
  final double cents;       // Desviación en cents (-50 a +50)
  final DateTime timestamp;
  
  String get fullName => '$name$octave';  // "E4"
  
  bool get isInTune => cents.abs() < 20;
}
```

### Exercise

```dart
class Exercise {
  final String id;
  final String title;
  final String description;
  final int difficulty;  // 1-5
  final Duration estimatedTime;
  final List<ExerciseStep> steps;
  final CompletionCriteria criteria;
}

class ExerciseStep {
  final int order;
  final StepType type;  // note, chord, rest
  final String expectedNote;
  final String instruction;
  final String? hint;
}

class CompletionCriteria {
  final double minAccuracy;
  final int minPerfectNotes;
}
```

### Session

```dart
class Session {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? exerciseId;
  final List<NoteAttempt> attempts;
  
  double get accuracy => 
    attempts.where((a) => a.isCorrect).length / attempts.length;
    
  Duration get duration => 
    (endTime ?? DateTime.now()).difference(startTime);
}

class NoteAttempt {
  final String expectedNote;
  final String playedNote;
  final double cents;
  final bool isCorrect;
  final DateTime timestamp;
}
```

## Decisiones de Arquitectura

### ADR-001: On-Device vs Cloud para Detección

**Contexto:** Necesitamos decidir dónde ejecutar el modelo de detección de notas.

**Decisión:** On-device con TensorFlow Lite

**Razones:**
1. Latencia: On-device elimina latencia de red (~100-500ms)
2. Privacidad: Audio no sale del dispositivo
3. Offline: Funciona sin conexión
4. Costo: No hay costo de servidor

**Consecuencias:**
- Modelo debe ser optimizado para móvil (<50MB)
- Performance varía según dispositivo
- Actualizaciones de modelo requieren update de app

### ADR-002: Riverpod sobre BLoC

**Contexto:** El proyecto ya usa Riverpod, evaluar si continuar.

**Decisión:** Mantener Riverpod

**Razones:**
1. Ya implementado en el código existente
2. Mejor para flujos reactivos de audio
3. Menor boilerplate que BLoC
4. Fácil testing con overrides

### ADR-003: Claude API para Feedback Contextual

**Contexto:** Necesitamos generar feedback natural y útil.

**Decisión:** Usar Claude API con caché agresivo

**Razones:**
1. Feedback más natural que reglas hardcodeadas
2. Puede adaptarse al contexto del ejercicio
3. Caché reduce costos significativamente

**Consecuencias:**
- Requiere conexión para feedback avanzado
- Fallback a feedback básico offline
- Costo de API (mitigado con caché)

## Métricas de Performance

### Objetivos

| Métrica | Target | Máximo Aceptable |
|---------|--------|------------------|
| Latencia detección | <200ms | <500ms |
| Tiempo de carga app | <2s | <4s |
| Uso de RAM | <150MB | <250MB |
| Tamaño de APK | <50MB | <80MB |
| Batería (30min uso) | <10% | <15% |

### Cómo Medir

```dart
// Latencia de detección
final stopwatch = Stopwatch()..start();
final note = await detectNote(audioChunk);
final latency = stopwatch.elapsedMilliseconds;
analytics.logLatency('note_detection', latency);

// Uso de memoria
final info = await SysInfo.getProcessMemory();
analytics.logMemory('practice_screen', info.rss);
```

## Seguridad y Privacidad

### Principios

1. **Audio nunca sale del dispositivo** (excepto para Claude API feedback, que no incluye audio)
2. **No se requiere cuenta** para MVP
3. **Datos locales encriptados** con SQLCipher
4. **Permisos mínimos**: solo micrófono

### Manejo de Permisos

```dart
Future<bool> requestMicrophonePermission() async {
  // 1. Verificar estado actual
  final status = await Permission.microphone.status;
  
  if (status.isGranted) return true;
  
  // 2. Mostrar explicación antes de pedir
  final shouldRequest = await showPermissionExplanation();
  if (!shouldRequest) return false;
  
  // 3. Pedir permiso
  final result = await Permission.microphone.request();
  return result.isGranted;
}
```

## Plan de Escalabilidad (Post-MVP)

```
MVP (actual)
│
├── Fase 2: Backend Ligero
│   ├── API para sincronizar progreso
│   ├── Sistema de usuarios
│   └── Ejercicios desde servidor
│
├── Fase 3: Features Sociales
│   ├── Leaderboards
│   ├── Compartir progreso
│   └── Desafíos entre amigos
│
└── Fase 4: Contenido Premium
    ├── Cursos estructurados
    ├── Canciones licenciadas
    └── Feedback de profesores reales
```
