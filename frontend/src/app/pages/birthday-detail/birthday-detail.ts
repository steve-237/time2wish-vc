import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { Birthday, GiftSuggestion } from '../../models/birthday.model';
import { WishModalComponent } from '../../components/wish-modal/wish-modal.component';

@Component({
  selector: 'app-birthday-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, WishModalComponent],
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
  
  newInterest = signal<string>('');
  isGeneratingGifts = signal<boolean>(false);
  giftSuggestions = signal<GiftSuggestion[]>([]);

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

  addInterest() {
    const val = this.newInterest().trim();
    const bId = this.birthday()?.id;
    if (val && bId) {
      this.birthdayService.addInterest(bId, val);
      this.newInterest.set('');
      
      // Update local signal to reflect immediately
      this.birthday.update(b => {
        if (!b) return b;
        return { ...b, interests: [...(b.interests || []), val] };
      });
    }
  }

  removeInterest(interest: string) {
    const bId = this.birthday()?.id;
    if (bId) {
      this.birthdayService.removeInterest(bId, interest);
      
      // Update local signal to reflect immediately
      this.birthday.update(b => {
        if (!b) return b;
        return { ...b, interests: (b.interests || []).filter(i => i !== interest) };
      });
    }
  }

  generateGifts() {
    const bId = this.birthday()?.id;
    if (!bId) return;

    this.isGeneratingGifts.set(true);
    const lang = this.t9n.currentLang();

    this.birthdayService.generateGiftSuggestions(bId, lang).subscribe({
      next: (gifts) => {
        this.giftSuggestions.set(gifts);
        this.isGeneratingGifts.set(false);
      },
      error: (err) => {
        console.error('Failed to generate gifts', err);
        this.isGeneratingGifts.set(false);
        alert(this.t9n.t('toasts.error') || 'Une erreur est survenue lors de la génération.');
      }
    });
  }

  onSendWish() {
    this.isWishModalOpen.set(true);
  }

  isConfirmModalOpen = signal<boolean>(false);

  onDelete() {
    this.isConfirmModalOpen.set(true);
  }

  cancelDelete() {
    this.isConfirmModalOpen.set(false);
  }

  confirmDelete() {
    const id = this.birthday()?.id;
    if (id) {
      this.birthdayService.deleteBirthday(id);
      this.router.navigate(['/dashboard']);
    }
  }
}
