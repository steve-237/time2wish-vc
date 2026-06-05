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

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BirthdayGridComponent, BirthdayListComponent, BirthdayCalendarComponent, WishModalComponent, DashboardChartsComponent],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css'
})
export class Dashboard implements OnInit, AfterViewInit, OnDestroy {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  private audioService = inject(AudioService);
  private notifService = inject(NotificationService);

  @ViewChild('confettiCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  private animationFrameId: number | null = null;

  // Filters
  searchQuery = signal<string>('');
  selectedCategory = signal<BirthdayCategory | 'All'>('All');
  selectedMonth = signal<number | -1>(-1); // -1 means All
  viewMode = signal<'grid' | 'list' | 'calendar'>('grid');
  timeFilter = signal<'upcoming' | 'past'>('upcoming');

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

      return matchesSearch && matchesCat && matchesMonth && matchesTime;
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
      this.exportToCSV();
    } else if (action === 'export-ical') {
      this.exportToICal();
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
      setTimeout(() => this.triggerConfetti(), 300);
    }
  }

  ngOnDestroy() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
    }
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

  private triggerConfetti() {
    const canvas = this.canvasRef.nativeElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const colors = ['#f43f5e', '#3b82f6', '#10b981', '#a855f7', '#f59e0b', '#ec4899'];
    const particles: any[] = [];

    for (let i = 0; i < 150; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height - canvas.height,
        r: Math.random() * 6 + 4,
        d: Math.random() * canvas.height,
        color: colors[Math.floor(Math.random() * colors.length)],
        tilt: Math.random() * 10 - 5,
        tiltAngleIncremental: Math.random() * 0.07 + 0.02,
        tiltAngle: 0,
        speed: Math.random() * 3 + 2
      });
    }

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      let alive = false;

      particles.forEach(p => {
        p.tiltAngle += p.tiltAngleIncremental;
        p.y += p.speed;
        p.tilt = Math.sin(p.tiltAngle) * 15;
        if (p.y <= canvas.height) alive = true;

        ctx.beginPath();
        ctx.lineWidth = p.r;
        ctx.strokeStyle = p.color;
        ctx.moveTo(p.x + p.tilt + p.r / 2, p.y);
        ctx.lineTo(p.x + p.tilt, p.y + p.tilt + p.r / 2);
        ctx.stroke();
      });

      if (alive) {
        this.animationFrameId = requestAnimationFrame(draw);
      } else {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    };

    draw();
    window.addEventListener('resize', () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    });
  }

  // --- CSV / iCal Import/Export ---
  exportToCSV() {
    const list = this.birthdayService.activeBirthdays();
    let csvContent = 'name,birthdate,category,notes,reminderDays,photoUrl\n';
    list.forEach(b => {
      const notes = b.notes ? `"${b.notes.replace(/"/g, '""')}"` : '';
      const row = `"${b.name.replace(/"/g, '""')}",${b.birthdate},${b.category},${notes},${b.reminderDays ?? 7},"${(b.photoUrl ?? '').replace(/"/g, '""')}"`;
      csvContent += row + '\n';
    });
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `time2wish_birthdays_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  exportToICal() {
    const list = this.birthdayService.activeBirthdays();
    let icsContent = 'BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Time2Wish//NONSGML Birthday Calendar//EN\nCALSCALE:GREGORIAN\n';
    
    list.forEach(b => {
      const cleanDate = b.birthdate.replace(/-/g, ''); // 19900515
      const bDate = new Date(b.birthdate);
      bDate.setDate(bDate.getDate() + 1);
      const cleanEndDate = bDate.toISOString().split('T')[0].replace(/-/g, '');
      
      icsContent += 'BEGIN:VEVENT\n';
      icsContent += `SUMMARY:🎂 Anniversaire de ${b.name}\n`;
      icsContent += `DTSTART;VALUE=DATE:${cleanDate}\n`;
      icsContent += `DTEND;VALUE=DATE:${cleanEndDate}\n`;
      icsContent += 'RRULE:FREQ=YEARLY\n';
      icsContent += `DESCRIPTION:${b.notes ? b.notes.replace(/\n/g, '\\n') : 'Time2Wish Birthday reminder'}\n`;
      icsContent += 'END:VEVENT\n';
    });
    
    icsContent += 'END:VCALENDAR';
    
    const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `time2wish_birthdays_${new Date().toISOString().split('T')[0]}.ics`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  onCSVImport(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    
    const file = input.files[0];
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result as string;
      this.parseAndImportCSV(text);
      input.value = ''; // Reset file input
    };
    reader.readAsText(file, 'UTF-8');
  }

  parseAndImportCSV(text: string) {
    try {
      const lines = text.split('\n');
      if (lines.length <= 1) {
        this.toastService.warning(this.t9n.t('toasts.import_error'));
        return;
      }
      
      const headers = lines[0].toLowerCase().trim().split(',');
      let importCount = 0;
      
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        
        // Simple CSV parsing (handling quotes)
        const cols = [];
        let insideQuotes = false;
        let current = '';
        for (let charIndex = 0; charIndex < line.length; charIndex++) {
          const char = line[charIndex];
          if (char === '"') {
            insideQuotes = !insideQuotes;
          } else if (char === ',' && !insideQuotes) {
            cols.push(current.trim());
            current = '';
          } else {
            current += char;
          }
        }
        cols.push(current.trim());
        
        // Extract values
        const nameIdx = headers.indexOf('name');
        const dateIdx = headers.indexOf('birthdate');
        const catIdx = headers.indexOf('category');
        const notesIdx = headers.indexOf('notes');
        const reminderIdx = headers.indexOf('reminderdays');
        const photoIdx = headers.indexOf('photourl');
        
        const name = nameIdx !== -1 ? cols[nameIdx] : '';
        const date = dateIdx !== -1 ? cols[dateIdx] : '';
        
        if (!name || !date) continue;
        
        // Validate date format (YYYY-MM-DD)
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(date)) continue;
        
        let category: any = 'Other';
        const catValue = catIdx !== -1 ? cols[catIdx] : 'Other';
        if (['Family', 'Friend', 'Work', 'Other'].includes(catValue)) {
          category = catValue;
        }
        
        const notes = notesIdx !== -1 ? cols[notesIdx] : '';
        const reminderDays = reminderIdx !== -1 ? parseInt(cols[reminderIdx], 10) || 7 : 7;
        const photoUrl = photoIdx !== -1 ? cols[photoIdx] : '';
        
        this.birthdayService.addBirthday(name, date, category, notes, reminderDays, photoUrl);
        importCount++;
      }
      
      if (importCount > 0) {
        this.toastService.success(this.t9n.t('toasts.import_success', importCount));
      } else {
        this.toastService.warning(this.t9n.t('toasts.import_error'));
      }
    } catch (err) {
      console.error(err);
      this.toastService.error(this.t9n.t('toasts.import_error'));
    }
  }
}
