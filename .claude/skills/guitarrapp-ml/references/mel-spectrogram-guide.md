# Mel Spectrogram Guide for Guitar Chord Detection

## Table of Contents
1. Why Mel Spectrograms for Chord Detection
2. Parameter Selection for Guitar
3. Train ↔ Inference Parameter Sync
4. Common Pitfalls
5. Visualization & Debugging
6. Data Augmentation on Spectrograms

---

## 1. Why Mel Spectrograms for Chord Detection

Guitar chords produce complex harmonic patterns. A mel spectrogram captures
these patterns in a 2D representation that CNNs can classify effectively:

- **Time axis**: Shows the chord onset, sustain, and decay
- **Frequency axis (mel-scaled)**: Compresses high frequencies where guitar
  harmonics are dense but perceptually similar — this matches how humans
  perceive pitch differences
- **Magnitude (color)**: Shows which frequencies are active and how loud

A single guitar chord produces a unique "fingerprint" in mel space because
each chord has a specific combination of fundamental frequencies and harmonics.

---

## 2. Parameter Selection for Guitar

### Sample Rate: 16,000 Hz
- Guitar fundamental range: ~82 Hz (low E) to ~330 Hz (high E, open)
- Harmonics extend to ~4,000 Hz for classification purposes
- 16 kHz captures up to 8 kHz (Nyquist), more than enough
- Lower than 44.1 kHz = smaller features = faster inference

### n_mels: 64
- 64 mel bins gives good frequency resolution for distinguishing chords
- 128 is overkill for 15-30 chord classes and increases model size
- 40 is too low — loses distinction between close chords (E vs Em)

### n_fft: 1024
- At 16 kHz, this gives ~64ms window — good for capturing chord harmonics
- Smaller (512) = better time resolution but worse frequency resolution
- Larger (2048) = better frequency but smears temporal features

### hop_length: 512
- 50% overlap with n_fft=1024
- Produces ~47 frames for 1.5s audio at 16kHz
- Good balance between temporal detail and feature size

### fmin: 80 Hz
- Just below low E string fundamental (82.4 Hz)
- Captures the fundamental of all standard tuning notes

### fmax: 4,000 Hz
- Captures harmonics that differentiate chord voicings
- Going higher adds noise without useful chord information

### Resulting feature shape
For 1.5 seconds of audio at these settings:
- Frames: floor((16000 × 1.5) / 512) + 1 ≈ 47
- Mel bins: 64
- Shape: (64, 47) or (64, 47, 1) with channel dim

---

## 3. Train ↔ Inference Parameter Sync

**THIS IS THE #1 SOURCE OF BUGS.** If the mel parameters in the Python
training pipeline differ from the Flutter inference code, the model will
appear to work during training (high accuracy) but fail completely on device.

### Checklist for sync:

| Parameter | Python (training) | Flutter (inference) |
|-----------|-------------------|---------------------|
| Sample rate | `sr=16000` in librosa.load | Audio capture rate |
| n_mels | `n_mels=64` | Mel filterbank size |
| n_fft | `n_fft=1024` | STFT window size |
| hop_length | `hop_length=512` | STFT hop |
| fmin | `fmin=80` | Mel filterbank min |
| fmax | `fmax=4000` | Mel filterbank max |
| Log scaling | `np.log(mel + 1e-6)` | Same offset constant |
| Normalization | Per-sample or global | Same method |

### How to verify:
1. Record a test chord on the actual device
2. Extract the raw audio from the device
3. Process it through BOTH the Python pipeline AND the Flutter pipeline
4. Compare the resulting spectrograms numerically (should be near-identical)

---

## 4. Common Pitfalls

### Pitfall 1: Inconsistent audio duration
- **Problem**: Some samples are 1.0s, others 2.5s → different spectrogram widths
- **Fix**: Always pad/truncate to a fixed duration BEFORE computing mel

