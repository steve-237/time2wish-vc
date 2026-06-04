import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Birthday, BirthdayStats, BirthdayCategory } from '../models/birthday.model';
import { AuthService } from './auth.service';
import { effect } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class BirthdayService {
  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly API_URL = 'http://localhost:8081/api/birthdays';

  // Signals
  readonly birthdays = signal<Birthday[]>([]);

  // Computed signals
  readonly activeBirthdays = computed(() => 
    this.birthdays()
      .filter(b => !b.isDeleted)
      .sort((a, b) => this.getDaysUntil(a.birthdate) - this.getDaysUntil(b.birthdate))
  );

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
    this.http.get<Birthday[]>(this.API_URL).subscribe({
      next: (list) => {
        // Map backend Date object or String format if necessary
        this.birthdays.set(list);
      },
      error: (err) => {
        console.error('Failed to load birthdays from API', err);
      }
    });
  }

  getBirthday(id: number): Birthday | undefined {
    return this.activeBirthdays().find(b => b.id === id);
  }

  addBirthday(name: string, birthdate: string, category: BirthdayCategory, notes?: string, reminderDays = 7, photoUrl?: string): void {
    const payload = {
      name,
      birthdate,
      category,
      notes,
      reminderDays,
      photoUrl: photoUrl || `https://api.dicebear.com/7.x/adventurer/svg?seed=${encodeURIComponent(name)}`
    };

    this.http.post<Birthday>(this.API_URL, payload).subscribe({
      next: (saved) => {
        this.birthdays.update(list => [...list, saved]);
      },
      error: (err) => {
        console.error('Failed to create birthday via API', err);
      }
    });
  }

  updateBirthday(id: number, name: string, birthdate: string, category: BirthdayCategory, notes?: string, reminderDays = 7, photoUrl?: string): void {
    const payload = {
      name,
      birthdate,
      category,
      notes,
      reminderDays,
      photoUrl
    };

    this.http.put<Birthday>(`${this.API_URL}/${id}`, payload).subscribe({
      next: (updated) => {
        this.birthdays.update(list => list.map(b => b.id === id ? updated : b));
      },
      error: (err) => {
        console.error('Failed to update birthday via API', err);
      }
    });
  }

  deleteBirthday(id: number): void {
    this.http.delete(`${this.API_URL}/${id}`).subscribe({
      next: () => {
        this.birthdays.update(list => list.filter(b => b.id !== id));
      },
      error: (err) => {
        console.error('Failed to delete birthday via API', err);
      }
    });
  }

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
