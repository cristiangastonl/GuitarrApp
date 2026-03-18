# GuitarrApp — ML Chord Detection: Plan de Implementación

## Estado actual del repo (branch main)
- Audio capture: flutter_sound a 44100Hz, PCM16, mono ✅
- Detección: YIN pitch detection (nota individual, no acordes) ✅
- Matching: frecuencia → nota root del acorde (no es ML) ✅
- Samples: 28 MP3s (14 acordes × 2 intensidades: normal + soft) ✅
- Dependencia FFT: fftea ^1.0.2 ✅
- **NO hay**: Python pipeline, modelo TFLite, mel spectrogram, tflite_flutter

## Lo que hay que construir (6 tareas en orden)

---

### Tarea 1: Dataset expansion via audio augmentation
**Objetivo:** Expandir los 28 samples existentes a ~500+ por acorde usando augmentation

```
Leé la skill en .claude/skills/guitarrapp-ml/SKILL.md

Creá un directorio training/ en la raíz del repo con esta estructura:
training/
├── scripts/
│   ├── augment_dataset.py
│   └── requirements.txt
├── dataset/
│   ├── raw/        (symlink o copia de assets/audio/chords/clean/)
│   ├── augmented/  (output)
│   └── labels.json
└── configs/
    └── training_config.yaml

El script augment_dataset.py debe:
1. Leer todos los MP3 de assets/audio/chords/clean/
2. Para cada sample, generar 30-50 variaciones usando:
   - Time stretch (±10%)
   - Pitch shift (±1 semitono)
   - Noise injection (SNR 20-40dB)
   - Volume variation (0.7x-1.3x)
3. Guardar como WAV 16kHz mono en dataset/augmented/{chord_name}/
4. Generar labels.json con el mapping chord_name → class_index
5. Agregar una clase "silence" con ruido blanco/rosa generado

Dependencias: librosa, soundfile, numpy
Target: mínimo 500 samples por clase, 14 clases + silence = ~7500 total
```

---

### Tarea 2: Feature extraction (mel spectrogram)
**Objetivo:** Extraer mel spectrograms de todos los samples augmented

```
Leé la skill en .claude/skills/guitarrapp-ml/SKILL.md
Leé references/mel-spectrogram-guide.md para los parámetros.

Creá training/scripts/extract_features.py que:
1. Lea todos los WAV de dataset/augmented/
2. Compute mel spectrograms con estos parámetros EXACTOS:
   - sr=16000, n_mels=64, n_fft=1024, hop_length=512
   - fmin=80, fmax=4000
   - Log scaling: np.log(mel + 1e-6)
3. Pad/truncate todos a duración fija (1.5 segundos → shape 64×47)
4. Guarde features como .npz con X (features) e y (labels)
5. Split 80/10/10 stratified (train/val/test)
6. Genere visualización: 1 spectrogram por clase como PNG para verificación visual

IMPORTANTE: Estos parámetros van a tener que matchear EXACTAMENTE con el
código Dart de inferencia que se cree en Tarea 5. Documentalos en
training/configs/mel_params.json
```

---

### Tarea 3: Modelo CNN + entrenamiento
**Objetivo:** Entrenar un CNN clasificador optimizado para TFLite

```
Leé la skill en .claude/skills/guitarrapp-ml/SKILL.md

Creá training/scripts/train_model.py que:
1. Cargue features de dataset/features.npz
2. Aplique SpecAugment on-the-fly durante training:
   - Frequency masking (param=5, 2 masks)
   - Time masking (param=10, 2 masks)
3. Construya un CNN small (target: <500KB quantized):
   - Conv2D(32) → BN → ReLU → MaxPool → Dropout(0.25)
   - Conv2D(64) → BN → ReLU → MaxPool → Dropout(0.25)
   - Conv2D(128) → BN → ReLU → GlobalAvgPool → Dropout(0.4)
   - Dense(64) → Dropout(0.3) → Dense(num_classes, softmax)
4. Training config:
   - Adam lr=1e-3, ReduceLROnPlateau
   - Early stopping patience=10
   - Class weights si hay imbalance
   - Batch size 32
5. Guarde el mejor modelo como training/models/best_model.keras
6. Genere métricas: accuracy, loss curves, per-class F1

Target: >85% accuracy en test set
```

