import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, CurrencyPipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment';
import { ToastService } from '../../../services/toast.service';

interface GiftDto {
  id: number;
  title: string;
  description: string;
  price: number;
  currentFunding: number;
  imageUrl: string;
  birthdayId: number;
}

@Component({
  selector: 'app-admin-gifts',
  standalone: true,
  imports: [CommonModule, CurrencyPipe],
  template: `
    <div class="admin-container">
      <div class="header-container mb-4">
        <h2 class="page-title">Cadeaux 🎁</h2>
        <p class="page-subtitle">Modération des idées cadeaux générées ou ajoutées par les utilisateurs</p>
      </div>

      <div class="gifts-grid">
        @for (gift of gifts(); track gift.id) {
          <div class="gift-card">
            <div class="gift-image-wrapper">
              @if (gift.imageUrl) {
                <img [src]="gift.imageUrl" [alt]="gift.title" class="gift-image" />
              } @else {
                <div class="no-image">
                  <span class="material-symbols-outlined">card_giftcard</span>
                </div>
              }
              <button class="delete-btn" (click)="deleteGift(gift)" title="Supprimer ce cadeau">
                <span class="material-symbols-outlined">delete</span>
              </button>
            </div>
            
            <div class="gift-details">
              <h3 class="gift-title">{{ gift.title }}</h3>
              <p class="gift-desc" [title]="gift.description">{{ gift.description }}</p>
              
              <div class="gift-stats">
                <div class="stat-item">
                  <span class="stat-label">Prix</span>
                  <span class="stat-value">{{ gift.price | currency:'EUR' }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">Cagnotte</span>
                  <span class="stat-value text-primary">{{ gift.currentFunding | currency:'EUR' }}</span>
                </div>
              </div>
              
              <div class="gift-footer">
                <span class="badge">Anniversaire #{{ gift.birthdayId }}</span>
                <span class="badge warning" *ngIf="gift.currentFunding > 0">Financé à {{ (gift.currentFunding / gift.price * 100) | number:'1.0-0' }}%</span>
              </div>
            </div>
          </div>
        } @empty {
          <div class="empty-state">
            <span class="material-symbols-outlined">inbox</span>
            <p>Aucun cadeau trouvé dans la base de données.</p>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .admin-container { padding: 1rem; }
    .mb-4 { margin-bottom: 2rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .gifts-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 1.5rem;
    }
    
    .gift-card {
      background: var(--bg-card);
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid var(--border-card);
      box-shadow: var(--glass-shadow);
      display: flex;
      flex-direction: column;
      transition: transform 0.2s;
    }
    .gift-card:hover {
      transform: translateY(-4px);
    }
    
    .gift-image-wrapper {
      position: relative;
      height: 160px;
      background: rgba(var(--primary-hsl), 0.05);
      border-bottom: 1px solid var(--border-card);
    }
    .gift-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .no-image {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-muted);
    }
    .no-image .material-symbols-outlined { font-size: 3rem; opacity: 0.5; }
    
    .delete-btn {
      position: absolute;
      top: 10px;
      right: 10px;
      background: rgba(239, 68, 68, 0.9);
      color: white;
      border: none;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      opacity: 0;
      transition: opacity 0.2s;
    }
    .gift-card:hover .delete-btn { opacity: 1; }
    .delete-btn:hover { background: #dc2626; transform: scale(1.1); }
    
    .gift-details {
      padding: 1.25rem;
      flex: 1;
      display: flex;
      flex-direction: column;
    }
    
    .gift-title {
      margin: 0 0 0.5rem 0;
      font-size: 1.1rem;
      color: var(--text-main);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .gift-desc {
      color: var(--text-muted);
      font-size: 0.85rem;
      margin: 0 0 1rem 0;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }
    
    .gift-stats {
      display: flex;
      justify-content: space-between;
      margin-bottom: 1rem;
      padding-top: 1rem;
      border-top: 1px dashed var(--border-card);
    }
    .stat-item { display: flex; flex-direction: column; }
    .stat-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; }
    .stat-value { font-size: 1.1rem; font-weight: bold; color: var(--text-main); }
    .text-primary { color: var(--primary); }
    
    .gift-footer {
      margin-top: auto;
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }
    
    .badge {
      background: rgba(100, 116, 139, 0.1);
      color: var(--text-muted);
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 500;
    }
    .badge.warning { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
    
    .empty-state { grid-column: 1 / -1; text-align: center; padding: 4rem; color: var(--text-muted); }
    .empty-state .material-symbols-outlined { font-size: 3rem; opacity: 0.5; margin-bottom: 1rem; }
  `]
})
export class AdminGiftsComponent implements OnInit {
  private http = inject(HttpClient);
  private toast = inject(ToastService);
  
  gifts = signal<GiftDto[]>([]);

  ngOnInit() {
    this.loadGifts();
  }

  loadGifts() {
    this.http.get<GiftDto[]>(`${environment.apiUrl}/admin/gifts`).subscribe({
      next: (data) => this.gifts.set(data),
      error: () => this.toast.error('Erreur lors du chargement des cadeaux')
    });
  }

  deleteGift(gift: GiftDto) {
    if(confirm(`Voulez-vous supprimer définitivement le cadeau "${gift.title}" ?`)) {
      this.http.delete(`${environment.apiUrl}/admin/gifts/${gift.id}`).subscribe({
        next: () => {
          this.gifts.update(list => list.filter(g => g.id !== gift.id));
          this.toast.success('Cadeau supprimé avec succès');
        },
        error: () => this.toast.error('Impossible de supprimer ce cadeau (il a peut-être des contributions)')
      });
    }
  }
}
