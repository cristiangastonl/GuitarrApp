# Arcade Theme - GuitarrApp

## Paleta de Colores

### Colores Principales
```dart
// Fondo
background:        Color(0xFF0D0D0D)  // Negro profundo
backgroundLight:   Color(0xFF1A1A2E)  // Azul oscuro sutil

// Neón (colores principales)
neonGreen:         Color(0xFF00FF41)  // Verde matrix - éxito, perfecto
neonPink:          Color(0xFFFF00FF)  // Magenta - acentos, títulos
neonCyan:          Color(0xFF00FFFF)  // Cyan - info, secundario
neonYellow:        Color(0xFFFFFF00)  // Amarillo - combo, puntos
neonRed:           Color(0xFFFF0040)  // Rojo - error, miss

// Estados
success:           neonGreen
warning:           neonYellow
error:             neonRed
info:              neonCyan

// Texto
textPrimary:       Color(0xFFFFFFFF)  // Blanco
textSecondary:     Color(0xFF888888)  // Gris
```

### Uso de Colores
| Elemento | Color | Notas |
|----------|-------|-------|
| Fondo general | background | Negro profundo |
| Cards/Containers | backgroundLight | Leve contraste |
| Título app | neonPink | Con efecto glow |
| Botones primarios | neonGreen | Con glow |
| Botones secundarios | neonCyan | Sin glow |
| Puntuación | neonYellow | Siempre con glow |
| Combo | neonYellow | Parpadea al subir |
| PERFECT | neonGreen | Flash + glow |
| GOOD | neonCyan | Flash suave |
| OK | neonYellow | Sin flash |
| MISS | neonRed | Flash + shake |
| Nivel bloqueado | textSecondary | Opacidad 50% |
| Estrellas llenas | neonYellow | Con glow |
| Estrellas vacías | textSecondary | Sin glow |

---

## Tipografía

### Fuente Principal
**Press Start 2P** de Google Fonts
- Estilo pixelado retro
- Usar para: títulos, scores, combos

### Fuente Secundaria
**Roboto Mono** o monospace del sistema
- Para texto largo y descripciones
- Más legible que Press Start 2P

### Tamaños
```dart
// Títulos
titleLarge:    24.0  // "GUITARR APP"
titleMedium:   18.0  // "NIVEL 1: Em"
titleSmall:    14.0  // Subtítulos

// Cuerpo
bodyLarge:     16.0  // Instrucciones
bodyMedium:    14.0  // Texto general
bodySmall:     12.0  // Captions

// Especiales
scoreDisplay:  32.0  // Puntuación grande
comboDisplay:  24.0  // Combo actual
feedbackText:  48.0  // "PERFECT!"
```

---

## Efectos Visuales

### Glow Effect (Neón)
```dart
BoxDecoration neonGlow(Color color) {
  return BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.6),
        blurRadius: 15,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 30,
        spreadRadius: 5,
      ),
    ],
  );
}
```

### Animaciones

#### Parpadeo (Blink)
- Duración: 1 segundo
- Curva: ease-in-out
- Uso: "INSERT COIN", indicador de escucha

#### Pulso (Pulse)
- Duración: 0.5 segundos
- Escala: 1.0 → 1.2 → 1.0
- Uso: Combo al subir, estrellas al ganar

#### Flash de Feedback
- Duración: 0.3 segundos
- PERFECT: Verde flash full screen + texto grande
- GOOD: Cyan flash parcial
- MISS: Rojo flash + shake del diagrama

#### Entrada de Pantalla
- Duración: 0.4 segundos
- Tipo: Slide desde abajo + fade in

---

## Wireframes ASCII

### Home Screen
```
┌─────────────────────────────────┐
│                                 │
│         GUITARR APP             │  ← neonPink, parpadea
│            ♪ ♫                  │
│                                 │
│                                 │
│      ▶ NUEVO JUEGO              │  ← neonGreen, glow
│                                 │
│      ▶ CONTINUAR                │  ← neonCyan
│                                 │
│      ▶ HIGH SCORES              │  ← neonCyan
│                                 │
│                                 │
│                                 │
│         INSERT COIN             │  ← textSecondary, blink
└─────────────────────────────────┘
```

### Level Test Screen
```
┌─────────────────────────────────┐
│    ← BACK       TEST DE NIVEL   │
│                                 │
│     Tocá el acorde:             │
│                                 │
│           Em                    │  ← neonPink grande
│                                 │
│    ┌─────────────────────┐      │
│    │  E ─●───────────────│      │
│    │  B ─●───────────────│      │  ← Diagrama del acorde
│    │  G ─●───────────────│      │
│    │  D ───●─────────────│      │
│    │  A ───●─────────────│      │
│    │  E ─●───────────────│      │
│    └─────────────────────┘      │
│                                 │
│     )))  ESCUCHANDO...  (((     │  ← neonCyan, animado
│                                 │
│      ████████░░░░░░ 3/5         │  ← Progreso del test
│                                 │
└─────────────────────────────────┘
```

