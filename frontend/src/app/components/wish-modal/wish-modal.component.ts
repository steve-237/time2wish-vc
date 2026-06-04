import { Component, Input, Output, EventEmitter, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Birthday } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';
import { TemplateService } from '../../services/template.service';
import { TemplateManagerComponent } from '../template-manager/template-manager.component';

@Component({
  selector: 'app-wish-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, TemplateManagerComponent],
  templateUrl: './wish-modal.component.html',
  styleUrls: ['./wish-modal.component.css']
})
export class WishModalComponent implements OnInit {
  @Input({ required: true }) birthday!: Birthday;
  @Output() close = new EventEmitter<void>();

  t9n = inject(TranslationService);
  templateService = inject(TemplateService);
  private readonly http = inject(HttpClient);

  // Tab switch: 'ai' (Generation par IA) or 'custom' (Modèles personnalisés)
  selectedMode = signal<'ai' | 'custom'>('ai');

  // AI fields
  aiTone = signal<string>('friendly');
  aiInstructions = signal<string>('');
  isGenerating = signal<boolean>(false);

  // Custom templates fields
  selectedTemplateId = signal<string>('friendly');
  isTemplateManagerOpen = signal<boolean>(false);

  channel: 'email' | 'whatsapp' = 'whatsapp';
  customMessage: string = '';

  ngOnInit() {
    // Generate default AI wish on init
    this.generateAiWish();
  }

  onTemplateChange(id: string) {
    this.selectedTemplateId.set(id);
    this.updateCustomTemplateMessage();
  }

  // Generate wish via Backend AI API
  generateAiWish() {
    this.isGenerating.set(true);
    this.http.post<{ message: string }>('http://localhost:8081/api/ai/generate', {
      birthdayId: this.birthday.id,
      tone: this.aiTone(),
      extraInstructions: this.aiInstructions(),
      lang: this.t9n.currentLang()
    }).subscribe({
      next: (res) => {
        this.customMessage = res.message;
        this.isGenerating.set(false);
      },
      error: (err) => {
        console.error('Failed to generate AI wish', err);
        // Fallback locally
        this.customMessage = this.generateLocalFallback(this.aiTone());
        this.isGenerating.set(false);
      }
    });
  }

  updateCustomTemplateMessage() {
    const name = this.birthday.name;
    const currentId = this.selectedTemplateId();
    
    if (currentId === 'friendly' || currentId === 'funny' || currentId === 'formal') {
      this.customMessage = this.generateLocalFallback(currentId);
    } else if (currentId.startsWith('custom-')) {
      const idStr = currentId.substring(7);
      const id = parseInt(idStr, 10);
      const tmpl = this.templateService.templates().find(t => t.id === id);
      if (tmpl) {
        this.customMessage = tmpl.content.replace(/\{name\}/gi, name);
      }
    }
  }

  private generateLocalFallback(tone: string): string {
    const name = this.birthday.name;
    const lang = this.t9n.currentLang();
    
    if (lang === 'en') {
      if (tone === 'friendly') {
        return `Happy birthday ${name}! I wish you a day full of joy, laughter and great moments. Big hugs! 🎉🎂`;
      } else if (tone === 'funny') {
        return `Happy birthday ${name}! Another year older... but let's not count the candles, it might take too long! Enjoy your day! 😜🍰`;
      } else if (tone === 'poetic') {
        return `On this special day, ${name}, may your dreams take flight and your heart be light. Wishing you a year of pure delight. Happy birthday! 🌸`;
      } else {
        return `Dear ${name}, wishing you a very happy birthday. May this year bring you continued success and happiness. Best regards. ✨`;
      }
    } else if (lang === 'de') {
      if (tone === 'friendly') {
        return `Herzlichen Glückwunsch zum Geburtstag, ${name}! Ich wünsche dir einen Tag voller Freude, Lachen und tollen Momenten. Liebe Grüße! 🎉🎂`;
      } else if (tone === 'funny') {
        return `Alles Gute zum Geburtstag, ${name}! Wieder ein Jahr älter... aber lass uns die Kerzen nicht zählen, das dauert zu lange! Genieße deinen Tag! 😜🍰`;
      } else if (tone === 'poetic') {
        return `Zum Geburtstag viel Sonnenschein und ein glücklich Sein. Mögen deine Träume fliegen und Sorgen unterliegen. Alles Gute, ${name}! 🌸`;
      } else {
        return `Sehr geehrte(r) ${name}, ich wünsche Ihnen alles Gute zum Geburtstag. Möge dieses neue Lebensjahr Ihnen Erfolg, Freude und Gesundheit bringen. ✨`;
      }
    } else {
      // Default French
      if (tone === 'friendly') {
        return `Joyeux anniversaire ${name} ! Je te souhaite une journée remplie de joie, de rires et de bons moments. Gros bisous ! 🎉🎂`;
      } else if (tone === 'funny') {
        return `Bon anniversaire ${name} ! Un an de plus... tu te rapproches de la sagesse (ou pas !). Profite bien et ne compte pas les bougies, ça fatigue ! 😜🍰`;
      } else if (tone === 'poetic') {
        return `Que cette journée t'apporte douceur et poésie, ${name}. Que chaque instant de ta nouvelle année de vie soit rempli de sourires et d'harmonie. Joyeux anniversaire. 🌸`;
      } else {
        return `Je vous souhaite un très heureux anniversaire, ${name}. Que cette nouvelle année vous apporte réussite personnelle et professionnelle. Cordialement. ✨`;
      }
    }
  }

  send() {
    const encodedText = encodeURIComponent(this.customMessage);
    if (this.channel === 'whatsapp') {
      const waNumber = this.birthday.whatsapp ? this.birthday.whatsapp.replace(/[^0-9]/g, '') : '';
      const url = `https://wa.me/${waNumber}?text=${encodedText}`;
      window.open(url, '_blank');
    } else {
      const emailAddress = this.birthday.email || '';
      const subject = encodeURIComponent(this.t9n.currentLang() === 'en' ? `Happy Birthday ${this.birthday.name}!` : `Joyeux Anniversaire ${this.birthday.name} !`);
      const url = `mailto:${emailAddress}?subject=${subject}&body=${encodedText}`;
      window.open(url, '_blank');
    }
    this.close.emit();
  }
}
