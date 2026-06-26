import { Component, signal, computed, inject, OnInit, AfterViewInit, ElementRef, ViewChild, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { Birthday, BirthdayCategory } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';
import { BirthdayGridComponent } from '../../components/birthday-grid/birthday-grid.component';
import { BirthdayListComponent } from '../../components/birthday-list/birthday-list.component';
import { BirthdayCalendarComponent } from '../../components/birthday-calendar/birthday-calendar.component';
import { WishModalComponent } from '../../components/wish-modal/wish-modal.component';
import { AudioService } from '../../services/audio.service';
import { NotificationService } from '../../services/notification.service';
import { ToastService } from '../../services/toast.service';
import { DashboardChartsComponent } from '../../components/dashboard-charts/dashboard-charts.component';
import { ExportService } from '../../services/export.service';
import { ConfettiService } from '../../services/confetti.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BirthdayGridComponent, BirthdayListComponent, BirthdayCalendarComponent, WishModalComponent, DashboardChartsComponent],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss'
})
export class Dashboard implements OnInit, AfterViewInit, OnDestroy {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  private audioService = inject(AudioService);
  private notifService = inject(NotificationService);
  exportService = inject(ExportService);
  private confettiService = inject(ConfettiService);
  authService = inject(AuthService);

  isOptionsMenuOpen = signal<boolean>(false);
  isAdvancedFiltersOpen = signal<boolean>(false);

