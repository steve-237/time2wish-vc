import { Component, inject, OnInit, signal, effect, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminService, StatsResponse } from '../../../services/admin.service';
import { TranslationService } from '../../../services/translation.service';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartType } from 'chart.js';

import { StatsService } from '../../../services/stats.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, BaseChartDirective],
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
        <div class="stat-card revenue-card">
          <div class="stat-icon">💰</div>
          <div class="stat-info">
            <span class="stat-value">{{ stats()?.totalRevenue || 0 | currency:'EUR' }}</span>
            <span class="stat-label">Revenus (Total)</span>
          </div>
        </div>
      </div>

      <div class="charts-grid" *ngIf="stats()">
        <div class="chart-card">
          <h3 class="chart-title">Inscriptions (6 derniers mois)</h3>
          <div class="chart-wrapper">
            <canvas baseChart 
              [data]="barChartData" 
              [options]="barChartOptions" 
              [type]="barChartType">
            </canvas>
          </div>
        </div>
        <div class="chart-card">
          <h3 class="chart-title">Évolution des Revenus (MRR)</h3>
          <div class="chart-wrapper">
            <canvas baseChart 
              [data]="revenueChartData" 
              [options]="revenueChartOptions" 
              [type]="revenueChartType">
            </canvas>
          </div>
        </div>
        <div class="chart-card">
          <h3 class="chart-title">Répartition des Forfaits</h3>
          <div class="chart-wrapper pie-wrapper">
            <canvas baseChart 
              [data]="pieChartData" 
              [options]="pieChartOptions" 
              [type]="pieChartType">
            </canvas>
          </div>
        </div>
        <div class="chart-card">
          <h3 class="chart-title">Utilisation de l'IA (30 jours)</h3>
          <div class="chart-wrapper">
            <canvas baseChart 
              [data]="aiChartData" 
              [options]="aiChartOptions" 
              [type]="aiChartType">
            </canvas>
          </div>
        </div>
      </div>

      <div class="recent-users-section" *ngIf="stats()?.recentUsers?.length">
        <h3 class="section-title">Inscriptions Récentes</h3>
        <div class="recent-list">
          @for (user of stats()?.recentUsers; track user.id) {
            <div class="recent-item">
              <img [src]="user.avatarUrl || getInitialsAvatar(user.fullName)" class="recent-avatar" alt="avatar" />
              <div class="recent-info">
                <div class="recent-name">{{ user.fullName }}</div>
                <div class="recent-email">{{ user.email }}</div>
              </div>
              <div class="recent-date">
                {{ user.createdAt | date:'short' }}
              </div>
            </div>
          }
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
      margin-bottom: 2rem;
    }
    .stat-card {
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: 12px;
      padding: 1.5rem;
      display: flex;
      align-items: center;
      gap: 1.5rem;
      box-shadow: var(--glass-shadow);
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    }
    .users-card .stat-icon {
      background-color: rgba(59, 130, 246, 0.1);
      color: #3b82f6;
    }
    .birthdays-card .stat-icon {
      background-color: rgba(236, 72, 153, 0.1);
      color: #ec4899;
    }
    .revenue-card .stat-icon {
      background-color: rgba(16, 185, 129, 0.1);
      color: #10b981;
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
      color: var(--text-main);
      line-height: 1;
      margin-bottom: 0.25rem;
    }
    .stat-label {
      font-size: 0.875rem;
      color: var(--text-muted);
      font-weight: 500;
    }

    .charts-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }
    @media (max-width: 768px) {
      .charts-grid { grid-template-columns: 1fr; }
    }
    .chart-card {
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: 12px;
      padding: 1.5rem;
      box-shadow: var(--glass-shadow);
    }
    .chart-title {
      font-size: 1.1rem;
      font-weight: 600;
      color: var(--text-main);
      margin-top: 0;
      margin-bottom: 1.5rem;
    }
    .chart-wrapper {
      position: relative;
      height: 300px;
      width: 100%;
    }
    .pie-wrapper {
      height: 250px;
      display: flex;
      justify-content: center;
    }

    .recent-users-section {
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: 12px;
      padding: 1.5rem;
      box-shadow: var(--glass-shadow);
    }
    .section-title {
      font-size: 1.1rem;
      font-weight: 600;
      color: var(--text-main);
      margin-top: 0;
      margin-bottom: 1.5rem;
    }
    .recent-list {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }
    .recent-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 1rem;
      border-radius: 8px;
      background: rgba(var(--primary-hsl), 0.05);
      border: 1px solid var(--border-card);
    }
    .recent-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      object-fit: cover;
    }
    .recent-info {
      flex: 1;
    }
    .recent-name {
      font-weight: 600;
      color: var(--text-main);
      font-size: 0.95rem;
    }
    .recent-email {
      color: var(--text-muted);
      font-size: 0.85rem;
    }
    .recent-date {
      color: var(--text-muted);
      font-size: 0.8rem;
    }
  `]
})
export class AdminDashboardComponent implements OnInit {
  private adminService = inject(AdminService);
  t9n = inject(TranslationService);
  stats = signal<StatsResponse | null>(null);

  // Charts configuration
  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: { beginAtZero: true, ticks: { precision: 0 } }
    }
  };
  public barChartType: ChartType = 'bar';
  public barChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [ { data: [], label: 'Inscriptions', backgroundColor: 'rgba(59, 130, 246, 0.7)', borderRadius: 6 } ]
  };

  public pieChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'right' }
    }
  };
  public pieChartType: ChartType = 'pie';
  public pieChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [ { data: [], backgroundColor: ['#3b82f6', '#ec4899', '#f59e0b', '#10b981'] } ]
  };

  // Revenue Chart configuration
  public revenueChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: { beginAtZero: true }
    }
  };
  public revenueChartType: ChartType = 'line';
  public revenueChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [ { 
      data: [], 
      label: 'Revenus (€)', 
      borderColor: '#10b981', 
      backgroundColor: 'rgba(16, 185, 129, 0.2)',
      fill: true,
      tension: 0.4
    } ]
  };

  // AI Chart configuration
  public aiChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: { beginAtZero: true, ticks: { precision: 0 } }
    }
  };
  public aiChartType: ChartType = 'bar';
  public aiChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [ { data: [], label: 'Générations IA', backgroundColor: '#a855f7', borderRadius: 6 } ]
  };

  constructor() {
    effect(() => {
      const data = this.stats();
      if (data) {
        // Update Bar Chart
        if (data.monthlyRegistrations) {
          this.barChartData.labels = Object.keys(data.monthlyRegistrations);
          this.barChartData.datasets[0].data = Object.values(data.monthlyRegistrations);
          // Trigger change detection for chart
          this.barChartData = { ...this.barChartData };
        }
        
        // Update Pie Chart
        if (data.planDistribution) {
          this.pieChartData.labels = Object.keys(data.planDistribution);
          this.pieChartData.datasets[0].data = Object.values(data.planDistribution);
          this.pieChartData = { ...this.pieChartData };
        }
        
        // Update Revenue Chart
        if (data.monthlyRevenue) {
          this.revenueChartData.labels = Object.keys(data.monthlyRevenue);
          this.revenueChartData.datasets[0].data = Object.values(data.monthlyRevenue);
          this.revenueChartData = { ...this.revenueChartData };
        }
      }
    });
  }

  private statsService = inject(StatsService);

  ngOnInit() {
    this.adminService.getStats().subscribe({
      next: (data) => this.stats.set(data),
      error: (err) => console.error('Error fetching stats', err)
    });
    
    this.statsService.getAiStats().subscribe({
      next: (data) => {
        if (data && data.length > 0) {
          this.aiChartData.labels = data.map(d => d.featureType);
          this.aiChartData.datasets[0].data = data.map(d => d.count);
          this.aiChartData = { ...this.aiChartData };
        }
      },
      error: (err) => console.error('Error fetching AI stats', err)
    });
  }

  getInitialsAvatar(name: string): string {
    let hash = 0;
    if (name) {
      for (let i = 0; i < name.length; i++) {
        hash = name.charCodeAt(i) + ((hash << 5) - hash);
      }
    }
    const color = Math.floor(Math.abs((Math.sin(hash) * 10000) % 1 * 16777215)).toString(16).padStart(6, '0');
    const nameParam = name ? encodeURIComponent(name) : 'U';
    return `https://ui-avatars.com/api/?name=${nameParam}&background=${color}&color=fff&rounded=true&bold=true`;
  }
}
