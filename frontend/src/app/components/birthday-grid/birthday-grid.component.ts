import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Birthday } from '../../models/birthday.model';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-birthday-grid',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './birthday-grid.component.html',
  styleUrls: ['./birthday-grid.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BirthdayGridComponent {
  @Input({ required: true }) birthdays: Birthday[] = [];
  
  @Output() sendWish = new EventEmitter<{ birthday: Birthday, event: Event }>();
  @Output() delete = new EventEmitter<{ id: number, event: Event }>();

  // Use services directly for pure UI helpers (getUrgencyClass, translations)
  public birthdayService = inject(BirthdayService);
  public t9n = inject(TranslationService);

  getLabel(rawLabel: string): string {
    if (rawLabel === '__today__') return this.t9n.t('countdown.today');
    if (rawLabel === '__tomorrow__') return this.t9n.t('countdown.tomorrow');
    if (rawLabel.startsWith('__days__:')) {
      const days = rawLabel.split(':')[1];
      return this.t9n.t('countdown.days', days);
    }
    return rawLabel;
  }

  onSendWish(birthday: Birthday, event: Event) {
    this.sendWish.emit({ birthday, event });
  }

  onDelete(id: number, event: Event) {
    this.delete.emit({ id, event });
  }

  trackById(index: number, b: Birthday): number {
    return b.id;
  }
}
