# 📋 User Stories - GuitarrApp MVP

## Epic: Practicar con Feedback en Tiempo Real

### US-001: Detectar nota tocada

**Como** guitarrista principiante,  
**quiero** que la app detecte qué nota toqué,  
**para** saber si es la correcta sin necesitar otro instrumento de referencia.

#### Criterios de Aceptación
- [ ] La app detecta la nota dentro de 500ms de tocarla
- [ ] Muestra el nombre de la nota (ej: "E", "A", "D")
- [ ] Muestra la octava (ej: "E2", "E4")
- [ ] Funciona con guitarra acústica y eléctrica
- [ ] Precisión >80% en ambiente silencioso

#### Notas Técnicas
- Usar modelo Basic Pitch o CREPE
- On-device processing para latencia
- Sample rate: 44100 Hz

---

### US-002: Recibir feedback inmediato

**Como** guitarrista principiante,  
**quiero** recibir feedback inmediato cuando toco,  
**para** corregir errores en el momento y no practicar mal.

#### Criterios de Aceptación
- [ ] Feedback visual aparece en <1 segundo
- [ ] Feedback de "correcto" es claramente positivo (verde, check)
- [ ] Feedback de "incorrecto" indica qué nota se esperaba
- [ ] No interrumpe el flujo de práctica (no modals bloqueantes)

#### Notas Técnicas
- Animación de feedback <300ms
- Sonido opcional para feedback

---

### US-003: Seguir ejercicios guiados

**Como** guitarrista principiante,  
**quiero** seguir ejercicios guiados paso a paso,  
**para** tener estructura en mi práctica y saber qué aprender primero.

#### Criterios de Aceptación
- [ ] Puedo ver una lista de ejercicios disponibles
- [ ] Cada ejercicio tiene instrucciones claras
- [ ] El ejercicio avanza automáticamente cuando toco bien
- [ ] Puedo reintentar una nota si me equivoco
- [ ] Veo mi progreso dentro del ejercicio (ej: 3/10 notas)

#### Notas Técnicas
- Ejercicios en JSON para fácil edición
- Mínimo 10 ejercicios para MVP

---

### US-004: Ver mi progreso

**Como** guitarrista principiante,  
**quiero** ver mi progreso a lo largo del tiempo,  
**para** motivarme y saber que estoy mejorando.

#### Criterios de Aceptación
- [ ] Veo resumen al terminar cada sesión (accuracy, tiempo)
- [ ] Puedo ver historial de sesiones pasadas
- [ ] Veo qué ejercicios he completado
- [ ] La información persiste entre sesiones de la app

#### Notas Técnicas
- SQLite para persistencia local
- No requiere cuenta/login para MVP

---

### US-005: Recibir consejos específicos

**Como** guitarrista principiante,  
**quiero** que me digan QUÉ corregir específicamente,  
**para** mejorar más rápido que solo sabiendo "incorrecto".

#### Criterios de Aceptación
- [ ] Si estoy desafinado, me dice si estoy alto o bajo
- [ ] Si toco nota incorrecta, me sugiere dónde está la correcta
- [ ] Los consejos son breves y accionables (<2 oraciones)
- [ ] El tono es motivador, no crítico

#### Notas Técnicas
- Integrar Claude API para feedback contextual
- Caché de respuestas comunes

---

## Epic: Setup Inicial

### US-006: Dar permiso de micrófono

**Como** usuario nuevo,  
**quiero** un flujo claro para dar permiso de micrófono,  
**para** empezar a usar la app sin confusión.

#### Criterios de Aceptación
- [ ] La app explica POR QUÉ necesita el micrófono antes de pedir
- [ ] Si niego permiso, me explica cómo habilitarlo después
- [ ] No pide permiso hasta que intento practicar
- [ ] Funciona en iOS y Android

#### Notas Técnicas
- permission_handler package
- Pre-prompt antes del dialog del sistema

---

### US-007: Entender cómo usar la app

**Como** usuario nuevo,  
**quiero** un onboarding breve que me enseñe lo básico,  
**para** empezar a practicar rápido sin leer manuales.

#### Criterios de Aceptación
- [ ] Onboarding de máximo 3 pantallas
- [ ] Puedo saltarlo si quiero
- [ ] Solo se muestra la primera vez
- [ ] Incluye una demo rápida del feedback

#### Notas Técnicas
- Guardar flag de onboarding completado en SharedPreferences

---

## Epic: Práctica Libre

### US-008: Practicar sin ejercicio guiado

**Como** guitarrista,  
**quiero** poder tocar libremente y ver qué notas toco,  
**para** experimentar o afinar mi guitarra.

#### Criterios de Aceptación
- [ ] Modo "práctica libre" accesible desde home
- [ ] Muestra nota detectada en tiempo real
- [ ] No hay "correcto" o "incorrecto", solo información
- [ ] Puedo ver historial de notas tocadas en la sesión

#### Notas Técnicas
- Misma UI de detección pero sin comparación

---

## Priorización para MVP

| User Story | Prioridad | Sprint |
|------------|-----------|--------|
| US-001 | P0 - Crítico | Sprint 1 |
| US-002 | P0 - Crítico | Sprint 2 |
| US-006 | P0 - Crítico | Sprint 1 |
| US-003 | P1 - Alto | Sprint 3 |
| US-005 | P1 - Alto | Sprint 2 |
| US-004 | P2 - Medio | Sprint 3 |
| US-007 | P2 - Medio | Sprint 3 |
| US-008 | P3 - Bajo | Sprint 3 |

---

## User Stories Post-MVP (Backlog)

### US-009: Afinar mi guitarra
**Como** guitarrista, quiero usar la app como afinador.

### US-010: Aprender acordes
**Como** principiante, quiero que la app detecte acordes, no solo notas.

### US-011: Practicar con canciones
**Como** guitarrista, quiero practicar con mis canciones favoritas.

### US-012: Compartir mi progreso
**Como** usuario, quiero compartir mis logros en redes sociales.

### US-013: Competir con amigos
**Como** usuario, quiero ver cómo me comparo con otros.

### US-014: Practicar offline
**Como** usuario, quiero usar la app sin conexión a internet.