  @ViewChild('confettiCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  private cleanupConfetti?: () => void;

  get userPlan() {
    return this.authService.currentUser()?.plan || 'BASIC';
  }

  // Filters
  searchQuery = signal<string>('');
  selectedCategory = signal<BirthdayCategory | 'All'>('All');
  selectedMonth = signal<number | -1>(-1); // -1 means All
  viewMode = signal<'grid' | 'list' | 'calendar'>('grid');
  timeFilter = signal<'upcoming' | 'past'>('upcoming');
  filterFavorite = signal<boolean>(false);

  // Reminder trigger state
  reminderStatus = signal<'idle' | 'loading' | 'success' | 'error'>('idle');
  reminderMessage = signal<string>('');

  // Wish Modal state
  isWishModalOpen = signal<boolean>(false);
  selectedBirthdayForWish = signal<Birthday | null>(null);

  // Categories list
  readonly categories: (BirthdayCategory | 'All')[] = ['All', 'Family', 'Friend', 'Work', 'Other'];

  // Month names – reactive to language changes
  readonly months = computed(() => this.t9n.getMonths());

  // Computed filtered list
  readonly filteredBirthdays = computed(() => {
    const query = this.searchQuery().toLowerCase().trim();
    const cat = this.selectedCategory();
    const month = this.selectedMonth();
    const tf = this.timeFilter();

    return this.birthdayService.activeBirthdays().filter(b => {
      const matchesSearch = !query || b.name.toLowerCase().includes(query);
      const matchesCat = cat === 'All' || b.category === cat;
      const bMonth = new Date(b.birthdate).getMonth();
      const matchesMonth = month === -1 || bMonth === month;
      
      const isPast = this.isBirthdayPast(b.birthdate);
      const matchesTime = tf === 'upcoming' ? !isPast : isPast;
      const matchesFavorite = !this.filterFavorite() || b.isFavorite;

      return matchesSearch && matchesCat && matchesMonth && matchesTime && matchesFavorite;
    });
  });

  /** Check if a birthday's occurrence this year has already passed */
  isBirthdayPast(birthdateStr: string): boolean {
    const birthdate = new Date(birthdateStr);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const thisYearOccurrence = new Date(today.getFullYear(), birthdate.getMonth(), birthdate.getDate());
    return thisYearOccurrence.getTime() < today.getTime();
  }

  /** Calculate current age from birthdate */
  getAge(birthdateStr: string): number {
    const birthdate = new Date(birthdateStr);
    const today = new Date();
    let age = today.getFullYear() - birthdate.getFullYear();
    const monthDiff = today.getMonth() - birthdate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthdate.getDate())) {
      age--;
    }
    return age;
  }

  onActionSelect(event: Event) {
    const select = event.target as HTMLSelectElement;
    const action = select.value;
    select.value = ""; // Reset
    
    if (action === 'export-csv') {
      this.exportService.exportToCSV(this.birthdayService.activeBirthdays());
    } else if (action === 'export-ical') {
      this.exportService.exportListToICal(this.birthdayService.activeBirthdays());
    } else if (action === 'import-csv') {
      const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement;
      if (fileInput) {
        fileInput.click();
      }
    }
  }

  ngOnInit() {
    this.birthdayService.loadFromStorage();
  }

  ngAfterViewInit() {
    const stats = this.birthdayService.statistics();
    if (stats.todayCount > 0) {
      setTimeout(() => {
        this.cleanupConfetti = this.confettiService.triggerConfetti(this.canvasRef.nativeElement);
      }, 300);
    }
  }

  ngOnDestroy() {
    if (this.cleanupConfetti) {
      this.cleanupConfetti();
    }
    this.confettiService.stopConfetti();
  }

  /** Translates internal countdown tokens to the current language */
  getLabel(rawLabel: string): string {
    if (rawLabel === '__today__') return this.t9n.t('countdown.today');
    if (rawLabel === '__tomorrow__') return this.t9n.t('countdown.tomorrow');
    if (rawLabel.startsWith('__days__:')) {
      const days = rawLabel.split(':')[1];
      return this.t9n.t('countdown.days', days);
    }
    return rawLabel;
  }

  // --- Event Handlers from Dumb Components ---
  onSendWish(payload: { birthday: Birthday, event: Event }) {
    this.sendWish(payload.birthday, payload.event);
  }

  onDeleteRequested(payload: { id: number, event: Event }) {
    this.deleteBirthday(payload.id, payload.event);
  }

  // Action methods
  sendWish(b: Birthday, event?: Event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    this.selectedBirthdayForWish.set(b);
    this.isWishModalOpen.set(true);
  }

  isConfirmModalOpen = signal(false);
  birthdayIdToDelete = signal<number | null>(null);

  deleteBirthday(id: number, event?: Event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    this.birthdayIdToDelete.set(id);
    this.isConfirmModalOpen.set(true);
  }

  confirmDelete() {
    const id = this.birthdayIdToDelete();
    if (id !== null) {
      const birthdayToDel = this.filteredBirthdays().find(b => b.id === id);
      const name = birthdayToDel ? birthdayToDel.name : 'Inconnu';
      
      this.birthdayService.deleteBirthday(id);
      this.audioService.playDeleteSound();
      this.notifService.logAction('DELETE', `L'anniversaire de ${name} a été supprimé.`);
    }
    this.isConfirmModalOpen.set(false);
    this.birthdayIdToDelete.set(null);
  }

  cancelDelete() {
    this.isConfirmModalOpen.set(false);
    this.birthdayIdToDelete.set(null);
  }

  onTriggerReminders() {
    this.reminderStatus.set('loading');
    this.reminderMessage.set('');
    this.birthdayService.triggerReminders().subscribe({
      next: (res) => {
        this.reminderStatus.set('success');
        this.reminderMessage.set(res.message);
        setTimeout(() => this.reminderStatus.set('idle'), 6000);
      },
      error: (err) => {
        this.reminderStatus.set('error');
        this.reminderMessage.set(err?.error?.message || 'Erreur lors du déclenchement des rappels.');
        setTimeout(() => this.reminderStatus.set('idle'), 6000);
      }
    });
  }

  onCSVImport(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    
    const file = input.files[0];
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result as string;
      this.exportService.parseAndImportCSV(text);
      input.value = ''; // Reset file input
    };
    reader.readAsText(file, 'UTF-8');
    }
}
