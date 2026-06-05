import { Component, Input, OnChanges, SimpleChanges, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { Birthday } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-dashboard-charts',
  standalone: true,
  imports: [CommonModule, BaseChartDirective],
  templateUrl: './dashboard-charts.component.html',
  styleUrl: './dashboard-charts.component.css'
})
export class DashboardChartsComponent implements OnChanges {
  @Input() birthdays: Birthday[] = [];
  t9n = inject(TranslationService);

  // === Bar Chart (Birthdays by Month) ===
  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: { beginAtZero: true, ticks: { stepSize: 1 } },
      x: { grid: { display: false } }
    }
  };
  public barChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: 'rgba(37, 99, 235, 0.7)', hoverBackgroundColor: 'rgba(37, 99, 235, 1)', borderRadius: 4 }]
  };

  // === Doughnut Chart (Birthdays by Category) ===
  public doughnutChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'right' }
    }
  };
  public doughnutChartData: ChartData<'doughnut'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: [] }]
  };

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['birthdays']) {
      this.updateCharts();
    }
  }

  private updateCharts() {
    const list = this.birthdays || [];
    
    // 1. Calculate Birthdays per Month
    const months = new Array(12).fill(0);
    list.forEach(b => {
      const date = new Date(b.birthdate);
      if (!isNaN(date.getTime())) {
        months[date.getMonth()]++;
      }
    });
    
    const monthLabels = this.t9n.t('dashboard.months') || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    this.barChartData = {
      labels: monthLabels as string[],
      datasets: [
        { 
          data: months, 
          label: this.t9n.t('charts.birthdays') || 'Anniversaires',
          backgroundColor: 'rgba(37, 99, 235, 0.7)',
          hoverBackgroundColor: 'rgba(37, 99, 235, 1)',
          borderRadius: 4
        }
      ]
    };

    // 2. Calculate Birthdays by Category
    const categoryCount: { [key: string]: number } = {};
    list.forEach(b => {
      categoryCount[b.category] = (categoryCount[b.category] || 0) + 1;
    });

    const categories = Object.keys(categoryCount);
    const counts = categories.map(c => categoryCount[c]);
    
    // Assign predefined colors to common categories, random for others
    const colorMap: { [key: string]: string } = {
      'Family': '#f43f5e',
      'Friend': '#3b82f6',
      'Work': '#10b981',
      'Other': '#8b5cf6'
    };
    
    const colors = categories.map(c => colorMap[c] || '#f59e0b');

    this.doughnutChartData = {
      labels: categories,
      datasets: [
        {
          data: counts,
          backgroundColor: colors,
          hoverOffset: 4
        }
      ]
    };
  }
}
