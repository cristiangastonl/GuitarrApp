---
name: guitarrapp-ml
description: >
  Skill for training, evaluating, and expanding the ML chord detection model
  for GuitarrApp — a Flutter mobile app that gives real-time feedback on guitar
  playing. Use this skill whenever working on: chord classification model training,
  TFLite model export/quantization, mel spectrogram feature extraction, audio
  dataset preparation (WAV/MP3 chord samples), expanding chord vocabulary
  (minors, 7ths, barre chords), model accuracy evaluation, audio augmentation,
  noise filtering, or anything related to the GuitarrApp Python training pipeline.
  Also trigger when the user mentions "modelo", "entrenar", "acordes", "samples",
  "TFLite", "spectrogram", "dataset", "chord detection", "clasificador",
  "re-entrenar", or "GuitarrApp ML".
---

# GuitarrApp ML — Chord Detection Training Skill

This skill guides Claude Code through the ML pipeline for GuitarrApp's chord
detection system. The app uses a TFLite model that classifies guitar chords
from mel spectrograms captured via the device microphone.

## Project Context

Read `references/project-context.md` for the full project state, stack, and
current roadmap before starting any task.

**Quick summary:**
- **App**: Flutter (Android first) + Riverpod
- **Repo**: https://github.com/cristiangastonl/GuitarrApp
- **ML Model**: NOT YET IMPLEMENTED — this skill guides building it
- **Current detection**: YIN pitch → frequency matching against chord root notes
- **Current chords**: 14 chords × 2 intensities (normal + soft) = 28 MP3 samples
  in `assets/audio/chords/clean/{chord}/{intensity}/`
  Chords: A, Am, B, Bm, C, Cm, D, Dm, E, Em, F, Fm, G, Gm
- **Audio capture**: flutter_sound (mobile) at **44100 Hz**, PCM16, mono
  Buffer size: 2048 samples, 50% overlap
- **Pitch detection**: YIN + autocorrelation + temporal smoothing (3 frames)
- **AI coaching**: Gemini 2.0 Flash (separate from chord detection)

### Current Audio Parameters (from `mobile_audio_capture.dart`)
```dart
static const int _sampleRate = 44100;
static const int _bufferSize = 2048;
// Noise gate: adaptive, starts at 0.02 RMS
// YIN threshold: 0.15
// Confidence threshold: 0.5
// Temporal smoothing: 3 consecutive frames within 80 cents
```

### Current Chord Matching (from `lesson_screen.dart`)
The app currently matches detected **single-note frequency** against chord
root frequencies using cents tolerance. This is NOT ML-based chord detection.
The game calls `_matchFrequencyToChord(frequency, chord)` which compares
the YIN-detected pitch against known frequencies and returns accuracy 0.0-1.0.

**This skill's goal is to replace this frequency-matching approach with
proper ML-based chord classification using TFLite.**

---

## Pipeline Overview

The training pipeline has 5 stages. Always confirm which stage the user needs
before diving in.

### Stage 1: Dataset Preparation

**Goal:** Organize and validate audio samples for training.

**Directory structure expected:**
```
training/
├── dataset/
│   ├── raw/              # Original recordings (WAV/MP3)
│   │   ├── E_major/
│   │   ├── E_minor/
│   │   ├── A_major/
│   │   └── ...
│   ├── processed/        # Normalized, trimmed, resampled
│   └── augmented/        # After augmentation
├── models/
│   ├── checkpoints/
│   └── exports/          # Final .tflite files
├── scripts/
│   ├── prepare_dataset.py
│   ├── train_model.py
│   ├── export_tflite.py
│   ├── evaluate_model.py
│   └── augment_data.py
└── configs/
    └── training_config.yaml
```

**Key rules:**
- All audio MUST be resampled to a consistent sample rate (16kHz or 44.1kHz — pick one and stick with it)
- **CURRENT STATE**: Only 1 sample per chord per intensity (28 total).
  This is FAR too few for ML. Target: minimum 50 per class, ideally 200+.
- Include "silence" / "noise" as a class for real-world robustness
- Samples should be ~1-2 seconds of a single chord being strummed

