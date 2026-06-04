import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login {
  authService = inject(AuthService);
  t9n = inject(TranslationService);
  router = inject(Router);

  isLoginTab = signal<boolean>(true);
  
  email = signal<string>('');
  password = signal<string>('');
  fullName = signal<string>('');
  errorMessage = signal<string>('');

  constructor() {
    // Redirect if already authenticated
    if (this.authService.isAuthenticated()) {
      this.router.navigate(['/dashboard']);
    }
  }

  toggleTab() {
    this.isLoginTab.update(val => !val);
    this.errorMessage.set('');
  }

  onSubmit() {
    this.errorMessage.set('');

    if (!this.email() || !this.password()) {
      this.errorMessage.set('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (this.isLoginTab()) {
      // Login flow
      this.authService.login(this.email(), this.password()).subscribe(success => {
        if (success) {
          this.router.navigate(['/dashboard']);
        } else {
          this.errorMessage.set('Identifiants incorrects.');
        }
      });
    } else {
      // Register flow
      if (!this.fullName()) {
        this.errorMessage.set('Le nom complet est obligatoire.');
        return;
      }
      
      this.authService.register(this.email(), this.password(), this.fullName()).subscribe(success => {
        if (success) {
          // Log in automatically after registration
          this.authService.login(this.email(), this.password()).subscribe(loginSuccess => {
            if (loginSuccess) {
              this.router.navigate(['/dashboard']);
            } else {
              this.errorMessage.set('Erreur de connexion automatique.');
            }
          });
        } else {
          this.errorMessage.set('Cet email est déjà enregistré.');
        }
      });
    }
  }
}
