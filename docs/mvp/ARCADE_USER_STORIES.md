# User Stories - GuitarrApp MVP Arcade

## US-1: Tomar Test de Nivel
**Como** nuevo usuario
**Quiero** hacer un test de nivel tocando acordes con mi guitarra
**Para** que la app sepa en qué nivel debo empezar

### Criterios de Aceptación
- [ ] El test pide tocar 5 acordes básicos (Em, Am, E, A, D)
- [ ] Muestra el diagrama del acorde a tocar
- [ ] Escucha el micrófono y detecta el acorde
- [ ] Da feedback visual (correcto/incorrecto)
- [ ] Al finalizar, desbloquea niveles según rendimiento
- [ ] Si acierta 0-1: Nivel 1 desbloqueado
- [ ] Si acierta 2-3: Niveles 1-3 desbloqueados
- [ ] Si acierta 4-5: Niveles 1-5 desbloqueados

---

## US-2: Jugar una Lección
**Como** usuario
**Quiero** jugar una lección de acorde estilo arcade
**Para** practicar el acorde y ganar puntos

### Criterios de Aceptación
- [ ] Muestra el diagrama del acorde objetivo
- [ ] Tiene un contador de intentos (10 por nivel)
- [ ] Escucha el micrófono cuando el usuario está listo
- [ ] Detecta si el acorde tocado es correcto
- [ ] Muestra feedback visual inmediato (PERFECT/GOOD/MISS)
- [ ] Acumula puntos según precisión
- [ ] Al completar 10 intentos, muestra pantalla de resultados

---

## US-3: Ganar Puntos y Combos
**Como** jugador
**Quiero** ganar puntos y hacer combos
**Para** sentir progreso y emoción al jugar

### Criterios de Aceptación
- [ ] PERFECT (+100 pts): Acorde detectado con >90% confianza
- [ ] GOOD (+50 pts): Acorde detectado con 70-90% confianza
- [ ] OK (+25 pts): Acorde detectado con 50-70% confianza
- [ ] MISS (0 pts): Acorde no detectado o incorrecto
- [ ] El combo aumenta (x2, x3, x4...) con aciertos consecutivos
- [ ] El combo se reinicia a x1 con un MISS
- [ ] Los puntos se multiplican por el combo actual
- [ ] Se muestra el combo actual con animación

---

## US-4: Desbloquear Niveles
**Como** jugador
**Quiero** desbloquear nuevos niveles al completar los anteriores
**Para** progresar en mi aprendizaje de acordes

### Criterios de Aceptación
- [ ] Los niveles 2-10 empiezan bloqueados (excepto post-test)
- [ ] Para desbloquear el siguiente nivel:
  - Completar el nivel actual
  - Obtener al menos 1 estrella (>70% precisión)
- [ ] Sistema de estrellas por nivel:
  - 1 estrella: 70-84% precisión
  - 2 estrellas: 85-94% precisión
  - 3 estrellas: 95-100% precisión
- [ ] El progreso se guarda en el dispositivo
- [ ] Al reabrir la app, los niveles desbloqueados persisten

---

## US-5: Ver High Scores
**Como** jugador
**Quiero** ver mis mejores puntuaciones
**Para** intentar superarme

### Criterios de Aceptación
- [ ] Cada nivel guarda el high score individual
- [ ] Muestra estrellas obtenidas por nivel
- [ ] Muestra el high score total (suma de todos los niveles)
- [ ] El high score se actualiza solo si se supera el anterior
- [ ] Los scores persisten entre sesiones

---

## Definición de los 10 Acordes

| Nivel | Acorde | Dificultad | Notas (cuerdas 6-1) |
|-------|--------|------------|---------------------|
| 1 | Em | Básico | E-B-E-G-B-E |
| 2 | Am | Básico | X-A-E-A-C-E |
| 3 | E | Básico | E-B-E-G#-B-E |
| 4 | A | Básico | X-A-E-A-C#-E |
| 5 | D | Básico | X-X-D-A-D-F# |
| 6 | G | Intermedio | G-B-D-G-B-G |
| 7 | C | Intermedio | X-C-E-G-C-E |
| 8 | Dm | Intermedio | X-X-D-A-D-F |
| 9 | F | Avanzado | F-C-F-A-C-F |
| 10 | Bm | Avanzado | X-B-F#-B-D-F# |

---

## Criterios de QA

### Funcionales
- [ ] La app abre sin errores
- [ ] El test de nivel detecta acordes correctamente
- [ ] Los puntos se calculan correctamente
- [ ] Los combos se incrementan/reinician correctamente
- [ ] El progreso se guarda y persiste
- [ ] Los niveles se desbloquean según las reglas

### UX
- [ ] El feedback visual es inmediato (<200ms)
- [ ] Los colores neón son vibrantes y legibles
- [ ] Las animaciones son fluidas
- [ ] El diagrama de acordes es claro

### Audio
- [ ] El micrófono se activa correctamente
- [ ] La detección de acordes funciona en silencio normal
- [ ] No hay falsos positivos por ruido ambiente
