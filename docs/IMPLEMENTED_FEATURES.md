# GuitarrApp - Funcionalidades Implementadas

## Resumen

Aplicación web/móvil para aprender guitarra con detección de audio en tiempo real, ejercicios interactivos y feedback inmediato.

---

## Stack Tecnológico

- **Framework**: Flutter 3.x
- **Estado**: Riverpod
- **Plataforma Principal**: Web (Chrome)
- **Audio Web**: Web Audio API (JavaScript)
- **Base de Datos**: SQLite (solo móvil, pendiente para web)

---

## Funcionalidades Implementadas

### 1. Sistema de Cursos y Ejercicios

#### Estructura
- Cursos organizados por nivel de dificultad
- Módulos dentro de cada curso
- Ejercicios con progresión lógica
- Sistema de prerequisitos entre módulos

#### Cursos Disponibles (7 total)

| Curso | Nivel | Ejercicios | Estado |
|-------|-------|------------|--------|
| Fundamentos de Timing | Principiante | 8 | ✅ Completo |
| Primeras Notas | Principiante | 9 | ✅ Completo |
| Coordinación de Manos | Principiante | 6 | ✅ Completo |
| Acordes Abiertos | Principiante | 11 | ⏳ Sin ejercicios |
| Patrones de Rasgueo | Intermedio | 6 | ⏳ Sin ejercicios |
| Técnicas Expresivas | Intermedio | 7 | ⏳ Sin ejercicios |
| Escala Pentatónica | Intermedio | 6 | ⏳ Sin ejercicios |

#### Ejercicios Implementados (23 total)

**Fundamentos de Timing:**
- Pulso Básico 60/80/100 BPM
- Corcheas 60/80 BPM
- Silencios Rítmicos
- Patrón Mixto
- Síncopa Básica

**Primeras Notas:**
- Cuerda 6 (Mi grave)
- Cuerda 5 (La)
- Cuerda 4 (Re)
- Cuerdas Graves E-A-D
- Las 6 Cuerdas
- Primer/Segundo/Tercer Traste
- Cromático en E

**Coordinación de Manos:**
- Ejercicio 1-2-3-4 (lento/medio)
- 1-2-3-4 Moviendo de Cuerda
- Patrón 1-3-2-4
- Patrón 1-4-2-3
- Patrón Reverso 4-3-2-1

---

### 2. Sistema de Audio Web

#### Captura de Micrófono
- **Archivo**: `web/audio_capture.js` + `lib/core/audio/web_audio_capture.dart`
- Captura de audio del micrófono via Web Audio API
- Análisis de pitch en tiempo real
- Detección de nota musical (A-G con octava)
- Cálculo de frecuencia y confianza
- Indicador de afinación (cents)

#### Síntesis de Audio (Demo)
- **Archivo**: `web/audio_synth.js` + `lib/core/audio/audio_synth_service.dart`
- Generación de tonos de guitarra simulados
- Reproducción de ejercicios de ejemplo
- Metrónomo integrado
- Soporte para todas las notas de guitarra estándar

#### Metrónomo
- **Archivo**: `web/metronome_web.js` + `lib/core/audio/metronome_service.dart`
- Click de metrónomo con acentos
- Tempo ajustable (40-200 BPM)
- Sincronización con ejercicios

---

### 3. Pantallas Implementadas

#### Pantalla Principal (TutorHomeScreen)
- Tarjeta de bienvenida/estadísticas
- Sugerencia de test diagnóstico
- Grid de acciones: Cursos, Diagnóstico, Test Micro

#### Lista de Cursos (CourseListScreen)
- Lista de todos los cursos disponibles
- Filtro por dificultad
- Indicador de progreso (cuando hay DB)

#### Detalle de Curso (CourseDetailScreen)
- Header con info del curso
- Objetivos de aprendizaje
- Lista de ejercicios del curso
- Estado de cada ejercicio (completado/en progreso/bloqueado)

#### Pantalla de Ejercicio (ExerciseScreen)
- **Pre-ejercicio:**
  - Botón "Escuchar Demo" - reproduce el ejercicio
  - Vista previa de notas del ejercicio
  - Instrucciones y consejos
  - Selector de BPM ajustable
