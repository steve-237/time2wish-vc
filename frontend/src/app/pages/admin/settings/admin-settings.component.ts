import { Component, inject, OnInit, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminService, AppSetting } from '../../../services/admin.service';
import { FormsModule } from '@angular/forms';
import { TranslationService } from '../../../services/translation.service';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../../services/toast.service';
import { Subscription } from 'rxjs';
import { environment } from '../../../../environments/environment';

import { Client, StompSubscription } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

interface SystemMetrics {
  activeUsers: number;
  memoryMax: number;
  memoryAllocated: number;
  memoryFree: number;
  memoryUsed: number;
  cpuLoad: number;
  availableProcessors: number;
}

interface LogMessage {
  timestamp: string;
  level: string;
  logger: string;
  thread: string;
  message: string;
}

@Component({
  selector: 'app-admin-settings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-settings.component.html',
  styleUrls: ['./admin-settings.component.css']
})
export class AdminSettingsComponent implements OnInit, OnDestroy {
  private adminService = inject(AdminService);
  private http = inject(HttpClient);
  private toast = inject(ToastService);
  t9n = inject(TranslationService);
  
  settings = signal<AppSetting[]>([]);
  activeTab = signal<'general' | 'modules' | 'monitor' | 'advanced'>('general');

  metrics = signal<SystemMetrics | null>(null);
  logs = signal<LogMessage[]>([]);
  
  private metricsInterval: any;
  private stompClient: Client | null = null;
  private logSub: StompSubscription | null = null;

  ngOnInit() {
    this.loadSettings();
  }

  ngOnDestroy() {
    this.stopMonitoring();
  }

  setTab(tab: 'general' | 'modules' | 'monitor' | 'advanced') {
    this.activeTab.set(tab);
    if (tab === 'monitor') {
      this.startMonitoring();
    } else {
      this.stopMonitoring();
    }
  }

  loadSettings() {
    this.adminService.getSettings().subscribe({
      next: (data) => this.settings.set(data),
      error: (err) => console.error('Error fetching settings', err)
    });
  }

  get generalSettings() {
    return this.settings().filter(s => !s.key.startsWith('MODULE_'));
  }

  get moduleSettings() {
    return this.settings().filter(s => s.key.startsWith('MODULE_'));
  }

  onToggleChange(setting: AppSetting, event: any) {
    const newVal = event.target.checked ? 'true' : 'false';
    this.updateSetting(setting.key, newVal);
  }

  onNumberChange(setting: AppSetting, event: any) {
    this.updateSetting(setting.key, event.target.value);
  }

  onTextChange(setting: AppSetting, event: any) {
    this.updateSetting(setting.key, event.target.value);
  }

  updateSetting(key: string, value: string) {
    this.adminService.updateSetting(key, value).subscribe({
      next: (updatedSetting) => {
        this.settings.update(arr => arr.map(s => s.key === key ? updatedSetting : s));
        this.toast.success(`Paramètre ${this.formatKey(key)} mis à jour`);
      },
      error: (err) => {
        console.error('Error updating setting', err);
        this.toast.error('Erreur de mise à jour');
        this.loadSettings(); // revert
      }
    });
  }

  formatKey(key: string): string {
    return key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  // Monitor Logic
  startMonitoring() {
    this.fetchMetrics();
    this.metricsInterval = setInterval(() => this.fetchMetrics(), 5000);
    this.fetchInitialLogs();
    this.connectWebSockets();
  }

  stopMonitoring() {
    if (this.metricsInterval) clearInterval(this.metricsInterval);
    if (this.stompClient) {
      this.stompClient.deactivate();
      this.stompClient = null;
    }
  }

  fetchMetrics() {
    this.http.get<SystemMetrics>(`${environment.apiUrl}/admin/system/metrics`).subscribe({
      next: (data) => this.metrics.set(data)
    });
  }

  fetchInitialLogs() {
    this.http.get<LogMessage[]>(`${environment.apiUrl}/admin/system/logs`).subscribe({
      next: (data) => this.logs.set(data || [])
    });
  }

  connectWebSockets() {
    if (this.stompClient) return;

    const socketUrl = environment.apiUrl.replace('/api', '/ws');
    this.stompClient = new Client({
      webSocketFactory: () => new SockJS(socketUrl),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
    });

    this.stompClient.onConnect = () => {
      this.logSub = this.stompClient!.subscribe('/topic/admin.logs', (message) => {
        const logMsg: LogMessage = JSON.parse(message.body);
        this.logs.update(logs => {
          const newLogs = [...logs, logMsg];
          if (newLogs.length > 500) newLogs.shift();
          return newLogs;
        });
      });
    };

    this.stompClient.activate();
  }

  downloadBackup() {
    this.http.get(`${environment.apiUrl}/admin/system/backup`, { responseType: 'blob' }).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `time2wish_backup_${new Date().getTime()}.json`;
        a.click();
        window.URL.revokeObjectURL(url);
        this.toast.success('Sauvegarde téléchargée avec succès');
      },
      error: () => this.toast.error('Erreur lors de la sauvegarde')
    });
  }

  formatBytes(bytes: number, decimals = 2) {
    if (!+bytes) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
  }
}
