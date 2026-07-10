import { Component, inject, OnInit, OnDestroy, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-logs',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="admin-container">
      <div class="header-container">
        <div>
          <h2 class="page-title">Logs Système 🖥️</h2>
          <p class="page-subtitle">Suivi en direct des événements du serveur (500 dernières lignes)</p>
        </div>
        <div class="actions">
          <button class="btn btn-secondary" (click)="clearLogs()" [disabled]="isLoading()">
            <span class="material-symbols-outlined">delete</span> Effacer
          </button>
          <button class="btn btn-primary" (click)="loadLogs()" [disabled]="isLoading()">
            <span class="material-symbols-outlined" [class.spin]="isLoading()">refresh</span> Rafraîchir
          </button>
        </div>
      </div>

      <div class="terminal-wrapper">
        <div class="terminal-header">
          <div class="window-controls">
            <span class="dot red"></span>
            <span class="dot yellow"></span>
            <span class="dot green"></span>
          </div>
          <div class="terminal-title">time2wish-backend - bash</div>
        </div>
        <div class="terminal-body" #terminalBody>
          @if (logs().length === 0 && !isLoading()) {
            <div class="empty-logs">Aucun log disponible ou fichier vide.</div>
          }
          @for (line of logs(); track $index) {
            <div class="log-line" [class.error]="isError(line)" [class.warn]="isWarn(line)">{{ line }}</div>
          }
          @if (isLoading()) {
            <div class="log-line loading-text">Chargement des logs...</div>
          }
        </div>
      </div>
    </div>
  `,
  styles: [`
    .admin-container { padding: 1rem; }
    .header-container { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 1.5rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    .actions { display: flex; gap: 0.5rem; }
    
    .spin { animation: spin 1s linear infinite; }
    @keyframes spin { 100% { transform: rotate(360deg); } }

    .terminal-wrapper {
      background: #1e1e1e;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      border: 1px solid #333;
      display: flex;
      flex-direction: column;
      height: calc(100vh - 200px);
      min-height: 500px;
    }

    .terminal-header {
      background: #2d2d2d;
      padding: 10px 15px;
      display: flex;
      align-items: center;
      border-bottom: 1px solid #111;
    }

    .window-controls { display: flex; gap: 6px; }
    .dot { width: 12px; height: 12px; border-radius: 50%; }
    .red { background: #ff5f56; }
    .yellow { background: #ffbd2e; }
    .green { background: #27c93f; }

    .terminal-title {
      color: #999;
      font-size: 0.85rem;
      font-family: monospace;
      margin-left: auto;
      margin-right: auto;
    }

    .terminal-body {
      padding: 15px;
      overflow-y: auto;
      flex: 1;
      font-family: 'Courier New', Courier, monospace;
      font-size: 0.85rem;
      line-height: 1.4;
      color: #ccc;
    }

    .log-line {
      word-wrap: break-word;
      white-space: pre-wrap;
      margin-bottom: 2px;
    }

    .log-line.error { color: #ff5f56; font-weight: bold; }
    .log-line.warn { color: #ffbd2e; }
    .empty-logs { color: #666; font-style: italic; text-align: center; margin-top: 2rem; }
    .loading-text { color: #27c93f; animation: pulse 1.5s infinite; }

    @keyframes pulse {
      0% { opacity: 0.5; }
      50% { opacity: 1; }
      100% { opacity: 0.5; }
    }
  `]
})
export class AdminLogsComponent implements OnInit, OnDestroy {
  private http = inject(HttpClient);
  private toast = inject(ToastService);
  
  logs = signal<string[]>([]);
  isLoading = signal(false);
  private autoRefreshInterval: any;

  ngOnInit() {
    this.loadLogs();
    // Auto-refresh every 10 seconds
    this.autoRefreshInterval = setInterval(() => {
      this.loadLogs();
    }, 10000);
  }

  ngOnDestroy() {
    if (this.autoRefreshInterval) {
      clearInterval(this.autoRefreshInterval);
    }
  }

  loadLogs() {
    if (this.isLoading()) return;
    this.isLoading.set(true);
    this.http.get<string[]>(`${environment.apiUrl}/admin/logs`).subscribe({
      next: (data) => {
        this.logs.set(data);
        this.isLoading.set(false);
        this.scrollToBottom();
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  clearLogs() {
    if(confirm('Êtes-vous sûr de vouloir vider le fichier de log ?')) {
      this.http.delete(`${environment.apiUrl}/admin/logs`).subscribe({
        next: () => {
          this.logs.set([]);
          this.toast.success('Logs effacés');
        },
        error: () => this.toast.error('Erreur lors de la suppression des logs')
      });
    }
  }

  isError(line: string): boolean {
    return line.includes('ERROR') || line.includes('Exception');
  }

  isWarn(line: string): boolean {
    return line.includes('WARN');
  }

  private scrollToBottom() {
    setTimeout(() => {
      const container = document.querySelector('.terminal-body');
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    }, 100);
  }
}
