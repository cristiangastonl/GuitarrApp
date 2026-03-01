// Audio Synthesizer for Guitar App - Plays note examples
class AudioSynth {
  constructor() {
    this.audioContext = null;
    this.isPlaying = false;
    this.scheduledNotes = [];
    this.currentGain = null;
  }

  async initialize() {
    if (this.audioContext) return true;

    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 44100
      });

      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      console.log('AudioSynth initialized');
      return true;
    } catch (e) {
      console.error('Failed to initialize AudioSynth:', e);
      return false;
    }
  }

  // Get frequency for a note name (e.g., "E2", "A4")
  noteToFrequency(noteName) {
    const noteFrequencies = {
      'C0': 16.35, 'C#0': 17.32, 'D0': 18.35, 'D#0': 19.45, 'E0': 20.60, 'F0': 21.83,
      'F#0': 23.12, 'G0': 24.50, 'G#0': 25.96, 'A0': 27.50, 'A#0': 29.14, 'B0': 30.87,
      'C1': 32.70, 'C#1': 34.65, 'D1': 36.71, 'D#1': 38.89, 'E1': 41.20, 'F1': 43.65,
      'F#1': 46.25, 'G1': 49.00, 'G#1': 51.91, 'A1': 55.00, 'A#1': 58.27, 'B1': 61.74,
      'C2': 65.41, 'C#2': 69.30, 'D2': 73.42, 'D#2': 77.78, 'E2': 82.41, 'F2': 87.31,
      'F#2': 92.50, 'G2': 98.00, 'G#2': 103.83, 'A2': 110.00, 'A#2': 116.54, 'B2': 123.47,
      'C3': 130.81, 'C#3': 138.59, 'D3': 146.83, 'D#3': 155.56, 'E3': 164.81, 'F3': 174.61,
      'F#3': 185.00, 'G3': 196.00, 'G#3': 207.65, 'A3': 220.00, 'A#3': 233.08, 'B3': 246.94,
      'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13, 'E4': 329.63, 'F4': 349.23,
      'F#4': 369.99, 'G4': 392.00, 'G#4': 415.30, 'A4': 440.00, 'A#4': 466.16, 'B4': 493.88,
      'C5': 523.25, 'C#5': 554.37, 'D5': 587.33, 'D#5': 622.25, 'E5': 659.25, 'F5': 698.46,
      'F#5': 739.99, 'G5': 783.99, 'G#5': 830.61, 'A5': 880.00, 'A#5': 932.33, 'B5': 987.77,
    };

    return noteFrequencies[noteName] || 440;
  }

  // Play a single note with guitar-like sound
  playNote(noteName, duration = 0.5, startTime = null) {
    if (!this.audioContext) return;

    const frequency = this.noteToFrequency(noteName);
    const time = startTime || this.audioContext.currentTime;

    // Create oscillator for fundamental frequency
    const osc1 = this.audioContext.createOscillator();
    osc1.type = 'triangle';
    osc1.frequency.setValueAtTime(frequency, time);

    // Create second oscillator for harmonics
    const osc2 = this.audioContext.createOscillator();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(frequency * 2, time);

    // Create gain for envelope
    const gainNode = this.audioContext.createGain();
    const gain2 = this.audioContext.createGain();

    // Guitar-like ADSR envelope
    gainNode.gain.setValueAtTime(0, time);
    gainNode.gain.linearRampToValueAtTime(0.4, time + 0.01); // Attack
    gainNode.gain.linearRampToValueAtTime(0.3, time + 0.1);  // Decay
    gainNode.gain.linearRampToValueAtTime(0.2, time + duration * 0.7); // Sustain
    gainNode.gain.linearRampToValueAtTime(0, time + duration); // Release

    gain2.gain.setValueAtTime(0.1, time);
    gain2.gain.linearRampToValueAtTime(0, time + duration * 0.5);

    // Connect
    osc1.connect(gainNode);
    osc2.connect(gain2);
    gainNode.connect(this.audioContext.destination);
    gain2.connect(this.audioContext.destination);

    // Start and stop
    osc1.start(time);
    osc2.start(time);
    osc1.stop(time + duration + 0.1);
    osc2.stop(time + duration + 0.1);

    return { osc1, osc2, gainNode };
  }

  // Play a metronome click
  playClick(isAccent = false) {
    if (!this.audioContext) return;

    const time = this.audioContext.currentTime;
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(isAccent ? 1000 : 800, time);

    gain.gain.setValueAtTime(0.3, time);
    gain.gain.exponentialRampToValueAtTime(0.001, time + 0.1);

    osc.connect(gain);
    gain.connect(this.audioContext.destination);

    osc.start(time);
    osc.stop(time + 0.1);
  }

  // Play a sequence of notes (exercise demo)
  async playSequence(notes, bpm = 60) {
    if (!this.audioContext || this.isPlaying) return;

    await this.initialize();

    if (this.audioContext.state === 'suspended') {
      await this.audioContext.resume();
    }

    this.isPlaying = true;
    const beatDuration = 60 / bpm;
    const startTime = this.audioContext.currentTime + 0.1;

    this.scheduledNotes = [];

    for (const note of notes) {
      if (note.isRest) continue;

      const noteStartTime = startTime + (note.startBeat * beatDuration);
      const noteDuration = note.duration * beatDuration * 0.9;

      const scheduled = this.playNote(note.note, noteDuration, noteStartTime);
      this.scheduledNotes.push(scheduled);
    }

    // Calculate total duration
    const lastNote = notes[notes.length - 1];
    const totalDuration = (lastNote.startBeat + lastNote.duration) * beatDuration;

    // Set timeout to mark as not playing
    setTimeout(() => {
      this.isPlaying = false;
    }, (totalDuration + 0.5) * 1000);

    return totalDuration;
  }

  // Play exercise with metronome
  async playExerciseWithMetronome(notes, bpm = 60, beatsPerMeasure = 4, totalBeats = 8) {
    if (!this.audioContext || this.isPlaying) return;

    await this.initialize();

    if (this.audioContext.state === 'suspended') {
      await this.audioContext.resume();
    }

    this.isPlaying = true;
    const beatDuration = 60 / bpm;
    const startTime = this.audioContext.currentTime + 0.1;

    // Schedule metronome clicks
    for (let beat = 0; beat < totalBeats; beat++) {
      const clickTime = startTime + (beat * beatDuration);
      const isAccent = beat % beatsPerMeasure === 0;

      setTimeout(() => {
        if (this.isPlaying) this.playClick(isAccent);
      }, (clickTime - this.audioContext.currentTime) * 1000);
    }

    // Schedule notes
    for (const note of notes) {
      if (note.isRest) continue;

      const noteStartTime = startTime + (note.startBeat * beatDuration);
      const noteDuration = note.duration * beatDuration * 0.9;

      this.playNote(note.note, noteDuration, noteStartTime);
    }

    const totalDuration = totalBeats * beatDuration;

    setTimeout(() => {
      this.isPlaying = false;
    }, (totalDuration + 0.5) * 1000);

    return totalDuration;
  }

  // Stop all playing
  stop() {
    this.isPlaying = false;
    // Note: Web Audio API doesn't easily allow stopping scheduled notes
    // They will play out, but new ones won't be scheduled
  }
}

// Global instance
window.audioSynth = new AudioSynth();

// Initialize on first click
document.addEventListener('click', async () => {
  if (window.audioSynth && !window.audioSynth.audioContext) {
    await window.audioSynth.initialize();
  }
}, { once: true });

console.log('Audio synth module loaded');
