import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminService, StatsResponse } from '../../../services/admin.service';
import { TranslationService } from '../../../services/translation.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="dashboard-container">
      <h2 class="page-title">{{ t9n.t('admin.dashboard.subtitle') }}</h2>
      <div class="stats-grid">
        <div class="stat-card users-card">
          <div class="stat-icon">👥</div>
          <div class="stat-info">
            <span class="stat-value">{{ stats()?.totalUsers || 0 }}</span>
            <span class="stat-label">{{ t9n.t('admin.dashboard.users') }}</span>
          </div>
        </div>
        <div class="stat-card birthdays-card">
          <div class="stat-icon">🎂</div>
          <div class="stat-info">
            <span class="stat-value">{{ stats()?.totalBirthdays || 0 }}</span>
            <span class="stat-label">{{ t9n.t('admin.dashboard.birthdays') }}</span>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-container {
      padding: 1rem;
    }
    .page-title {
      font-family: var(--font-title);
      font-size: 1.8rem;
      font-weight: 700;
      display: inline-block;
      background: linear-gradient(135deg, hsl(var(--primary-hsl)) 0%, hsl(var(--accent-hsl)) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 2rem;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
    }
    .stat-card {
      background: white;
      border-radius: 12px;
      padding: 1.5rem;
      display: flex;
      align-items: center;
      gap: 1.5rem;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
    }
    .users-card .stat-icon {
      background-color: #dbeafe;
      color: #3b82f6;
    }
    .birthdays-card .stat-icon {
      background-color: #fce7f3;
      color: #ec4899;
    }
    .stat-icon {
      width: 64px;
      height: 64px;
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 2rem;
    }
    .stat-info {
      display: flex;
      flex-direction: column;
    }
    .stat-value {
      font-size: 2rem;
      font-weight: 700;
      color: #111827;
      line-height: 1;
      margin-bottom: 0.25rem;
    }
    .stat-label {
      font-size: 0.875rem;
      color: #6b7280;
      font-weight: 500;
    }
  `]
})
export class AdminDashboardComponent implements OnInit {
  private adminService = inject(AdminService);
  t9n = inject(TranslationService);
  stats = signal<StatsResponse | null>(null);

  ngOnInit() {
    this.adminService.getStats().subscribe({
      next: (data) => this.stats.set(data),
      error: (err) => console.error('Error fetching stats', err)
    });
  }
}
