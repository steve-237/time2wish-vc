import { Component, inject, signal, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { Router } from '@angular/router';
import { TranslationService } from '../../services/translation.service';
import { PromoService } from '../../services/promo.service';
import { FormsModule } from '@angular/forms';
import { environment } from '../../../environments/environment';
@Component({
  selector: 'app-pricing',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="pricing-modal-overlay" (click)="close.emit()">
      <div class="pricing-modal-content glass-panel" (click)="$event.stopPropagation()">
        <button class="icon-btn close-modal-btn" (click)="close.emit()">
          <span class="material-symbols-outlined">close</span>
        </button>
        <div class="pricing-header">
          <h1>{{ t9n.t('pricing.title') }}</h1>
          <p>{{ t9n.t('pricing.subtitle') }}</p>
          <div style="margin-top: 16px; display: inline-flex; align-items: center; gap: 8px; background: rgba(245, 158, 11, 0.1); padding: 8px 16px; border-radius: 20px; border: 1px solid rgba(245, 158, 11, 0.2);">
            <span class="material-symbols-outlined" style="color: #f59e0b;">generating_tokens</span>
            <span style="font-size: 0.9rem; color: var(--text-muted);">
              <strong>WishCoins</strong> : Utilisez-les pour générer des idées de cadeaux et vœux avec l'IA. Obtenez-les via nos forfaits !
            </span>
          </div>
        </div>

        <div class="pricing-grid">
          <!-- BASIC -->
          <div class="pricing-card" [class.active]="currentPlan() === 'BASIC'">
            <div class="card-header">
              <h3>BASIC</h3>
              <div class="price">{{ t9n.t('pricing.free') }}</div>
              <p>{{ t9n.t('pricing.basic_desc') }}</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.basic_f1') }}</li>
              <li><span class="material-symbols-outlined cross">close</span> {{ t9n.t('pricing.basic_f2') }}</li>
              <li><span class="material-symbols-outlined cross">close</span> {{ t9n.t('pricing.basic_f3') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.basic_f4') }}</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'BASIC'"
              [class.btn-select]="currentPlan() !== 'BASIC'"
              [disabled]="currentPlan() === 'BASIC' || isLoading()"
              (click)="selectPlan('BASIC')">
              {{ currentPlan() === 'BASIC' ? t9n.t('pricing.btn_current') : t9n.t('pricing.btn_choose') + ' BASIC' }}
            </button>
          </div>

          <!-- PLUS -->
          <div class="pricing-card popular" [class.active]="currentPlan() === 'PLUS'">
            <div class="popular-badge">{{ t9n.t('pricing.popular_badge') }}</div>
            <div class="card-header">
              <h3>PLUS</h3>
              <div class="price">4,99 € <span>{{ t9n.t('pricing.per_month') }}</span></div>
              <p>{{ t9n.t('pricing.plus_desc') }}</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.plus_f1') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.plus_f2') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.plus_f3') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.plus_f4') }}</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'PLUS'"
              [class.btn-popular]="currentPlan() !== 'PLUS'"
              [disabled]="currentPlan() === 'PLUS' || isLoading()"
              (click)="selectPlan('PLUS')">
              {{ currentPlan() === 'PLUS' ? t9n.t('pricing.btn_current') : t9n.t('pricing.btn_choose') + ' PLUS' }}
            </button>
          </div>

          <!-- PRO -->
          <div class="pricing-card" [class.active]="currentPlan() === 'PRO'">
            <div class="card-header">
              <h3>PRO</h3>
              <div class="price">9,99 € <span>{{ t9n.t('pricing.per_month') }}</span></div>
              <p>{{ t9n.t('pricing.pro_desc') }}</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.pro_f1') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.pro_f2') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.pro_f3') }}</li>
              <li><span class="material-symbols-outlined check">check</span> {{ t9n.t('pricing.pro_f4') }}</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'PRO'"
              [class.btn-select]="currentPlan() !== 'PRO'"
              [disabled]="currentPlan() === 'PRO' || isLoading()"
              (click)="selectPlan('PRO')">
              {{ currentPlan() === 'PRO' ? t9n.t('pricing.btn_current') : t9n.t('pricing.btn_choose') + ' PRO' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Confirmation Modal -->
      <!-- Payment Method Selection Modal -->
      @if (planToConfirm()) {
        <div class="pricing-modal-overlay" style="z-index: 100000;" (click)="cancelPlanChange()">
          <div class="pricing-modal-content confirm-modal-content glass-panel" style="max-width: 500px;" (click)="$event.stopPropagation()">
            <div class="pricing-header" style="margin-bottom: 2rem;">
              <h2 style="font-size: 1.5rem;">{{ t9n.t('pricing.choose_payment_method') || 'Moyen de paiement' }}</h2>
            </div>
            <p style="text-align: center; margin-bottom: 2rem;">
              {{ t9n.t('pricing.confirm_change') ? t9n.t('pricing.confirm_change').replace('%s', planToConfirm()!) : 'Vous allez souscrire au forfait ' + planToConfirm() + '.' }}
            </p>
            
            <div class="payment-methods" style="display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem;">
              
              <!-- Promo Code Section -->
              <div class="promo-section" style="background: rgba(var(--primary-hsl), 0.05); padding: 1rem; border-radius: 8px; margin-bottom: 1rem; border: 1px dashed var(--primary);">
                <label style="display: block; font-size: 0.85rem; margin-bottom: 0.5rem; color: var(--text-muted);">Avez-vous un code promo ?</label>
                <div style="display: flex; gap: 0.5rem;">
                  <input type="text" [(ngModel)]="promoCode" placeholder="Code (ex: SUMMER20)" style="flex: 1; padding: 0.5rem; border-radius: 6px; border: 1px solid var(--border-card); background: var(--bg-main); color: var(--text-main); text-transform: uppercase;">
                  <button class="btn btn-primary" [disabled]="!promoCode || isCheckingPromo()" (click)="applyPromo()" style="padding: 0.5rem 1rem;">
                    {{ isCheckingPromo() ? '...' : 'Appliquer' }}
                  </button>
                </div>
                @if (appliedDiscount()) {
                  <div style="margin-top: 0.5rem; color: #10b981; font-weight: bold; font-size: 0.9rem;">
                    <span class="material-symbols-outlined" style="font-size: 1rem; vertical-align: middle;">check_circle</span>
                    Code appliqué : -{{ appliedDiscount() }}%
                  </div>
                  <div style="margin-top: 0.5rem; font-size: 1.1rem;">
                    Nouveau prix : <span style="text-decoration: line-through; opacity: 0.5; margin-right: 0.5rem;">{{ getBasePrice() }}€</span>
                    <strong>{{ getDiscountedPrice() }}€</strong>
                  </div>
                }
              </div>

              <button class="btn btn-select" [disabled]="isLoading()" (click)="checkoutWith('STRIPE')" style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                <span class="material-symbols-outlined">credit_card</span>
                Carte de Crédit (Stripe)
              </button>
              
              <button class="btn btn-select" [disabled]="isLoading()" (click)="checkoutWith('PAYPAL')" style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                <span class="material-symbols-outlined">account_balance_wallet</span>
                PayPal
              </button>
              
              <button class="btn btn-select" [disabled]="isLoading()" (click)="checkoutWith('MOMO')" style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                <span class="material-symbols-outlined">phone_iphone</span>
                Mobile Money (MTN / Orange)
              </button>

              <button class="btn btn-popular" [disabled]="isLoading()" (click)="switchPlanDirectly()" style="display: flex; align-items: center; justify-content: center; gap: 10px; margin-top: 8px; background: linear-gradient(135deg, #10b981, #059669); color: #fff; width: 100%; padding: 12px; border-radius: 8px; border: none; font-weight: 700; cursor: pointer;">
                <span class="material-symbols-outlined">bolt</span>
                Activer le Forfait Immédiatement
              </button>
            </div>

            <div style="display: flex; justify-content: center;">
              <button class="btn btn-select" style="width: auto; background: transparent; border: 1px solid var(--text-color);" (click)="cancelPlanChange()">{{ t9n.t('form.btn_cancel') || 'Annuler' }}</button>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styleUrl: './pricing.scss'
})
export class PricingComponent {
  @Output() close = new EventEmitter<void>();
  authService = inject(AuthService);
  http = inject(HttpClient);
  toastService = inject(ToastService);
  router = inject(Router);
  t9n = inject(TranslationService);
  promoService = inject(PromoService);

  isLoading = signal(false);
  planToConfirm = signal<string | null>(null);
  
  promoCode = '';
  isCheckingPromo = signal(false);
  appliedDiscount = signal<number | null>(null);

  currentPlan() {
    return this.authService.currentUser()?.plan || 'BASIC';
  }

  selectPlan(plan: string) {
    this.planToConfirm.set(plan);
  }

  cancelPlanChange() {
    this.planToConfirm.set(null);
    this.promoCode = '';
    this.appliedDiscount.set(null);
  }

  getBasePrice(): number {
    return this.planToConfirm() === 'PRO' ? 9.99 : 4.99;
  }

  getDiscountedPrice(): string {
    const base = this.getBasePrice();
    const discount = this.appliedDiscount();
    if (!discount) return base.toString();
    const newPrice = base * (1 - (discount / 100));
    return newPrice.toFixed(2);
  }

  applyPromo() {
    if (!this.promoCode) return;
    this.isCheckingPromo.set(true);
    this.promoService.validatePromo(this.promoCode).subscribe({
      next: (res) => {
        this.appliedDiscount.set(res.discountPercentage);
        this.isCheckingPromo.set(false);
        this.toastService.success('Code promo appliqué !');
      },
      error: (err) => {
        this.appliedDiscount.set(null);
        this.isCheckingPromo.set(false);
        this.toastService.error(err.error?.message || 'Code invalide');
      }
    });
  }

  switchPlanDirectly() {
    const plan = this.planToConfirm();
    if (!plan) return;

    this.isLoading.set(true);
    const token = this.authService.accessToken();

    this.http.put<{message: string, plan: string}>(`${environment.apiUrl}/users/me/plan`, { plan }, {
      headers: { Authorization: `Bearer ${token}` }
    }).subscribe({
      next: () => {
        this.authService.reloadUserProfile().subscribe(() => {
          this.isLoading.set(false);
          this.toastService.success(`Forfait mis à jour avec succès : ${plan} !`);
          this.cancelPlanChange();
          this.close.emit();
        });
      },
      error: (err) => {
        this.isLoading.set(false);
        this.toastService.error(err.error?.message || 'Erreur lors de la mise à jour du forfait');
      }
    });
  }

  checkoutWith(provider: string) {
    const plan = this.planToConfirm();
    if (!plan) return;
    
    this.isLoading.set(true);
    const payload = { 
      plan, 
      provider,
      promoCode: this.appliedDiscount() ? this.promoCode.toUpperCase() : null 
    };

    this.http.post<{url: string}>(environment.apiUrl + '/payments/checkout', payload).subscribe({
      next: (res) => {
        // Redirection vers la passerelle de paiement
        window.location.href = res.url;
      },
      error: (err) => {
        this.toastService.error('Erreur lors de l\'initialisation du paiement');
        this.isLoading.set(false);
      }
    });
  }
}