### Pitfall 2: Different normalization
- **Problem**: Training uses per-sample normalization, inference doesn't (or vice versa)
- **Fix**: Use the same normalization everywhere. Recommend log scale with
  fixed offset: `log(mel + 1e-6)`

### Pitfall 3: Sample rate mismatch
- **Problem**: Samples recorded at 44.1kHz, training loads at 16kHz, but
  Flutter captures at 22.05kHz
- **Fix**: Force resample everywhere to the same rate (16kHz recommended)

### Pitfall 4: Forgetting the channel dimension
- **Problem**: Training feeds (64, 47) but model expects (64, 47, 1)
- **Fix**: Always expand dims: `spectrogram[..., np.newaxis]`

### Pitfall 5: int8 quantization range
- **Problem**: After quantization, input range changes from float to int8
- **Fix**: Use the quantization parameters (scale + zero_point) from the
  TFLite model metadata to correctly map float spectrograms to int8 at inference

---

## 5. Visualization & Debugging

Always visualize spectrograms when debugging detection issues:

```python
import matplotlib.pyplot as plt
import librosa.display

def plot_chord_spectrogram(audio_path, chord_name, config=MEL_CONFIG):
    """Visualize mel spectrogram for a chord sample."""
    y, sr = librosa.load(audio_path, sr=config['sr'])
    mel = librosa.feature.melspectrogram(y=y, **config)
    log_mel = librosa.power_to_db(mel, ref=np.max)

    fig, axes = plt.subplots(1, 2, figsize=(14, 4))

    # Waveform
    librosa.display.waveshow(y, sr=sr, ax=axes[0])
    axes[0].set_title(f'{chord_name} — Waveform')

    # Mel spectrogram
    img = librosa.display.specshow(
        log_mel, sr=sr, hop_length=config['hop_length'],
        x_axis='time', y_axis='mel', ax=axes[1],
        fmin=config['fmin'], fmax=config['fmax']
    )
    axes[1].set_title(f'{chord_name} — Mel Spectrogram')
    fig.colorbar(img, ax=axes[1], format='%+2.0f dB')

    plt.tight_layout()
    plt.savefig(f'spectrogram_{chord_name}.png', dpi=100)
    plt.close()
```

### What to look for:
- **Good chord sample**: Clear horizontal bands (harmonics), defined onset
- **Bad sample**: Fuzzy, no clear structure, or mostly silent
- **Confusable chords**: If two chords look nearly identical in mel space,
  the model will struggle — consider adding more distinguishing features
  or more training samples

---

## 6. Data Augmentation on Spectrograms (SpecAugment)

SpecAugment applies masks directly to mel spectrograms and is highly
effective for small audio datasets:

```python
def spec_augment(mel_spectrogram, freq_mask_param=5, time_mask_param=10,
                 num_freq_masks=2, num_time_masks=2):
    """Apply SpecAugment: frequency and time masking."""
    augmented = mel_spectrogram.copy()
    n_mels, n_frames = augmented.shape

    # Frequency masking
    for _ in range(num_freq_masks):
        f = np.random.randint(0, freq_mask_param)
        f0 = np.random.randint(0, n_mels - f)
        augmented[f0:f0 + f, :] = 0

    # Time masking
    for _ in range(num_time_masks):
        t = np.random.randint(0, time_mask_param)
        t0 = np.random.randint(0, n_frames - t)
        augmented[:, t0:t0 + t] = 0

    return augmented
```

**When to use which augmentation:**

| Augmentation | Apply to | Good for |
|-------------|----------|----------|
| Time stretch | Raw audio | Tempo variation |
| Pitch shift | Raw audio | Tuning variation |
| Add noise | Raw audio | Environmental robustness |
| SpecAugment freq mask | Spectrogram | Frequency robustness |
| SpecAugment time mask | Spectrogram | Timing robustness |
| Volume variation | Raw audio | Mic distance/gain variation |

**Rule of thumb:** Apply 2-3 raw audio augmentations per sample,
then apply SpecAugment during training (on-the-fly, not saved).
This can effectively 10x your dataset size.
