import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Birthday, BirthdayStats, BirthdayCategory, GiftSuggestion, Gift, SharedBirthday } from '../models/birthday.model';
import { AuthService } from './auth.service';
import { effect } from '@angular/core';
import { ToastService } from './toast.service';
import { TranslationService } from './translation.service';
import { environment } from '../../environments/environment';
@Injectable({
  providedIn: 'root'
})
export class BirthdayService {
  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly toastService = inject(ToastService);
  private readonly t9n = inject(TranslationService);
  private readonly API_URL = environment.apiUrl + '/birthdays';

  // Signals
  readonly birthdays = signal<Birthday[]>([]);
  readonly isLoading = signal<boolean>(false);
  readonly lastAddedBirthdayId = signal<number | null>(null);

  // Computed signals
  readonly activeBirthdays = computed(() => {
    const lastAddedId = this.lastAddedBirthdayId();
    return this.birthdays()
      .filter(b => !b.isDeleted)
      .sort((a, b) => {
        if (a.id === lastAddedId) return -1;
        if (b.id === lastAddedId) return 1;
        return this.getDaysUntil(a.birthdate) - this.getDaysUntil(b.birthdate);
      });
  });

  readonly statistics = computed<BirthdayStats>(() => {
    const list = this.activeBirthdays();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let todayCount = 0;
    let thisMonthCount = 0;
    let next30DaysCount = 0;
    const distribution: { [key in BirthdayCategory]?: number } = {};

    list.forEach(b => {
      const daysUntil = this.getDaysUntil(b.birthdate);
      const bDate = new Date(b.birthdate);
      const currentMonth = today.getMonth();

      // Today
      if (daysUntil === 0) todayCount++;
      // This Month
      if (bDate.getMonth() === currentMonth) thisMonthCount++;
      // Next 30 Days
      if (daysUntil >= 0 && daysUntil <= 30) next30DaysCount++;

      // Category distribution
      distribution[b.category] = (distribution[b.category] || 0) + 1;
    });

    return {
      total: list.length,
      todayCount,
      thisMonthCount,
      next30DaysCount,
      categoryDistribution: distribution
    };
  });

  constructor() {
    // Automatically load birthdays whenever the user logs in
    effect(() => {
      if (this.authService.isAuthenticated()) {
        this.loadFromStorage();
      } else {
        this.birthdays.set([]);
      }
    });
  }

  loadFromStorage(): void {
    this.isLoading.set(true);
    this.http.get<Birthday[]>(this.API_URL).subscribe({
      next: (list) => {
        // Map backend Date object or String format if necessary
        this.birthdays.set(list);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load birthdays from API', err);
        this.isLoading.set(false);
      }
    });
  }

  getBirthday(id: number): Birthday | undefined {
    return this.activeBirthdays().find(b => b.id === id);
  }

  addBirthday(name: string, birthdate: string, category: BirthdayCategory, notes?: string, reminderDays = 7, photoUrl?: string, showAge = true, email?: string, whatsapp?: string, gender?: 'Masculin' | 'Féminin' | 'Autre', interests: string[] = [], isFavorite = false): void {
    const randomHex = Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
    const defaultPhoto = `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=${randomHex}&color=fff&rounded=true&bold=true`;

    const payload = {
      name,
      birthdate,
      category,
      notes,
      reminderDays,
      photoUrl: photoUrl || defaultPhoto,
      showAge,
      email,
      whatsapp,
      gender,
      interests,
      isFavorite
    };

    this.http.post<Birthday>(this.API_URL, payload).subscribe({
      next: (saved) => {
        this.birthdays.update(list => [...list, saved]);
        this.toastService.success(this.t9n.t('toasts.add_success', saved.name));
        this.lastAddedBirthdayId.set(saved.id);
        setTimeout(() => {
          if (this.lastAddedBirthdayId() === saved.id) {
            this.lastAddedBirthdayId.set(null);
          }
        }, 15000);
      },
      error: (err) => {
        console.error('Failed to create birthday via API', err);
        this.toastService.error(this.t9n.t('toasts.import_error'));
      }
    });
  }

  updateBirthday(id: number, name: string, birthdate: string, category: BirthdayCategory, notes?: string, reminderDays = 7, photoUrl?: string, showAge = true, email?: string, whatsapp?: string, gender?: 'Masculin' | 'Féminin' | 'Autre', interests: string[] = [], isFavorite = false): void {
    const payload = {
      name,
      birthdate,
      category,
      notes,
      reminderDays,
      photoUrl,
      showAge,
      email,
      whatsapp,
      gender,
      interests,
      isFavorite
    };

    this.http.put<Birthday>(`${this.API_URL}/${id}`, payload).subscribe({
      next: (updated) => {
        this.birthdays.update(list => list.map(b => b.id === id ? updated : b));
        this.toastService.success(this.t9n.t('toasts.update_success', updated.name));
      },
      error: (err) => {
        console.error('Failed to update birthday via API', err);
        this.toastService.error(this.t9n.t('toasts.import_error'));
      }
    });
  }

