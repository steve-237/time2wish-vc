import { Component, inject, signal, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { Router } from '@angular/router';
import { TranslationService } from '../../services/translation.service';
import { environment } from '../../environments/environment';
@Component({
  selector: 'app-pricing',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="pricing-modal-overlay" (click)="close.emit()">
      <div class="pricing-modal-content glass-panel" (click)="$event.stopPropagation()">
        <button class="icon-btn close-modal-btn" (click)="close.emit()">
          <span class="material-symbols-outlined">close</span>
        </button>
        <div class="pricing-header">
          <h1>{{ t9n.t('pricing.title') }}</h1>
          <p>{{ t9n.t('pricing.subtitle') }}</p>
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

  isLoading = signal(false);

  currentPlan() {
    return this.authService.currentUser()?.plan || 'BASIC';
  }

  selectPlan(plan: string) {
    const confirmMsg = this.t9n.t('pricing.confirm_change').replace('%s', plan);
    if (confirm(confirmMsg)) {
      this.isLoading.set(true);
      this.http.put(environment.apiUrl + '/users/me/plan', { plan }).subscribe({
        next: (res: any) => {
          const successMsg = this.t9n.t('pricing.success_change').replace('%s', plan);
          this.toastService.success(successMsg);
          
          // Mise à jour locale du token/user
          const user = this.authService.currentUser();
          if (user) {
            this.authService.currentUser.set({ ...user, plan: res.plan });
          }
          this.isLoading.set(false);
        },
        error: (err) => {
          this.toastService.error(this.t9n.t('pricing.error_change'));
          this.isLoading.set(false);
        }
      });
    }
  }
}
