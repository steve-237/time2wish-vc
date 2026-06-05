import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { Birthday } from '../../models/birthday.model';
import { WishModalComponent } from '../../components/wish-modal/wish-modal.component';

@Component({
  selector: 'app-birthday-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, WishModalComponent],
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
  isWishModalOpen = signal<boolean>(false);

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

  onClose() {
    this.router.navigate(['/dashboard']);
  }

  onShare() {
    const url = window.location.href;
    navigator.clipboard.writeText(url).then(() => {
      // Optional: if there was a toast service we could use it here
      alert(this.t9n.t('detail.share_success') || 'Lien copié dans le presse-papier !');
    }).catch(err => {
      console.error('Could not copy text: ', err);
    });
  }

  onSendWish() {
    this.isWishModalOpen.set(true);
  }

  onDelete() {
    const id = this.birthday()?.id;
    if (id && confirm(this.t9n.t('detail.confirm_delete') || 'Êtes-vous sûr de vouloir supprimer cet anniversaire ?')) {
      this.birthdayService.deleteBirthday(id);
      this.router.navigate(['/dashboard']);
    }
  }
}
