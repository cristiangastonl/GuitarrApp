# GuitarrApp - Guía de Inicio Rápido

## Requisitos

- Flutter 3.16+
- Dart 3.2+
- iOS 12+ / Android API 21+

## Instalación

```bash
# Clonar repositorio
git clone <repo-url>
cd GuitarrApp

# Instalar dependencias
flutter pub get

# Ejecutar
flutter run
```

## Estructura Rápida

```
lib/
├── core/
│   ├── models/          # Modelos de datos
│   ├── services/        # Lógica de negocio
│   └── storage/         # Base de datos
├── features/
│   └── tutor/           # Feature principal
│       └── presentation/
│           ├── screens/ # Pantallas
│           ├── widgets/ # Componentes
│           └── providers/ # Estado (Riverpod)
└── shared/              # Componentes compartidos
```

## Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `lib/core/services/exercise_evaluation_service.dart` | Evaluación de ejercicios |
| `lib/features/tutor/presentation/screens/exercise_screen.dart` | Pantalla de práctica |
| `assets/data/exercises/exercises.json` | Definición de ejercicios |
| `assets/data/exercises/courses.json` | Definición de cursos |

## Agregar un Ejercicio

1. Abrir `assets/data/exercises/exercises.json`
2. Agregar nuevo ejercicio:

```json
{
  "id": "mi_ejercicio_01",
  "name": "Mi Ejercicio",
  "type": "timing",
  "difficulty": "beginner",
  "targetBpm": 60,
  "beatsPerMeasure": 4,
  "totalBeats": 8,
  "expectedNotes": [
    {"note": "E2", "string": 6, "fret": 0, "startBeat": 0, "duration": 1},
    {"note": "E2", "string": 6, "fret": 0, "startBeat": 1, "duration": 1}
  ],
  "instructions": "Instrucciones aquí",
  "courseId": "course_id_existente"
}
```

3. Hot reload o reiniciar app

## Agregar un Curso

1. Abrir `assets/data/exercises/courses.json`
2. Agregar curso:

```json
{
  "id": "mi_curso",
  "name": "Mi Nuevo Curso",
  "difficulty": "beginner",
  "modules": [
    {
      "id": "mod_1",
      "name": "Módulo 1",
      "exerciseIds": ["mi_ejercicio_01"],
      "orderInCourse": 0
    }
  ],
  "category": "timing",
  "estimatedMinutes": 15,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

## Tipos de Ejercicio

| Tipo | Descripción |
|------|-------------|
| `timing` | Solo ritmo, sin importar la nota |
| `singleNotes` | Notas individuales específicas |
| `chords` | Acordes (futuro) |
| `technique` | Técnicas específicas (futuro) |
| `mixed` | Combinación |

## Niveles de Dificultad

- `beginner` - Principiante
- `intermediate` - Intermedio
- `advanced` - Avanzado
- `expert` - Experto

## Formato de Notas

```json
{
  "note": "E2",      // Nota con octava
  "string": 6,       // Cuerda (1-6, 1=prima)
  "fret": 0,         // Traste (0=al aire)
  "startBeat": 0,    // Beat de inicio
  "duration": 1,     // Duración en beats
  "isRest": false    // true para silencios
}
```

## Debugging

### Ver logs de audio
```dart
import 'package:flutter/foundation.dart';
debugPrint('Nota detectada: $note');
```

### Acceder a Dev Tools
La ruta `/dev-tools` está disponible para herramientas de desarrollo.

## Providers Principales

```dart
// Obtener progreso del usuario
final progress = ref.watch(userProgressProvider);

// Obtener cursos
final courses = ref.watch(coursesProvider);

// Estado del ejercicio actual
final state = ref.watch(currentExerciseStateProvider);

// Feedback en tiempo real
final feedback = ref.watch(realTimeFeedbackProvider);
```

## FAQ

**¿Cómo cambio el usuario predeterminado?**
```dart
ref.read(currentUserIdProvider.notifier).state = 'nuevo_id';
```

**¿Cómo reseteo el progreso?**
```dart
await DatabaseHelper.deleteAllData();
```

**¿Dónde está la detección de audio?**
`lib/core/services/real_time_audio_analysis_service.dart`

**¿Cómo agrego feedback personalizado?**
Modificar `lib/core/services/ai_feedback_service.dart`
