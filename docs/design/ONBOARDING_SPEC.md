# GuitarrApp - Especificacion de Onboarding

## Resumen

Flujo de onboarding de 5 pantallas para nuevos usuarios de GuitarrApp. El objetivo es guiar al usuario desde la bienvenida hasta estar listo para practicar, asegurando que el microfono funcione correctamente y personalizando la experiencia segun su nivel.

---

## Sistema de Diseno Base

### Colores Principales
```dart
// Fondo
GuitarrColors.backgroundPrimary    // #1B1B1B - Fondo principal
GuitarrColors.backgroundSecondary  // #242424 - Fondo secundario

// Marca
GuitarrColors.ampOrange           // #FF6B35 - Color primario (CTA)
GuitarrColors.guitarTeal          // #4ECDC4 - Secundario/Info
GuitarrColors.steelGold           // #FFD93D - Acentos/Exito

// Estados
GuitarrColors.success             // #4CAF50 - Exito
GuitarrColors.error               // #E53935 - Error

// Texto
GuitarrColors.textPrimary         // #FFFFFF - Texto principal
GuitarrColors.textSecondary       // #E0E0E0 - Texto secundario
GuitarrColors.textTertiary        // #BDBDBD - Texto terciario
```

### Tipografia
```dart
GuitarrTypography.displayLarge    // 32px, ExtraBold - Titulos principales
GuitarrTypography.displayMedium   // 28px, Bold - Subtitulos
GuitarrTypography.headlineMedium  // 20px, SemiBold - Encabezados
GuitarrTypography.bodyLarge       // 16px, Regular - Texto descriptivo
GuitarrTypography.buttonPrimary   // 16px, SemiBold - Botones
```

### Componentes
- **GlassCard**: Cards con efecto glassmorphism (blur 15px, borde 20px radius)
- **PulseAnimation**: Animaciones de pulso para indicadores
- **RecordingPulse**: Indicador de grabacion/escucha

---

## Pantalla 1: Bienvenida

### Proposito
Presentar la propuesta de valor de GuitarrApp y generar entusiasmo en el usuario.

### Estructura Visual

```
+------------------------------------------+
|                                          |
|              [Logo Animado]              |
|           (guitarra + ondas)             |
|                                          |
|           "GuitarrApp"                   |
|         (displayLarge, ampOrange)        |
|                                          |
|     "Aprende guitarra con feedback      |
|          en tiempo real"                 |
|       (bodyLarge, textSecondary)         |
|                                          |
|         +--------------------+           |
|         |                    |           |
|         |  [Ilustracion]     |           |
|         |  Guitarrista       |           |
|         |  con ondas de      |           |
|         |  sonido            |           |
|         |                    |           |
|         +--------------------+           |
|                                          |
|    +--------------------------------+    |
|    |          Comenzar              |    |
|    +--------------------------------+    |
|           (ElevatedButton, ampOrange)    |
|                                          |
|         "Ya tengo cuenta"                |
|       (TextButton, guitarTeal)           |
|                                          |
|              [o] [o] [o] [o] [o]         |
|              (Indicadores de pagina)     |
+------------------------------------------+
```

### Copy / Textos

| Elemento | Texto | Estilo |
|----------|-------|--------|
| Titulo | "GuitarrApp" | displayLarge, ampOrange |
| Subtitulo | "Aprende guitarra con feedback en tiempo real" | bodyLarge, textSecondary |
| CTA Principal | "Comenzar" | buttonPrimary, textPrimary |
| CTA Secundario | "Ya tengo cuenta" | buttonText, guitarTeal |

### Elementos de UI

1. **Logo Animado**
   - Icono de guitarra con ondas de sonido expandiendose
   - Usar `PulseAnimation` para el efecto de ondas
   - Color: `ampOrange`
   - Tamano: 120x120px

2. **Ilustracion Central**
   - Imagen vectorial de persona tocando guitarra
   - Ondas de audio visualizadas
   - Estilo minimalista, colores: ampOrange, guitarTeal
   - Dentro de `GlassCard` con padding 24px

