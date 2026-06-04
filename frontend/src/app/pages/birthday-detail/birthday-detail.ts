import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { Birthday } from '../../models/birthday.model';

@Component({
  selector: 'app-birthday-detail',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './birthday-detail.html',
  styleUrl: './birthday-detail.css'
})
export class BirthdayDetail implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  route = inject(ActivatedRoute);
  router = inject(Router);

  birthday = signal<Birthday | null>(null);
  daysUntil = signal<number>(0);

  ngOnInit() {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      const id = +idParam;
      const b = this.birthdayService.getBirthday(id);
      if (b) {
        this.birthday.set(b);
        this.daysUntil.set(this.birthdayService.getDaysUntil(b.birthdate));
      } else {
        this.router.navigate(['/dashboard']);
      }
    }
  }

  /** Translates internal countdown token to current language */
  getLabel(rawLabel: string): string {
    if (rawLabel === '__today__') return this.t9n.t('countdown.today');
    if (rawLabel === '__tomorrow__') return this.t9n.t('countdown.tomorrow');
    if (rawLabel.startsWith('__days__:')) {
      const days = rawLabel.split(':')[1];
      return this.t9n.t('countdown.days', days);
    }
    return rawLabel;
  }

  onSendWish() {
    const b = this.birthday();
    if (!b) return;

    const message = this.t9n.t('dashboard.wish_message', b.name);
    alert(`Message préparé :\n"${message}"\n\n(Redirection simulée)`);
    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(message)}`;
    window.open(whatsappUrl, '_blank');
  }

  onDelete() {
    const b = this.birthday();
    if (!b) return;

    if (confirm(this.t9n.t('dashboard.confirm_delete'))) {
      this.birthdayService.deleteBirthday(b.id);
      this.router.navigate(['/dashboard']);
    }
  }
}
