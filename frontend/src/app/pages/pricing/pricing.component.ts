import { Component, inject, signal, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../services/toast.service';
import { Router } from '@angular/router';

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
          <h1>Choisissez votre Forfait</h1>
          <p>Débloquez tout le potentiel de Time2Wish avec nos forfaits pensés pour vous.</p>
        </div>

        <div class="pricing-grid">
          <!-- BASIC -->
          <div class="pricing-card" [class.active]="currentPlan() === 'BASIC'">
            <div class="card-header">
              <h3>BASIC</h3>
              <div class="price">Gratuit</div>
              <p>Pour commencer en douceur</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> Jusqu'à 3 anniversaires</li>
              <li><span class="material-symbols-outlined cross">close</span> Idées cadeaux par IA bloquées</li>
              <li><span class="material-symbols-outlined cross">close</span> Pas de rappel par email</li>
              <li><span class="material-symbols-outlined check">check</span> Support Standard</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'BASIC'"
              [class.btn-select]="currentPlan() !== 'BASIC'"
              [disabled]="currentPlan() === 'BASIC' || isLoading()"
              (click)="selectPlan('BASIC')">
              {{ currentPlan() === 'BASIC' ? 'Forfait Actuel' : 'Choisir BASIC' }}
            </button>
          </div>

          <!-- PLUS -->
          <div class="pricing-card popular" [class.active]="currentPlan() === 'PLUS'">
            <div class="popular-badge">Le plus Populaire</div>
            <div class="card-header">
              <h3>PLUS</h3>
              <div class="price">4,99 € <span>/ mois</span></div>
              <p>Idéal pour la famille</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> Jusqu'à 50 anniversaires</li>
              <li><span class="material-symbols-outlined check">check</span> Idées cadeaux par IA incluses</li>
              <li><span class="material-symbols-outlined check">check</span> Rappels par email (1j avant)</li>
              <li><span class="material-symbols-outlined check">check</span> Support Prioritaire</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'PLUS'"
              [class.btn-popular]="currentPlan() !== 'PLUS'"
              [disabled]="currentPlan() === 'PLUS' || isLoading()"
              (click)="selectPlan('PLUS')">
              {{ currentPlan() === 'PLUS' ? 'Forfait Actuel' : 'Choisir PLUS' }}
            </button>
          </div>

          <!-- PRO -->
          <div class="pricing-card" [class.active]="currentPlan() === 'PRO'">
            <div class="card-header">
              <h3>PRO</h3>
              <div class="price">9,99 € <span>/ mois</span></div>
              <p>Aucune limite</p>
            </div>
            <ul class="features-list">
              <li><span class="material-symbols-outlined check">check</span> Anniversaires Illimités</li>
              <li><span class="material-symbols-outlined check">check</span> IA Ultra-personnalisée</li>
              <li><span class="material-symbols-outlined check">check</span> Rappels Configurables</li>
              <li><span class="material-symbols-outlined check">check</span> Support Dédié 24/7</li>
            </ul>
            <button 
              class="btn" 
              [class.btn-current]="currentPlan() === 'PRO'"
              [class.btn-select]="currentPlan() !== 'PRO'"
              [disabled]="currentPlan() === 'PRO' || isLoading()"
              (click)="selectPlan('PRO')">
              {{ currentPlan() === 'PRO' ? 'Forfait Actuel' : 'Choisir PRO' }}
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

  isLoading = signal(false);

  currentPlan() {
    return this.authService.currentUser()?.plan || 'BASIC';
  }

  selectPlan(plan: string) {
    if (confirm(`Voulez-vous vraiment simuler le passage au forfait ${plan} ?`)) {
      this.isLoading.set(true);
      this.http.put('http://localhost:8081/api/users/me/plan', { plan }).subscribe({
        next: (res: any) => {
          this.toastService.success(`Forfait mis à jour vers ${plan} !`);
          
          // Mise à jour locale du token/user
          const user = this.authService.currentUser();
          if (user) {
            this.authService.currentUser.set({ ...user, plan: res.plan });
          }
          this.isLoading.set(false);
        },
        error: (err) => {
          this.toastService.error('Erreur lors du changement de forfait');
          this.isLoading.set(false);
        }
      });
    }
  }
}
