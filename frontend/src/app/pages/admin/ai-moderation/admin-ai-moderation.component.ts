import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment';

interface AiLogDto {
  id: number;
  userEmail: string;
  userFullName: string;
  featureType: string;
  prompt: string;
  generatedContent: string;
  tokensCost: number;
  createdAt: string;
}

@Component({
  selector: 'app-admin-ai-logs',
  standalone: true,
  imports: [CommonModule, DatePipe],
  template: `
    <div class="logs-container">
      <h2 class="page-title">Modération IA</h2>
      <p class="page-subtitle">Historique des requêtes et contenus générés par l'IA.</p>
      
      <div class="filters">
        <button class="filter-btn" [class.active]="filter() === 'ALL'" (click)="filter.set('ALL')">Tous</button>
        <button class="filter-btn" [class.active]="filter() === 'WISH'" (click)="filter.set('WISH')">Vœux (Texte)</button>
        <button class="filter-btn" [class.active]="filter() === 'GIFT'" (click)="filter.set('GIFT')">Cadeaux (JSON)</button>
        <button class="filter-btn" [class.active]="filter() === 'IMAGE'" (click)="filter.set('IMAGE')">Images</button>
      </div>

      <div class="table-wrapper">
        <table class="logs-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Utilisateur</th>
              <th>Type</th>
              <th>Prompt (Requête)</th>
              <th>Contenu Généré</th>
              <th>Coût (Tokens)</th>
            </tr>
          </thead>
          <tbody>
            @for (log of filteredLogs(); track log.id) {
              <tr>
                <td class="date-col">{{ log.createdAt | date:'short' }}</td>
                <td>
                  <div class="user-info">
                    <span class="user-name">{{ log.userFullName }}</span>
                    <span class="user-email">{{ log.userEmail }}</span>
                  </div>
                </td>
                <td>
                  <span class="type-badge" [ngClass]="log.featureType.toLowerCase()">
                    {{ log.featureType }}
                  </span>
                </td>
                <td class="text-col">
                  <div class="scroll-box">{{ log.prompt || 'N/A' }}</div>
                </td>
                <td class="text-col">
                  <div class="scroll-box result-box" [class.is-image]="log.featureType === 'IMAGE'">
                    {{ log.generatedContent || 'N/A' }}
                  </div>
                </td>
                <td class="cost-col">{{ log.tokensCost }}</td>
              </tr>
            }
            @if (filteredLogs().length === 0) {
              <tr>
                <td colspan="6" class="empty-state">Aucun log IA trouvé.</td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .logs-container { padding: 1.5rem; }
    .page-title { font-size: 1.8rem; font-weight: 700; color: var(--text-main); margin-bottom: 0.5rem; }
    .page-subtitle { color: var(--text-muted); margin-bottom: 2rem; }
    
    .filters { display: flex; gap: 1rem; margin-bottom: 1.5rem; }
    .filter-btn { padding: 0.5rem 1rem; border-radius: 8px; border: 1px solid var(--border-card); background: var(--bg-card); color: var(--text-muted); cursor: pointer; transition: all 0.2s; font-weight: 500; }
    .filter-btn:hover { background: rgba(var(--primary-hsl), 0.1); color: var(--primary); }
    .filter-btn.active { background: var(--primary); color: white; border-color: var(--primary); }
    
    .table-wrapper { background: var(--bg-card); border-radius: 12px; box-shadow: var(--glass-shadow); overflow-x: auto; border: 1px solid var(--border-card); }
    .logs-table { width: 100%; border-collapse: collapse; text-align: left; }
    .logs-table th, .logs-table td { padding: 1rem; border-bottom: 1px solid var(--border-card); vertical-align: top; }
    .logs-table th { font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; background: rgba(0,0,0,0.02); }
    
    .user-info { display: flex; flex-direction: column; gap: 0.2rem; }
    .user-name { font-weight: 600; font-size: 0.9rem; color: var(--text-main); }
    .user-email { font-size: 0.8rem; color: var(--text-muted); }
    
    .type-badge { padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; }
    .type-badge.wish { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .type-badge.gift { background: rgba(16, 185, 129, 0.1); color: #10b981; }
    .type-badge.image { background: rgba(168, 85, 247, 0.1); color: #a855f7; }
    
    .scroll-box { max-height: 100px; max-width: 300px; overflow-y: auto; font-size: 0.85rem; color: var(--text-main); background: rgba(0,0,0,0.02); padding: 0.5rem; border-radius: 6px; white-space: pre-wrap; word-break: break-word; }
    .result-box { background: rgba(16, 185, 129, 0.05); border-left: 3px solid #10b981; }
    .result-box.is-image { background: rgba(168, 85, 247, 0.05); border-left: 3px solid #a855f7; font-style: italic; }
    
    .date-col { font-size: 0.85rem; color: var(--text-muted); white-space: nowrap; }
    .cost-col { font-weight: 600; color: var(--text-main); text-align: center; }
    .empty-state { text-align: center; color: var(--text-muted); padding: 3rem !important; }
  `]
})
export class AdminAiLogsComponent implements OnInit {
  private http = inject(HttpClient);
  logs = signal<AiLogDto[]>([]);
  filter = signal<string>('ALL');
  
  filteredLogs = computed(() => {
    const currentFilter = this.filter();
    if (currentFilter === 'ALL') return this.logs();
    return this.logs().filter(l => l.featureType === currentFilter);
  });

  ngOnInit() {
    this.http.get<AiLogDto[]>(environment.apiUrl + '/admin/stats/ai/logs').subscribe({
      next: (data) => this.logs.set(data),
      error: (err) => console.error('Error fetching AI logs', err)
    });
  }
}
