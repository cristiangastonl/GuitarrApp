// Audio Capture for Guitar App - Web Audio API
class AudioCapture {
  constructor() {
    this.audioContext = null;
    this.analyser = null;
    this.microphone = null;
    this.isCapturing = false;
    this.onAudioData = null;
    this.animationFrameId = null;
    this.bufferLength = 2048;
    this.dataArray = null;
    this.floatDataArray = null;
  }

  async initialize() {
    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 44100
      });

      // Resume context if suspended (Chrome autoplay policy)
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      console.log('AudioContext initialized, sample rate:', this.audioContext.sampleRate);
      return true;
    } catch (e) {
      console.error('Failed to initialize AudioContext:', e);
      return false;
    }
  }

  async startCapture() {
    if (this.isCapturing) return true;

    try {
      // Request microphone access
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
          sampleRate: 44100
        }
      });

      // Ensure context is running
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      // Create analyser node
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = this.bufferLength * 2;
      this.analyser.smoothingTimeConstant = 0.1;

      // Connect microphone to analyser
      this.microphone = this.audioContext.createMediaStreamSource(stream);
      this.microphone.connect(this.analyser);

      // Create data arrays
      this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
      this.floatDataArray = new Float32Array(this.analyser.fftSize);

      this.isCapturing = true;
      this._processAudio();

      console.log('Audio capture started');
      return true;
    } catch (e) {
      console.error('Failed to start audio capture:', e);
      return false;
    }
  }

  stopCapture() {
    this.isCapturing = false;

    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }

    if (this.microphone) {
      this.microphone.disconnect();
      this.microphone = null;
    }

    console.log('Audio capture stopped');
  }

  _processAudio() {
    if (!this.isCapturing) return;

    // Get time domain data (waveform)
    this.analyser.getFloatTimeDomainData(this.floatDataArray);

    // Check if there's actual audio (not just silence)
    let maxVal = 0;
    for (let i = 0; i < this.floatDataArray.length; i++) {
      const absVal = Math.abs(this.floatDataArray[i]);
      if (absVal > maxVal) maxVal = absVal;
    }

    // Only send data if there's actual audio above noise floor
    if (maxVal > 0.01 && this.onAudioData) {
      // Convert Float32Array to regular array for transfer
      const audioData = Array.from(this.floatDataArray);
      this.onAudioData(audioData, this.audioContext.sampleRate);
    }

    // Continue processing
    this.animationFrameId = requestAnimationFrame(() => this._processAudio());
  }

  // Pitch detection using autocorrelation (YIN-like algorithm)
  detectPitch(audioData, sampleRate) {
    const bufferSize = audioData.length;

    // Check if buffer has enough energy
    let rms = 0;
    for (let i = 0; i < bufferSize; i++) {
      rms += audioData[i] * audioData[i];
    }
    rms = Math.sqrt(rms / bufferSize);

    if (rms < 0.01) {
      return { frequency: 0, confidence: 0 };
    }

    // Autocorrelation
    const correlations = new Float32Array(bufferSize);
    for (let lag = 0; lag < bufferSize; lag++) {
      let correlation = 0;
      for (let i = 0; i < bufferSize - lag; i++) {
        correlation += audioData[i] * audioData[i + lag];
      }
      correlations[lag] = correlation;
    }

    // Find first peak after initial decline
    let foundPeak = false;
    let peakLag = 0;
    let peakValue = 0;

    // Skip very low lags (high frequencies we don't care about)
    const minLag = Math.floor(sampleRate / 1000); // ~1000Hz max
    const maxLag = Math.floor(sampleRate / 50);   // ~50Hz min

    for (let lag = minLag; lag < Math.min(maxLag, bufferSize); lag++) {
      if (correlations[lag] > peakValue) {
        peakValue = correlations[lag];
        peakLag = lag;
        foundPeak = true;
      }
    }

    if (!foundPeak || peakLag === 0) {
      return { frequency: 0, confidence: 0 };
    }

    // Calculate frequency from lag
    const frequency = sampleRate / peakLag;

    // Calculate confidence based on peak clarity
    const confidence = Math.min(1, peakValue / correlations[0]);

    // Validate frequency range for guitar (80Hz - 1200Hz roughly)
    if (frequency < 70 || frequency > 1500) {
      return { frequency: 0, confidence: 0 };
    }

    return { frequency, confidence };
  }

  // Convert frequency to note name
  frequencyToNote(frequency) {
    if (frequency <= 0) return null;

    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const A4 = 440;

    // Calculate semitones from A4
    const semitones = 12 * Math.log2(frequency / A4);
    const noteIndex = Math.round(semitones) + 9; // A is at index 9
    const octave = Math.floor((noteIndex + 3) / 12) + 4;
    const note = noteNames[((noteIndex % 12) + 12) % 12];

    // Calculate cents deviation
    const exactSemitones = semitones;
    const roundedSemitones = Math.round(semitones);
    const cents = (exactSemitones - roundedSemitones) * 100;

    return {
      name: note,
      octave: octave,
      fullName: note + octave,
      cents: Math.round(cents),
      frequency: frequency
    };
  }
}

// Global instance
window.audioCapture = new AudioCapture();

// Initialize on first user interaction
let initialized = false;
document.addEventListener('click', async () => {
  if (!initialized) {
    await window.audioCapture.initialize();
    initialized = true;
  }
}, { once: false });

console.log('Audio capture module loaded');
