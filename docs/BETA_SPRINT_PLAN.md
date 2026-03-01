# GuitarrApp - Plan de Sprint hacia Beta

**Fecha:** 2026-01-28
**Objetivo:** Aplicacion funcional para Beta testing
**Duracion estimada:** 5 dias de desarrollo intensivo

---

## Estado Actual (Resumen de Auditoria)

| Area | Estado | Critico para Beta |
|------|--------|-------------------|
| Errores de compilacion | 28 errores (referencias eliminadas) | SI |
| Audio Web | Funcional (WebAudio API) | OK |
| Audio Movil | Solo stub (no implementado) | SI |
| Deteccion de Pitch | Funcional on-device | OK |
| Evaluacion de ejercicios | Production-ready | OK |
| Base de datos | SQLite funcional, falla en web | PARCIAL |
| Onboarding | Eliminado completamente | SI |
| Feedback IA | Solo reglas estaticas | NO (post-beta) |
| Contenido (cursos/ejercicios) | 7 cursos, ~50 ejercicios | OK |

---

## Arquitectura de Trabajo por Agente

```
+------------------+     +------------------+     +------------------+
|    FRONTEND      |     |     BACKEND      |     |       UX         |
+------------------+     +------------------+     +------------------+
| - Corregir       |     | - Audio movil    |     | - Onboarding     |
|   errores        |     | - Persistencia   |     | - Celebraciones  |
| - Pantallas      |     |   multiplataforma|     | - Indicador      |
| - Integracion    |     | - APIs de        |     |   "cuando tocar" |
|   componentes    |     |   servicios      |     | - Polish visual  |
+------------------+     +------------------+     +------------------+
        |                        |                        |
        +------------------------+------------------------+
                                 |
                    +------------------------+
                    |    APP BETA READY      |
                    +------------------------+
```

---

## FASE 1: Estabilizacion (Dia 1-2)
> **Objetivo:** App que compila y corre sin errores

### Backend - Prioridad CRITICA

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| B1.1 | Eliminar referencias a `backing_track_service.dart` | Ninguna | 30min |
| B1.2 | Eliminar referencias a `tips_engine_service.dart` | Ninguna | 30min |
| B1.3 | Eliminar referencias a `secure_credentials_service.dart` | Ninguna | 30min |
| B1.4 | Eliminar/reemplazar referencias a `SongRiff`, `TonePreset` | B1.1-B1.3 | 1h |
| B1.5 | Corregir `stats_service.dart` - metodos `getAllSessions`, `getSessionsByRiff` | B1.4 | 1h |
| B1.6 | Limpiar `secure_database_helper.dart` de tipos eliminados | B1.4 | 1h |

**Archivos afectados:**
- `/lib/core/services/feedback_analysis_service.dart`
- `/lib/core/services/stats_service.dart`
- `/lib/core/storage/secure_database_helper.dart`
- `/lib/features/feedback/presentation/screens/feedback_screen.dart`

### Frontend - Prioridad CRITICA

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| F1.1 | Corregir imports en `feedback_screen.dart` | B1.1, B1.2 | 1h |
| F1.2 | Reemplazar providers eliminados con alternativas | F1.1 | 2h |
| F1.3 | Validar que todas las pantallas rendericen | F1.2 | 1h |
| F1.4 | Probar flujo completo: Home -> Curso -> Ejercicio -> Resultado | F1.3 | 1h |

### UX - Puede trabajar en paralelo

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| U1.1 | Auditar sistema de diseno actual | Ninguna | 2h |
| U1.2 | Documentar componentes existentes (GlassCard, etc.) | U1.1 | 1h |
| U1.3 | Crear mockups de onboarding (3-4 pantallas) | Ninguna | 3h |

---

## FASE 2: Audio Movil (Dia 2-3)
> **Objetivo:** Captura de audio funcional en iOS/Android

### Backend - Prioridad ALTA

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| B2.1 | Implementar `MobileAudioCaptureService` usando flutter_sound | FASE 1 | 3h |
| B2.2 | Crear interfaz comun `AudioCaptureInterface` | B2.1 | 1h |
| B2.3 | Implementar conditional imports (web vs mobile) | B2.2 | 1h |
| B2.4 | Integrar con `RealTimeAudioAnalysisService` | B2.3 | 2h |
| B2.5 | Manejar permisos de microfono (permission_handler) | B2.1 | 1h |