**Existing samples in repo** (`assets/audio/chords/`):
```
assets/audio/chords/
├── index.json              # Manifest with all chord paths
└── clean/
    ├── A/
    │   ├── normal/A_normal_take_01.mp3
    │   └── soft/A_soft_take_01.mp3
    ├── Am/
    │   ├── normal/Am_normal_take_01.mp3
    │   └── soft/Am_soft_take_01.mp3
    ├── B/  Bm/  C/  Cm/  D/  Dm/  E/  Em/  F/  Fm/  G/  Gm/
    │   └── (same structure: normal + soft, 1 take each)
    └── (14 chords × 2 intensities = 28 samples total)
```

**Training dataset structure (to be created):**
```
training/
├── dataset/
│   ├── raw/              # Additional recordings needed!
│   │   ├── A_major/      # Target: 50+ samples each
│   │   ├── A_minor/
│   │   └── ...
│   ├── processed/        # Normalized, trimmed, resampled
│   └── augmented/        # After augmentation (10x expansion)
├── models/
│   ├── checkpoints/
│   └── exports/          # Final .tflite files
├── scripts/
│   ├── prepare_dataset.py
│   ├── train_model.py
│   ├── export_tflite.py
│   ├── evaluate_model.py
│   └── augment_data.py
└── configs/
    └── training_config.yaml
```

**Dataset expansion strategy** (critical — 28 samples is not enough):
1. Use existing 28 samples as seeds
2. Apply audio augmentation to expand to ~500+ per class:
   - Time stretch, pitch shift, noise injection, volume variation
3. Record additional takes on physical guitar (different positions, mics)
4. Consider open-source guitar chord datasets as supplementary data

**Preprocessing script template:**
```python
import librosa
import numpy as np
import soundfile as sf
from pathlib import Path

TARGET_SR = 16000
DURATION = 1.5  # seconds
N_SAMPLES = int(TARGET_SR * DURATION)

def preprocess_audio(input_path: Path, output_path: Path):
    """Load, resample, normalize, and trim audio to fixed length."""
    y, sr = librosa.load(str(input_path), sr=TARGET_SR, mono=True)

    # Trim silence from edges
    y, _ = librosa.effects.trim(y, top_db=20)

    # Pad or truncate to fixed length
    if len(y) < N_SAMPLES:
        y = np.pad(y, (0, N_SAMPLES - len(y)), mode='constant')
    else:
        y = y[:N_SAMPLES]

    # Normalize amplitude
    y = y / (np.max(np.abs(y)) + 1e-7)

    sf.write(str(output_path), y, TARGET_SR)
```

### Stage 2: Feature Extraction (Mel Spectrogram)

**Goal:** Convert audio samples to mel spectrograms for CNN input.

**Parameters — two options depending on resampling strategy:**

**Option A: Resample to 16kHz (RECOMMENDED for smaller model + faster inference)**
```python
MEL_CONFIG_16K = {
    'n_mels': 64,           # Number of mel frequency bins
    'n_fft': 1024,          # FFT window size (~64ms at 16kHz)
    'hop_length': 512,      # Hop between STFT windows
    'fmin': 80,             # Min frequency (guitar low E ~82Hz)
    'fmax': 4000,           # Max frequency (guitar harmonics)
    'sr': 16000,            # Resampled rate
}
# Output shape for 1.5s audio: (64, 47) → add channel dim → (64, 47, 1)
```

**Option B: Keep native 44100Hz (matches current flutter_sound capture)**
```python
MEL_CONFIG_44K = {
    'n_mels': 64,           # Number of mel frequency bins
    'n_fft': 2048,          # FFT window size (~46ms at 44.1kHz)
    'hop_length': 1024,     # Hop between STFT windows
    'fmin': 80,             # Min frequency (guitar low E ~82Hz)
    'fmax': 4000,           # Max frequency (guitar harmonics)
    'sr': 44100,            # Native capture rate
}
# Output shape for 1.5s audio: (64, 65) → add channel dim → (64, 65, 1)
```

**Decision guide:**
- Option A = smaller features, faster inference, but requires resampling in
  Flutter before inference (or recording at 16kHz which flutter_sound supports)
- Option B = no resampling needed, direct from mic to model, but larger
  feature tensor and slightly slower inference
- If you pick Option A, change flutter_sound `sampleRate` to 16000 in
  `mobile_audio_capture.dart` line 61

**Critical:** The mel spectrogram parameters used during training MUST be
identical to those used in the Flutter app at inference time. If these are
mismatched, the model will fail silently (predicting random classes).