3. **Boton Comenzar**
   - `ElevatedButton` con estilo del tema
   - Ancho completo con padding horizontal 24px
   - Altura minima 56px
   - Border radius 16px

4. **Indicadores de Pagina**
   - 5 circulos de 8px
   - Activo: `ampOrange`
   - Inactivo: `textDisabled`
   - Separacion: 8px

### Animaciones

| Animacion | Duracion | Curva | Descripcion |
|-----------|----------|-------|-------------|
| Logo entrada | 800ms | elasticOut | Escala de 0.5 a 1.0 |
| Ondas pulso | 1500ms | easeInOut | Loop infinito, escala 1.0-1.3 |
| Texto fade-in | 600ms | easeOut | Delay 400ms despues del logo |
| Boton slide-up | 500ms | easeOut | Delay 800ms, desde offset Y +50 |

---

## Pantalla 2: Permiso de Microfono

### Proposito
Explicar por que se necesita el microfono y solicitar permiso de forma amigable.

### Estructura Visual

```
+------------------------------------------+
|                                          |
|            [Icono Microfono]             |
|           (con animacion escucha)        |
|                                          |
|      "Necesitamos escucharte"            |
|         (displayMedium, textPrimary)     |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard]                     |   |
|   |                                  |   |
|   |  Para darte feedback en tiempo   |   |
|   |  real, GuitarrApp necesita       |   |
|   |  acceso a tu microfono.          |   |
|   |                                  |   |
|   |  Esto nos permite:               |   |
|   |  [check] Detectar las notas      |   |
|   |  [check] Analizar tu ritmo       |   |
|   |  [check] Mejorar tu tecnica      |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|         [Icono candado]                  |
|     "Tu audio nunca se graba ni         |
|      se envia a ningun servidor"         |
|       (bodySmall, textTertiary)          |
|                                          |
|    +--------------------------------+    |
|    |     Permitir microfono         |    |
|    +--------------------------------+    |
|           (ElevatedButton, ampOrange)    |
|                                          |
|         "Ahora no"                       |
|       (TextButton, textTertiary)         |
|                                          |
|              [o] [*] [o] [o] [o]         |
+------------------------------------------+
```

### Copy / Textos

| Elemento | Texto | Estilo |
|----------|-------|--------|
| Titulo | "Necesitamos escucharte" | displayMedium, textPrimary |
| Descripcion | "Para darte feedback en tiempo real, GuitarrApp necesita acceso a tu microfono." | bodyLarge, textSecondary |
| Beneficio 1 | "Detectar las notas que tocas" | bodyMedium, textSecondary |
| Beneficio 2 | "Analizar tu ritmo y timing" | bodyMedium, textSecondary |
| Beneficio 3 | "Ayudarte a mejorar tu tecnica" | bodyMedium, textSecondary |
| Privacidad | "Tu audio nunca se graba ni se envia a ningun servidor" | bodySmall, textTertiary |
| CTA Principal | "Permitir microfono" | buttonPrimary, textPrimary |
| CTA Secundario | "Ahora no" | buttonText, textTertiary |

### Elementos de UI

1. **Icono Microfono Animado**
   - Icono de microfono con ondas concentricas
   - Usar `RecordingPulse` modificado
   - Color base: `guitarTeal`
   - Tamano: 100x100px
   - Ondas animadas mostrando "escucha activa"

2. **Lista de Beneficios**
   - Cada item con icono de check (`success`)
   - Icono: 20x20px
   - Espacio entre items: 12px
   - Dentro de `GlassCard`

3. **Indicador de Privacidad**
   - Icono de candado (16px) + texto
   - Color: `textTertiary`
   - Margen superior: 16px

4. **Boton Permitir**
   - Icono de microfono a la izquierda
   - Ancho completo
   - Estado loading durante solicitud

### Animaciones

