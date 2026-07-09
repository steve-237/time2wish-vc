import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { AdminService, AdminPaymentDto } from '../../../services/admin.service';
import { FormsModule } from '@angular/forms';
import { TranslationService } from '../../../services/translation.service';

@Component({
  selector: 'app-admin-payments',
  standalone: true,
  imports: [CommonModule, DatePipe, FormsModule],
  template: `
    <div class="payments-container">
      <div class="header-container">
        <h2 class="page-title">Historique des Transactions</h2>
        <div class="header-actions">
          <select [(ngModel)]="statusFilter" class="filter-select">
            <option value="ALL">Tous les statuts</option>
            <option value="SUCCESS">Succès (SUCCESS)</option>
            <option value="PENDING">En attente (PENDING)</option>
            <option value="FAILED">Échoué (FAILED)</option>
          </select>
        </div>
      </div>
      
      <div class="table-wrapper">
        <table class="payments-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Utilisateur</th>
              <th>Fournisseur</th>
              <th>Forfait</th>
              <th>Montant</th>
              <th>Statut</th>
            </tr>
          </thead>
          <tbody>
            @for (payment of filteredPayments(); track payment.id) {
              <tr>
                <td>{{ payment.createdAt | date:'short' }}</td>
                <td>
                  <div class="user-info">
                    <span class="user-name">{{ payment.userFullName }}</span>
                    <span class="user-email">{{ payment.userEmail }}</span>
                  </div>
                </td>
                <td>
                  <span class="provider-badge" [ngClass]="payment.provider.toLowerCase()">
                    {{ payment.provider }}
                  </span>
                </td>
                <td>
                  <span class="plan-badge" [ngClass]="payment.plan.toLowerCase()">{{ payment.plan }}</span>
                </td>
                <td>
                  <span class="amount-text">{{ payment.amount }} {{ payment.currency }}</span>
                </td>
                <td>
                  <span class="status-badge" [ngClass]="payment.status.toLowerCase()">
                    {{ payment.status }}
                  </span>
                </td>
              </tr>
            }
            @if (filteredPayments().length === 0) {
              <tr>
                <td colspan="6" class="empty-state">
                  Aucun paiement trouvé
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .payments-container { padding: 1rem; }
    .header-container { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0; }
    .filter-select { padding: 0.5rem; border-radius: 6px; border: 1px solid var(--border-card); background: var(--bg-card); color: var(--text-main); font-size: 0.9rem; }
    
    .table-wrapper { background: var(--bg-card); border-radius: 12px; box-shadow: var(--glass-shadow); overflow-x: auto; border: 1px solid var(--border-card); }
    .payments-table { width: 100%; border-collapse: collapse; text-align: left; color: var(--text-main); background: transparent; }
    .payments-table th, .payments-table td { padding: 1.25rem 1rem; border-bottom: 1px solid var(--border-card); vertical-align: middle; }
    .payments-table th { background-color: transparent; font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; border-bottom: 2px solid var(--border-card); }
    .payments-table tbody tr { transition: background-color 0.2s; }
    .payments-table tbody tr:hover { background-color: rgba(var(--primary-hsl), 0.05); }
    
    .user-info { display: flex; flex-direction: column; }
    .user-name { font-weight: 600; font-size: 0.9rem; }
    .user-email { font-size: 0.8rem; color: var(--text-muted); }
    
    .amount-text { font-weight: 600; font-size: 1rem; color: var(--text-main); }
    
    .status-badge { padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; display: inline-block; }
    .status-badge.success { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
    .status-badge.pending { background-color: rgba(245, 158, 11, 0.1); color: #f59e0b; }
    .status-badge.failed { background-color: rgba(239, 68, 68, 0.1); color: #ef4444; }

    .plan-badge { padding: 0.25rem 0.75rem; border-radius: 4px; font-size: 0.75rem; font-weight: 600; display: inline-block; background-color: rgba(var(--primary-hsl), 0.1); color: var(--primary); }
    .plan-badge.plus { background-color: rgba(236, 72, 153, 0.1); color: #ec4899; }
    .plan-badge.pro { background-color: rgba(139, 92, 246, 0.1); color: #8b5cf6; }

    .provider-badge { font-weight: 600; font-size: 0.85rem; }
    .provider-badge.stripe { color: #6366f1; }
    .provider-badge.paypal { color: #0284c7; }
    .provider-badge.momo { color: #f59e0b; }
    
    .empty-state { text-align: center; color: var(--text-muted); padding: 3rem !important; }
  `]
})
export class AdminPaymentsComponent implements OnInit {
  private adminService = inject(AdminService);
  t9n = inject(TranslationService);
  
  payments = signal<AdminPaymentDto[]>([]);
  statusFilter = signal<string>('ALL');
  
  filteredPayments = computed(() => {
    const all = this.payments();
    const filter = this.statusFilter();
    if (filter === 'ALL') return all;
    return all.filter(p => p.status === filter);
  });

  ngOnInit() {
    this.adminService.getPayments().subscribe({
      next: (data) => this.payments.set(data),
      error: (err) => console.error('Error fetching payments', err)
    });
  }
}
