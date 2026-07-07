import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-mock-checkout',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="mock-checkout-page">
      <div class="glass-card checkout-card">
        <div class="header">
          <h2>Passerelle de Paiement Fictive</h2>
          <span class="badge" [class]="provider()">{{ provider() }}</span>
        </div>
        
        <div class="details">
          <p>Vous êtes sur le point de payer pour le plan <strong>{{ plan() }}</strong>.</p>
          <div class="amount">{{ plan() === 'PRO' ? '9,99 €' : '4,99 €' }}</div>
        </div>

        <div class="actions">
          <button class="btn btn-select cancel-btn" (click)="cancel()" [disabled]="isLoading()">Annuler</button>
          <button class="btn btn-popular pay-btn" (click)="simulatePayment()" [disabled]="isLoading()">
            {{ isLoading() ? 'Traitement...' : 'Simuler le Paiement' }}
          </button>
        </div>
        
        <p class="disclaimer">
          Ceci est une page de simulation (Mock). En production, vous seriez redirigé vers l'interface de Stripe, PayPal, ou de l'opérateur Mobile Money.
        </p>
      </div>
    </div>
  `,
  styles: [`
    .mock-checkout-page {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: var(--bg-main);
    }
    .checkout-card {
      padding: 3rem;
      max-width: 500px;
      width: 100%;
      display: flex;
      flex-direction: column;
      gap: 2rem;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid rgba(255,255,255,0.1);
      padding-bottom: 1rem;
    }
    .header h2 { margin: 0; font-size: 1.5rem; }
    .badge {
      padding: 5px 10px;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: bold;
    }
    .badge.STRIPE { background: #635bff; color: white; }
    .badge.PAYPAL { background: #003087; color: white; }
    .badge.MOMO { background: #ffcc00; color: #333; }
    
    .details {
      text-align: center;
    }
    .amount {
      font-size: 3rem;
      font-weight: bold;
      color: var(--primary-color);
      margin-top: 1rem;
    }
    
    .actions {
      display: flex;
      gap: 1rem;
      margin-top: 1rem;
    }
    .actions .btn { 
      flex: 1; 
      padding: 1rem;
      border-radius: 8px;
      font-weight: 600;
      font-size: 1rem;
      cursor: pointer;
      transition: all 0.2s;
      border: none;
    }
    
    .cancel-btn {
      background: transparent;
      color: var(--text-main);
      border: 1px solid var(--border-card) !important;
    }
    .cancel-btn:hover:not(:disabled) {
      background: rgba(255, 255, 255, 0.05);
    }
    
    .pay-btn {
      background: #10b981;
      color: white;
    }
    .pay-btn:hover:not(:disabled) {
      background: #059669;
      transform: translateY(-2px);
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    
    .btn:disabled {
      opacity: 0.7;
      cursor: not-allowed;
    }
    
    .disclaimer {
      font-size: 0.8rem;
      color: var(--text-muted);
      text-align: center;
      margin-top: 1rem;
    }
  `]
})
export class MockCheckoutComponent implements OnInit {
  route = inject(ActivatedRoute);
  router = inject(Router);
  http = inject(HttpClient);
  authService = inject(AuthService);

  provider = signal<string>('STRIPE');
  plan = signal<string>('PLUS');
  isLoading = signal<boolean>(false);

  ngOnInit() {
    this.route.queryParams.subscribe(params => {
      if (params['provider']) this.provider.set(params['provider']);
      if (params['plan']) this.plan.set(params['plan']);
    });
  }

  cancel() {
    this.router.navigate(['/payment/cancel']);
  }

  simulatePayment() {
    this.isLoading.set(true);
    const user = this.authService.currentUser();
    if (!user) return;

    // Simulate webhook call to backend
    this.http.post(environment.apiUrl + '/payments/mock-webhook', {
      userId: user.id,
      provider: this.provider(),
      plan: this.plan()
    }).subscribe({
      next: () => {
        // En vrai, c'est Stripe qui appelle le webhook en arrière-plan,
        // puis redirige l'utilisateur vers /payment/success.
        setTimeout(() => {
          this.router.navigate(['/payment/success']);
        }, 1000);
      },
      error: () => {
        this.isLoading.set(false);
        alert('Erreur du webhook simulé');
      }
    });
  }
}
