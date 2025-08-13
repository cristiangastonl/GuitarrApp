# 🎸 GuitarrApp - MVP Development

## Project Overview
GuitarrApp es una aplicación para aprender guitarra tocando, enfocada en mejorar timing, técnica y tono a través de práctica estructurada con feedback en tiempo real.

---

## 1) Alcance del MVP (versión 0)

### Plataforma
- **Primary**: Mobile (ideal iOS primero por latencia)
- **Alternative**: Desktop si querés ir más rápido

### Módulos Incluidos
1. **Metrónomo** con acentos y rampas de tempo
2. **Practicar temas** (librería curada de riffs icónicos, con objetivos por pasos)
3. **Escucha y feedback básico**: tempo, limpieza de ataque, consistencia del palm mute, errores de entrada/salida de compás
4. **Asistente de tono** (reglas simples): pedirá tu guitarra y ampli y te dará un preset aproximado (ej: Boss Katana 50 Gen 3)

### Puntaje de Sesión
- **Timing 50%** (desviación de BPM y "tightness")
- **Limpieza/ataque 20%**
- **Palm mute/consistencia 20%**
- **Afinación básica en notas sostenidas 10%**

**Output**: Score 0–100 + 3 tips accionables

---

## 2) Flujo de Usuario

### 1. Onboarding Rápido
- Elegís objetivos (ej: "Mejorar downpicking" / "Subir tempo en riffs de AC/DC")
- Cargás setup (guitarra, pastillas, ampli/modelador)

### 2. Home
- Metas activas + botón "Practicar ahora"

### 3. Sesión de Práctica
- Elegís Tema/Riff, ves el Roadmap (pasos + tempos metas)
- Abrís el metrónomo, grabás 15–30s

### 4. Feedback
- Puntaje, gráfico de tempo (si te adelantás/atrasás)
- Tips de ejecución y preset sugerido para tu equipo

### 5. Historial
- Evolución por riff/tema, mejores tomas, próximos objetivos

---

## 3) "Practicar Temas" — Librería Inicial y Roadmaps

### Black Sabbath
- **Paranoid** (riff principal) → objetivo: 164 BPM limpios
  - Roadmap: 100 → 120 → 140 → 150 → 160 → 164 (sube si haces 3 tomas "clean" seguidas)
- **Iron Man** (riff) → foco: precisión en bends y timing en corcheas

### Metallica
- **Enter Sandman** (main riff, E) → foco: palm mute y consistencia de picking
  - Roadmap: 72 → 88 → 96 → 108 → 116 (target)
- **Master of Puppets** (downpicking) → bloques de resistencia de 20–30s, subiendo 4–6 BPM al superar umbral

### La Renga
- **El final es en donde partí** (riff) → foco: acentos y groove con púa alternada
- **La razón que te demora** (riff) → consistencia rítmica + ataque

### AC/DC
- **Back in Black** (intro) → dinámica/ghost notes + swing leve
- **Highway to Hell** (acordes) → control de gain y ataque parejo

### Ejemplo de Roadmap (Enter Sandman)
- **Paso 1**: Skeleton a 72 BPM (sin fills), 3 tomas limpias (≤±3% de desviación)
- **Paso 2**: Con palm mute marcado a 88 BPM
- **Paso 3**: Añadir acentos correctos a 96 BPM
- **Paso 4**: 108 BPM con clic solo en 1 y 3 (para sentir el groove)
- **Paso 5 (target)**: 116 BPM, 2 tomas seguidas con tightness ≥ 80

---

## 4) Feedback que dará el MVP

### Análisis por Categoría
- **Tempo/tightness**: desviación promedio y máx. por compás (te muestra "te adelantas en los beats 2 y 4")
- **Palm mute**: consistencia (variación RMS entre notas muteadas)
- **Ataque/limpieza**: detección de transitorios dobles (ataques sucios)
- **Afinación básica**: chequear nota objetivo en notas largas (desviación en cents)

### Tips Concretos Ejemplos
- "Probá 4 BPM menos: tu tightness cayó a partir de 108"
- "Palm mute irregular en compás 5; baja la mano hacia el puente"
- "Ataque fuerte en cuerda 6; inclina 10–15° la púa"

---

## 5) Asistente de Tono por Setup

### Input Requerido
- Guitarra (single/humbucker)
- Ampli/modelador
- Pastillas
- Afinación

### Ejemplos (Boss Katana 50 Gen 3)
- **AC/DC (Back in Black)**: Amp Crunch, Gain 2–3, Bass 4, Mid 7–8, Treb 6–7, Presence 6, Boost OD leve, Reverb plate muy baja, Master alto
- **Metallica (Enter Sandman)**: Amp Lead/Brown, Gain 6–7, Bass 6–7, Mid 3, Treb 6, Presence 6, Noise gate ON, Reverb casi nada. Púa firme y palm mute cerca del puente
- **Black Sabbath (Paranoid/Iron Man)**: Amp Lead, Fuzz si tenés (o Boost con Gain alto), Bass 6–7, Mid 7, Treb 5, Reverb short
- **La Renga**: Amp Crunch/Lead, Gain 5, Bass 5–6, Mid 6, Treb 6, un poco de room reverb

**Evolución futura**: El "Asistente de tono" aprende de tu grabación (comparando espectro y presencia) para ajustar mids y gain automáticamente.

---

## 6) Arquitectura (Simple y Construible)

### Frontend
- **UI**: SwiftUI (iOS) o Flutter
- **Audio I/O + Metrónomo**: AVAudioEngine (iOS) u Oboe (Android)