**Archivos a crear:**
- `/lib/core/audio/mobile_audio_capture.dart`
- `/lib/core/audio/mobile_audio_capture_stub.dart`
- `/lib/core/audio/audio_capture_interface.dart`

### Frontend - Prioridad ALTA

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| F2.1 | Actualizar `MicTestScreen` para usar nuevo servicio | B2.3 | 1h |
| F2.2 | UI de solicitud de permisos | B2.5 | 1h |
| F2.3 | Indicador de nivel de audio en tiempo real | B2.4 | 2h |

### UX - Paralelo

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| U2.1 | Disenar pantalla de permisos de microfono | Ninguna | 1h |
| U2.2 | Disenar estados de MicTestScreen (sin permiso, probando, listo) | U2.1 | 1h |

---

## FASE 3: Onboarding (Dia 3-4)
> **Objetivo:** Primera experiencia de usuario completa

### UX - Lider de esta fase

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| U3.1 | Finalizar diseno de flujo de onboarding | U1.3 | 1h |
| U3.2 | Definir copy/textos de cada pantalla | U3.1 | 1h |
| U3.3 | Especificar animaciones y transiciones | U3.2 | 1h |

**Pantallas requeridas:**
1. **Welcome** - Propuesta de valor, comenzar
2. **Permiso Microfono** - Explicacion + solicitud
3. **Test de Microfono** - Verificacion rapida
4. **Nivel Inicial** - Principiante/Intermedio/Avanzado (opcional diagnostic)
5. **Listo** - Resumen + ir a home

### Frontend - Implementacion

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| F3.1 | Crear `OnboardingFlow` widget con PageView | U3.1 | 2h |
| F3.2 | Implementar `WelcomeScreen` | F3.1 | 1h |
| F3.3 | Implementar `MicPermissionScreen` | F3.1, B2.5 | 1h |
| F3.4 | Implementar `QuickMicTestScreen` | F3.3, B2.4 | 2h |
| F3.5 | Implementar `LevelSelectionScreen` | F3.1 | 1h |
| F3.6 | Implementar `OnboardingCompleteScreen` | F3.1 | 1h |
| F3.7 | Integrar con `app.dart` (mostrar onboarding si es primera vez) | F3.1-F3.6 | 1h |

**Archivos a crear:**
- `/lib/features/onboarding/presentation/screens/onboarding_flow.dart`
- `/lib/features/onboarding/presentation/screens/welcome_screen.dart`
- `/lib/features/onboarding/presentation/screens/mic_permission_screen.dart`
- `/lib/features/onboarding/presentation/screens/level_selection_screen.dart`
- `/lib/features/onboarding/presentation/widgets/onboarding_page.dart`

### Backend - Soporte

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| B3.1 | Crear `OnboardingService` (estado de onboarding) | Ninguna | 1h |
| B3.2 | Persistir preferencias de usuario (SharedPreferences) | B3.1 | 30min |
| B3.3 | Provider para estado de onboarding | B3.2 | 30min |

---

## FASE 4: Polish UX (Dia 4-5)
> **Objetivo:** Experiencia pulida y satisfactoria

### UX - Prioridad ALTA

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| U4.1 | Disenar sistema de celebraciones (confetti, etc.) | FASE 3 | 2h |
| U4.2 | Disenar indicador visual "cuando tocar" | Ninguna | 2h |
| U4.3 | Revisar y pulir transiciones entre pantallas | FASE 3 | 1h |

### Frontend - Implementacion

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| F4.1 | Implementar widget de celebracion | U4.1 | 2h |
| F4.2 | Integrar celebracion en `ExerciseResultsScreen` | F4.1 | 1h |
| F4.3 | Implementar indicador "cuando tocar" en `ExerciseScreen` | U4.2 | 3h |
| F4.4 | Mejorar `TimingIndicator` con countdown visual | F4.3 | 2h |
| F4.5 | Agregar micro-animaciones a botones y cards | U4.3 | 2h |

**Componente "Cuando Tocar":**
```
+------------------------------------------+
|  PROXIMA NOTA EN:                        |
|                                          |
|     [=====>        ]  2 beats            |
|                                          |
|     Nota: E (cuerda 6)                   |
+------------------------------------------+
```

### Backend - Optimizacion

| ID | Tarea | Dependencias | Estimacion |
|----|-------|--------------|------------|
| B4.1 | Optimizar deteccion de pitch para baja latencia | Ninguna | 2h |
| B4.2 | Agregar caching de ejercicios cargados | Ninguna | 1h |

---

