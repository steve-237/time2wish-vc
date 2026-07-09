import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminService, AppSetting } from '../../../services/admin.service';
import { FormsModule } from '@angular/forms';
import { TranslationService } from '../../../services/translation.service';

@Component({
  selector: 'app-admin-settings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="settings-container">
      <div class="header-container">
        <h2 class="page-title">Paramètres Globaux</h2>
        <p class="page-subtitle">Gérez la configuration système de Time2Wish</p>
      </div>
      
      <div class="settings-grid">
        @for (setting of settings(); track setting.key) {
          <div class="setting-card">
            <div class="setting-info">
              <h3 class="setting-key">{{ formatKey(setting.key) }}</h3>
              <p class="setting-desc">{{ setting.description }}</p>
            </div>
            
            <div class="setting-control">
              @if (setting.type === 'BOOLEAN') {
                <label class="toggle-switch">
                  <input type="checkbox" 
                         [checked]="setting.value === 'true'"
                         (change)="onToggleChange(setting, $event)">
                  <span class="slider"></span>
                </label>
              } @else if (setting.type === 'INTEGER') {
                <input type="number" 
                       class="number-input"
                       [value]="setting.value"
                       (change)="onNumberChange(setting, $event)">
              } @else {
                <input type="text" 
                       class="text-input"
                       [value]="setting.value"
                       (change)="onTextChange(setting, $event)">
              }
            </div>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .settings-container { padding: 1rem; }
    .header-container { margin-bottom: 2rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .settings-grid {
      display: flex;
      flex-direction: column;
      gap: 1.5rem;
      max-width: 800px;
    }
    
    .setting-card {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: 12px;
      padding: 1.5rem;
      box-shadow: var(--glass-shadow);
      gap: 2rem;
    }
    
    .setting-info { flex: 1; }
    .setting-key { font-size: 1.1rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .setting-desc { font-size: 0.9rem; color: var(--text-muted); margin: 0; line-height: 1.4; }
    
    .setting-control {
      flex-shrink: 0;
      display: flex;
      align-items: center;
    }
    
    /* Toggle Switch CSS */
    .toggle-switch {
      position: relative;
      display: inline-block;
      width: 50px;
      height: 28px;
    }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .slider {
      position: absolute;
      cursor: pointer;
      top: 0; left: 0; right: 0; bottom: 0;
      background-color: #cbd5e1;
      transition: .4s;
      border-radius: 34px;
    }
    .slider:before {
      position: absolute;
      content: "";
      height: 20px; width: 20px;
      left: 4px; bottom: 4px;
      background-color: white;
      transition: .4s;
      border-radius: 50%;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    input:checked + .slider {
      background-color: var(--primary);
    }
    input:checked + .slider:before {
      transform: translateX(22px);
    }

    .number-input, .text-input {
      padding: 0.5rem 1rem;
      border-radius: 8px;
      border: 1px solid var(--border-card);
      background: var(--bg-main);
      color: var(--text-main);
      font-size: 1rem;
      width: 100px;
      text-align: center;
    }
    .number-input:focus, .text-input:focus {
      outline: none;
      border-color: var(--primary);
    }
    .text-input { width: 200px; text-align: left; }
  `]
})
export class AdminSettingsComponent implements OnInit {
  private adminService = inject(AdminService);
  t9n = inject(TranslationService);
  
  settings = signal<AppSetting[]>([]);

  ngOnInit() {
    this.loadSettings();
  }

  loadSettings() {
    this.adminService.getSettings().subscribe({
      next: (data) => this.settings.set(data),
      error: (err) => console.error('Error fetching settings', err)
    });
  }

  formatKey(key: string): string {
    return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  }

  onToggleChange(setting: AppSetting, event: Event) {
    const isChecked = (event.target as HTMLInputElement).checked;
    this.updateSetting(setting.key, isChecked ? 'true' : 'false');
  }

  onNumberChange(setting: AppSetting, event: Event) {
    const val = (event.target as HTMLInputElement).value;
    this.updateSetting(setting.key, val);
  }

  onTextChange(setting: AppSetting, event: Event) {
    const val = (event.target as HTMLInputElement).value;
    this.updateSetting(setting.key, val);
  }

  private updateSetting(key: string, value: string) {
    this.adminService.updateSetting(key, value).subscribe({
      next: () => {
        // Optimistic update
        this.settings.update(arr => arr.map(s => s.key === key ? { ...s, value } : s));
      },
      error: (err) => {
        console.error('Error updating setting', err);
        this.loadSettings(); // Revert on error
      }
    });
  }
}
