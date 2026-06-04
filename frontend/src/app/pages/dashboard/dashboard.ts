import { Component, signal, computed, inject, OnInit, AfterViewInit, ElementRef, ViewChild, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { Birthday, BirthdayCategory } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';
import { BirthdayGridComponent } from '../../components/birthday-grid/birthday-grid.component';
import { BirthdayListComponent } from '../../components/birthday-list/birthday-list.component';
import { AudioService } from '../../services/audio.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BirthdayGridComponent, BirthdayListComponent],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css'
})
export class Dashboard implements OnInit, AfterViewInit, OnDestroy {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  private audioService = inject(AudioService);
  private notifService = inject(NotificationService);

  @ViewChild('confettiCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  private animationFrameId: number | null = null;

  // Filters
  searchQuery = signal<string>('');
  selectedCategory = signal<BirthdayCategory | 'All'>('All');
  selectedMonth = signal<number | -1>(-1); // -1 means All
  viewMode = signal<'grid' | 'list'>('grid');

  // Reminder trigger state
  reminderStatus = signal<'idle' | 'loading' | 'success' | 'error'>('idle');
  reminderMessage = signal<string>('');

  // Categories list
  readonly categories: (BirthdayCategory | 'All')[] = ['All', 'Family', 'Friend', 'Work', 'Other'];

  // Month names – reactive to language changes
  readonly months = computed(() => this.t9n.getMonths());

  // Computed filtered list
  readonly filteredBirthdays = computed(() => {
    const query = this.searchQuery().toLowerCase().trim();
    const cat = this.selectedCategory();
    const month = this.selectedMonth();

    return this.birthdayService.activeBirthdays().filter(b => {
      const matchesSearch = !query || b.name.toLowerCase().includes(query);
      const matchesCat = cat === 'All' || b.category === cat;
      const bMonth = new Date(b.birthdate).getMonth();
      const matchesMonth = month === -1 || bMonth === month;
      return matchesSearch && matchesCat && matchesMonth;
    });
  });

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
    const subject = encodeURIComponent(`Joyeux Anniversaire ${b.name} !`);
    const body = encodeURIComponent(`Je te souhaite un très joyeux anniversaire ${b.name} ! Profite bien de ta journée ! 🎉🎂`);
    window.open(`mailto:?subject=${subject}&body=${body}`, '_blank');
  }

  deleteBirthday(id: number, event?: Event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (confirm(this.t9n.t('dashboard.confirm_delete'))) {
      const birthdayToDel = this.filteredBirthdays().find(b => b.id === id);
      const name = birthdayToDel ? birthdayToDel.name : 'Inconnu';
      
      this.birthdayService.deleteBirthday(id);
      this.audioService.playDeleteSound();
      this.notifService.logAction('DELETE', `L'anniversaire de ${name} a été supprimé.`);
    }
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
}
