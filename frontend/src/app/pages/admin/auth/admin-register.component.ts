import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ToastService } from '../../../services/toast.service';
import { environment } from '../../../../environments/environment';
import { TranslationService } from '../../../services/translation.service';
@Component({
  selector: 'app-admin-register',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  template: `
    <div class="admin-auth-container">
      <div class="admin-auth-card">
        <div class="admin-auth-header">
          <div class="admin-logo">
            <span class="material-symbols-outlined logo-icon">shield_person</span>
          </div>
          <h1>{{ t9n.t('admin.register.title') }}</h1>
          <p class="subtitle">{{ t9n.t('admin.register.subtitle') }}</p>
        </div>

        <form (ngSubmit)="onSubmit()" #registerForm="ngForm" class="admin-form">
          <div class="form-group">
            <label for="fullName">{{ t9n.t('admin.register.full_name') }}</label>
            <div class="input-with-icon">
              <span class="material-symbols-outlined input-icon">person</span>
              <input 
                type="text" 
                id="fullName" 
                name="fullName" 
                [(ngModel)]="fullName" 
                required 
                placeholder="Jean Dupont"
                class="admin-input">
            </div>
          </div>

          <div class="form-group">
            <label for="email">{{ t9n.t('admin.register.email') }}</label>
            <div class="input-with-icon">
              <span class="material-symbols-outlined input-icon">mail</span>
              <input 
                type="email" 
                id="email" 
                name="email" 
                [(ngModel)]="email" 
                required 
                placeholder="jean.dupont@time2wish.com"
                class="admin-input">
            </div>
          </div>

          <div class="form-group">
            <label for="password">{{ t9n.t('admin.register.password') }}</label>
            <div class="input-with-icon">
              <span class="material-symbols-outlined input-icon">lock</span>
              <input 
                type="password" 
                id="password" 
                name="password" 
                [(ngModel)]="password" 
                required 
                placeholder="••••••••"
                class="admin-input">
            </div>
          </div>

          <div class="admin-alert admin-alert-info">
            <span class="material-symbols-outlined">info</span>
            <p>{{ t9n.t('admin.register.info') }}</p>
          </div>

          <button type="submit" class="admin-btn-primary" [disabled]="!registerForm.form.valid || isLoading()">
            @if (isLoading()) {
              <span class="spinner"></span> Envoi de la demande...
            } @else {
              <span class="material-symbols-outlined">person_add</span> {{ t9n.t('admin.register.btn') }}
            }
          </button>
        </form>

        <div class="admin-auth-footer">
          <a routerLink="/admin/login" class="admin-link">{{ t9n.t('admin.register.link_login') }}</a>
        </div>
      </div>
    </div>
  `,
  styleUrl: './admin-auth.scss'
})
export class AdminRegisterComponent {
  fullName = '';
  email = '';
  password = '';
  isLoading = signal(false);

  http = inject(HttpClient);
  router = inject(Router);
  toastService = inject(ToastService);
  t9n = inject(TranslationService);

  private API_URL = environment.apiUrl + '/admin/auth/';

  onSubmit() {
    this.isLoading.set(true);
    this.http.post(this.API_URL + 'signup', {
      fullName: this.fullName,
      email: this.email,
      password: this.password
    }).subscribe({
      next: (res: any) => {
        this.toastService.success(res.message || 'Demande envoyée avec succès');
        this.router.navigate(['/admin/login']);
      },
      error: (err) => {
        this.isLoading.set(false);
        this.toastService.error(err.error?.message || 'Erreur lors de la création du compte');
      }
    });
  }
}
