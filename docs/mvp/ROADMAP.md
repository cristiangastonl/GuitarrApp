# 🎸 GuitarrApp MVP Roadmap

## Visión del MVP

**Una sola cosa, hecha increíblemente bien:**
> Tocas la guitarra → La IA te escucha → Te dice si lo hiciste bien o qué corregir

---

## 🎯 Definición del MVP Mínimo

### Lo que SÍ incluye:
- ✅ Captura de audio en tiempo real del micrófono
- ✅ Análisis de IA que detecta notas/acordes tocados
- ✅ Ejercicios guiados simples (ej: "Toca un acorde de Sol")
- ✅ Feedback visual y textual inmediato
- ✅ Progresión básica de dificultad

### Lo que NO incluye (post-MVP):
- ❌ Sistema de usuarios/login
- ❌ Gamificación compleja
- ❌ Integración con Spotify
- ❌ Múltiples instrumentos
- ❌ Social features

---

## 👥 Estructura de Agentes

```
┌─────────────────────────────────────────────────────────────┐
│                    🎯 PM (Product Manager)                   │
│         Coordina sprints, prioriza features, QA             │
└─────────────────────────────────────────────────────────────┘
            │                    │                    │
            ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   🎨 UX Agent   │  │  📱 Frontend    │  │  ⚙️ Backend     │
│                 │  │     Agent       │  │     Agent       │
│ - User flows    │  │ - Flutter UI    │  │ - Audio API     │
│ - Wireframes    │  │ - Audio capture │  │ - IA Analysis   │
│ - Prototipos    │  │ - Feedback UI   │  │ - Real-time     │
│ - Testing UX    │  │ - Animations    │  │ - WebSockets    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 📅 Roadmap por Sprints

### 🏃 Sprint 0: Discovery & Setup (1 semana)

#### 🎯 PM Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Definir user stories del MVP | P0 | Documento de stories |
| Establecer métricas de éxito | P0 | KPIs definidos |
| Setup de proyecto en GitHub | P0 | Board configurado |
| Definir stack tecnológico final | P0 | Documento técnico |

#### 🎨 UX Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Research: ¿Cómo practican guitarristas? | P0 | Insights documento |
| Definir el "Happy Path" principal | P0 | User flow diagram |
| Benchmark apps similares (Yousician, Fender Tone) | P1 | Análisis competitivo |
| Sketches iniciales del flujo core | P0 | Wireframes low-fi |

#### 📱 Frontend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Auditar código existente en repo | P0 | Informe técnico |
| POC: Captura de audio en Flutter | P0 | Demo funcional |
| Evaluar latencia de audio en móvil | P0 | Métricas de latencia |
| Setup ambiente de desarrollo | P0 | Repo configurado |

#### ⚙️ Backend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Research: Modelos de IA para audio musical | P0 | Comparativa de opciones |
| POC: Detección de notas con modelo existente | P0 | Demo funcional |
| Evaluar: On-device vs Cloud processing | P0 | Documento de decisión |
| Definir arquitectura de comunicación | P0 | Diagrama de arquitectura |

**🎯 Milestone Sprint 0:** Decisiones técnicas tomadas, POCs validados

---

### 🏃 Sprint 1: Core Audio Pipeline (2 semanas)

#### 🎯 PM Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Refinar backlog con aprendizajes del Sprint 0 | P0 | Backlog actualizado |
| Coordinar integración Frontend-Backend | P0 | Plan de integración |
| Definir criterios de aceptación del audio | P0 | Checklist QA |

#### 🎨 UX Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Diseñar pantalla principal de práctica | P0 | Wireframes hi-fi |
| Diseñar estados de feedback (correcto/incorrecto) | P0 | Design specs |
| Diseñar indicador visual de "IA escuchando" | P0 | Componente diseñado |
| Prototipo interactivo básico | P1 | Figma prototype |

#### 📱 Frontend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Implementar captura de audio continua | P0 | Módulo funcional |
| Stream de audio hacia backend/modelo | P0 | Pipeline funcionando |
| UI básica de "escuchando..." | P0 | Pantalla implementada |
| Manejo de permisos de micrófono | P0 | Flujo completo |

#### ⚙️ Backend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Implementar modelo de detección de notas | P0 | API funcionando |
| Optimizar latencia de respuesta (<500ms) | P0 | Benchmark <500ms |
| Endpoint de análisis de audio | P0 | API documentada |
| Sistema de WebSocket para real-time | P0 | Conexión estable |

**🎯 Milestone Sprint 1:** Puedo tocar una nota → La app la detecta correctamente

---

### 🏃 Sprint 2: Feedback Intelligence (2 semanas)

#### 🎯 PM Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Definir biblioteca inicial de ejercicios | P0 | Lista de 10-15 ejercicios |
| Testing con usuarios reales (3-5 personas) | P0 | Feedback documentado |
| Priorizar ajustes según feedback | P0 | Backlog repriorizado |

#### 🎨 UX Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Diseñar feedback positivo (celebración) | P0 | Animaciones/UI |
| Diseñar feedback correctivo (qué mejorar) | P0 | Componentes de ayuda |
| Diseñar visualización de nota esperada vs tocada | P0 | UI comparativa |
| Diseñar pantalla de selección de ejercicio | P1 | Wireframes |

#### 📱 Frontend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Implementar UI de feedback en tiempo real | P0 | Componentes funcionando |
| Animaciones de éxito/error | P0 | Animaciones fluidas |
| Visualización de nota esperada | P0 | UI implementada |
| Pantalla de selección de ejercicios | P1 | Screen funcional |

#### ⚙️ Backend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Lógica de comparación nota esperada vs tocada | P0 | Algoritmo funcionando |
| Sistema de puntuación/accuracy | P0 | Scoring system |
| Generación de feedback contextual con LLM | P0 | Respuestas inteligentes |
| Base de datos de ejercicios | P0 | DB estructurada |

**🎯 Milestone Sprint 2:** Toco un ejercicio → Recibo feedback específico de qué mejorar

---

### 🏃 Sprint 3: Ejercicios Guiados (2 semanas)

#### 🎯 PM Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Curar contenido de ejercicios iniciales | P0 | 10 ejercicios listos |
| Segunda ronda de user testing | P0 | Insights documentados |
| Preparar plan de lanzamiento beta | P1 | Launch plan |

#### 🎨 UX Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Diseñar flujo de progresión de ejercicios | P0 | User flow completo |
| Diseñar onboarding mínimo | P0 | 3 pantallas max |
| Diseñar "modo práctica libre" | P1 | Wireframes |
| Pulir micro-interacciones | P1 | Polish general |

#### 📱 Frontend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Implementar flujo de ejercicios secuenciales | P0 | Navegación completa |
| Onboarding de 3 pasos | P0 | Flujo implementado |
| Indicador de progreso en ejercicio | P0 | UI de progreso |
| Modo práctica libre básico | P1 | Screen funcional |

#### ⚙️ Backend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Sistema de progresión de dificultad | P0 | Algoritmo adaptativo |
| Detección de acordes (no solo notas) | P0 | Modelo mejorado |
| Almacenamiento local de progreso | P0 | Persistencia |
| Optimización de consumo de batería | P1 | Mejoras de eficiencia |

**🎯 Milestone Sprint 3:** Puedo completar una secuencia de ejercicios con feedback continuo

---

### 🏃 Sprint 4: Polish & Beta (2 semanas)

#### 🎯 PM Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Bug bash con todo el equipo | P0 | Lista de bugs |
| Preparar TestFlight / Play Store Beta | P0 | Builds subidos |
| Documentar known issues | P0 | Release notes |
| Reclutar beta testers (20-50) | P0 | Lista de testers |

#### 🎨 UX Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Review de consistencia visual | P0 | Ajustes finales |
| Diseñar pantallas de error/edge cases | P0 | Estados de error |
| Crear assets para stores | P0 | Screenshots, iconos |
| Documentar design system | P1 | Guía de estilo |

#### 📱 Frontend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Bug fixes críticos | P0 | Bugs resueltos |
| Optimización de performance | P0 | App fluida |
| Testing en múltiples dispositivos | P0 | Matriz de compatibilidad |
| Implementar analytics básicos | P1 | Eventos trackeados |

#### ⚙️ Backend Agent
| Tarea | Prioridad | Entregable |
|-------|-----------|------------|
| Stress testing del sistema | P0 | Informe de carga |
| Manejo de errores robusto | P0 | Error handling |
| Logging y monitoreo | P0 | Observabilidad |
| Documentación de API | P1 | Docs completos |

**🎯 Milestone Sprint 4:** MVP listo para beta pública

---

## 🏗️ Decisiones Técnicas Clave

### Audio Processing: ¿Dónde corre la IA?

| Opción | Pros | Contras | Recomendación |
|--------|------|---------|---------------|
| **On-Device (TensorFlow Lite)** | Sin latencia de red, funciona offline | Modelo limitado, más desarrollo | ✅ MVP |
| **Cloud (API)** | Modelo más potente, fácil actualizar | Latencia, requiere conexión | Post-MVP |
| **Híbrido** | Balance entre ambos | Complejidad | Futuro |

### Modelo de IA para Detección Musical

| Opción | Descripción | Recomendación |
|--------|-------------|---------------|
| **Basic Pitch (Spotify)** | Open source, detecta notas | ✅ Empezar aquí |
| **CREPE** | Detección de pitch precisa | Alternativa |
| **Modelo custom** | Entrenado específicamente | Post-MVP |
| **Whisper + fine-tuning** | Adaptación de modelo de audio | Experimental |

### Stack Tecnológico Propuesto

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│  Flutter + flutter_sound + tflite_flutter                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AUDIO PROCESSING                         │
│  On-device: TensorFlow Lite + Basic Pitch model             │
│  Fallback: Cloud API para casos complejos                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FEEDBACK ENGINE                           │
│  Reglas de comparación + Claude API para feedback natural   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      PERSISTENCE                             │
│  SQLite local (progreso) + JSON (ejercicios)                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Métricas de Éxito del MVP

### Métricas Técnicas
| Métrica | Target | Crítico |
|---------|--------|---------|
| Latencia de detección | <300ms | <500ms |
| Precisión de detección de notas | >90% | >80% |
| Crash rate | <1% | <2% |
| Tiempo de carga inicial | <3s | <5s |

### Métricas de Usuario
| Métrica | Target | Crítico |
|---------|--------|---------|
| Retención D1 | >40% | >25% |
| Ejercicios completados por sesión | >3 | >1 |
| Sesiones por semana (usuarios activos) | >3 | >2 |
| NPS de beta testers | >50 | >30 |

---

## 🗓️ Timeline Estimado

```
Semana 1     │ Sprint 0: Discovery
─────────────┼─────────────────────────────────────
Semana 2-3   │ Sprint 1: Core Audio Pipeline
─────────────┼─────────────────────────────────────
Semana 4-5   │ Sprint 2: Feedback Intelligence
─────────────┼─────────────────────────────────────
Semana 6-7   │ Sprint 3: Ejercicios Guiados
─────────────┼─────────────────────────────────────
Semana 8-9   │ Sprint 4: Polish & Beta
─────────────┼─────────────────────────────────────
Semana 10    │ 🚀 Beta Launch
```

**Total estimado: 10 semanas hasta Beta**

---

## 🚀 Quick Wins para Empezar YA

### Esta semana puedes:

1. **PM:** Crear el board en GitHub Projects con estos sprints
2. **UX:** Dibujar en papel el happy path (5 pantallas máximo)
3. **Frontend:** Hacer POC de captura de audio con el repo existente
4. **Backend:** Probar Basic Pitch de Spotify en un notebook

### Primer hito tangible (48 horas):
> "Abro la app → Toco una cuerda → Veo en pantalla qué nota fue"

---

## 📝 User Stories del MVP

### Epic: Practicar con Feedback

```
US-001: Como guitarrista principiante, 
        quiero que la app detecte qué nota toqué,
        para saber si es la correcta.

US-002: Como guitarrista principiante,
        quiero recibir feedback inmediato cuando toco,
        para corregir en el momento.

US-003: Como guitarrista principiante,
        quiero seguir ejercicios guiados,
        para tener estructura en mi práctica.

US-004: Como guitarrista principiante,
        quiero ver mi progreso,
        para motivarme a seguir practicando.

US-005: Como guitarrista principiante,
        quiero que me digan QUÉ corregir específicamente,
        para mejorar más rápido.
```

---

## ❓ Preguntas Abiertas para Resolver

1. **¿Qué nivel de guitarrista es el target principal?**
   - Total principiante (nunca tocó)
   - Principiante (sabe algo básico)
   - Intermedio (quiere mejorar técnica)

2. **¿Guitarra acústica, eléctrica, o ambas?**
   - Afecta el modelo de detección de audio

3. **¿iOS first, Android first, o ambos?**
   - Afecta priorización de testing

4. **¿Monetización en MVP o 100% gratis?**
   - Afecta decisiones de infraestructura

---

*Documento generado para GuitarrApp MVP*
*Última actualización: Enero 2025*
