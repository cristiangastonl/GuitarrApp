# GuitarrApp - Arquitectura del Tutor de Guitarra con IA

## Visión General

GuitarrApp es un tutor de guitarra que escucha al usuario tocar y proporciona feedback en tiempo real mediante ejercicios guiados. La app utiliza detección de pitch y análisis de audio para evaluar la precisión de timing y notas.

## Stack Tecnológico

- **Framework**: Flutter 3.16+
- **State Management**: Riverpod
- **Base de Datos**: SQLite (sqflite)
- **Audio**: flutter_sound, just_audio
- **Análisis de Audio**: FFT (fftea)

---

## Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── core/
│   ├── app/
│   │   └── app.dart                   # Widget principal MaterialApp
│   ├── models/                        # Modelos de dominio
│   │   ├── models.dart                # Barrel export
│   │   ├── exercise.dart              # Exercise, ExpectedNote
│   │   ├── course.dart                # Course, CourseModule
│   │   ├── exercise_result.dart       # ExerciseResult, NoteFeedback
│   │   ├── user_progress.dart         # UserProgress, DiagnosticResult
│   │   ├── session.dart               # Session (legacy, mantener)
│   │   └── user_setup.dart            # UserSetup
│   ├── services/
│   │   ├── exercise_evaluation_service.dart   # CORE: Evaluación de ejercicios
│   │   ├── course_progress_service.dart       # Gestión de cursos/progreso
│   │   ├── ai_feedback_service.dart           # Generación de tips
│   │   ├── diagnostic_service.dart            # Test de nivel
│   │   ├── real_time_audio_analysis_service.dart  # Análisis de audio
│   │   ├── chord_recognition_service.dart     # Detección de acordes
│   │   ├── technique_detection_service.dart   # Detección de técnicas
│   │   ├── recording_service.dart             # Grabación
│   │   ├── feedback_analysis_service.dart     # Análisis de feedback
│   │   └── [otros servicios de utilidad]
│   ├── audio/
│   │   └── metronome_service.dart     # Servicio del metrónomo
│   └── storage/
│       └── database_helper.dart       # SQLite CRUD operations
├── features/
│   └── tutor/
│       └── presentation/
│           ├── screens/
│           │   ├── tutor_home_screen.dart      # Home principal
│           │   ├── course_list_screen.dart     # Lista de cursos
│           │   ├── course_detail_screen.dart   # Detalle de curso
│           │   ├── exercise_screen.dart        # Pantalla de práctica
│           │   ├── exercise_results_screen.dart # Resultados
│           │   └── diagnostic_screen.dart      # Test de nivel
│           ├── widgets/
│           │   ├── course_card.dart            # Card de curso
│           │   ├── feedback_card.dart          # Feedback en tiempo real
│           │   ├── timing_indicator.dart       # Indicador de beat
│           │   └── note_display.dart           # Display de notas/tabs
│           └── providers/
│               └── tutor_providers.dart        # Providers de Riverpod
├── shared/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── typography.dart
│   └── widgets/
│       ├── glass_card.dart            # Componente glassmorphism
│       └── [otros widgets compartidos]
└── tools/
    └── dev_tools_screen.dart          # Herramientas de desarrollo

assets/
└── data/
    └── exercises/
        ├── courses.json               # Definición de cursos
        └── exercises.json             # Definición de ejercicios
```

---

## Modelos de Dominio

### Exercise
```dart
class Exercise {
  final String id;
  final String name;
  final ExerciseType type;      // timing, singleNotes, chords, technique, mixed
  final DifficultyLevel difficulty;
  final int targetBpm;
  final List<ExpectedNote> expectedNotes;
  final String instructions;
  // ...
}

class ExpectedNote {
  final String note;            // "E4", "A3"
  final int? fret;
  final int? string;
  final double startBeat;       // Beat donde debe sonar
  final double duration;
  final bool isRest;
}
```

### ExerciseResult
```dart
class ExerciseResult {
  final double overallScore;    // 0-100
  final double timingScore;
  final double noteAccuracy;
  final List<NoteFeedback> noteFeedback;
  final TimingAnalysis? timingAnalysis;
  final bool passed;            // Score >= 70
}
```

### UserProgress
```dart
class UserProgress {
  final String odingId;
  final Map<String, ExerciseProgress> exerciseProgress;
  final Map<String, CourseProgress> courseProgress;
  final DifficultyLevel currentLevel;
  final DiagnosticResult? latestDiagnostic;
  final int totalPracticeMinutes;
  final int currentStreak;
}
```

---

## Servicios Principales

### ExerciseEvaluationService (CORE)
El servicio más importante. Conecta el análisis de audio con la evaluación de ejercicios.

```dart
class ExerciseEvaluationService {
  // Iniciar ejercicio con countdown
  Future<void> startExercise(Exercise exercise, {int? bpm});

