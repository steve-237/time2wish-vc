import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TranslationService } from '../../services/translation.service';
import { BirthdayService } from '../../services/birthday.service';
import { DashboardChartsComponent } from '../dashboard-charts/dashboard-charts.component';

@Component({
  selector: 'app-statistics-modal',
  standalone: true,
  imports: [CommonModule, DashboardChartsComponent],
  template: `
    <div class="tm-modal-overlay" (click)="onClose()">
      <div class="tm-modal-content" style="max-width: 900px; padding: 24px;" (click)="$event.stopPropagation()">
        <!-- Header -->
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
          <h1 style="margin: 0; display: flex; align-items: center; gap: 10px;">
            <span class="material-symbols-outlined" style="color: var(--primary-color);">bar_chart</span>
            {{ t9n.t('dashboard.btn_stats') || 'Statistiques Avancées' }}
          </h1>
          <button class="icon-btn" (click)="onClose()" style="background: none; border: none; cursor: pointer;">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>

        <!-- Charts -->
        <div style="max-height: 70vh; overflow-y: auto; overflow-x: hidden; padding-right: 10px;">
          <app-dashboard-charts [birthdays]="birthdayService.birthdays()"></app-dashboard-charts>
        </div>
      </div>
    </div>
  `
})
export class StatisticsModalComponent {
  public t9n = inject(TranslationService);
  public birthdayService = inject(BirthdayService);
  private router = inject(Router);

  onClose() {
    this.router.navigate(['/dashboard']);
  }
}
