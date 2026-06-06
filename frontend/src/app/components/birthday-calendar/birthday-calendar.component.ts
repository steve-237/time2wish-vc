import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy, inject, signal, computed, effect, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Birthday } from '../../models/birthday.model';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';

export interface CalendarDay {
  day: number;
  month: number;
  year: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  birthdays: Birthday[];
}

@Component({
  selector: 'app-birthday-calendar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './birthday-calendar.component.html',
  styleUrls: ['./birthday-calendar.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BirthdayCalendarComponent implements OnChanges {
  @Input({ required: true }) birthdays: Birthday[] = [];
  @Input() initialMonth: number = -1; // Parent selected month filter

  @Output() sendWish = new EventEmitter<{ birthday: Birthday, event: Event }>();
  @Output() delete = new EventEmitter<{ id: number, event: Event }>();

  public t9n = inject(TranslationService);
  public birthdayService = inject(BirthdayService);

  public currentMonth = signal<number>(new Date().getMonth());
  public currentYear = signal<number>(new Date().getFullYear());
  public days = signal<CalendarDay[]>([]);

  // Localized month name
  public currentMonthName = computed(() => {
    const months = this.t9n.getMonths();
    return months[this.currentMonth()] || '';
  });

  // Week days starting on Monday (t9n keys/names)
  public weekDays = computed(() => {
    // Return localized days of the week, short format
    const lang = this.t9n.currentLang();
    if (lang === 'en') {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else if (lang === 'de') {
      return ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    } else {
      return ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    }
  });

  constructor() {
    // Regenerate calendar when input changes or local signals change
    effect(() => {
      this.generateCalendar();
    }, { allowSignalWrites: true });
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['initialMonth']) {
      const val = changes['initialMonth'].currentValue;
      if (val !== undefined && val !== -1) {
        this.currentMonth.set(val);
      } else if (val === -1 && changes['initialMonth'].firstChange) {
        this.currentMonth.set(new Date().getMonth());
      }
    }
    // Force regeneration on direct inputs change
    this.generateCalendar();
  }

  prevMonth() {
    if (this.currentMonth() === 0) {
      this.currentMonth.set(11);
      this.currentYear.update(y => y - 1);
    } else {
      this.currentMonth.update(m => m - 1);
    }
  }

  nextMonth() {
    if (this.currentMonth() === 11) {
      this.currentMonth.set(0);
      this.currentYear.update(y => y + 1);
    } else {
      this.currentMonth.update(m => m + 1);
    }
  }

  generateCalendar() {
    const year = this.currentYear();
    const month = this.currentMonth();
    
    // First day of month (0 = Sun, 1 = Mon, ..., 6 = Sat)
    const firstDay = new Date(year, month, 1).getDay();
    // Shift index so Monday is 0 and Sunday is 6
    const startOffset = (firstDay + 6) % 7;
    
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();
    
    const calendarDays: CalendarDay[] = [];
    
    // Previous month padding days
    for (let i = startOffset - 1; i >= 0; i--) {
      const dayNum = daysInPrevMonth - i;
      const prevMonth = month === 0 ? 11 : month - 1;
      const prevYear = month === 0 ? year - 1 : year;
      calendarDays.push({
        day: dayNum,
        month: prevMonth,
        year: prevYear,
        isCurrentMonth: false,
        isToday: this.isToday(dayNum, prevMonth, prevYear),
        birthdays: this.getBirthdaysForDay(dayNum, prevMonth)
      });
    }
    
    // Current month days
    for (let i = 1; i <= daysInMonth; i++) {
      calendarDays.push({
        day: i,
        month: month,
        year: year,
        isCurrentMonth: true,
        isToday: this.isToday(i, month, year),
        birthdays: this.getBirthdaysForDay(i, month)
      });
    }
    
    // Next month padding days (fill the 42 cells grid)
    const remainingCells = 42 - calendarDays.length;
    for (let i = 1; i <= remainingCells; i++) {
      const nextMonth = month === 11 ? 0 : month + 1;
      const nextYear = month === 11 ? year + 1 : year;
      calendarDays.push({
        day: i,
        month: nextMonth,
        year: nextYear,
        isCurrentMonth: false,
        isToday: this.isToday(i, nextMonth, nextYear),
        birthdays: this.getBirthdaysForDay(i, nextMonth)
      });
    }
    
    this.days.set(calendarDays);
  }

  getBirthdaysForDay(day: number, month: number): Birthday[] {
    return this.birthdays.filter(b => {
      const bDate = new Date(b.birthdate);
      return bDate.getDate() === day && bDate.getMonth() === month;
    });
  }

  isToday(day: number, month: number, year: number): boolean {
    const today = new Date();
    return today.getDate() === day && today.getMonth() === month && today.getFullYear() === year;
  }

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

  getCategoryColor(cat: string): string {
    switch (cat) {
      case 'Family': return 'var(--cat-family)';
      case 'Friend': return 'var(--cat-friend)';
      case 'Work': return 'var(--cat-work)';
      case 'Other': return 'var(--cat-other)';
      default: return 'var(--text-muted)';
    }
  }

  onSendWish(birthday: Birthday, event: Event) {
    this.sendWish.emit({ birthday, event });
  }

  onDelete(id: number, event: Event) {
    this.delete.emit({ id, event });
  }

  trackByDay(index: number, cell: CalendarDay): string {
    return `${cell.year}-${cell.month}-${cell.day}`;
  }
}