  // Streams para UI
  Stream<RealTimeFeedback> get realTimeFeedback;
  Stream<ExerciseState> get stateChanges;
  Stream<int> get beatChanges;

  // Evaluar al finalizar
  Future<ExerciseResult> evaluateExercise(String odingId);
}
```

**Flujo de evaluación:**
1. Usuario inicia ejercicio → countdown con metrónomo
2. Durante ejercicio: `RealTimeAudioAnalysisService` detecta notas
3. Cada nota detectada se compara con `expectedNotes`
4. Se emite `RealTimeFeedback` para UI
5. Al finalizar: se calcula `ExerciseResult`

### CourseProgressService
Gestiona cursos, ejercicios y progreso del usuario.

```dart
class CourseProgressService {
  Future<List<Course>> getAvailableCourses(DifficultyLevel? level);
  Future<void> recordExerciseResult(ExerciseResult result);
  Future<bool> isExerciseUnlocked(String exerciseId, String odingId);
  Future<Exercise?> getNextRecommendedExercise(String odingId);
}
```

### AIFeedbackService
Genera tips basados en reglas (MVP). Preparado para integración LLM futura.

```dart
class AIFeedbackService {
  List<String> generateTips(ExerciseResult result);
  Future<SessionFeedback> generateSessionFeedback(List<ExerciseResult> results);
}
```

### DiagnosticService
Evalúa el nivel del usuario mediante ejercicios de diagnóstico.

```dart
class DiagnosticService {
  Future<List<Exercise>> getDiagnosticExercises();
  Future<DiagnosticResult> runDiagnostic(String odingId, List<ExerciseResult> results);
}
```

---

## Providers (Riverpod)

```dart
// Usuario actual
final currentUserIdProvider = StateProvider<String>((ref) => 'default_user');

// Progreso del usuario
final userProgressProvider = FutureProvider<UserProgress?>((ref) async {...});

// Cursos disponibles
final coursesProvider = FutureProvider<List<Course>>((ref) async {...});

// Estado del ejercicio actual
final currentExerciseStateProvider = StreamProvider<ExerciseState>((ref) {...});

// Beat actual durante ejercicio
final currentBeatProvider = StreamProvider<int>((ref) {...});

// Feedback en tiempo real
final realTimeFeedbackProvider = StreamProvider<RealTimeFeedback>((ref) {...});
```

---

## Flujo de Usuario

```
┌─────────────────┐
│  TutorHomeScreen │
│  - Stats        │
│  - Continuar    │
│  - Cursos       │
│  - Diagnóstico  │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌──────────────┐
│Diagnós-│ │CourseListScreen│
│tico    │ │              │
└────┬───┘ └──────┬───────┘
     │            │
     ▼            ▼
┌─────────────────────┐
│ CourseDetailScreen  │
│ - Lista ejercicios  │
│ - Progreso         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   ExerciseScreen    │
│ - Countdown         │
│ - Notas esperadas   │
│ - Feedback tiempo   │
│   real              │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ExerciseResultsScreen│
│ - Score             │
│ - Desglose          │
│ - Tips              │
└─────────────────────┘
```

---

## Base de Datos

### Tablas Principales

```sql
-- Progreso general del usuario
user_progress (
  oding_id TEXT PRIMARY KEY,
  current_level TEXT,
  total_practice_minutes INTEGER,
  current_streak INTEGER,
  ...
)

-- Progreso por ejercicio
exercise_progress (
  oding_id TEXT,
  exercise_id TEXT,
  status TEXT,           -- locked, available, inProgress, completed, mastered
  attempts INTEGER,
  best_score REAL,
  ...
)

-- Resultados de ejercicios
exercise_results (
  id TEXT PRIMARY KEY,
  oding_id TEXT,
  exercise_id TEXT,
  overall_score REAL,
  timing_score REAL,
  note_accuracy REAL,
  ...
)

