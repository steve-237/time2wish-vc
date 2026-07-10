import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PromoService, PromoCode } from '../../../services/promo.service';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-promos',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  template: `
    <div class="admin-container">
      <div class="header-container flex-between mb-4">
        <div>
          <h2 class="page-title">Codes Promotionnels 🎟️</h2>
          <p class="page-subtitle">Gérez les codes de réduction pour vos utilisateurs</p>
        </div>
        <button class="btn-PRO" (click)="isCreateModalOpen.set(true)">
          <span class="material-symbols-outlined">add</span> Créer un code
        </button>
      </div>

      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>Code</th>
              <th>Réduction</th>
              <th>Utilisations</th>
              <th>Expiration</th>
              <th>Statut</th>
              <th style="text-align: right;">Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (promo of promos(); track promo.id) {
              <tr [class.inactive]="!promo.active">
                <td>
                  <strong class="code-badge">{{ promo.code }}</strong>
                </td>
                <td><span class="discount-badge">-{{ promo.discountPercentage }}%</span></td>
                <td>
                  <div class="usage-bar-container">
                    <div class="usage-text">{{ promo.currentUses }} / {{ promo.maxUses || '∞' }}</div>
                    @if (promo.maxUses) {
                      <div class="usage-progress">
                        <div class="progress-fill" [style.width.%]="(promo.currentUses! / promo.maxUses) * 100" [class.full]="promo.currentUses! >= promo.maxUses"></div>
                      </div>
                    }
                  </div>
                </td>
                <td>
                  @if (promo.expiresAt) {
                    <span [class.expired]="isExpired(promo.expiresAt)">{{ promo.expiresAt | date:'shortDate' }}</span>
                  } @else {
                    <span class="text-muted">Jamais</span>
                  }
                </td>
                <td>
                  <label class="toggle-switch">
                    <input type="checkbox" [checked]="promo.active" (change)="toggleStatus(promo)">
                    <span class="slider"></span>
                  </label>
                </td>
                <td class="actions-cell">
                  <button class="icon-btn text-danger" (click)="deletePromo(promo)" title="Supprimer">
                    <span class="material-symbols-outlined">delete</span>
                  </button>
                </td>
              </tr>
            } @empty {
              <tr>
                <td colspan="6" class="empty-state">
                  <span class="material-symbols-outlined">local_activity</span>
                  <p>Aucun code promo créé. Commencez par en ajouter un !</p>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create Modal -->
    @if (isCreateModalOpen()) {
      <div class="modal-backdrop" (click)="isCreateModalOpen.set(false)">
        <div class="modal-container" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h3>Nouveau Code Promo</h3>
            <button class="icon-btn" (click)="isCreateModalOpen.set(false)">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>
          <div class="modal-body">
            <div class="form-group mb-3">
              <label class="form-label">Code (Ex: SUMMER20)</label>
              <input type="text" class="form-control" [(ngModel)]="newPromo.code" style="text-transform: uppercase;">
            </div>
            <div class="form-group mb-3">
              <label class="form-label">Pourcentage de réduction (%)</label>
              <input type="number" class="form-control" [(ngModel)]="newPromo.discountPercentage" min="1" max="100">
            </div>
            <div class="form-group mb-3">
              <label class="form-label">Nombre max d'utilisations (laisser vide si illimité)</label>
              <input type="number" class="form-control" [(ngModel)]="newPromo.maxUses" min="1">
            </div>
            <div class="form-group mb-4">
              <label class="form-label">Date d'expiration (optionnel)</label>
              <input type="datetime-local" class="form-control" [(ngModel)]="newPromo.expiresAt">
            </div>
            <button class="btn-PRO w-100" (click)="createPromo()" [disabled]="!newPromo.code || !newPromo.discountPercentage">
              Créer le code
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .admin-container { padding: 1rem; }
    .flex-between { display: flex; justify-content: space-between; align-items: flex-end; }
    .mb-3 { margin-bottom: 1rem; }
    .mb-4 { margin-bottom: 1.5rem; }
    .w-100 { width: 100%; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .table-wrapper { background: var(--bg-card); border-radius: 12px; box-shadow: var(--glass-shadow); overflow-x: auto; border: 1px solid var(--border-card); }
    .data-table { width: 100%; border-collapse: collapse; text-align: left; color: var(--text-main); }
    .data-table th, .data-table td { padding: 1.25rem 1rem; border-bottom: 1px solid var(--border-card); vertical-align: middle; }
    .data-table th { font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; border-bottom: 2px solid var(--border-card); }
    .data-table tbody tr { transition: background-color 0.2s; }
    .data-table tbody tr:hover { background-color: rgba(var(--primary-hsl), 0.05); }
    .data-table tbody tr.inactive { opacity: 0.6; }
    
    .code-badge { background: rgba(var(--primary-hsl), 0.1); color: var(--primary); padding: 4px 10px; border-radius: 6px; font-family: monospace; font-size: 1rem; letter-spacing: 1px; border: 1px dashed var(--primary); }
    .discount-badge { background: #10b981; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 0.85rem; }
    
    .usage-bar-container { width: 120px; }
    .usage-text { font-size: 0.85rem; margin-bottom: 4px; text-align: right; color: var(--text-muted); }
    .usage-progress { height: 6px; background: var(--border-card); border-radius: 3px; overflow: hidden; }
    .progress-fill { height: 100%; background: var(--primary); transition: width 0.3s; }
    .progress-fill.full { background: #ef4444; }
    
    .expired { color: #ef4444; font-weight: 500; }
    .text-muted { color: var(--text-muted); }
    .text-danger { color: #ef4444; }
    
    .actions-cell { text-align: right; }
    .icon-btn { background: none; border: none; cursor: pointer; display: inline-flex; padding: 4px; border-radius: 4px; transition: background 0.2s; }
    .icon-btn:hover { background: rgba(0,0,0,0.05); }

    /* Toggle Switch */
    .toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #cbd5e1; transition: .4s; border-radius: 34px; }
    .slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
    input:checked + .slider { background-color: #10b981; }
    input:checked + .slider:before { transform: translateX(20px); }

    /* Modal */
    .modal-backdrop { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); backdrop-filter: blur(4px); z-index: 1000; display: flex; align-items: center; justify-content: center; padding: 1rem; }
    .modal-container { background: var(--bg-card); border-radius: 16px; padding: 1.5rem; width: 100%; max-width: 450px; box-shadow: 0 20px 40px rgba(0,0,0,0.2); border: 1px solid var(--border-card); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    .modal-header h3 { margin: 0; font-size: 1.2rem; color: var(--text-main); }
    .empty-state { text-align: center; padding: 3rem; color: var(--text-muted); }
    .empty-state .material-symbols-outlined { font-size: 3rem; opacity: 0.5; margin-bottom: 1rem; }
  `]
})
export class AdminPromosComponent implements OnInit {
  private promoService = inject(PromoService);
  private toast = inject(ToastService);
  
  promos = signal<PromoCode[]>([]);
  isCreateModalOpen = signal(false);
  
  newPromo: Partial<PromoCode> = {
    code: '',
    discountPercentage: 20
  };

  ngOnInit() {
    this.loadPromos();
  }

  loadPromos() {
    this.promoService.getAllPromos().subscribe({
      next: (data) => this.promos.set(data)
    });
  }

  createPromo() {
    this.promoService.createPromo(this.newPromo).subscribe({
      next: (res) => {
        this.promos.update(list => [res, ...list]);
        this.isCreateModalOpen.set(false);
        this.newPromo = { code: '', discountPercentage: 20 };
        this.toast.success('Code promo créé avec succès !');
      },
      error: (err) => {
        this.toast.error(err.error || 'Erreur lors de la création');
      }
    });
  }

  toggleStatus(promo: PromoCode) {
    this.promoService.togglePromoStatus(promo.id!).subscribe({
      next: (res) => {
        this.promos.update(list => list.map(p => p.id === promo.id ? res : p));
      },
      error: () => this.toast.error('Erreur')
    });
  }

  deletePromo(promo: PromoCode) {
    if(confirm(`Voulez-vous supprimer le code ${promo.code} ?`)) {
      this.promoService.deletePromo(promo.id!).subscribe({
        next: () => {
          this.promos.update(list => list.filter(p => p.id !== promo.id));
        }
      });
    }
  }

  isExpired(dateStr: string): boolean {
    return new Date(dateStr) < new Date();
  }
}
