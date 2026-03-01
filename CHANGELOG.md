# Changelog

## [2.0.0] - 2026-01-24

### Reestructuración Mayor: Tutor de Guitarra con IA

La app fue completamente reestructurada para enfocarse en ser un tutor de guitarra que escucha al usuario y proporciona feedback en tiempo real.

### Agregado

#### Nuevos Modelos (`lib/core/models/`)
- `exercise.dart` - Modelo de ejercicio con notas esperadas
- `course.dart` - Modelo de curso con módulos
- `exercise_result.dart` - Resultados de ejercicios con feedback detallado
- `user_progress.dart` - Progreso del usuario con tracking de streaks

#### Nuevos Servicios (`lib/core/services/`)
- `exercise_evaluation_service.dart` - Evaluación de ejercicios en tiempo real
- `course_progress_service.dart` - Gestión de cursos y progreso
- `ai_feedback_service.dart` - Generación de tips basados en reglas
- `diagnostic_service.dart` - Test de nivel del usuario

#### Nueva Feature: Tutor (`lib/features/tutor/`)
- `tutor_home_screen.dart` - Pantalla principal con stats y accesos rápidos
- `course_list_screen.dart` - Lista de cursos disponibles
- `course_detail_screen.dart` - Detalle de curso con ejercicios
- `exercise_screen.dart` - Pantalla de práctica con feedback en tiempo real
- `exercise_results_screen.dart` - Resultados con desglose y tips
- `diagnostic_screen.dart` - Test de nivel

#### Nuevos Widgets
- `course_card.dart` - Card para mostrar cursos
- `feedback_card.dart` - Feedback visual durante ejercicio
- `timing_indicator.dart` - Indicador de beat/compás
- `note_display.dart` - Visualización de notas esperadas

#### Contenido Inicial (`assets/data/exercises/`)
- 2 cursos: "Fundamentos de Timing" y "Primeras Notas"
- 22 ejercicios progresivos
- 4 ejercicios de diagnóstico

#### Documentación (`docs/`)
- `ARCHITECTURE.md` - Arquitectura completa del proyecto
- `QUICKSTART.md` - Guía de inicio rápido

### Eliminado

#### Servicios Eliminados (20 archivos)
- `spotify_service.dart`
- `spotify_playlist_service.dart`
- `spotify_smart_recommendations_service.dart`
- `social_features_service.dart`
- `cloud_sync_service.dart`
- `achievements_service.dart`
- `adaptive_learning_service.dart`
- `advanced_analytics_service.dart`
- `production_monitoring_service.dart`
- `intelligent_backing_tracks_service.dart`
- `backing_track_service.dart`
- `tone_preset_service.dart`
- `secure_credentials_service.dart`
- `tablature_service.dart`
- `riff_loader_service.dart`
- `tips_engine_service.dart`
- `optimized_database_service.dart`
- `performance_monitor.dart`
- `audio_player_service.dart`
- `onboarding_service.dart`

#### Features Eliminados
- `lib/features/tone_presets/` - Presets de tono
- `lib/features/onboarding/` - Onboarding original
- `lib/features/history/` - Historial de sesiones

#### Widgets Eliminados
- `spotify_playlist_widget.dart`
- `advanced_analytics_widget.dart`
- `analytics_chart_widget.dart`
- `smart_recommendations_widget.dart`
- `intelligent_backing_tracks_widget.dart`
- `optimized_preset_grid.dart`
- `memory_optimized_audio_widget.dart`
- `audio_preview_controls.dart`

#### Modelos Eliminados
- `tone_preset.dart`
- `song_riff.dart`

#### Otros Eliminados
- `main_stable.dart`
- `main_demo.dart`
- `main_safe.dart`
- Firebase initialization (simplificado)
- Secure credentials initialization

### Modificado

#### Base de Datos
- Nueva versión de schema (v2)
- Nuevas tablas: `exercise_progress`, `course_progress`, `exercise_results`, `diagnostic_results`
- Migración automática desde v1

#### Entry Points
- `main.dart` - Simplificado, sin Firebase/credentials
- `app.dart` - Ahora carga `TutorHomeScreen`

#### Dependencias
- Agregado: `uuid: ^4.2.1`
- Actualizado: assets paths en `pubspec.yaml`

### Servicios Conservados
Los siguientes servicios de audio fueron conservados por su complejidad y funcionalidad:
- `real_time_audio_analysis_service.dart`
- `chord_recognition_service.dart`
- `technique_detection_service.dart`
- `recording_service.dart`
- `feedback_analysis_service.dart`
- `metronome_service.dart`
- `input_validation_service.dart`
- `secure_logging_service.dart`
- `stats_service.dart`

---

## [1.0.0] - 2024-XX-XX

### Initial Release
- App original con múltiples features
- Integración Spotify
- Sistema de backing tracks
- Analytics avanzados
- Social features
