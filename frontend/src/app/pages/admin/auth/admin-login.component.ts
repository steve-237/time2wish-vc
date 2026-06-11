import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../../services/auth.service';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  template: `
    <div class="admin-auth-container">
      <div class="admin-auth-card">
        <div class="admin-auth-header">
          <div class="admin-logo">
            <span class="material-symbols-outlined logo-icon">admin_panel_settings</span>
          </div>
          <h1>Time2Wish</h1>
          <p class="subtitle">Portail d'Administration</p>
        </div>

        <form (ngSubmit)="onSubmit()" #loginForm="ngForm" class="admin-form">
          <div class="form-group">
            <label for="email">Email Professionnel</label>
            <div class="input-with-icon">
              <span class="material-symbols-outlined input-icon">mail</span>
              <input 
                type="email" 
                id="email" 
                name="email" 
                [(ngModel)]="email" 
                required 
                placeholder="admin@time2wish.com"
                class="admin-input">
            </div>
          </div>

          <div class="form-group">
            <label for="password">Mot de passe</label>
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

          <button type="submit" class="admin-btn-primary" [disabled]="!loginForm.form.valid || isLoading()">
            @if (isLoading()) {
              <span class="spinner"></span> Connexion...
            } @else {
              <span class="material-symbols-outlined">login</span> Connexion au portail
            }
          </button>
        </form>

        <div class="admin-auth-footer">
          <a routerLink="/admin/register" class="admin-link">Demander un accès administrateur</a>
          <div class="separator"></div>
          <a routerLink="/login" class="admin-link text-muted">Retour à l'application</a>
        </div>
      </div>
    </div>
  `,
  styleUrl: './admin-auth.scss'
})
export class AdminLoginComponent {
  email = '';
  password = '';
  isLoading = signal(false);

  authService = inject(AuthService);
  router = inject(Router);
  toastService = inject(ToastService);

  onSubmit() {
    this.isLoading.set(true);
    this.authService.login(this.email, this.password).subscribe({
      next: (res) => {
        const user = this.authService.currentUser();
        if (user && (user.roles.includes('ROLE_ADMIN') || user.roles.includes('ROLE_SUPERADMIN'))) {
          this.toastService.success('Bienvenue sur le portail d\'administration');
          this.router.navigate(['/admin/dashboard']);
        } else {
          // Normal user trying to log into admin portal
          this.authService.logout().subscribe();
          this.toastService.error('Accès refusé. Vous n\'êtes pas administrateur.');
          this.isLoading.set(false);
        }
      },
      error: (err) => {
        this.isLoading.set(false);
        if (err.status === 401) {
          if (err.error?.message?.includes('pending')) {
            this.toastService.error('Votre compte administrateur est en attente de validation.');
          } else if (err.error?.message?.includes('blocked')) {
            this.toastService.error('Ce compte a été bloqué.');
          } else {
            this.toastService.error('Identifiants incorrects.');
          }
        } else {
          this.toastService.error('Erreur de connexion serveur.');
        }
      }
    });
  }
}
