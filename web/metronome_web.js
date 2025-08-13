// Web Audio API implementation for metronome
class WebMetronome {
    constructor() {
        this.audioContext = null;
        this.gainNode = null;
        this.isInitialized = false;
    }

    async initialize() {
        if (this.isInitialized) return;
        
        try {
            // Create audio context
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            
            // Create gain node for volume control
            this.gainNode = this.audioContext.createGain();
            this.gainNode.connect(this.audioContext.destination);
            this.gainNode.gain.value = 0.3; // Default volume
            
            this.isInitialized = true;
            console.log('Web metronome initialized');
        } catch (error) {
            console.error('Failed to initialize web metronome:', error);
        }
    }

    async playClick(isAccent = false, frequency = null, duration = 0.1) {
        if (!this.isInitialized) {
            await this.initialize();
        }

        if (!this.audioContext) {
            console.warn('Audio context not available');
            return;
        }

        try {
            // Resume audio context if suspended (required for some browsers)
            if (this.audioContext.state === 'suspended') {
                await this.audioContext.resume();
            }

            // Set frequency based on accent
            const clickFrequency = frequency || (isAccent ? 1000 : 800);
            
            // Create oscillator
            const oscillator = this.audioContext.createOscillator();
            const envelope = this.audioContext.createGain();
            
            // Connect nodes
            oscillator.connect(envelope);
            envelope.connect(this.gainNode);
            
            // Configure oscillator
            oscillator.type = 'sine';
            oscillator.frequency.setValueAtTime(clickFrequency, this.audioContext.currentTime);
            
            // Configure envelope (attack-decay)
            const now = this.audioContext.currentTime;
            envelope.gain.setValueAtTime(0, now);
            envelope.gain.linearRampToValueAtTime(0.3, now + 0.01); // Quick attack
            envelope.gain.exponentialRampToValueAtTime(0.001, now + duration); // Decay
            
            // Start and stop
            oscillator.start(now);
            oscillator.stop(now + duration);
            
        } catch (error) {
            console.error('Error playing metronome click:', error);
        }
    }

    setVolume(volume) {
        if (this.gainNode) {
            this.gainNode.gain.value = Math.max(0, Math.min(1, volume));
        }
    }
}

// Create global instance
window.webMetronome = new WebMetronome();

// Flutter channel communication
window.addEventListener('flutter_metronome_play', async (event) => {
    const { isAccent, frequency, duration } = event.detail || {};
    await window.webMetronome.playClick(isAccent, frequency, duration);
});

window.addEventListener('flutter_metronome_volume', (event) => {
    const { volume } = event.detail || {};
    window.webMetronome.setVolume(volume);
});

// Auto-initialize on user interaction
document.addEventListener('click', () => {
    if (!window.webMetronome.isInitialized) {
        window.webMetronome.initialize();
    }
}, { once: true });

console.log('Web metronome script loaded');