### Backend/Análisis
- **Extracción de features (on-device)**: FFT + onsets + beat tracking (autocorrelación para tempo, energía de banda para palm mute, detección de transitorios)
- **Motor de evaluación**:
  - Timing: alinear onsets al grid del metrónomo, calcular desviación (ms)
  - Limpieza/ataque: contar transitorios dobles (>1 pico en 30–50 ms)
  - Palm mute: relación energía baja vs. alta frecuencia
  - Afinación: YIN o autocorrelación en notas largas
- **Reglas de tono**: primero heurísticas; luego modelo ligero (on-device) para sugerencias más finas
- **Datos**: todo local; opcional backup/analytics anonimizados más adelante

---

## 7) Modelo de Datos (Mínimo)

### Core Models
- **UserSetup**: { guitarra_tipo, pastillas, ampli, afinación }
- **Song/Riff**: { banda, título, bpm_target, tabs/guía, checkpoints }
- **Session**: { riff_id, bpm, fecha, score_total, timing_ms_avg, palm_consistency, notas }
- **TonePreset**: { banda/tema, amp_type, gain, eq { bass, mid, treble, presence }, fx }

---

## 8) Roadmap de Desarrollo (Fases)

### Fase 1 – Núcleo de Práctica
- Metrónomo sólido (acentos, subdivisiones, rampas)
- Grabación + análisis de timing y limpieza
- UI de roadmaps por riff (con desbloqueo por objetivos)

### Fase 2 – Tono y Setup
- Formulario de setup + presets por banda
- Comparador de tono (centroide espectral / presencia) → tips simples de EQ/gain

### Fase 3 – Librería y Progreso
- +8–12 riffs (2–3 por banda)
- Historial y gráficos de mejora, badges por hitos (ej: "Downpicking 110 BPM")

### Fase 4 – Afinación y Musicalidad
- Chequeo de bends y vibrato (afinación en cents)
- Modo "clic en 2 y 4" y "clic fantasma" para groove

---

## 9) Ejemplo de "Hoja de Ruta" (Enter Sandman)

### Objetivo
Tocar el riff a 116 BPM con palm mute consistente y timing ≤ ±20 ms

### KRs (Key Results)
- **KR1**: Tightness ≥ 80 en 108 BPM (2 tomas seguidas)
- **KR2**: Palm mute var. RMS ≤ 12% en compases 3–6
- **KR3**: Ataques limpios (0 transitorios dobles por compás durante 20s)

---

## 10) Próximos Pasos Inmediatos

1. Confirmo lista exacta de riffs (2 por banda) y BPM objetivo
2. Armo JSON base de ejercicios + presets de tono
3. Boceto 3 pantallas: Home, Sesión, Feedback
4. Defino el algoritmo de tightness y umbrales

---

# Databases Structure for Notion

## 📋 Features Roadmap
**Properties:**
- Name (Title)
- Phase (Select: Fase 1, Fase 2, Fase 3, Fase 4)
- Status (Select: Not Started, In Progress, Done)
- Priority (Select: High, Medium, Low)
- Description (Text)
- Acceptance Criteria (Text)

## 📱 UI Tasks  
**Properties:**
- Task Name (Title)
- Screen (Select: Onboarding, Home, Practice Session, Feedback, History)
- Status (Select: Not Started, In Progress, Done)
- Sprint (Select: Sprint 1, Sprint 2, Sprint 3, Sprint 4)
- Priority (Select: High, Medium, Low)
- Estimated Hours (Number)
- Description (Text)
- Dependencies (Relation)

## ⚙️ Backend Tasks
**Properties:**
- Task Name (Title)
- Category (Select: Audio Engine, Analysis, Data Models, API, Integration)
- Status (Select: Not Started, In Progress, Done)
- Sprint (Select: Sprint 1, Sprint 2, Sprint 3, Sprint 4)
- Priority (Select: High, Medium, Low)
- Technical Complexity (Select: Low, Medium, High)
- Estimated Hours (Number)
- Description (Text)
- Dependencies (Relation)

## 🎵 Riffs Library
**Properties:**
- Song Title (Title)
- Band (Select: Black Sabbath, Metallica, La Renga, AC/DC)
- Target BPM (Number)
- Focus Area (Select: Palm Mute, Downpicking, Ghost Notes, Bends, Groove)
- Roadmap Steps (Text)
- Implementation Status (Select: Not Started, In Progress, Done)
- Audio File (File)
- Tabs/Guide (Text)

## 🔧 Tone Presets
**Properties:**
- Preset Name (Title)
- Band/Song (Relation to Riffs Library)
- Amp Type (Text)
- Gain (Number)
- Bass (Number)
- Mid (Number)
- Treble (Number)
- Presence (Number)
- Effects (Text)
- Guitar Type (Select: Single Coil, Humbucker)
- Amp Model (Select: Boss Katana, Marshall, Fender, Other)

## 📊 Sprint Planning
**Properties:**
- Sprint Name (Title)
- Sprint Number (Select: Sprint 1, Sprint 2, Sprint 3, Sprint 4)
- Start Date (Date)
- End Date (Date)
- Goals (Text)
- Status (Select: Planning, In Progress, Complete)
- UI Tasks (Relation)
- Backend Tasks (Relation)
- Total Estimated Hours (Formula)

## 🧪 Technical Specs
**Properties:**
- Spec Name (Title)
- Category (Select: Algorithm, Architecture, Audio Processing, Analysis)
- Priority (Select: High, Medium, Low)
- Status (Select: Not Started, In Progress, Done)
- Implementation Notes (Text)
- Code References (Text)
- Related Tasks (Relation)