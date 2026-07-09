import { Component, EventEmitter, Output, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FeedbackService } from '../../services/feedback.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-feedback-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="modal-backdrop" (click)="close.emit()">
      <div class="modal-container" (click)="$event.stopPropagation()">
        
        @if (isSubmitted()) {
          <div class="success-view text-center">
            <span class="material-symbols-outlined text-success" style="font-size: 4rem; margin-bottom: 1rem;">check_circle</span>
            <h3 style="margin-bottom: 0.5rem;">Merci pour votre retour !</h3>
            <p class="text-muted" style="margin-bottom: 2rem;">Votre avis nous aide énormément à améliorer l'application.</p>
            <button class="btn-PRO" (click)="close.emit()" style="width: 100%;">Fermer</button>
          </div>
        } @else {
          <div class="modal-header">
            <h3>Donnez-nous votre avis</h3>
            <button class="icon-btn" (click)="close.emit()">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="modal-body">
            <p class="text-center text-muted mb-4">Comment évaluez-vous votre expérience avec Time2Wish ?</p>
            
            <div class="stars-container flex-center mb-4">
              @for (star of [1, 2, 3, 4, 5]; track star) {
                <span class="material-symbols-outlined star-icon" 
                      [class.active]="star <= rating()" 
                      (click)="rating.set(star)">
                  star
                </span>
              }
            </div>

            <div class="form-group">
              <label class="form-label">Votre commentaire (optionnel)</label>
              <textarea class="form-control" rows="4" [(ngModel)]="comment" placeholder="Qu'avez-vous particulièrement apprécié ? Que pourrions-nous améliorer ?"></textarea>
            </div>
          </div>

          <div class="modal-footer mt-4 flex-gap">
            <button class="btn btn-secondary" (click)="close.emit()">Annuler</button>
            <button class="btn-PRO" (click)="submit()" [disabled]="rating() === 0 || isSubmitting()">
              {{ isSubmitting() ? 'Envoi...' : 'Envoyer mon avis' }}
            </button>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .modal-backdrop {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(0,0,0,0.5);
      backdrop-filter: blur(4px);
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1rem;
    }
    .modal-container {
      background: var(--bg-card);
      border-radius: 24px;
      padding: 2rem;
      width: 100%;
      max-width: 500px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.2);
      border: 1px solid var(--border-card);
      animation: modalSlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes modalSlideUp {
      from { opacity: 0; transform: translateY(40px) scale(0.95); }
      to { opacity: 1; transform: translateY(0) scale(1); }
    }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
    }
    .modal-header h3 { margin: 0; font-size: 1.3rem; }
    .stars-container { gap: 8px; }
    .star-icon {
      font-size: 2.5rem;
      color: var(--border-card);
      cursor: pointer;
      transition: all 0.2s;
    }
    .star-icon:hover { transform: scale(1.1); }
    .star-icon.active { color: #f59e0b; font-variation-settings: 'FILL' 1; }
    .text-success { color: #10b981; }
    .flex-gap { display: flex; gap: 1rem; }
    .flex-gap button { flex: 1; }
  `]
})
export class FeedbackModalComponent {
  @Output() close = new EventEmitter<void>();
  
  private feedbackService = inject(FeedbackService);
  private toast = inject(ToastService);

  rating = signal<number>(0);
  comment = '';
  isSubmitting = signal(false);
  isSubmitted = signal(false);

  submit() {
    if (this.rating() === 0) return;
    this.isSubmitting.set(true);

    this.feedbackService.submitFeedback({ rating: this.rating(), comment: this.comment }).subscribe({
      next: () => {
        this.isSubmitting.set(false);
        this.isSubmitted.set(true);
      },
      error: () => {
        this.toast.error('Une erreur est survenue lors de l\'envoi.');
        this.isSubmitting.set(false);
      }
    });
  }
}
