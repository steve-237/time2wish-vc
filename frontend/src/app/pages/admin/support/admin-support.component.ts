import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SupportService, SupportTicket } from '../../../services/support.service';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-support',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  template: `
    <div class="support-container">
      <div class="header-container">
        <h2 class="page-title">Support & Tickets</h2>
        <p class="page-subtitle">Gérez les demandes de support des utilisateurs</p>
      </div>

      <div class="table-wrapper">
        <table class="tickets-table">
          <thead>
            <tr>
              <th style="width: 80px;">ID</th>
              <th>Utilisateur</th>
              <th>Sujet</th>
              <th>Statut</th>
              <th>Date</th>
              <th style="text-align: right;">Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (ticket of tickets(); track ticket.id) {
              <tr [class.unread]="ticket.status === 'OPEN'">
                <td class="id-cell">#{{ ticket.id }}</td>
                <td>
                  <div class="user-cell">
                    <span class="user-name">{{ ticket.user?.fullName }}</span>
                    <span class="user-email">{{ ticket.user?.email }}</span>
                  </div>
                </td>
                <td class="subject-cell">{{ ticket.subject }}</td>
                <td>
                  <select [value]="ticket.status" (change)="onStatusChange(ticket, $event)" class="form-select status-select" [ngClass]="{
                    'status-open': ticket.status === 'OPEN',
                    'status-resolved': ticket.status === 'RESOLVED',
                    'status-closed': ticket.status === 'CLOSED'
                  }">
                    <option value="OPEN">Ouvert</option>
                    <option value="RESOLVED">Résolu</option>
                    <option value="CLOSED">Fermé</option>
                  </select>
                </td>
                <td class="date-cell">{{ ticket.createdAt | date:'dd/MM/yyyy HH:mm' }}</td>
                <td class="actions-cell">
                  <button class="btn btn-secondary btn-sm" (click)="openTicket(ticket)">
                    <span class="material-symbols-outlined">visibility</span>
                    Traiter
                  </button>
                </td>
              </tr>
            } @empty {
              <tr>
                <td colspan="6" class="empty-state">Aucun ticket trouvé.</td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      <!-- Ticket Modal -->
      @if (selectedTicket()) {
        <div class="tm-modal-overlay">
          <div class="tm-modal-content ticket-modal">
            <div class="modal-header flex-between">
              <div>
                <span class="ticket-id">Ticket #{{ selectedTicket()?.id }}</span>
                <h3>{{ selectedTicket()?.subject }}</h3>
              </div>
              <button class="icon-btn" (click)="selectedTicket.set(null)">
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>
            
            <div class="modal-body">
              <div class="user-message-box">
                <div class="box-header">
                  <span class="user-name">{{ selectedTicket()?.user?.fullName }}</span>
                  <span class="date">{{ selectedTicket()?.createdAt | date:'medium' }}</span>
                </div>
                <p>{{ selectedTicket()?.message }}</p>
              </div>

              @if (selectedTicket()?.adminReply) {
                <div class="admin-message-box mt-3">
                  <div class="box-header">
                    <span class="admin-name">Réponse (Admin)</span>
                    <span class="date">{{ selectedTicket()?.repliedAt | date:'medium' }}</span>
                  </div>
                  <p>{{ selectedTicket()?.adminReply }}</p>
                </div>
              }

              <div class="reply-section mt-4">
                <h4>Répondre à l'utilisateur</h4>
                <textarea class="form-control" rows="4" [(ngModel)]="replyMessage" placeholder="Écrivez votre réponse ici..."></textarea>
                <div class="mt-3" style="text-align: right;">
                  <button class="btn-PRO" (click)="submitReply()" [disabled]="!replyMessage || isSubmitting()">
                    <span class="material-symbols-outlined">send</span>
                    Envoyer la réponse
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .support-container { padding: 1rem; }
    .header-container { margin-bottom: 2rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .table-wrapper { background: var(--bg-card); border-radius: 12px; box-shadow: var(--glass-shadow); overflow-x: auto; border: 1px solid var(--border-card); }
    .tickets-table { width: 100%; border-collapse: collapse; text-align: left; color: var(--text-main); }
    .tickets-table th, .tickets-table td { padding: 1rem; border-bottom: 1px solid var(--border-card); vertical-align: middle; }
    .tickets-table th { font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; border-bottom: 2px solid var(--border-card); }
    .tickets-table tr.unread { background: rgba(59, 130, 246, 0.05); }
    .tickets-table tr.unread .subject-cell { font-weight: 600; }
    
    .id-cell { color: var(--text-muted); font-family: monospace; }
    .user-cell { display: flex; flex-direction: column; }
    .user-name { font-weight: 600; font-size: 0.9rem; }
    .user-email { color: var(--text-muted); font-size: 0.8rem; }
    .subject-cell { color: var(--text-main); }
    .date-cell { color: var(--text-muted); font-size: 0.85rem; }
    .actions-cell { text-align: right; }
    
    .btn-sm { padding: 0.25rem 0.75rem; font-size: 0.85rem; display: inline-flex; align-items: center; gap: 0.25rem; }
    .btn-sm .material-symbols-outlined { font-size: 1rem; }
    
    .status-select { padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.8rem; font-weight: 600; border: none; outline: none; cursor: pointer; }
    .status-open { background-color: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .status-resolved { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
    .status-closed { background-color: rgba(100, 116, 139, 0.1); color: #64748b; }
    
    .empty-state { text-align: center; padding: 3rem; color: var(--text-muted); }

    .ticket-modal { max-width: 700px; width: 90%; padding: 0; overflow: hidden; }
    .modal-header { padding: 1.5rem; border-bottom: 1px solid var(--border-card); background: var(--bg-main); }
    .modal-header h3 { margin: 0.25rem 0 0 0; font-size: 1.25rem; color: var(--text-main); }
    .ticket-id { font-size: 0.85rem; color: var(--primary); font-weight: 600; text-transform: uppercase; }
    
    .modal-body { padding: 1.5rem; max-height: 70vh; overflow-y: auto; }
    .user-message-box { background: var(--bg-main); padding: 1.25rem; border-radius: 8px; border: 1px solid var(--border-card); }
    .admin-message-box { background: rgba(var(--primary-hsl), 0.05); padding: 1.25rem; border-radius: 8px; border-left: 3px solid var(--primary); }
    .box-header { display: flex; justify-content: space-between; margin-bottom: 0.75rem; border-bottom: 1px solid rgba(0,0,0,0.05); padding-bottom: 0.5rem; }
    body.dark-theme .box-header { border-bottom-color: rgba(255,255,255,0.05); }
    .box-header .date { font-size: 0.8rem; color: var(--text-muted); }
    .admin-name { font-weight: 600; color: var(--primary); }
    .user-message-box p, .admin-message-box p { margin: 0; white-space: pre-wrap; line-height: 1.5; color: var(--text-main); }
    
    .reply-section h4 { margin: 0 0 1rem 0; color: var(--text-main); }
    .mt-3 { margin-top: 1rem; }
    .mt-4 { margin-top: 1.5rem; }
  `]
})
export class AdminSupportComponent implements OnInit {
  private supportService = inject(SupportService);
  private toast = inject(ToastService);

  tickets = signal<SupportTicket[]>([]);
  selectedTicket = signal<SupportTicket | null>(null);
  replyMessage = '';
  isSubmitting = signal(false);

  ngOnInit() {
    this.loadTickets();
  }

  loadTickets() {
    this.supportService.getAllTickets().subscribe({
      next: (data) => this.tickets.set(data),
      error: () => this.toast.error('Erreur lors du chargement des tickets')
    });
  }

  openTicket(ticket: SupportTicket) {
    this.selectedTicket.set(ticket);
    this.replyMessage = '';
  }

  onStatusChange(ticket: SupportTicket, event: Event) {
    const newStatus = (event.target as HTMLSelectElement).value;
    this.supportService.updateTicketStatus(ticket.id, newStatus).subscribe({
      next: (updated) => {
        this.tickets.update(arr => arr.map(t => t.id === updated.id ? updated : t));
        this.toast.success('Statut mis à jour');
      },
      error: () => this.toast.error('Erreur lors de la mise à jour')
    });
  }

  submitReply() {
    const ticket = this.selectedTicket();
    if (!ticket || !this.replyMessage) return;

    this.isSubmitting.set(true);
    this.supportService.replyToTicket(ticket.id, this.replyMessage).subscribe({
      next: (updated) => {
        this.tickets.update(arr => arr.map(t => t.id === updated.id ? updated : t));
        this.selectedTicket.set(null);
        this.isSubmitting.set(false);
        this.toast.success('Réponse envoyée');
      },
      error: () => {
        this.toast.error("Erreur lors de l'envoi");
        this.isSubmitting.set(false);
      }
    });
  }
}