| Animacion | Duracion | Curva | Descripcion |
|-----------|----------|-------|-------------|
| Microfono ondas | 1200ms | easeInOut | Loop, 3 circulos expandiendose |
| Check items | 400ms cada | easeOut | Fade + slide desde izquierda, staggered 150ms |
| Boton pulse | 2000ms | easeInOut | Pulso sutil cuando esta listo |

### Estados del Boton

| Estado | Visual | Texto |
|--------|--------|-------|
| Default | ampOrange, enabled | "Permitir microfono" |
| Loading | ampOrange + spinner | "Solicitando..." |
| Granted | success, disabled | "Permiso concedido" (auto-avanza) |
| Denied | error outline | "Ir a ajustes" |

---

## Pantalla 3: Test Rapido del Microfono

### Proposito
Verificar que el microfono funciona correctamente y mostrar la deteccion de notas en accion.

### Estructura Visual

```
+------------------------------------------+
|                                          |
|        "Probemos tu microfono"           |
|         (displayMedium, textPrimary)     |
|                                          |
|     "Toca cualquier nota en tu          |
|          guitarra"                       |
|       (bodyLarge, textSecondary)         |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Visualizador]      |   |
|   |                                  |   |
|   |       [Forma de onda animada]    |   |
|   |                                  |   |
|   |           "E"                    |   |
|   |      (headlineLarge, ampOrange)  |   |
|   |                                  |   |
|   |        "Mi (329 Hz)"             |   |
|   |      (bodyMedium, guitarTeal)    |   |
|   |                                  |   |
|   |    [Barra de confianza]          |   |
|   |    ==================            |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Estado]            |   |
|   |                                  |   |
|   |  [check] Tu guitarra suena       |   |
|   |          genial!                 |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|    +--------------------------------+    |
|    |        Continuar               |    |
|    +--------------------------------+    |
|           (Solo visible tras detectar)   |
|                                          |
|              [o] [o] [*] [o] [o]         |
+------------------------------------------+
```

### Copy / Textos

| Elemento | Texto | Estilo |
|----------|-------|--------|
| Titulo | "Probemos tu microfono" | displayMedium, textPrimary |
| Instruccion inicial | "Toca cualquier nota en tu guitarra" | bodyLarge, textSecondary |
| Nota detectada | Variable (ej: "E", "A", "D") | headlineLarge, ampOrange |
| Frecuencia | Variable (ej: "Mi (329 Hz)") | bodyMedium, guitarTeal |
| Mensaje exito | "Tu guitarra suena genial!" | successMessage |
| Estado escuchando | "Escuchando..." | bodyMedium, textTertiary |
| CTA | "Continuar" | buttonPrimary |

### Elementos de UI

1. **Visualizador de Audio**
   - `GlassCard` con altura fija 200px
   - Forma de onda animada en tiempo real
   - Color de onda: `guitarTeal` con gradiente
   - Fondo: `glassOverlay`

2. **Display de Nota**
   - Nota musical grande (48px, `bpmDisplay` style)
   - Nombre completo + frecuencia debajo
   - Animacion de escala al detectar nueva nota

3. **Barra de Confianza**
   - Muestra precision de la deteccion
   - Altura: 6px
   - Gradiente: `bpmProgressGradient`
   - Border radius: 3px

4. **Card de Estado**
   - `GlassCard` con icono + mensaje
   - Icono check animado al detectar
   - Borde `success` cuando detecta correctamente

5. **Boton Continuar**
   - Aparece con fade-in tras 2 notas detectadas
   - O tras 3 segundos de deteccion continua

### Animaciones

| Animacion | Duracion | Curva | Descripcion |
|-----------|----------|-------|-------------|
| Forma de onda | Tiempo real | - | Refleja entrada de audio |
| Nota detectada | 200ms | elasticOut | Escala 0.8 -> 1.0 al cambiar |
| Indicador escucha | 800ms | easeInOut | Pulso continuo mientras espera |
| Check exito | 500ms | bounceOut | Icono aparece con bounce |
| Boton fade-in | 400ms | easeOut | Aparece tras deteccion exitosa |

### Estados de la Pantalla

