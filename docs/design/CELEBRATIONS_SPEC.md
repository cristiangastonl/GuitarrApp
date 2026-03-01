# Especificacion de Celebraciones y Feedback Visual

> GuitarrApp - FASE 2: Polish UX
> Documento de especificaciones para celebraciones y mejoras de feedback visual

---

## Indice

1. [Celebracion de Nota Perfecta](#a-celebracion-de-nota-perfecta)
2. [Streak Counter](#b-streak-counter)
3. [Indicador "Cuando Tocar"](#c-indicador-cuando-tocar)
4. [Feedback Mejorado de Errores](#d-feedback-mejorado-de-errores)
5. [Referencias de Colores](#referencias-de-colores)

---

## A. Celebracion de Nota Perfecta

### Descripcion General
Cuando el usuario toca una nota perfectamente (timing y pitch correctos), se dispara una celebracion visual de confetti/particulas para reforzar positivamente el logro.

### Efecto de Confetti/Particulas

#### Tipo de Particulas
- **Forma**: Rectangulos pequenos (4x8px) y circulos (6px diametro)
- **Cantidad**: 30-50 particulas por celebracion
- **Origen**: Centro-superior de la pantalla, expandiendose hacia abajo
- **Patron de dispersion**: Explosion radial con gravedad simulada

#### Fisica de Particulas
```
Velocidad inicial: 200-400 px/s
Angulo de dispersion: 45 a 135 grados (arco superior)
Gravedad: 800 px/s^2
Rotacion: 180-720 grados durante la vida
Friction: 0.98 por frame
```

#### Comportamiento
1. **Spawn**: Particulas aparecen en el punto de origen
2. **Explosion**: Se dispersan con velocidades aleatorias
3. **Gravedad**: Caen naturalmente hacia abajo
4. **Fade out**: Opacidad decrece al 50% de la vida
5. **Desaparicion**: Se eliminan al salir de pantalla o terminar duracion

### Colores a Usar

| Color | Hex | Uso |
|-------|-----|-----|
| Amp Orange | `#FF6B35` | Particulas primarias (40%) |
| Steel Gold | `#FFD93D` | Particulas de acento (30%) |
| Guitar Teal | `#4ECDC4` | Particulas secundarias (20%) |
| Success Green | `#4CAF50` | Destellos de exito (10%) |

**Distribucion recomendada**: Mezcla aleatoria con pesos indicados.

### Duracion de la Animacion

| Fase | Duracion | Descripcion |
|------|----------|-------------|
| Inicio | 0ms | Disparo de particulas |
| Pico | 300ms | Maxima expansion |
| Caida | 300-800ms | Particulas cayendo |
| Fade out | 200ms | Desvanecimiento final |
| **Total** | **800-1200ms** | Duracion completa |

### Sonido Opcional

> **Nota**: El sonido es opcional y debe poder desactivarse en configuracion.

#### Descripcion del Sonido
- **Tipo**: Sonido sintetico tipo "sparkle" o "chime"
- **Frecuencia base**: 880Hz (A5) con armonicos
- **Duracion**: 400ms
- **Envolvente**: Attack rapido (10ms), decay largo (390ms)
- **Volumen**: 60% del volumen principal de la app

#### Alternativa Simple
- Archivo de audio pregrabado: `assets/sounds/perfect_note.wav`
- Formato: WAV 44.1kHz 16-bit mono
- Duracion maxima: 500ms

### Implementacion Widget

```dart
ConfettiCelebration(
  duration: Duration(milliseconds: 1000),
  colors: [
    GuitarrColors.ampOrange,
    GuitarrColors.steelGold,
    GuitarrColors.guitarTeal,
    GuitarrColors.success,
  ],
  intensity: ConfettiIntensity.medium, // low, medium, high
  origin: Offset(0.5, 0.2), // Centro-arriba normalizado
)
```

---

## B. Streak Counter

### Descripcion General
Contador visual que muestra cuantas notas correctas consecutivas ha logrado el usuario. Sirve como motivacion y gamificacion del aprendizaje.

### Diseno Visual del Contador

#### Estructura
```
+----------------------------------+
|          [ICONO FUEGO]           |
|              x12                 |
|        "Racha perfecta!"         |
+----------------------------------+
```

#### Elementos Visuales

1. **Icono de racha**: Llama/fuego estilizado que crece con el streak
2. **Numero grande**: El contador prominente (ej: "12")
3. **Texto motivacional**: Mensaje que cambia segun el nivel
4. **Borde con glow**: Brillo del color correspondiente al nivel

#### Tipografia
- **Numero**: `headlineLarge` (48px, extraBold)
- **Texto**: `titleSmall` (14px, medium)
- **Prefijo "x"**: `headlineMedium` (20px, semiBold)

### Posicion en Pantalla

```
+------------------------------------------+
|                                          |
|  [TIMING]                    [STREAK]    |  <- Esquina superior derecha
|                                          |
|         [AREA DE EJERCICIO]              |
|                                          |
|              [NOTAS]                     |
|                                          |
|            [FEEDBACK]                    |
+------------------------------------------+
```

**Posicion**: Esquina superior derecha
**Offset**: 16px del borde derecho, 80px del borde superior (debajo del app bar)
**z-index**: Sobre el contenido del ejercicio pero debajo de modales

### Animacion Cuando Aumenta

#### Secuencia de Animacion (150ms total)

1. **Scale Up** (0-75ms)
   - Escala de 1.0 a 1.3
   - Curva: `Curves.easeOut`

2. **Scale Down** (75-150ms)
   - Escala de 1.3 a 1.0
   - Curva: `Curves.elasticOut`

3. **Numero cambia**
   - AnimatedSwitcher con transicion de slide up + fade
   - Duracion: 200ms

4. **Efecto de pulso** (solo en milestones)
   - Ring expandiendose del color del nivel
   - Duracion: 300ms
   - Opacidad: 0.6 -> 0.0

### Colores por Nivel de Streak

| Nivel | Rango | Color | Hex | Mensaje |
|-------|-------|-------|-----|---------|
| Inicial | 1-4 | Text Secondary | `#E0E0E0` | (sin mostrar) |
| Bronce | 5-9 | Warning (Gold) | `#FFD93D` | "Buena racha!" |
| Plata | 10-19 | Guitar Teal | `#4ECDC4` | "Excelente!" |
| Oro | 20-49 | Amp Orange | `#FF6B35` | "Increible!" |
| Diamante | 50+ | Success + Glow | `#4CAF50` | "LEGENDARIO!" |

#### Efectos Especiales por Nivel

**Bronce (5+)**
- Aparece el contador
- Borde sutil del color

**Plata (10+)**
- Icono de fuego animado
- Borde mas prominente
- Mini confetti al alcanzar

**Oro (20+)**
- Fuego mas grande con particulas
- Glow pulsante
- Vibracion haptica (si disponible)

**Diamante (50+)**
- Efectos maximos
- Particulas constantes
- Texto con shimmer/brillo
- Confetti al alcanzar

### Comportamiento al Perder Streak

1. **Animacion de perdida** (400ms)
   - Scale down a 0.8
   - Fade out a opacidad 0.3
   - Shake horizontal (3 ciclos, 8px)

2. **Reset visual**
   - Contador vuelve a 0
   - Desaparece si era < 5

3. **Mensaje de animo** (opcional)
   - "Casi! Intenta de nuevo"
   - Aparece brevemente (2s)

### Implementacion Widget

```dart
StreakCounter(
  count: 12,
  onMilestoneReached: (milestone) {
    // Trigger celebrations
  },
  showMotivationalText: true,
  position: StreakPosition.topRight,
)
```

---

## C. Indicador "Cuando Tocar"

### Descripcion General
Sistema visual que guia al usuario sobre el momento exacto para tocar cada nota. Complementa el TimingIndicator existente con feedback mas intuitivo.

### Opcion 1: Linea de Tempo que Avanza

#### Diseno
```
  |  .  .  |  .  .  |  .  .  |  .  .  |
  |==============================>     |
  ^cursor                              ^notas proximas
```

#### Especificaciones

- **Contenedor**: Barra horizontal de 100% ancho, 60px altura
- **Fondo**: `surface2` (`#2D2D2D`) con gradiente sutil
- **Linea de tiempo**:
  - Color: `glassBorder` (`#33FFFFFF`)
  - Marcas de beat: circulos de 4px cada beat
  - Marcas de compas: lineas verticales de 20px altura

- **Cursor de posicion actual**:
  - Forma: Linea vertical con cabeza triangular
  - Color: `ampOrange` (`#FF6B35`)
  - Altura: 100% del contenedor
  - Animacion: Movimiento suave (linear interpolation)
  - Glow: 8px blur del color naranja

- **Notas proximas**:
  - Representadas como circulos en la linea
  - Tamano: 12px normales, 16px la proxima
  - Color: `guitarTeal` las proximas, `textTertiary` las pasadas
  - Correctas: `success` con checkmark
  - Incorrectas: `error` con X

### Opcion 2: Pulso Visual en el Momento Exacto (Recomendada)

#### Diseno del Pulso

Anillo concentrico que se contrae hacia el centro, indicando cuando tocar.

```
     +-------+
    /    O    \     <- Anillo externo (se contrae)
   |     |     |
   |    [N]    |    <- Nota objetivo en el centro
   |     |     |
    \    O    /     <- Anillo interno
     +-------+
```

#### Especificaciones

1. **Anillo de aproximacion**
   - Forma: Circulo que se contrae
   - Tamano inicial: 120px diametro
   - Tamano final: 60px diametro (tamano de la nota)
   - Color: `guitarTeal` con opacidad 0.6 -> 1.0
   - Duracion: 1 beat completo (calculado desde BPM)
   - Grosor del borde: 4px

2. **Zona de acierto**
   - Cuando el anillo alcanza el tamano de la nota
   - Ventana de tiempo: +/- 100ms del beat exacto
   - Visual: Flash de `ampOrange` si acierta

3. **Nota objetivo**
   - Circulo central de 60px
   - Muestra el nombre de la nota (ej: "A", "E2")
   - Color de fondo: `surface3`
   - Color de texto: `textPrimary`

#### Timing Visual

```
Beat: |----1----|----2----|----3----|----4----|
Ring: [expand]  [shrink]  [flash]  [next]
      start     halfway   hit!     repeat
```

### Integracion con TimingIndicator Existente

El componente `TimingIndicator` existente ya proporciona:
- Contador de beat actual
- Indicadores de compas
- Barra de progreso

**Integracion propuesta**:

1. **Envolver TimingIndicator** con el nuevo pulso visual
2. **Sincronizar** el anillo de aproximacion con `currentBeat`
3. **Compartir** el estado de `beatsPerMeasure` y `totalBeats`

```dart
// Uso integrado
EnhancedTimingIndicator(
  currentBeat: currentBeat,
  totalBeats: totalBeats,
  beatsPerMeasure: 4,
  bpm: 120,
  showApproachRing: true,
  showBeatIndicators: true,
)
```

---

## D. Feedback Mejorado de Errores

### Descripcion General
Mejorar la comunicacion visual de errores para que el usuario entienda exactamente que salio mal y como corregirlo.

### Mostrar "Tocaste X, esperaba Y" de Forma Visual

#### Layout del Feedback de Error

```
+--------------------------------------------------+
|                                                   |
|    [NOTA TOCADA]  -->  [NOTA ESPERADA]           |
|        "E2"       vs       "A2"                   |
|                                                   |
|    "Tocaste E2, pero era A2"                     |
|                                                   |
|    [====== DIFERENCIA DE TONO ======]            |
|         -5 semitonos                              |
|                                                   |
+--------------------------------------------------+
```

#### Componentes Visuales

1. **Comparacion lado a lado**
   - Nota tocada (izquierda): Circulo con borde `error` (`#E53935`)
   - Flecha o "vs": Icono de comparacion
   - Nota esperada (derecha): Circulo con borde `success` (`#4CAF50`)

2. **Texto explicativo**
   - Fuente: `bodyMedium`
   - Color: `textSecondary`
   - Formato: "Tocaste [X], pero era [Y]"

3. **Indicador de diferencia** (si es error de pitch)
   - Barra horizontal mostrando la distancia en semitonos
   - Flechas indicando direccion (mas agudo/mas grave)
   - Color gradiente de `error` a `success`

#### Colores de Estados de Error

| Tipo de Error | Color Principal | Color Fondo | Icono |
|---------------|-----------------|-------------|-------|
| Nota incorrecta | `#E53935` | `#E5393515` | error_outline |
| Demasiado temprano | `#FF9800` | `#FF980015` | arrow_back |
| Demasiado tarde | `#FF9800` | `#FF980015` | arrow_forward |
| Nota perdida | `#9E9E9E` | `#9E9E9E15` | close |

### Mini Diagrama de Posicion de Dedos (Opcional)

#### Diseno del Diagrama

```
    TRASTE
    1   2   3   4   5
E |-●-|---|---|---|---|  <- Dedo aqui
B |---|---|---|---|---|
G |---|---|---|---|---|
D |---|---|---|---|---|
A |---|---|---|---|---|
E |---|---|---|---|---|
```

#### Especificaciones

- **Tamano**: 120px ancho x 100px alto (compacto)
- **Trastes visibles**: 5 (ajustable segun la nota)
- **Cuerdas**: Las 6 cuerdas de guitarra estandar
- **Indicador de dedo**: Circulo de 12px con color `ampOrange`
- **Cuerda activa**: Resaltada con mayor opacidad
- **Numero de traste**: Mostrado arriba del diagrama

#### Implementacion

```dart
FretDiagram(
  string: 1,  // 1-6
  fret: 2,    // 0-24
  showLabel: true,
  highlightColor: GuitarrColors.ampOrange,
  size: FretDiagramSize.compact, // compact, medium, large
)
```

### Animacion "Casi, Intenta de Nuevo"

#### Secuencia de Animacion (600ms total)

1. **Shake horizontal** (0-300ms)
   ```
   Desplazamiento: [-8px, +8px, -6px, +6px, -4px, +4px, 0px]
   Duracion por ciclo: ~43ms
   Curva: Curves.easeInOut
   ```

2. **Flash de color** (150-350ms)
   - Overlay del color de error al 30% opacidad
   - Fade in: 100ms
   - Fade out: 100ms

3. **Texto motivacional** (300-600ms)
   - Fade in del mensaje
   - Ejemplos: "Casi!", "Un poco mas!", "Sigue intentando!"
   - Fuente: `titleMedium` en color `warning`

#### Mensajes Motivacionales (Rotacion Aleatoria)

```dart
const motivationalMessages = [
  "Casi lo tienes!",
  "Muy cerca!",
  "Sigue asi!",
  "Un poco mas!",
  "Ya casi!",
  "Buen intento!",
];
```

### Widget de Feedback de Error Mejorado

```dart
EnhancedErrorFeedback(
  playedNote: "E2",
  expectedNote: "A2",
  timingOffset: -45, // ms (negativo = temprano)
  showFretDiagram: true,
  fretPosition: FretPosition(string: 5, fret: 0),
  expectedFretPosition: FretPosition(string: 5, fret: 5),
  onRetry: () => startAgain(),
)
```

---

## Referencias de Colores

### Colores del Sistema de Diseno

```dart
// Primarios
GuitarrColors.ampOrange        // #FF6B35 - Brand principal
GuitarrColors.ampOrangeLight   // #FF8A65 - Variante clara
GuitarrColors.ampOrangeDark    // #E55722 - Variante oscura

// Secundarios
GuitarrColors.guitarTeal       // #4ECDC4 - Acento secundario
GuitarrColors.guitarTealLight  // #80E5DE - Variante clara
GuitarrColors.guitarTealDark   // #26A69A - Variante oscura

// Acentos
GuitarrColors.steelGold        // #FFD93D - Highlights/warnings
GuitarrColors.steelGoldLight   // #FFE082 - Variante clara
GuitarrColors.steelGoldDark    // #FFC107 - Variante oscura

// Semanticos
GuitarrColors.success          // #4CAF50 - Exito
GuitarrColors.warning          // #FFD93D - Advertencia
GuitarrColors.error            // #E53935 - Error
GuitarrColors.info             // #4ECDC4 - Informacion

// Superficies
GuitarrColors.backgroundPrimary   // #1B1B1B
GuitarrColors.backgroundSecondary // #242424
GuitarrColors.backgroundTertiary  // #2D2D2D
GuitarrColors.surface3            // #363636

// Texto
GuitarrColors.textPrimary      // #FFFFFF
GuitarrColors.textSecondary    // #E0E0E0
GuitarrColors.textTertiary     // #BDBDBD
```

### Paleta de Celebraciones

```dart
// Confetti (distribucion de peso)
const celebrationColors = {
  GuitarrColors.ampOrange: 0.40,    // 40%
  GuitarrColors.steelGold: 0.30,    // 30%
  GuitarrColors.guitarTeal: 0.20,   // 20%
  GuitarrColors.success: 0.10,      // 10%
};

// Streak levels
const streakLevelColors = {
  'bronze': GuitarrColors.steelGold,
  'silver': GuitarrColors.guitarTeal,
  'gold': GuitarrColors.ampOrange,
  'diamond': GuitarrColors.success,
};
```

---

## Resumen de Widgets a Implementar

| Widget | Archivo | Prioridad |
|--------|---------|-----------|
| ConfettiCelebration | `/lib/shared/widgets/confetti_celebration.dart` | Alta |
| StreakCounter | `/lib/shared/widgets/streak_counter.dart` | Alta |
| ApproachRing | `/lib/shared/widgets/approach_ring.dart` | Media |
| EnhancedErrorFeedback | `/lib/shared/widgets/enhanced_error_feedback.dart` | Media |
| FretDiagram | `/lib/shared/widgets/fret_diagram.dart` | Baja |

---

*Documento creado para GuitarrApp - FASE 2: Polish UX*
*Ultima actualizacion: Enero 2026*
