import { Component, input, signal, inject, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AstrologyService } from '../../services/astrology.service';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { AstrologyInsight, ZodiacCompatibility } from '../../models/astrology.model';
import { Birthday } from '../../models/birthday.model';

@Component({
  selector: 'app-astrology-widget',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './astrology-widget.component.html',
  styleUrls: ['./astrology-widget.component.scss']
})
export class AstrologyWidgetComponent {
  readonly birthdate = input.required<string>();
  readonly currentBirthday = input<Birthday | null>(null);

  protected readonly astrologyService = inject(AstrologyService);
  protected readonly birthdayService = inject(BirthdayService);
  protected readonly t9n = inject(TranslationService);

  readonly insight = signal<AstrologyInsight | null>(null);
  readonly compatibility = signal<ZodiacCompatibility | null>(null);
  readonly isCompatModalOpen = signal<boolean>(false);
  readonly selectedPartner = signal<Birthday | null>(null);

  constructor() {
    effect(() => {
      const bDate = this.birthdate();
      if (bDate) {
        this.astrologyService.getInsights(bDate, this.t9n.currentLang()).subscribe(data => {
          this.insight.set(data);
        });
      }
    });
  }

  getElementClass(element: string | undefined): string {
    if (!element) return 'element-fire';
    const e = element.toLowerCase();
    if (e.includes('feu') || e.includes('fire')) return 'element-fire';
    if (e.includes('eau') || e.includes('water')) return 'element-water';
    if (e.includes('terre') || e.includes('earth')) return 'element-earth';
    return 'element-air';
  }

  openCompatibilityModal(): void {
    const current = this.currentBirthday();
    const all = this.birthdayService.birthdays();
    const others = all.filter(b => b.id !== current?.id);
    if (others.length > 0) {
      this.selectedPartner.set(others[0]);
      this.calculatePartnerCompatibility(others[0]);
    }
    this.isCompatModalOpen.set(true);
  }

  closeCompatibilityModal(): void {
    this.isCompatModalOpen.set(false);
  }

  onPartnerChange(partnerId: string): void {
    const id = Number(partnerId);
    const partner = this.birthdayService.birthdays().find(b => b.id === id);
    if (partner) {
      this.selectedPartner.set(partner);
      this.calculatePartnerCompatibility(partner);
    }
  }

  private calculatePartnerCompatibility(partner: Birthday): void {
    const bDate = this.birthdate();
    if (bDate && partner.birthdate) {
      this.astrologyService.getCompatibility(bDate, partner.birthdate, this.t9n.currentLang()).subscribe(res => {
        this.compatibility.set(res);
      });
    }
  }
}
