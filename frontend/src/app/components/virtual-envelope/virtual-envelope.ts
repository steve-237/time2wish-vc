import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import confetti from 'canvas-confetti';

@Component({
  selector: 'app-virtual-envelope',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './virtual-envelope.html',
  styleUrl: './virtual-envelope.scss',
})
export class VirtualEnvelope {
  @Output() opened = new EventEmitter<void>();
  isOpening = false;
  isFullyOpened = false;

  openEnvelope() {
    if (this.isOpening) return;
    this.isOpening = true;

    // Fire confetti after flap opens (delay 600ms)
    setTimeout(() => {
      this.fireConfetti();
    }, 600);

    // Notify parent after animation completes
    setTimeout(() => {
      this.isFullyOpened = true;
      setTimeout(() => this.opened.emit(), 600); // Wait for fade-out
    }, 2500);
  }

  private fireConfetti() {
    const duration = 2000;
    const end = Date.now() + duration;

    const frame = () => {
      confetti({
        particleCount: 5,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: ['#2563EB', '#7C3AED', '#EC4899', '#F59E0B'],
        zIndex: 10000
      });
      confetti({
        particleCount: 5,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: ['#2563EB', '#7C3AED', '#EC4899', '#F59E0B'],
        zIndex: 10000
      });

      if (Date.now() < end) {
        requestAnimationFrame(frame);
      }
    };
    frame();
  }
}
