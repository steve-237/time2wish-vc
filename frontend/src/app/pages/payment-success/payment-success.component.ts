import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-payment-success',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="payment-result-page">
      <div class="glass-card result-card">
        <div class="icon-circle success">
          <span class="material-symbols-outlined">check_circle</span>
        </div>
        <h1>{{ t9n.t('payment.success_title') || 'Paiement Réussi !' }}</h1>
        <p>{{ t9n.t('payment.success_desc') || 'Merci pour votre abonnement. Vos nouvelles fonctionnalités sont débloquées.' }}</p>
        
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
    .icon-circle.success {
      background: rgba(34, 197, 94, 0.2);
      color: #22c55e;
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
export class PaymentSuccessComponent implements OnInit {
  router = inject(Router);
  authService = inject(AuthService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);

  ngOnInit() {
    // Recharger la session pour récupérer le nouveau plan
    this.authService.refreshSession().subscribe({
      next: () => {
        this.toastService.success('Votre abonnement est actif.');
      }
    });
  }

  goToDashboard() {
    this.router.navigate(['/dashboard']);
  }
}