**Feature extraction:**
```python
import librosa
import numpy as np

def extract_mel_spectrogram(audio_path, config=MEL_CONFIG):
    """Extract log mel spectrogram matching Flutter inference params."""
    y, sr = librosa.load(audio_path, sr=config['sr'])

    mel = librosa.feature.melspectrogram(
        y=y,
        sr=config['sr'],
        n_mels=config['n_mels'],
        n_fft=config['n_fft'],
        hop_length=config['hop_length'],
        fmin=config['fmin'],
        fmax=config['fmax'],
    )

    # Log scale with offset to avoid log(0)
    log_mel = np.log(mel + 1e-6)

    return log_mel
```

**Validation checklist before training:**
- [ ] Spectrogram shape is consistent across all samples
- [ ] Visualize 3-5 samples per class to verify they look distinct
- [ ] Verify silence/noise class looks different from chord classes
- [ ] Parameters match Flutter `MelSpectrogram` implementation exactly

### Stage 3: Model Architecture & Training

**Goal:** Train a CNN classifier optimized for mobile inference.

**Recommended architecture (small, TFLite-friendly):**
```python
import tensorflow as tf

def build_chord_classifier(input_shape, num_classes):
    """Small CNN optimized for TFLite int8 quantization."""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=input_shape),

        # Conv block 1
        tf.keras.layers.Conv2D(32, (3, 3), padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Dropout(0.25),

        # Conv block 2
        tf.keras.layers.Conv2D(64, (3, 3), padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Dropout(0.25),

        # Conv block 3
        tf.keras.layers.Conv2D(128, (3, 3), padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.4),

        # Classification head
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(num_classes, activation='softmax'),
    ])
    return model
```

**Training guidelines:**
- Optimizer: Adam with lr=1e-3, reduce on plateau
- Batch size: 32 (adjust for dataset size)
- Epochs: 50-100 with early stopping (patience=10)
- Validation split: 80/10/10 (train/val/test) — stratified by chord class
- Loss: categorical_crossentropy (or sparse if using integer labels)
- Always use class weights if dataset is imbalanced

**Data augmentation (critical for small datasets):**
```python
def augment_audio(y, sr):
    """Apply augmentations that simulate real-world guitar playing."""
    augmentations = []

    # Time stretch (±10%) — simulates tempo variation
    rate = np.random.uniform(0.9, 1.1)
    augmentations.append(librosa.effects.time_stretch(y, rate=rate))

    # Pitch shift (±1 semitone) — simulates tuning variation
    n_steps = np.random.uniform(-1, 1)
    augmentations.append(librosa.effects.pitch_shift(y, sr=sr, n_steps=n_steps))

    # Add background noise
    noise = np.random.normal(0, 0.005, len(y))
    augmentations.append(y + noise)

    # Volume variation
    gain = np.random.uniform(0.7, 1.3)
    augmentations.append(y * gain)

    return augmentations
```

**SpecAugment (on mel spectrograms, highly recommended):**
- Frequency masking: mask 1-5 random frequency bands
- Time masking: mask 1-3 random time windows
- This dramatically improves robustness on mobile

### Stage 4: TFLite Export & Quantization

**Goal:** Convert trained model to int8 quantized TFLite for mobile.

```python
import tensorflow as tf
import numpy as np

def export_to_tflite(model, representative_dataset_gen, output_path):
    """Export with full int8 quantization for best mobile performance."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Full integer quantization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset_gen
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8

    tflite_model = converter.convert()

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    # Report size
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"Model exported: {output_path} ({size_mb:.2f} MB)")

def representative_dataset_gen(dataset_samples):
    """Generator for calibration during quantization."""
    def gen():
        for sample in dataset_samples[:200]:
            yield [np.expand_dims(sample, axis=0).astype(np.float32)]
    return gen
```

**Post-export validation:**
- [ ] Model file size < 1 MB (target: 200-500 KB for 15-20 chord classes)
- [ ] Run inference on 10 known samples → verify predictions match Keras model
- [ ] Measure inference latency on target device (target: < 50ms)
- [ ] Verify input/output shapes match Flutter integration code

### Stage 5: Evaluation & Iteration

**Goal:** Measure model quality and identify weaknesses.