- **Durante ejercicio:**
  - Indicador de timing (beat actual)
  - Visualización de notas por compás
  - Feedback en tiempo real (nota tocada vs esperada)
- **Post-ejercicio:**
  - Navegación a resultados

#### Test de Micrófono (MicTestScreen)
- Estado del micrófono (conectado/desconectado)
- Nota detectada en tiempo real
- Frecuencia en Hz
- Nivel de confianza (%)
- Indicador de afinación (cents)
- Gráfico de nivel de señal
- Historial de notas detectadas
- Instrucciones de uso

#### Pantalla de Diagnóstico (DiagnosticScreen)
- Ejercicios de evaluación de nivel
- Determina nivel del usuario

---

### 4. Componentes UI

#### Widgets Personalizados
- **GlassCard**: Efecto glassmorphism para tarjetas
- **TimingIndicator**: Muestra beat actual y progreso
- **NoteDisplay**: Visualización de notas por compás
- **FeedbackCard**: Feedback de nota tocada (correcto/incorrecto/timing)

#### Tema
- Tema oscuro por defecto
- Colores primarios: naranja/ámbar
- Fuentes y espaciado consistentes

---

### 5. Servicios

#### CourseProgressService
- Carga de cursos desde JSON
- Carga de ejercicios desde JSON
- Gestión de progreso del usuario (requiere DB)

#### ExerciseEvaluationService
- Evaluación de ejercicios en tiempo real
- Detección de notas tocadas vs esperadas
- Cálculo de timing (perfecto/bueno/ok/tarde/temprano)
- Generación de resultados

#### RealTimeAudioAnalysisService
- Análisis de audio en tiempo real
- Detección de pitch
- Stream de resultados de detección

---

## Archivos de Datos

### Cursos
- **Ubicación**: `assets/data/exercises/courses.json`
- 7 cursos definidos con módulos y ejercicios

### Ejercicios
- **Ubicación**: `assets/data/exercises/exercises.json`
- 23 ejercicios con notas, instrucciones y consejos

---

## Limitaciones Actuales

### Web
1. **Base de datos**: SQLite no funciona en web, por lo que:
   - No se guarda progreso del usuario
   - No hay estadísticas persistentes
   - Todos los ejercicios están desbloqueados

2. **Audio**:
   - Requiere interacción del usuario para iniciar (política de Chrome)
   - La detección de pitch puede variar según el micrófono

### Ejercicios Pendientes
- Acordes Abiertos (11 ejercicios)
- Patrones de Rasgueo (6 ejercicios)
- Técnicas Expresivas (7 ejercicios)
- Escala Pentatónica (6 ejercicios)

---

## Cómo Ejecutar

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Chrome
flutter run -d chrome
```

---

## Próximos Pasos Sugeridos

1. **Completar ejercicios** para cursos pendientes
2. **Implementar almacenamiento web** (IndexedDB o localStorage)
3. **Mejorar detección de pitch** para mayor precisión
4. **Agregar visualización de tablatura** en ejercicios
5. **Sistema de logros/achievements**
6. **Modo offline** con service workers

---

## Estructura de Archivos Clave

```
lib/
├── core/
│   ├── audio/
│   │   ├── metronome_service.dart
│   │   ├── web_audio_capture.dart
│   │   └── audio_synth_service.dart
│   ├── models/
│   │   ├── course.dart
│   │   ├── exercise.dart
│   │   └── user_progress.dart
│   └── services/
│       ├── course_progress_service.dart
│       └── exercise_evaluation_service.dart
├── features/
│   └── tutor/
│       └── presentation/
│           ├── screens/
│           │   ├── tutor_home_screen.dart
│           │   ├── course_list_screen.dart
│           │   ├── course_detail_screen.dart
│           │   ├── exercise_screen.dart
│           │   └── mic_test_screen.dart
│           └── widgets/
│               ├── note_display.dart
│               ├── timing_indicator.dart
│               └── feedback_card.dart
└── shared/
    └── widgets/
        └── glass_card.dart

web/
├── audio_capture.js    # Captura de micrófono
├── audio_synth.js      # Síntesis de audio
└── metronome_web.js    # Metrónomo

assets/data/exercises/
├── courses.json        # Definición de cursos
└── exercises.json      # Definición de ejercicios
```
