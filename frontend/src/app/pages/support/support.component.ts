import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SupportService, SupportTicket } from '../../services/support.service';
import { ToastService } from '../../services/toast.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-support',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  template: `
    <div class="support-container">
      <div class="header-container">
        <h2 class="page-title">Support & Assistance</h2>
        <p class="page-subtitle">Contactez notre équipe pour toute question ou problème.</p>
        <button class="btn-PRO mt-3" (click)="isModalOpen.set(true)" *ngIf="!isModalOpen()">
          <span class="material-symbols-outlined">add_comment</span>
          Nouveau Ticket
        </button>
      </div>

      <!-- New Ticket Form -->
      @if (isModalOpen()) {
        <div class="glass-card mb-4">
          <h3>Ouvrir un nouveau ticket</h3>
          <div class="form-group">
            <label class="form-label">Sujet</label>
            <input type="text" class="form-control" [(ngModel)]="newSubject" placeholder="Ex: Problème avec mon paiement">
          </div>
          <div class="form-group mt-3">
            <label class="form-label">Message</label>
            <textarea class="form-control" rows="4" [(ngModel)]="newMessage" placeholder="Décrivez votre problème en détail..."></textarea>
          </div>
          <div class="mt-4 flex-gap">
            <button class="btn btn-secondary" (click)="isModalOpen.set(false)">Annuler</button>
            <button class="btn-PRO" (click)="submitTicket()" [disabled]="!newSubject || !newMessage || isSubmitting()">
              {{ isSubmitting() ? 'Envoi...' : 'Envoyer la demande' }}
            </button>
          </div>
        </div>
      }

      <!-- Tickets List -->
      <div class="tickets-list">
        <h3>Vos tickets récents</h3>
        @if (tickets().length === 0) {
          <div class="empty-state">
            <span class="material-symbols-outlined">chat_bubble_outline</span>
            <p>Vous n'avez aucun ticket de support ouvert.</p>
          </div>
        }
        @for (ticket of tickets(); track ticket.id) {
          <div class="ticket-card glass-card">
            <div class="ticket-header">
              <div class="ticket-info">
                <h4>{{ ticket.subject }}</h4>
                <span class="ticket-date">{{ ticket.createdAt | date:'short' }}</span>
              </div>
              <span class="badge" [ngClass]="{
                'status-open': ticket.status === 'OPEN',
                'status-resolved': ticket.status === 'RESOLVED',
                'status-closed': ticket.status === 'CLOSED'
              }">
                {{ ticket.status === 'OPEN' ? 'Ouvert' : (ticket.status === 'RESOLVED' ? 'Résolu' : 'Fermé') }}
              </span>
            </div>
            <div class="ticket-body">
              <p class="user-message">{{ ticket.message }}</p>
              
              @if (ticket.adminReply) {
                <div class="admin-reply-box">
                  <div class="reply-header">
                    <span class="material-symbols-outlined icon-admin">support_agent</span>
                    <strong>Réponse de l'équipe</strong>
                    <span class="reply-date">{{ ticket.repliedAt | date:'short' }}</span>
                  </div>
                  <p class="reply-message">{{ ticket.adminReply }}</p>
                </div>
              } @else {
                <div class="waiting-reply">
                  <span class="material-symbols-outlined">pending</span>
                  <em>En attente d'une réponse de notre équipe...</em>
                </div>
              }
            </div>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .support-container { max-width: 800px; margin: 0 auto; padding: 2rem 1rem; }
    .header-container { margin-bottom: 2rem; }
    .page-title { font-size: 1.8rem; font-weight: 700; color: var(--text-main); margin-bottom: 0.5rem; }
    .page-subtitle { color: var(--text-muted); font-size: 1rem; }
    .mb-4 { margin-bottom: 1.5rem; }
    .mt-3 { margin-top: 1rem; }
    .mt-4 { margin-top: 1.5rem; }
    .flex-gap { display: flex; gap: 1rem; }
    
    .ticket-card { padding: 1.5rem; margin-bottom: 1rem; border: 1px solid var(--border-card); }
    .ticket-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border-card); }
    .ticket-info h4 { margin: 0 0 0.5rem 0; font-size: 1.1rem; color: var(--text-main); }
    .ticket-date { font-size: 0.85rem; color: var(--text-muted); }
    .user-message { color: var(--text-main); line-height: 1.5; white-space: pre-wrap; margin-bottom: 1.5rem; }
    
    .badge { padding: 0.35rem 0.75rem; border-radius: 6px; font-size: 0.75rem; font-weight: 600; }
    .status-open { background-color: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .status-resolved { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
    .status-closed { background-color: rgba(100, 116, 139, 0.1); color: #64748b; }
    
    .admin-reply-box { background: rgba(var(--primary-hsl), 0.05); border-left: 3px solid var(--primary); padding: 1rem; border-radius: 0 8px 8px 0; }
    .reply-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; color: var(--primary); }
    .reply-date { font-size: 0.8rem; color: var(--text-muted); margin-left: auto; }
    .icon-admin { font-size: 1.2rem; }
    .reply-message { color: var(--text-main); margin: 0; line-height: 1.5; white-space: pre-wrap; }
    
    .waiting-reply { display: flex; align-items: center; gap: 0.5rem; color: var(--text-muted); font-size: 0.9rem; padding: 0.5rem; background: rgba(0,0,0,0.02); border-radius: 8px; }
    
    .empty-state { text-align: center; padding: 3rem; background: var(--bg-card); border-radius: 12px; border: 1px dashed var(--border-card); color: var(--text-muted); }
    .empty-state .material-symbols-outlined { font-size: 3rem; opacity: 0.5; margin-bottom: 1rem; }
  `]
})
export class SupportComponent implements OnInit {
  private supportService = inject(SupportService);
  private toast = inject(ToastService);

  tickets = signal<SupportTicket[]>([]);
  isModalOpen = signal(false);
  isSubmitting = signal(false);
  
  newSubject = '';
  newMessage = '';

  ngOnInit() {
    this.loadTickets();
  }

  loadTickets() {
    this.supportService.getMyTickets().subscribe({
      next: (data) => this.tickets.set(data),
      error: () => this.toast.error('Erreur lors du chargement des tickets')
    });
  }

  submitTicket() {
    if (!this.newSubject || !this.newMessage) return;
    this.isSubmitting.set(true);

    this.supportService.createTicket(this.newSubject, this.newMessage).subscribe({
      next: (newTicket) => {
        this.tickets.update(t => [newTicket, ...t]);
        this.isModalOpen.set(false);
        this.newSubject = '';
        this.newMessage = '';
        this.isSubmitting.set(false);
        this.toast.success('Ticket envoyé avec succès');
      },
      error: () => {
        this.toast.error("Erreur lors de l'envoi du ticket");
        this.isSubmitting.set(false);
      }
    });
  }
}