**Metrics to track:**
- Overall accuracy (target: > 85% for MVP, > 92% for production)
- Per-class precision/recall (identify confused chord pairs)
- Confusion matrix (common confusions: Em↔E, Am↔A, Dm↔D)
- Latency on target device

**Evaluation script pattern:**
```python
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt

def evaluate_model(model, test_dataset, label_names):
    """Full evaluation with confusion matrix and per-class metrics."""
    y_true, y_pred = [], []

    for x, y in test_dataset:
        pred = model.predict(x)
        y_pred.extend(np.argmax(pred, axis=1))
        y_true.extend(y.numpy() if hasattr(y, 'numpy') else y)

    # Classification report
    print(classification_report(y_true, y_pred, target_names=label_names))

    # Confusion matrix
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(12, 10))
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=label_names,
                yticklabels=label_names, cmap='Blues')
    plt.title('Chord Classification Confusion Matrix')
    plt.ylabel('True Chord')
    plt.xlabel('Predicted Chord')
    plt.tight_layout()
    plt.savefig('confusion_matrix.png', dpi=150)
    print("Saved confusion_matrix.png")
```

**Common failure modes and fixes:**
| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Major/minor confusion (E vs Em) | Too few samples, similar spectrogram | Add more samples per class, use SpecAugment |
| Poor performance on real device | Mel param mismatch train↔inference | Verify ALL params match between Python and Flutter |
| Works in quiet, fails in noise | No noise augmentation | Add noise samples to training, include noise class |
| Barre chords misclassified | Barre chords have muted strings → unusual spectrogram | Record barre samples at multiple positions, augment heavily |
| Model too large for mobile | Architecture too deep/wide | Use depthwise separable convolutions, reduce filters |
| Slow inference | Float32 model or large input | Quantize to int8, reduce mel bins or duration |

---

## Chord Expansion Workflow (Phase 4: CONT-01)

When expanding from the current 14 chords to include 7ths, barre, and
additional minor chords:

1. **Plan the chord set** — Define exactly which chords to add and
   their string mappings:
   - Open chords: already have E, A, D, G, C, Em, Am, Dm, F, B
   - 7th chords: E7, A7, D7, G7, B7, Am7, Em7, Dm7
   - Barre chords: F barre, Bm barre, C#m, F#m

2. **Record samples** — Minimum 50 per new chord class, at 2 intensities
   (soft strum, full strum). Use the same recording setup/mic as existing
   samples for consistency.

3. **Retrain from scratch** — Don't fine-tune; rebuild the dataset with
   all chords and retrain. The model is small enough that full retraining
   is fast (~minutes on GPU).

4. **Validate confusable pairs** — After training, check the confusion
   matrix specifically for:
   - E ↔ E7 (very similar, one note difference)
   - Am ↔ Am7
   - D ↔ Dm
   - Barre F ↔ Open F

5. **Update Flutter integration** — Update the label list in the app to
   match the new model's output classes. The label order MUST match the
   training label order exactly.

---

## Flutter Integration Checklist

After any model retrain/export, verify these in the Flutter codebase:

- [ ] Copy new `.tflite` to `assets/models/chord_classifier_int8.tflite`
- [ ] Update `labels` list to match training class order
- [ ] Verify `MelSpectrogram` params in Dart match Python training params
- [ ] Run `MicTestPage` to verify detection works on device
- [ ] Test with calibration wizard (Phase 2 already complete)
- [ ] Check that `ChordMatcher` utility handles new chord names

---

## Quick Reference Commands

```bash
# Install Python dependencies for training
pip install tensorflow librosa soundfile numpy scikit-learn matplotlib seaborn pyyaml

# Prepare dataset (preprocess + augment)
python scripts/prepare_dataset.py --input dataset/raw --output dataset/processed
python scripts/augment_data.py --input dataset/processed --output dataset/augmented

# Train model
python scripts/train_model.py --config configs/training_config.yaml

# Export to TFLite
python scripts/export_tflite.py --model models/checkpoints/best.h5 --output models/exports/chord_classifier_int8.tflite

# Evaluate
python scripts/evaluate_model.py --model models/exports/chord_classifier_int8.tflite --test-data dataset/processed/test
```

---

## References

- `references/project-context.md` — Full GuitarrApp project state from Notion
- `references/mel-spectrogram-guide.md` — Deep dive on mel params and common pitfalls