-- Resultados de diagnóstico
diagnostic_results (
  id TEXT PRIMARY KEY,
  oding_id TEXT,
  recommended_level TEXT,
  category_scores TEXT,  -- JSON
  ...
)
```

---

## Formato de Ejercicios (JSON)

### courses.json
```json
{
  "id": "course_timing_fundamentals",
  "name": "Fundamentos de Timing",
  "difficulty": "beginner",
  "modules": [
    {
      "id": "mod_timing_basics",
      "name": "Pulso Básico",
      "exerciseIds": ["timing_pulse_60", "timing_pulse_80"],
      "prerequisiteModuleId": null
    }
  ],
  "category": "timing",
  "estimatedMinutes": 30,
  "learningObjectives": ["Mantener pulso constante", ...]
}
```

### exercises.json
```json
{
  "id": "timing_pulse_60",
  "name": "Pulso Básico 60 BPM",
  "type": "timing",
  "difficulty": "beginner",
  "targetBpm": 60,
  "beatsPerMeasure": 4,
  "totalBeats": 16,
  "expectedNotes": [
    {"note": "E2", "string": 6, "fret": 0, "startBeat": 0, "duration": 1},
    {"note": "E2", "string": 6, "fret": 0, "startBeat": 1, "duration": 1},
    ...
  ],
  "instructions": "Toca una nota por beat...",
  "tips": ["Cuenta mentalmente 1-2-3-4", ...],
  "courseId": "course_timing_fundamentals"
}
```

---

## Extender el Sistema

### Agregar un Nuevo Curso

1. Agregar definición en `assets/data/exercises/courses.json`
2. Agregar ejercicios en `assets/data/exercises/exercises.json`
3. Asegurar que `courseId` en ejercicios coincida con `id` del curso

### Agregar Nuevo Tipo de Ejercicio

1. Agregar valor a `ExerciseType` en `exercise.dart`
2. Modificar `ExerciseEvaluationService._evaluateDetectedNote()` si requiere lógica especial
3. Actualizar UI en `ExerciseScreen` si requiere visualización diferente

### Integrar LLM para Feedback

1. Crear `lib/core/services/llm_service.dart`
2. Modificar `AIFeedbackService.generateTips()` para llamar al LLM
3. Implementar fallback a reglas si API no disponible

```dart
class LLMService {
  Future<String> generateFeedback(ExerciseResult result, Exercise exercise) async {
    // Llamar a Claude API
    // Prompt: "El usuario completó {exercise.name} con score {result.overallScore}..."
  }
}
```

### Agregar Detección de Acordes en Ejercicios

1. Crear ejercicios con `type: "chords"`
2. En `expectedNotes`, usar formato de acorde:
   ```json
   {"note": "Am", "startBeat": 0, "duration": 4}
   ```
3. Modificar evaluación para usar `ChordRecognitionService`

---

## Testing

### Verificar Compilación
```bash
flutter pub get
flutter analyze
```

### Ejecutar App
```bash
flutter run
```

### Estructura de Tests Recomendada
```
test/
├── core/
│   ├── models/
│   │   └── exercise_test.dart
│   └── services/
│       ├── exercise_evaluation_service_test.dart
│       └── course_progress_service_test.dart
└── features/
    └── tutor/
        └── presentation/
            └── screens/
                └── exercise_screen_test.dart
```

---

## Próximos Pasos Sugeridos

1. **Fase 6: Integración LLM** - Feedback personalizado con Claude API
2. **Acordes** - Agregar ejercicios de acordes usando `ChordRecognitionService`
3. **Técnicas** - Ejercicios de hammer-on, pull-off usando `TechniqueDetectionService`
4. **Gamificación** - Sistema de logros y recompensas
5. **Audio Visual** - Visualización de espectro de frecuencias durante práctica

---

## Servicios Conservados (No Modificar)

Estos servicios existentes contienen lógica compleja de audio que funciona:

- `real_time_audio_analysis_service.dart` - Detección de pitch y tono
- `chord_recognition_service.dart` - Identificación de acordes
- `technique_detection_service.dart` - Detección de técnicas de guitarra
- `metronome_service.dart` - Metrónomo con soporte web/mobile

---

*Documentación generada: Enero 2026*
*Versión: 2.0 - Reestructuración como Tutor IA*
