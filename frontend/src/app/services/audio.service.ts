import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class AudioService {
  private audioContext: AudioContext | null = null;

  constructor() {
    // Initialize lazily to avoid auto-play policy issues
  }

  private initContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
    if (this.audioContext.state === 'suspended') {
      this.audioContext.resume();
    }
  }

  /**
   * Plays a pleasant success chime (e.g., when adding a birthday)
   */
  playSuccessSound() {
    this.initContext();
    if (!this.audioContext) return;

    const t = this.audioContext.currentTime;
    
    // Create oscillator and gain node
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();
    
    osc.connect(gain);
    gain.connect(this.audioContext.destination);
    
    // Waveform and frequency (C5 to E5 arpeggio)
    osc.type = 'sine';
    osc.frequency.setValueAtTime(523.25, t); // C5
    osc.frequency.setValueAtTime(659.25, t + 0.1); // E5
    osc.frequency.setValueAtTime(783.99, t + 0.2); // G5
    
    // Volume envelope
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(0.3, t + 0.05);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.5);
    
    osc.start(t);
    osc.stop(t + 0.5);
  }

  /**
   * Plays a soft, low tone for deletion
   */
  playDeleteSound() {
    this.initContext();
    if (!this.audioContext) return;

    const t = this.audioContext.currentTime;
    
    const osc = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();
    
    osc.connect(gain);
    gain.connect(this.audioContext.destination);
    
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(200, t); // Low G
    osc.frequency.exponentialRampToValueAtTime(100, t + 0.3); // Drop pitch
    
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(0.3, t + 0.05);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.4);
    
    osc.start(t);
    osc.stop(t + 0.4);
  }
}