  deleteBirthday(id: number): void {
    const birthdayToDelete = this.getBirthday(id);
    const name = birthdayToDelete ? birthdayToDelete.name : 'Inconnu';
    
    this.http.delete(`${this.API_URL}/${id}`).subscribe({
      next: () => {
        this.birthdays.update(list => list.filter(b => b.id !== id));
        this.toastService.success(this.t9n.t('toasts.delete_success', name));
      },
      error: (err) => {
        console.error('Failed to delete birthday via API', err);
        this.toastService.error(this.t9n.t('toasts.import_error'));
      }
    });
  }

  addInterest(birthdayId: number, interest: string): void {
    const birthday = this.getBirthday(birthdayId);
    if (!birthday) return;
    
    const updatedInterests = [...(birthday.interests || []), interest];
    
    this.updateBirthday(
      birthdayId,
      birthday.name,
      birthday.birthdate,
      birthday.category,
      birthday.notes,
      birthday.reminderDays,
      birthday.photoUrl,
      birthday.showAge,
      birthday.email,
      birthday.whatsapp,
      birthday.gender,
      updatedInterests,
      birthday.isFavorite
    );
  }

  removeInterest(birthdayId: number, interest: string): void {
    const birthday = this.getBirthday(birthdayId);
    if (!birthday) return;
    
    const updatedInterests = (birthday.interests || []).filter(i => i !== interest);
    
    this.updateBirthday(
      birthdayId,
      birthday.name,
      birthday.birthdate,
      birthday.category,
      birthday.notes,
      birthday.reminderDays,
      birthday.photoUrl,
      birthday.showAge,
      birthday.email,
      birthday.whatsapp,
      birthday.gender,
      updatedInterests,
      birthday.isFavorite
    );
  }

  toggleFavorite(id: number, isFavorite: boolean): void {
    const birthday = this.getBirthday(id);
    if (!birthday) return;
    
    // Optimistic UI update
    this.birthdays.update(list => list.map(b => b.id === id ? { ...b, isFavorite } : b));
    
    this.updateBirthday(
      id,
      birthday.name,
      birthday.birthdate,
      birthday.category,
      birthday.notes,
      birthday.reminderDays,
      birthday.photoUrl,
      birthday.showAge,
      birthday.email,
      birthday.whatsapp,
      birthday.gender,
      birthday.interests || [],
      isFavorite
    );
  }

  generateGiftSuggestions(id: number, lang: string) {
    return this.http.get<GiftSuggestion[]>(`${this.API_URL}/${id}/generate-gifts?lang=${lang}`);
  }

  // --- Gift Sharing Phase 7 ---
  getSavedGifts(birthdayId: number) {
    return this.http.get<Gift[]>(`${this.API_URL}/${birthdayId}/gifts`);
  }

  saveGift(birthdayId: number, gift: Partial<Gift>) {
    return this.http.post<Gift>(`${this.API_URL}/${birthdayId}/gifts`, gift);
  }

  deleteGift(birthdayId: number, giftId: number) {
    return this.http.delete(`${this.API_URL}/${birthdayId}/gifts/${giftId}`);
  }

  generateShareToken(birthdayId: number) {
    return this.http.post<{token: string}>(`${this.API_URL}/${birthdayId}/gifts/share`, {});
  }

  getSharedList(token: string) {
    return this.http.get<SharedBirthday>(`${environment.apiUrl}/public/shared/${token}`);
  }

  reserveGift(token: string, giftId: number, guestName: string) {
    return this.http.post<Gift>(`${environment.apiUrl}/public/shared/${token}/gifts/${giftId}/reserve`, { guestName });
  }
  // -----------------------------

  /** Triggers the backend reminder scheduler manually. Returns observable with result. */
  triggerReminders() {
    return this.http.post<{ message: string; remindersProcessed: number }>(
      `${this.API_URL}/test-reminders`,
      {}
    );
  }

  // Helper method to compute days until next occurrence
  getDaysUntil(birthdateStr: string): number {
    const birthdate = new Date(birthdateStr);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const currentYear = today.getFullYear();
    const nextOccurrence = new Date(currentYear, birthdate.getMonth(), birthdate.getDate());

    if (nextOccurrence.getTime() < today.getTime()) {
      nextOccurrence.setFullYear(currentYear + 1);
    }

    const diffTime = nextOccurrence.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    // If it's today
    if (nextOccurrence.getTime() === today.getTime()) {
      return 0;
    }

    return diffDays;
  }

  // Get countdown label (language-neutral — caller provides translated strings)
  getCountdownLabel(days: number): string {
    if (days === 0) return '__today__';
    if (days === 1) return '__tomorrow__';
    return `__days__:${days}`;
  }

  // Get class based on days remaining
  getUrgencyClass(days: number): string {
    if (days === 0) return 'today';
    if (days <= 3) return 'soon';
    if (days <= 7) return 'upcoming';
    return 'normal';
  }
}