## FASE 5: Integracion y QA (Dia 5)
> **Objetivo:** Todo funcionando junto, listo para beta

### Todos los agentes

| ID | Tarea | Asignado | Estimacion |
|----|-------|----------|------------|
| Q5.1 | Prueba completa en Web (Chrome) | Frontend | 2h |
| Q5.2 | Prueba completa en Android | Backend | 2h |
| Q5.3 | Prueba completa en iOS (si disponible) | Backend | 2h |
| Q5.4 | Revision de UX completa | UX | 2h |
| Q5.5 | Correccion de bugs encontrados | Todos | 3h |
| Q5.6 | Build de release para beta | Frontend | 1h |

---

## Diagrama de Dependencias

```
FASE 1 (Compilacion)
    |
    +-- B1.1-B1.6 (Backend: limpiar errores)
    |       |
    |       +-- F1.1-F1.4 (Frontend: corregir pantallas)
    |
    +-- U1.1-U1.3 (UX: auditoria y mockups) [PARALELO]

         |
         v

FASE 2 (Audio Movil)
    |
    +-- B2.1-B2.5 (Backend: implementar audio)
    |       |
    |       +-- F2.1-F2.3 (Frontend: UI de audio)
    |
    +-- U2.1-U2.2 (UX: disenos) [PARALELO]

         |
         v

FASE 3 (Onboarding)
    |
    +-- U3.1-U3.3 (UX: lidera diseno)
    |       |
    |       +-- F3.1-F3.7 (Frontend: implementa)
    |       |
    |       +-- B3.1-B3.3 (Backend: servicios)

         |
         v

FASE 4 (Polish)
    |
    +-- U4.1-U4.3 (UX: disena)
    |       |
    |       +-- F4.1-F4.5 (Frontend: implementa)
    |
    +-- B4.1-B4.2 (Backend: optimiza) [PARALELO]

         |
         v

FASE 5 (QA)
    |
    +-- Q5.1-Q5.6 (Todos: testing e integracion)
```

---

## Resumen de Asignaciones por Agente

### FRONTEND (Total: ~28h)
- Fase 1: 5h - Correccion de errores
- Fase 2: 4h - UI de audio
- Fase 3: 9h - Implementar onboarding
- Fase 4: 10h - Polish y animaciones
- Fase 5: 3h - Testing y builds

### BACKEND (Total: ~22h)
- Fase 1: 5h - Limpiar referencias rotas
- Fase 2: 8h - Audio movil completo
- Fase 3: 2h - Servicios de onboarding
- Fase 4: 3h - Optimizaciones
- Fase 5: 4h - Testing multiplataforma

### UX (Total: ~16h)
- Fase 1: 6h - Auditoria y mockups onboarding
- Fase 2: 2h - Disenos de permisos
- Fase 3: 3h - Flujo completo de onboarding
- Fase 4: 5h - Celebraciones e indicadores
- Fase 5: 2h - Revision final

---

## Criterios de Exito para Beta

### Funcionales
- [ ] App compila sin errores en web, iOS, Android
- [ ] Usuario puede completar onboarding
- [ ] Microfono captura audio en todas las plataformas
- [ ] Ejercicios se evaluan correctamente
- [ ] Progreso se guarda entre sesiones

### UX
- [ ] Onboarding claro y fluido (< 2 min)
- [ ] Usuario sabe cuando tocar (indicador visual)
- [ ] Celebracion al completar ejercicio
- [ ] Transiciones suaves entre pantallas

### Rendimiento
- [ ] Latencia de deteccion < 100ms
- [ ] App responde fluidamente a 60fps
- [ ] Tiempo de carga inicial < 3s

---

## Notas para Coordinacion

1. **Comunicacion diaria:** Sync de 15min al inicio de cada dia
2. **Bloqueos:** Reportar inmediatamente en canal compartido
3. **Code reviews:** Obligatorios para merges a main
4. **Branches:** `feature/fase-X-nombre-tarea`
5. **Commits:** Prefijos: `fix:`, `feat:`, `refactor:`, `docs:`

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Audio movil no funciona | Media | Alto | Tener fallback a web para beta |
| Permisos iOS complicados | Alta | Medio | Documentar proceso, pedir help |
| Dependencias entre fases | Media | Alto | Buffer de 1 dia al final |
| Scope creep | Alta | Medio | Congelar features despues de Fase 4 |

---

**Proximo paso inmediato:** Agente Backend comienza con B1.1-B1.3 mientras Frontend prepara entorno de desarrollo.