---

### Tarea 4: Export a TFLite int8
**Objetivo:** Convertir el modelo a TFLite quantizado para mobile

```
Leé la skill en .claude/skills/guitarrapp-ml/SKILL.md

Creá training/scripts/export_tflite.py que:
1. Cargue training/models/best_model.keras
2. Convierta a TFLite con full int8 quantization:
   - Representative dataset de 200 samples del training set
   - input/output type = int8
3. Guarde como training/models/chord_classifier_int8.tflite
4. Genere training/models/labels.txt (una clase por línea, en orden)
5. Valide: corra inferencia TFLite en 20 samples de test y compare
   con predicciones del modelo Keras original
6. Reporte tamaño del modelo (target: <500KB)

Creá training/scripts/evaluate_model.py que:
1. Cargue el .tflite
2. Corra en todo el test set
3. Genere confusion matrix como PNG
4. Genere classification report (precision/recall/F1 por clase)
5. Identifique los pares de acordes más confundidos
```

---

### Tarea 5: Integración Flutter (tflite_flutter)
**Objetivo:** Crear el servicio Dart que hace inferencia con el modelo TFLite

```
Leé la skill en .claude/skills/guitarrapp-ml/SKILL.md

1. Agregá dependencia: tflite_flutter al pubspec.yaml

2. Copiá el modelo y labels a Flutter:
   - assets/models/chord_classifier_int8.tflite
   - assets/models/labels.txt
   - Agregá ambos al pubspec.yaml assets

3. Creá lib/core/audio/mel_spectrogram_service.dart:
   - Compute mel spectrogram en Dart con EXACTAMENTE los mismos
     parámetros que el Python training:
     sr=16000, n_mels=64, n_fft=1024, hop_length=512, fmin=80, fmax=4000
   - Usa fftea para el STFT
   - Implementá mel filterbank manualmente (o buscá un package)
   - Log scaling: log(mel + 1e-6)
   - Pad/truncate a shape (64, 47)

4. Creá lib/core/audio/chord_classifier_service.dart:
   - Cargue el modelo TFLite al iniciar
   - Método: classifyChord(Float32List audioSamples) → (String chord, double confidence)
   - Resample audio de 44100Hz a 16000Hz si es necesario
   - Compute mel spectrogram
   - Quantize input (float → int8 usando scale/zero_point del modelo)
   - Run inference
   - Return top prediction con confidence

5. Creá lib/core/audio/chord_detection_service.dart:
   - Reemplazá el approach actual de frequency matching
   - Acumulá audio buffer (~1.5 segundos)
   - Cuando el buffer esté lleno, clasificá con ChordClassifierService
   - Stream results via StreamController<ChordDetectionResult>

6. Actualizá mobile_audio_capture.dart:
   - Integrá ChordDetectionService en el pipeline
   - Mantené YIN pitch detection como fallback/complemento para el tuner
```

---

### Tarea 6: Integración en game logic
**Objetivo:** Conectar el nuevo clasificador ML al gameplay existente

```
1. Actualizá lesson_screen.dart:
   - Reemplazá _matchFrequencyToChord() con el resultado de
     ChordClassifierService
   - El clasificador devuelve (chord_name, confidence)
   - Usá confidence como accuracy para el scoring existente
   - Si chord_name == expected_chord: accuracy = confidence
   - Si chord_name != expected_chord: accuracy = 0

2. Actualizá song_game_screen.dart con la misma lógica

3. Actualizá mic_test_page.dart en onboarding:
   - Mostrá el acorde detectado por ML (no solo la nota)
   - Verificá que el modelo carga correctamente

4. Actualizá level_test_screen.dart:
   - Usá clasificación ML en vez de frequency matching

5. Corré flutter test y flutter analyze
```

---

## Orden de ejecución recomendado

Las tareas 1-4 son Python puro (training pipeline).
Las tareas 5-6 son Flutter/Dart (integración).

Podés hacer 1→2→3→4 secuencialmente, y después 5→6.
Cada tarea es un commit separado.

## Archivos clave a no romper
- lib/core/audio/mobile_audio_capture.dart (mantener YIN para el tuner)
- lib/features/lessons/presentation/providers/game_provider.dart (scoring logic)
- assets/audio/chords/ (samples existentes, no modificar)