### Lesson List Screen
```
┌─────────────────────────────────┐
│    ← BACK        NIVELES        │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐        │
│  │ 1   │ │ 2   │ │ 3   │        │
│  │ Em  │ │ Am  │ │ E   │        │
│  │ ★★★ │ │ ★★☆ │ │ ★☆☆ │        │
│  └─────┘ └─────┘ └─────┘        │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐        │
│  │ 4   │ │ 5   │ │ 6   │        │
│  │ A   │ │ D   │ │ G   │        │
│  │  🔒 │ │  🔒 │ │  🔒 │        │
│  └─────┘ └─────┘ └─────┘        │
│                                 │
│  ... (niveles 7-10)             │
│                                 │
│      HIGH SCORE: 12,450         │  ← neonYellow
│                                 │
└─────────────────────────────────┘
```

### Lesson Gameplay Screen
```
┌─────────────────────────────────┐
│  SCORE: 1,250      COMBO: x4    │  ← neonYellow
│                                 │
│       NIVEL 3: ACORDE E         │  ← neonPink
│                                 │
│    ┌─────────────────────┐      │
│    │  E ─●───────────────│      │
│    │  B ─●───────────────│      │
│    │  G ───●─────────────│      │
│    │  D ───●─────────────│      │
│    │  A ───●─────────────│      │
│    │  E ─●───────────────│      │
│    └─────────────────────┘      │
│                                 │
│      ████████████░░░░ 8/10      │  ← Progreso
│                                 │
│         ▶ TOCAR                 │  ← neonGreen, grande
│                                 │
└─────────────────────────────────┘
```

### Feedback Overlay (PERFECT)
```
┌─────────────────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓                      ▓▓▓▓▓│
│▓▓▓▓▓    ★ PERFECT! ★      ▓▓▓▓▓│  ← neonGreen, flash
│▓▓▓▓▓                      ▓▓▓▓▓│
│▓▓▓▓▓    +100 pts          ▓▓▓▓▓│
│▓▓▓▓▓    COMBO x5!         ▓▓▓▓▓│  ← neonYellow
│▓▓▓▓▓                      ▓▓▓▓▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└─────────────────────────────────┘
```

### Level Complete Screen
```
┌─────────────────────────────────┐
│                                 │
│    ★★★ NIVEL COMPLETO! ★★★     │  ← neonGreen, glow
│                                 │
│         ACORDE: E               │
│                                 │
│      ╔═══════════════════╗      │
│      ║  SCORE: 8,750     ║      │  ← neonYellow
│      ║  COMBO MAX: x7    ║      │
│      ║  PRECISIÓN: 92%   ║      │
│      ╚═══════════════════╝      │
│                                 │
│           ★ ★ ★                 │  ← Estrellas, neonYellow
│                                 │
│                                 │
│   ▶ SIGUIENTE    ▶ REPETIR     │  ← neonGreen, neonCyan
│                                 │
└─────────────────────────────────┘
```

---

## Diagrama de Acordes

### Formato Visual
```
     TRASTES
     1   2   3   4
   ╔═══╤═══╤═══╤═══╗
 E ║ ● │   │   │   ║  ← Dedo en traste
 B ║ ● │   │   │   ║
 G ║   │ ● │   │   ║
 D ║   │ ● │   │   ║
 A ║   │ ● │   │   ║
 E ║ ● │   │   │   ║
   ╚═══╧═══╧═══╧═══╝

   Dedos: 1=índice, 2=medio, 3=anular, 4=meñique
```

### Colores del Diagrama
- Borde: neonCyan
- Cuerda: textSecondary (líneas)
- Dedo presionando: neonGreen (círculo relleno)
- Cuerda al aire: neonGreen (círculo vacío arriba)
- Cuerda silenciada: neonRed (X arriba)
- Número de dedo: background (dentro del círculo)

---

## Sonidos

| Evento | Sonido |
|--------|--------|
| PERFECT | Fanfarria corta (arcade win) |
| GOOD | Beep positivo |
| OK | Beep neutro |
| MISS | Buzz de error |
| Combo up | "Power up" sound |
| Level complete | Fanfarria larga |
| Button press | Click retro |
| Level unlock | "Achievement" sound |