| Estado | Visual | Comportamiento |
|--------|--------|----------------|
| Esperando | Pulso "Escuchando...", onda plana | Esperando entrada de audio |
| Detectando | Onda activa, nota mostrada | Actualiza nota en tiempo real |
| Exito | Card verde, boton visible | Nota detectada exitosamente |
| Error | Card roja, mensaje de ayuda | "No detectamos audio. Verifica tu microfono" |

---

## Pantalla 4: Nivel del Usuario

### Proposito
Personalizar la experiencia segun el nivel de habilidad del usuario.

### Estructura Visual

```
+------------------------------------------+
|                                          |
|       "Cual es tu nivel?"                |
|         (displayMedium, textPrimary)     |
|                                          |
|   "Esto nos ayuda a recomendarte        |
|    ejercicios adecuados"                 |
|       (bodyLarge, textSecondary)         |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Principiante]      |   |
|   |  [icono guitarra 1]              |   |
|   |                                  |   |
|   |  Principiante                    |   |
|   |  "Estoy empezando o llevo        |   |
|   |   menos de 6 meses"              |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Intermedio]        |   |
|   |  [icono guitarra 2]              |   |
|   |                                  |   |
|   |  Intermedio                      |   |
|   |  "Conozco acordes basicos        |   |
|   |   y algunas escalas"             |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Avanzado]          |   |
|   |  [icono guitarra 3]              |   |
|   |                                  |   |
|   |  Avanzado                        |   |
|   |  "Domino tecnicas complejas      |   |
|   |   y quiero perfeccionar"         |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|              [o] [o] [o] [*] [o]         |
+------------------------------------------+
```

### Copy / Textos

| Elemento | Texto | Estilo |
|----------|-------|--------|
| Titulo | "Cual es tu nivel?" | displayMedium, textPrimary |
| Subtitulo | "Esto nos ayuda a recomendarte ejercicios adecuados" | bodyLarge, textSecondary |

**Nivel Principiante:**
| Campo | Texto |
|-------|-------|
| Titulo | "Principiante" |
| Descripcion | "Estoy empezando o llevo menos de 6 meses tocando" |
| Icono | Guitarra con 1 estrella |

**Nivel Intermedio:**
| Campo | Texto |
|-------|-------|
| Titulo | "Intermedio" |
| Descripcion | "Conozco acordes basicos y algunas escalas" |
| Icono | Guitarra con 2 estrellas |

**Nivel Avanzado:**
| Campo | Texto |
|-------|-------|
| Titulo | "Avanzado" |
| Descripcion | "Domino tecnicas complejas y quiero perfeccionar" |
| Icono | Guitarra con 3 estrellas |

### Elementos de UI

1. **Cards de Nivel**
   - `MusicGlassCard` con `onTap`
   - Estado seleccionado: `isActive = true`
   - Icono a la izquierda (48x48px)
   - Titulo: `headlineMedium`
   - Descripcion: `bodyMedium`, `textTertiary`
   - Padding: 20px
   - Margen entre cards: 12px

2. **Indicador de Seleccion**
   - Borde `ampOrange` (2px) cuando seleccionado
   - Glow sutil con `BoxShadow`
   - Checkmark en esquina superior derecha

3. **Iconos de Nivel**
   - Principiante: Guitarra simple + 1 estrella
   - Intermedio: Guitarra + 2 estrellas
   - Avanzado: Guitarra electrica + 3 estrellas
   - Color: `ampOrange` para icono, `steelGold` para estrellas

### Animaciones

| Animacion | Duracion | Curva | Descripcion |
|-----------|----------|-------|-------------|
| Cards entrada | 600ms | easeOut | Staggered slide-up, 100ms delay entre cada |
| Seleccion | 300ms | easeOut | Escala 1.0 -> 1.02 + borde aparece |
| Check mark | 400ms | elasticOut | Aparece con bounce |
| Transicion | 500ms | easeInOut | Auto-avanza 800ms despues de seleccionar |

