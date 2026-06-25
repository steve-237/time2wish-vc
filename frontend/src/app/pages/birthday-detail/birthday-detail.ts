import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink, RouterModule } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { ExportService } from '../../services/export.service';
import { ToastService } from '../../services/toast.service';
import { Birthday, GiftSuggestion, Gift } from '../../models/birthday.model';
import { WishModalComponent } from '../../components/wish-modal/wish-modal.component';
import { CardGeneratorComponent } from '../../components/card-generator/card-generator.component';
import { GiftListModalComponent } from '../../components/gift-list-modal/gift-list-modal.component';
import { AuthService } from '../../services/auth.service';
import { UiService } from '../../services/ui.service';

@Component({
  selector: 'app-birthday-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, RouterModule, WishModalComponent, CardGeneratorComponent, GiftListModalComponent],
  templateUrl: './birthday-detail.html',
  styleUrl: './birthday-detail.scss'
})
export class BirthdayDetail implements OnInit {
  birthdayService = inject(BirthdayService);
  exportService = inject(ExportService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  route = inject(ActivatedRoute);
  router = inject(Router);
  authService = inject(AuthService);
  uiService = inject(UiService);

  birthday = signal<Birthday | null>(null);
  daysUntil = signal<number>(0);
  isWishModalOpen = signal<boolean>(false);
  
  newInterest = signal<string>('');
  isGeneratingGifts = signal<boolean>(false);
  aiError = signal<boolean>(false);
  giftSource = signal<string>('');
  giftSuggestions = signal<GiftSuggestion[]>([]);
  savedGifts = signal<Gift[]>([]);

  ngOnInit() {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      const id = +idParam;
      const b = this.birthdayService.getBirthday(id);
      if (b) {
        this.birthday.set(b);
        this.daysUntil.set(this.birthdayService.getDaysUntil(b.birthdate));
        this.loadGifts(b.id);
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

  isConfirmModalOpen = signal<boolean>(false);
  isShareModalOpen = signal<boolean>(false);
  isCardModalOpen = signal<boolean>(false);
  isGiftListModalOpen = signal<boolean>(false);
  canWebShare = signal<boolean>(!!navigator.share);

  onClose() {
    this.router.navigate(['/dashboard']);
  }

  toggleFavorite() {
    const b = this.birthday();
    if (b) {
      const newStatus = !b.isFavorite;
      this.birthdayService.toggleFavorite(b.id, newStatus);
      // Update local signal to reflect immediately
      this.birthday.update(current => current ? { ...current, isFavorite: newStatus } : current);
    }
  }

  onShareClick() {
    this.isShareModalOpen.set(true);
  }

  shareNative() {
    const b = this.birthday();
    if (!b) return;
    
    if (navigator.share) {
      navigator.share({
        title: `Anniversaire de ${b.name}`,
        text: `N'oubliez pas de souhaiter un joyeux anniversaire à ${b.name} le ${new Date(b.birthdate).toLocaleDateString()} !`,
        url: window.location.href
      }).then(() => {
        this.isShareModalOpen.set(false);
      }).catch(err => {
        console.error('Share failed:', err);
      });
    }
  }

  downloadIcs() {
    const b = this.birthday();
    if (b) {
      this.exportService.downloadSingleIcs(b);
      this.isShareModalOpen.set(false);
    }
  }

  copyLink() {
    const url = window.location.href;
    navigator.clipboard.writeText(url).then(() => {
      this.toastService.success(this.t9n.t('detail.share_success') || 'Lien copié dans le presse-papier !');
      this.isShareModalOpen.set(false);
    }).catch(err => {
      console.error('Could not copy text: ', err);
      this.toastService.error('Erreur lors de la copie du lien.');
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

  // ... (keep loadBirthday logic as it was, but we are replacing from line 145 so we just replace generateGifts and keeping other things untouched)
  removeInterest(interest: string) {
    const bId = this.birthday()?.id;
    if (bId) {
      this.birthdayService.removeInterest(bId, interest);
      
      this.birthday.update(b => {
        if (!b) return b;
        return { ...b, interests: (b.interests || []).filter(i => i !== interest) };
      });
    }
  }

  generateGifts() {
    const bId = this.birthday()?.id;
    if (!bId) {
      this.toastService.error('Erreur : ID de l\'anniversaire introuvable.');
      return;
    }

    this.isGeneratingGifts.set(true);
    this.aiError.set(false);
    const lang = this.t9n.currentLang();
    this.toastService.info('Lancement de la génération...');

    this.birthdayService.generateGiftSuggestions(bId, lang).subscribe({
      next: (response) => {
        this.toastService.success('Cadeaux générés avec succès !');
        this.giftSuggestions.set(response.suggestions);
        this.giftSource.set(response.source);
        this.isGeneratingGifts.set(false);
      },
      error: (err) => {
        console.error('Failed to generate gifts', err);
        this.toastService.error('Erreur technique (voir console).');
        this.isGeneratingGifts.set(false);
        this.aiError.set(true);
      }
    });
  }

  loadGifts(birthdayId: number) {
    this.birthdayService.getSavedGifts(birthdayId).subscribe({
      next: (gifts) => this.savedGifts.set(gifts),
      error: (err) => console.error('Failed to load gifts', err)
    });
  }

  saveGift(sugg: GiftSuggestion) {
    const bId = this.birthday()?.id;
    if (!bId) return;

    const newGift: Partial<Gift> = {
      name: sugg.name,
      description: sugg.preparationTips || sugg.whereToBuy,
      priceRange: sugg.estimatedPrice,
      url: sugg.purchaseLink
    };

    this.birthdayService.saveGift(bId, newGift).subscribe({
      next: (gift) => {
        this.savedGifts.update(g => [...g, gift]);
        this.toastService.success(this.t9n.t('detail.share_success') || 'Cadeau ajouté à la liste !');
      },
      error: (err) => {
        console.error('Failed to save gift', err);
        this.toastService.error('Erreur lors de la sauvegarde du cadeau.');
      }
    });
  }

  addManualGift(giftData: {name: string, description: string, priceRange: string, url: string}) {
    const bId = this.birthday()?.id;
    if (!bId) return;

    this.birthdayService.saveGift(bId, giftData).subscribe({
      next: (gift) => {
        this.savedGifts.update(g => [...g, gift]);
        this.toastService.success('Cadeau ajouté manuellement !');
      },
      error: (err) => {
        console.error('Failed to save manual gift', err);
        this.toastService.error('Erreur lors de l\'ajout du cadeau.');
      }
    });
  }

  updateGift(giftId: number, giftData: {name: string, description: string, priceRange: string, url: string}) {
    const bId = this.birthday()?.id;
    if (!bId) return;

    this.birthdayService.updateGift(bId, giftId, giftData).subscribe({
      next: (updatedGift) => {
        this.savedGifts.update(g => g.map(gift => gift.id === giftId ? updatedGift : gift));
        this.toastService.success('Cadeau modifié avec succès !');
      },
      error: (err) => {
        console.error('Failed to update gift', err);
        this.toastService.error('Erreur lors de la modification du cadeau.');
      }
    });
  }

  deleteGift(giftId: number) {
    const bId = this.birthday()?.id;
    if (!bId) return;

    this.birthdayService.deleteGift(bId, giftId).subscribe({
      next: () => {
        this.savedGifts.update(g => g.filter(gift => gift.id !== giftId));
        this.toastService.success('Cadeau supprimé de la liste.');
      },
      error: (err) => {
        console.error('Failed to delete gift', err);
        this.toastService.error('Erreur lors de la suppression.');
      }
    });
  }

  generateShareLink() {
    const b = this.birthday();
    if (!b || !b.id) return;

    this.birthdayService.generateShareToken(b.id).subscribe({
      next: (res) => {
        this.birthday.update(current => current ? { ...current, shareToken: res.token } : current);
        this.toastService.success('Lien de partage généré !');
      },
      error: (err) => {
        console.error('Failed to generate share link', err);
        this.toastService.error('Erreur lors de la génération du lien.');
      }
    });
  }

  copyShareLink() {
    const token = this.birthday()?.shareToken;
    if (!token) return;
    
    const url = `${window.location.origin}/shared/${token}`;
    navigator.clipboard.writeText(url).then(() => {
      this.toastService.success('Lien de partage copié dans le presse-papier !');
    }).catch(err => {
      console.error('Could not copy text: ', err);
      this.toastService.error('Erreur lors de la copie du lien.');
    });
  }

  onSendWish() {
    this.isWishModalOpen.set(true);
  }


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
