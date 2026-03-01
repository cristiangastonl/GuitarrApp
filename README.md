# GuitarrApp 🎸
**Tutor de Guitarra con IA - Aprende tocando con feedback en tiempo real**

## 🎵 Acerca del Proyecto

GuitarrApp es un tutor de guitarra que **escucha mientras tocas** y te da feedback en tiempo real. Mediante detección de pitch y análisis de audio, evalúa tu precisión de timing y notas, ayudándote a mejorar de forma medible.

**Versión:** 2.0
**Plataforma:** Flutter (iOS/Android)
**Arquitectura:** Clean Architecture + Riverpod

---

## ✨ Características Principales

### 🎯 Práctica Guiada
- Ejercicios progresivos de timing y notas
- Feedback visual en tiempo real (verde/amarillo/rojo)
- Metrónomo integrado con indicador de beat
- Cursos estructurados con desbloqueo progresivo

### 📊 Evaluación Inteligente
- Puntuación de timing, precisión y consistencia
- Análisis detallado de cada nota tocada
- Tips personalizados basados en tu desempeño
- Test de nivel para determinar tu punto de partida

### 📈 Seguimiento de Progreso
- Historial de ejercicios completados
- Racha diaria de práctica
- Estadísticas de tiempo practicado
- Progreso por curso y módulo

---

## 🏗️ Arquitectura

```
lib/
├── core/
│   ├── models/          # Exercise, Course, ExerciseResult, UserProgress
│   ├── services/        # Evaluación, progreso, feedback, diagnóstico
│   ├── audio/           # Metrónomo
│   └── storage/         # SQLite
├── features/
│   └── tutor/
│       └── presentation/
│           ├── screens/   # Home, cursos, ejercicio, resultados
│           ├── widgets/   # Feedback, timing, notas
│           └── providers/ # Riverpod state
└── shared/
    ├── theme/           # Tema glassmorphic
    └── widgets/         # Componentes reutilizables

assets/
└── data/exercises/
    ├── courses.json     # Definición de cursos
    └── exercises.json   # Definición de ejercicios
```

---

## 🚀 Inicio Rápido

```bash
# Instalar dependencias
flutter pub get

# Ejecutar
flutter run

# Verificar código
flutter analyze
```

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arquitectura completa del proyecto |
| [docs/QUICKSTART.md](docs/QUICKSTART.md) | Guía para agregar ejercicios y cursos |
| [docs/TODO.md](docs/TODO.md) | Próximos pasos y mejoras pendientes |
| [CHANGELOG.md](CHANGELOG.md) | Historial de cambios |

---

## 🎮 Flujo de Usuario

```
Home → Cursos → Detalle Curso → Ejercicio → Resultados
  │
  └── Diagnóstico → Test de Nivel → Recomendaciones
```

1. **Home**: Ver stats, continuar práctica, acceder a cursos
2. **Cursos**: Elegir curso según nivel y categoría
3. **Ejercicio**: Practicar con metrónomo y feedback en tiempo real
4. **Resultados**: Ver puntuación, desglose y tips para mejorar

---

## 🎸 Contenido Incluido

### Cursos
- **Fundamentos de Timing** (10 ejercicios) - Pulso, corcheas, silencios, síncopa
- **Primeras Notas** (8 ejercicios) - Cuerdas al aire, trastes, melodía simple

### Ejercicios de Diagnóstico
- Timing básico e intermedio
- Notas básico e intermedio

---

## 🔧 Tecnologías

- **Flutter 3.16+** - Framework multiplataforma
- **Riverpod** - State management reactivo
- **SQLite** - Persistencia local
- **flutter_sound** - Captura de audio
- **fftea** - Análisis FFT para detección de pitch

---

## 📱 Servicios Core

| Servicio | Función |
|----------|---------|
| `ExerciseEvaluationService` | Evaluación de ejercicios en tiempo real |
| `CourseProgressService` | Gestión de cursos y progreso |
| `AIFeedbackService` | Generación de tips (reglas/MVP) |
| `DiagnosticService` | Test de nivel |
| `RealTimeAudioAnalysisService` | Detección de pitch y análisis de audio |

---

## 🔮 Roadmap

- [ ] **Fase 6**: Integración LLM para feedback personalizado
- [ ] **Acordes**: Ejercicios de cambio de acordes
- [ ] **Técnicas**: Hammer-on, pull-off, bends
- [ ] **Gamificación**: Logros y recompensas

---

## 📄 Licencia

Proyecto privado - Todos los derechos reservados

---

**Desarrollado con ❤️ para guitarristas**
*GuitarrApp - Aprende tocando, no solo mirando* 🎸