### Comportamiento
- Al seleccionar un nivel, auto-avanza a la siguiente pantalla tras 800ms
- Muestra brevemente animacion de confirmacion
- El nivel seleccionado se guarda en `SharedPreferences`

---

## Pantalla 5: Listo para Empezar

### Proposito
Confirmar la configuracion y motivar al usuario a comenzar a practicar.

### Estructura Visual

```
+------------------------------------------+
|                                          |
|           [Animacion Exito]              |
|        (confetti + check animado)        |
|                                          |
|           "Todo listo!"                  |
|         (displayLarge, ampOrange)        |
|                                          |
|      "Tu perfil esta configurado"        |
|       (bodyLarge, textSecondary)         |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Resumen]           |   |
|   |                                  |   |
|   |  Microfono         [check] OK    |   |
|   |  -------------------------       |   |
|   |  Nivel         Principiante      |   |
|   |  -------------------------       |   |
|   |  Listo para       Aprender       |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|   +----------------------------------+   |
|   |  [GlassCard - Siguiente]         |   |
|   |                                  |   |
|   |  "Tu primer ejercicio te espera: |   |
|   |   Las 6 cuerdas al aire"         |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|    +--------------------------------+    |
|    |     Empezar a practicar        |    |
|    +--------------------------------+    |
|           (ElevatedButton, ampOrange)    |
|                                          |
|         "Explorar primero"               |
|       (TextButton, guitarTeal)           |
|                                          |
|              [o] [o] [o] [o] [*]         |
+------------------------------------------+
```

### Copy / Textos

| Elemento | Texto | Estilo |
|----------|-------|--------|
| Titulo | "Todo listo!" | displayLarge, ampOrange |
| Subtitulo | "Tu perfil esta configurado" | bodyLarge, textSecondary |
| Microfono | "Microfono" / "OK" | bodyMedium / success |
| Nivel | "Nivel" / Variable | bodyMedium / ampOrange |
| Preview | "Tu primer ejercicio te espera:" | bodyMedium, textTertiary |
| Ejercicio | Variable segun nivel | headlineSmall, guitarTeal |
| CTA Principal | "Empezar a practicar" | buttonPrimary |
| CTA Secundario | "Explorar primero" | buttonText, guitarTeal |

### Ejercicio Sugerido segun Nivel

| Nivel | Ejercicio | Descripcion |
|-------|-----------|-------------|
| Principiante | "Las 6 cuerdas al aire" | Identifica cada cuerda |
| Intermedio | "Escala de Do Mayor" | Practica la escala basica |
| Avanzado | "Arpegios de septima" | Tecnica avanzada de arpegios |

### Elementos de UI

1. **Animacion de Exito**
   - Circulo con check mark grande (80px)
   - Efecto confetti usando particulas
   - Color principal: `success`
   - Duracion total: 1500ms

2. **Card de Resumen**
   - `GlassCard` con lista de items
   - Cada item: etiqueta + valor
   - Divider entre items (`divider` color)
   - Check verde para microfono OK

3. **Card de Preview**
   - `MusicGlassCard` con genero "exercise"
   - Icono de play a la derecha
   - Borde sutilmente animado

4. **Boton Principal**
   - Mayor tamano que otros botones (altura 60px)
   - Icono de play a la izquierda
   - Efecto shimmer opcional

### Animaciones

| Animacion | Duracion | Curva | Descripcion |
|-----------|----------|-------|-------------|
| Check entrada | 600ms | elasticOut | Escala desde 0 con bounce |
| Confetti | 2000ms | linear | Particulas cayendo |
| Titulo fade | 400ms | easeOut | Delay 300ms |
| Cards slide | 500ms | easeOut | Staggered desde abajo |
| Boton pulse | 1500ms | easeInOut | Pulso continuo invitando a tocar |

### Comportamiento
- Al tocar "Empezar a practicar": Navega al ejercicio sugerido
- Al tocar "Explorar primero": Navega al home/dashboard
- Marca onboarding como completado en `SharedPreferences`

---

## Navegacion y Flujo

