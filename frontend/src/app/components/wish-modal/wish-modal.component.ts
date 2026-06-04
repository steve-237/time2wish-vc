import { Component, Input, Output, EventEmitter, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Birthday } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-wish-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './wish-modal.component.html',
  styleUrls: ['./wish-modal.component.css']
})
export class WishModalComponent implements OnInit {
  @Input({ required: true }) birthday!: Birthday;
  @Output() close = new EventEmitter<void>();

  t9n = inject(TranslationService);

  templateType: 'friendly' | 'funny' | 'formal' = 'friendly';
  channel: 'email' | 'whatsapp' = 'whatsapp';
  customMessage: string = '';

  ngOnInit() {
    this.updateMessage();
  }

  onTemplateChange(type: 'friendly' | 'funny' | 'formal') {
    this.templateType = type;
    this.updateMessage();
  }

  updateMessage() {
    const name = this.birthday.name;
    const lang = this.t9n.currentLang();
    
    if (lang === 'en') {
      if (this.templateType === 'friendly') {
        this.customMessage = `Happy birthday ${name}! I wish you a day full of joy, laughter and great moments. Big hugs! 🎉🎂`;
      } else if (this.templateType === 'funny') {
        this.customMessage = `Happy birthday ${name}! Another year older... but let's not count the candles, it might take too long! Enjoy your day! 😜🍰`;
      } else {
        this.customMessage = `Dear ${name}, wishing you a very happy birthday. May this year bring you continued success and happiness. Best regards. ✨`;
      }
    } else if (lang === 'de') {
      if (this.templateType === 'friendly') {
        this.customMessage = `Herzlichen Glückwunsch zum Geburtstag, ${name}! Ich wünsche dir einen Tag voller Freude, Lachen und tollen Momenten. Liebe Grüße! 🎉🎂`;
      } else if (this.templateType === 'funny') {
        this.customMessage = `Alles Gute zum Geburtstag, ${name}! Wieder ein Jahr älter... aber lass uns die Kerzen nicht zählen, das dauert zu lange! Genieße deinen Tag! 😜🍰`;
      } else {
        this.customMessage = `Sehr geehrte(r) ${name}, ich wünsche Ihnen alles Gute zum Geburtstag. Möge dieses neue Lebensjahr Ihnen Erfolg, Freude und Gesundheit bringen. ✨`;
      }
    } else {
      // Default French
      if (this.templateType === 'friendly') {
        this.customMessage = `Joyeux anniversaire ${name} ! Je te souhaite une journée remplie de joie, de rires et de bons moments. Gros bisous ! 🎉🎂`;
      } else if (this.templateType === 'funny') {
        this.customMessage = `Bon anniversaire ${name} ! Un an de plus... tu te rapproches de la sagesse (ou pas !). Profite bien et ne compte pas les bougies, ça fatigue ! 😜🍰`;
      } else {
        this.customMessage = `Je vous souhaite un très heureux anniversaire, ${name}. Que cette nouvelle année vous apporte réussite personnelle et professionnelle. Cordialement. ✨`;
      }
    }
  }

  send() {
    const encodedText = encodeURIComponent(this.customMessage);
    if (this.channel === 'whatsapp') {
      const url = `https://wa.me/?text=${encodedText}`;
      window.open(url, '_blank');
    } else {
      const subject = encodeURIComponent(this.t9n.currentLang() === 'en' ? `Happy Birthday ${this.birthday.name}!` : `Joyeux Anniversaire ${this.birthday.name} !`);
      const url = `mailto:?subject=${subject}&body=${encodedText}`;
      window.open(url, '_blank');
    }
    this.close.emit();
  }
}
