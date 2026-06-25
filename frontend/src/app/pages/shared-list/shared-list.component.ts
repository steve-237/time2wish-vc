import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { SharedBirthday, Gift } from '../../models/birthday.model';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-shared-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './shared-list.component.html',
  styleUrl: './shared-list.component.scss'
})
export class SharedListComponent implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  route = inject(ActivatedRoute);
  router = inject(Router);

  birthday = signal<SharedBirthday | null>(null);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);

  isReserveModalOpen = signal<boolean>(false);
  selectedGift = signal<Gift | null>(null);
  guestName = signal<string>('');
  token = signal<string>('');

  ngOnInit() {
    const tokenParam = this.route.snapshot.paramMap.get('token');
    if (tokenParam) {
      this.token.set(tokenParam);
      this.loadSharedList(tokenParam);
    } else {
      this.error.set("Lien de partage invalide.");
      this.isLoading.set(false);
    }
  }

  loadSharedList(token: string) {
    this.birthdayService.getSharedList(token).subscribe({
      next: (b) => {
        this.birthday.set(b);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load shared list', err);
        this.error.set("Ce lien de partage est invalide ou a expiré.");
        this.isLoading.set(false);
      }
    });
  }

  openReserveModal(gift: Gift) {
    if (gift.isReserved) return;
    this.selectedGift.set(gift);
    this.guestName.set('');
    this.isReserveModalOpen.set(true);
  }

  closeReserveModal() {
    this.isReserveModalOpen.set(false);
    this.selectedGift.set(null);
  }

  confirmReservation() {
    const gift = this.selectedGift();
    const name = this.guestName().trim();
    if (!gift || !name) return;

    this.birthdayService.reserveGift(this.token(), gift.id, name).subscribe({
      next: (updatedGift) => {
        this.birthday.update(b => {
          if (!b) return b;
          return {
            ...b,
            gifts: b.gifts.map(g => g.id === gift.id ? updatedGift : g)
          };
        });
        this.toastService.success(`Merci ${name} ! Le cadeau est réservé.`);
        this.closeReserveModal();
      },
      error: (err) => {
        console.error('Failed to reserve gift', err);
        this.toastService.error("Erreur lors de la réservation du cadeau.");
      }
    });
  }
}