### Diagrama de Flujo

```
[Pantalla 1: Bienvenida]
         |
         v
[Pantalla 2: Permiso Microfono]
         |
    +----+----+
    |         |
    v         v
[Granted] [Denied]
    |         |
    v         v
[Pantalla 3]  [Modal: Ir a ajustes]
         |
         v
[Pantalla 4: Nivel]
         |
         v
[Pantalla 5: Listo]
         |
    +----+----+
    |         |
    v         v
[Ejercicio] [Home]
```

### Gestos de Navegacion

| Gesto | Accion |
|-------|--------|
| Swipe izquierda | Avanza (si permitido) |
| Swipe derecha | Retrocede |
| Tap en indicador | Va a esa pantalla (si desbloqueada) |
| Back button | Retrocede (confirma salir en P1) |

### Persistencia

```dart
// Keys para SharedPreferences
'onboarding_completed'     // bool
'user_skill_level'         // String: 'beginner', 'intermediate', 'advanced'
'microphone_permission'    // String: 'granted', 'denied', 'not_asked'
'onboarding_last_screen'   // int: para retomar si cierra la app
```

---

## Especificaciones Tecnicas

### Estructura de Archivos Sugerida

```
lib/
  features/
    onboarding/
      presentation/
        screens/
          onboarding_flow.dart        // PageView controller
          welcome_screen.dart         // Pantalla 1
          microphone_permission_screen.dart  // Pantalla 2
          microphone_test_screen.dart // Pantalla 3
          skill_level_screen.dart     // Pantalla 4
          ready_screen.dart           // Pantalla 5
        widgets/
          onboarding_page_indicator.dart
          animated_logo.dart
          microphone_visualizer.dart
          level_card.dart
          confetti_animation.dart
        providers/
          onboarding_provider.dart    // Riverpod state
```

### Dependencias Necesarias

```yaml
# pubspec.yaml (ya existentes en el proyecto)
flutter_riverpod: ^2.x
permission_handler: ^11.x  # Para permisos de microfono
shared_preferences: ^2.x

# Posiblemente agregar
confetti_widget: ^0.7.x    # Para animacion de confetti (opcional)
```

### Responsividad

| Breakpoint | Ajustes |
|------------|---------|
| < 360px | Reducir padding a 16px, fuentes -2px |
| 360-414px | Diseno base |
| > 414px | Aumentar padding, centrar contenido max 414px |

### Accesibilidad

- Todos los botones tienen `semanticsLabel`
- Contraste minimo WCAG AA (4.5:1)
- Animaciones respetan `MediaQuery.disableAnimations`
- Tamanos de tap minimo 48x48px
- Soporte para lectores de pantalla

---

## Metricas de Exito

### KPIs a Trackear

| Metrica | Objetivo | Herramienta |
|---------|----------|-------------|
| Completion rate | > 80% | Analytics |
| Drop-off por pantalla | < 10% por pantalla | Analytics |
| Tiempo promedio | < 2 minutos | Analytics |
| Permiso microfono granted | > 90% | Analytics |

### Eventos a Registrar

```dart
// Eventos de analytics
'onboarding_started'
'onboarding_screen_viewed' {screen: 1-5}
'microphone_permission_requested'
'microphone_permission_result' {granted: bool}
'microphone_test_completed' {success: bool}
'skill_level_selected' {level: String}
'onboarding_completed' {duration_seconds: int}
'onboarding_skipped' {at_screen: int}
```

---

## Notas de Implementacion

1. **Usar `PageView`** con `PageController` para el flujo principal
2. **Animaciones coordinadas** usando `AnimationController` compartido por pantalla
3. **Estado global** con Riverpod para persistir progreso
4. **Lazy loading** de pantallas para mejor rendimiento
5. **Pre-cargar assets** de audio en pantalla 2 para test rapido
6. **Timeout de 10s** en test de microfono con opcion de reintentar

---

*Documento creado: Enero 2026*
*Version: 1.0*
*Autor: Agente UX GuitarrApp*
