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
      <div class="tm-modal-content stats-modal-content" (click)="$event.stopPropagation()">
        <!-- Header -->
        <div class="stats-modal-header">
          <h1 class="stats-modal-title">
            <span class="material-symbols-outlined stats-icon">bar_chart</span>
            {{ t9n.t('dashboard.btn_stats') || 'Statistiques Avancées' }}
          </h1>
          <button class="icon-btn close-btn" (click)="onClose()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>

        <!-- Charts -->
        <div class="stats-charts-container">
          <app-dashboard-charts [birthdays]="birthdayService.birthdays()"></app-dashboard-charts>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .stats-modal-content {
      max-width: 900px;
      padding: 24px;
    }
    .stats-modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }
    .stats-modal-title {
      margin: 0;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .stats-icon {
      color: hsl(var(--primary-hsl));
    }
    .close-btn {
      background: none;
      border: none;
      cursor: pointer;
    }
    .stats-charts-container {
      max-height: 70vh;
      overflow-y: auto;
      overflow-x: hidden;
      padding-right: 10px;
    }
  `]
})
export class StatisticsModalComponent {
  public t9n = inject(TranslationService);
  public birthdayService = inject(BirthdayService);
  private router = inject(Router);

  onClose() {
    this.router.navigate(['/dashboard']);
  }
}
