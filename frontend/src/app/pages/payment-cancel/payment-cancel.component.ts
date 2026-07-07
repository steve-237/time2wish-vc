import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-payment-cancel',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="payment-result-page">
      <div class="glass-card result-card">
        <div class="icon-circle cancel">
          <span class="material-symbols-outlined">cancel</span>
        </div>
        <h1>{{ t9n.t('payment.cancel_title') || 'Paiement Annulé' }}</h1>
        <p>{{ t9n.t('payment.cancel_desc') || 'Vous avez annulé le processus de paiement. Aucun prélèvement n\\'a été effectué.' }}</p>
        
        <button class="btn-return" (click)="goToDashboard()">
          {{ t9n.t('payment.back_to_dashboard') || 'Retour au tableau de bord' }}
        </button>
      </div>
    </div>
  `,
  styles: [`
    .payment-result-page {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: var(--bg-main);
    }
    .result-card {
      padding: 3rem;
      text-align: center;
      max-width: 500px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 1.5rem;
    }
    .icon-circle {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      margin-bottom: 1rem;
    }
    .icon-circle.cancel {
      background: rgba(239, 68, 68, 0.2);
      color: #ef4444;
    }
    .icon-circle span {
      font-size: 40px;
    }
    .btn-return {
      margin-top: 1rem;
      padding: 1rem 2rem;
      background: #8b5cf6;
      color: white;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-return:hover {
      background: #7c3aed;
      transform: translateY(-2px);
      box-shadow: 0 4px 6px rgba(0,0,0,0.2);
    }
  `]
})
export class PaymentCancelComponent {
  router = inject(Router);
  t9n = inject(TranslationService);

  goToDashboard() {
    this.router.navigate(['/dashboard']);
  }
}
