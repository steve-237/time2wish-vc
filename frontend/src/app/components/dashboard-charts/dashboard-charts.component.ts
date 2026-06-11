import { Component, Input, OnChanges, SimpleChanges, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { Birthday, getZodiacSign } from '../../models/birthday.model';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-dashboard-charts',
  standalone: true,
  imports: [CommonModule, BaseChartDirective],
  templateUrl: './dashboard-charts.component.html',
  styleUrl: './dashboard-charts.component.scss'
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

  // === Pie Chart (Birthdays by Gender) ===
  public genderChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'right' } }
  };
  public genderChartData: ChartData<'pie'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: [] }]
  };

  // === Bar Chart (Age Distribution) ===
  public ageChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      y: { beginAtZero: true, ticks: { stepSize: 1 } },
      x: { grid: { display: false } }
    }
  };
  public ageChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: 'rgba(16, 185, 129, 0.7)', hoverBackgroundColor: 'rgba(16, 185, 129, 1)', borderRadius: 4 }]
  };

  // === Polar Area Chart (Zodiac Signs) ===
  public zodiacChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'right' } }
  };
  public zodiacChartData: ChartData<'polarArea'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: [] }]
  };

  // === Horizontal Bar Chart (Top Interests) ===
  public interestsChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    indexAxis: 'y',
    plugins: { legend: { display: false } },
    scales: {
      x: { beginAtZero: true, ticks: { stepSize: 1 } },
      y: { grid: { display: false } }
    }
  };
  public interestsChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: '#f59e0b', borderRadius: 4 }]
  };

  // === Pie Chart (Favorites) ===
  public favoritesChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'right' } }
  };
  public favoritesChartData: ChartData<'pie'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: [] }]
  };

  // === Radar Chart (Days of Week) ===
  public weekdayChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } }
  };
  public weekdayChartData: ChartData<'radar'> = {
    labels: [],
    datasets: [{ data: [], backgroundColor: 'rgba(59, 130, 246, 0.4)', borderColor: '#3b82f6', pointBackgroundColor: '#3b82f6' }]
  };

  // === Doughnut Chart (Reminders) ===
  public remindersChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'right' } }
  };
  public remindersChartData: ChartData<'doughnut'> = {
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
      labels: categories.map(c => this.t9n.t('categories.' + c) || c),
      datasets: [
        {
          data: counts,
          backgroundColor: colors,
          hoverOffset: 4
        }
      ]
    };

    // 3. Calculate Birthdays by Gender
    let maleCount = 0;
    let femaleCount = 0;
    let otherCount = 0;
    let unspecifiedCount = 0;

    list.forEach(b => {
      if (b.gender === 'Masculin') maleCount++;
      else if (b.gender === 'Féminin') femaleCount++;
      else if (b.gender === 'Autre') otherCount++;
      else unspecifiedCount++;
    });

    this.genderChartData = {
      labels: ['Masculin', 'Féminin', 'Autre', 'Non spécifié'],
      datasets: [{
        data: [maleCount, femaleCount, otherCount, unspecifiedCount],
        backgroundColor: ['#3b82f6', '#ec4899', '#8b5cf6', '#9ca3af'],
        hoverOffset: 4
      }]
    };

    // 4. Calculate Age Distribution
    const ageGroups = { '0-18': 0, '19-30': 0, '31-50': 0, '51+': 0 };
    list.forEach(b => {
      if (b.showAge === false) return; // Skip if age is hidden
      const age = this.getAge(b.birthdate);
      if (age <= 18) ageGroups['0-18']++;
      else if (age <= 30) ageGroups['19-30']++;
      else if (age <= 50) ageGroups['31-50']++;
      else ageGroups['51+']++;
    });

    this.ageChartData = {
      labels: Object.keys(ageGroups),
      datasets: [{
        data: Object.values(ageGroups),
        label: 'Personnes',
        backgroundColor: 'rgba(16, 185, 129, 0.7)',
        hoverBackgroundColor: 'rgba(16, 185, 129, 1)',
        borderRadius: 4
      }]
    };

    // 5. Calculate Zodiac Signs Distribution
    const zodiacCount: { [key: string]: number } = {};
    list.forEach(b => {
      const zodiac = getZodiacSign(b.birthdate);
      zodiacCount[zodiac.emoji + ' ' + zodiac.name] = (zodiacCount[zodiac.emoji + ' ' + zodiac.name] || 0) + 1;
    });

    const zodiacLabels = Object.keys(zodiacCount);
    const zodiacData = Object.values(zodiacCount);
    
    // Generate distinct colors for zodiac signs
    const zodiacColors = zodiacLabels.map((_, i) => `hsl(${(i * 360) / zodiacLabels.length}, 70%, 60%)`);

    this.zodiacChartData = {
      labels: zodiacLabels,
      datasets: [{
        data: zodiacData,
        backgroundColor: zodiacColors
      }]
    };

    // 6. Calculate Top Interests
    const interestCount: { [key: string]: number } = {};
    list.forEach(b => {
      if (b.interests && Array.isArray(b.interests)) {
        b.interests.forEach(interest => {
          const formatted = interest.trim();
          if (formatted) {
            interestCount[formatted] = (interestCount[formatted] || 0) + 1;
          }
        });
      }
    });
    
    // Sort and take top 7
    const sortedInterests = Object.entries(interestCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 7);

    this.interestsChartData = {
      labels: sortedInterests.map(i => i[0]),
      datasets: [{
        data: sortedInterests.map(i => i[1]),
        label: 'Personnes',
        backgroundColor: 'rgba(245, 158, 11, 0.7)',
        hoverBackgroundColor: 'rgba(245, 158, 11, 1)',
        borderRadius: 4
      }]
    };

    // 7. Calculate Favorites
    let favCount = 0;
    let notFavCount = 0;
    list.forEach(b => {
      if (b.isFavorite) favCount++;
      else notFavCount++;
    });

    this.favoritesChartData = {
      labels: ['Favoris', 'Standards'],
      datasets: [{
        data: [favCount, notFavCount],
        backgroundColor: ['#fbbf24', '#e5e7eb'],
        hoverOffset: 4
      }]
    };

    // 8. Calculate Day of Week (Original Birthdate)
    const weekdaysCount = [0, 0, 0, 0, 0, 0, 0]; // Sun, Mon, Tue, Wed, Thu, Fri, Sat
    list.forEach(b => {
      const d = new Date(b.birthdate);
      if (!isNaN(d.getTime())) {
        weekdaysCount[d.getDay()]++;
      }
    });

    this.weekdayChartData = {
      labels: ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
      datasets: [{
        data: weekdaysCount,
        label: 'Naissances',
        backgroundColor: 'rgba(59, 130, 246, 0.4)',
        borderColor: '#3b82f6',
        pointBackgroundColor: '#3b82f6'
      }]
    };

    // 9. Calculate Reminder Settings
    const reminderCount: { [key: string]: number } = {};
    list.forEach(b => {
      const key = b.reminderDays === 0 ? 'Jour J' : (b.reminderDays === 1 ? '1 jour avant' : `${b.reminderDays} jours avant`);
      reminderCount[key] = (reminderCount[key] || 0) + 1;
    });

    const remLabels = Object.keys(reminderCount);
    const remData = Object.values(reminderCount);
    const remColors = remLabels.map((_, i) => `hsl(${160 + (i * 30)}, 70%, 60%)`);

    this.remindersChartData = {
      labels: remLabels,
      datasets: [{
        data: remData,
        backgroundColor: remColors,
        hoverOffset: 4
      }]
    };
  }

  private getAge(birthdateStr: string): number {
    const birthdate = new Date(birthdateStr);
    const today = new Date();
    let age = today.getFullYear() - birthdate.getFullYear();
    const monthDiff = today.getMonth() - birthdate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthdate.getDate())) {
      age--;
    }
    return age;
  }
}
