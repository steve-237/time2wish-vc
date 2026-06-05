import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './profile.html',
  styleUrl: './profile.css'
})
export class Profile implements OnInit {
  authService = inject(AuthService);
  t9n = inject(TranslationService);

  // Profile Form State
  fullName = signal<string>('');
  bio = signal<string>('');
  avatarUrl = signal<string>('');
  
  // Password Form State
  currentPassword = signal<string>('');
  newPassword = signal<string>('');
  confirmPassword = signal<string>('');

  // UI State
  isSaving = signal<boolean>(false);
  isSavingPassword = signal<boolean>(false);
  message = signal<string>('');
  messageType = signal<'success' | 'error'>('success');

  ngOnInit() {
    const user = this.authService.currentUser();
    if (user) {
      this.fullName.set(user.fullName);
      this.bio.set(user.bio || '');
      this.avatarUrl.set(user.avatarUrl || '');
    }
  }

  onSaveProfile() {
    if (!this.fullName()) {
      this.showMessage('Le nom complet est obligatoire.', 'error');
      return;
    }

    this.isSaving.set(true);
    this.authService.updateProfile(this.fullName(), this.bio(), this.avatarUrl()).subscribe({
      next: (success) => {
        this.isSaving.set(false);
        if (success) {
          this.showMessage(this.t9n.t('profile.msg_profile_success') || 'Profil mis à jour avec succès.', 'success');
        } else {
          this.showMessage('Erreur lors de la mise à jour du profil.', 'error');
        }
      },
      error: () => {
        this.isSaving.set(false);
        this.showMessage('Erreur serveur.', 'error');
      }
    });
  }

  onUpdatePassword() {
    if (!this.currentPassword() || !this.newPassword() || !this.confirmPassword()) {
      this.showMessage('Veuillez remplir tous les champs de mot de passe.', 'error');
      return;
    }

    if (this.newPassword() !== this.confirmPassword()) {
      this.showMessage('Les nouveaux mots de passe ne correspondent pas.', 'error');
      return;
    }

    this.isSavingPassword.set(true);
    this.authService.updatePassword(this.currentPassword(), this.newPassword()).subscribe({
      next: (success) => {
        this.isSavingPassword.set(false);
        if (success) {
          this.showMessage(this.t9n.t('profile.msg_password_success') || 'Mot de passe modifié avec succès.', 'success');
          this.currentPassword.set('');
          this.newPassword.set('');
          this.confirmPassword.set('');
        } else {
          this.showMessage('Mot de passe actuel incorrect ou erreur.', 'error');
        }
      },
      error: () => {
        this.isSavingPassword.set(false);
        this.showMessage('Erreur serveur. Mot de passe actuel incorrect ?', 'error');
      }
    });
  }

  private showMessage(msg: string, type: 'success' | 'error') {
    this.message.set(msg);
    this.messageType.set(type);
    setTimeout(() => this.message.set(''), 5000);
  }
}
