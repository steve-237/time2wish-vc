import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { ThemeService } from '../../services/theme.service';
import { ImageUploadComponent } from '../../components/image-upload/image-upload.component';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, ImageUploadComponent],
  templateUrl: './profile.html',
  styleUrl: './profile.scss'
})
export class Profile implements OnInit {
  public authService = inject(AuthService);
  public t9n = inject(TranslationService);
  public toastService = inject(ToastService);
  public themeService = inject(ThemeService);
  private router = inject(Router);

  // Note: We need access to App component methods, but it's simpler to directly manipulate the body class and localStorage 
  // since app.ts already loads it on init, or we can just replicate the logic here.

  currentUser = this.authService.currentUser;

  onClose() {
    this.router.navigate(['/dashboard']);
  }

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

  ngOnInit() {
    const user = this.authService.currentUser();
    if (user) {
      this.fullName.set(user.fullName);
      this.bio.set(user.bio || '');
      this.avatarUrl.set(user.avatarUrl || '');
    }
  }

  onAvatarChange(newUrl: string) {
    if (!newUrl) {
      // If the user removes their avatar, fall back to initials
      const randomHex = Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
      const initialsUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(this.fullName())}&background=${randomHex}&color=fff&rounded=true&bold=true`;
      this.avatarUrl.set(initialsUrl);
    } else {
      this.avatarUrl.set(newUrl);
    }
  }

  // Application Preferences State
  // App mode and Color theme are now managed by ThemeService

  themes = [
    { id: 'theme-ocean', name: 'Océan', color1: '#2563eb', color2: '#7c3aed' },
    { id: 'theme-emerald', name: 'Émeraude', color1: '#10b981', color2: '#06b6d4' },
    { id: 'theme-rose', name: 'Rose', color1: '#f43f5e', color2: '#f97316' },
    { id: 'theme-amber', name: 'Ambre', color1: '#eab308', color2: '#f97316' },
    { id: 'theme-royal', name: 'Royal', color1: '#a855f7', color2: '#ec4899' },
    { id: 'theme-ruby', name: 'Rubis', color1: '#e11d48', color2: '#f472b6' },
    { id: 'theme-midnight', name: 'Minuit', color1: '#4f46e5', color2: '#c084fc' },
    { id: 'theme-sunset', name: 'Crépuscule', color1: '#f97316', color2: '#e11d48' },
    { id: 'theme-noir', name: 'Noir', color1: '#111827', color2: '#4b5563' },
    { id: 'theme-blanc', name: 'Blanc', color1: '#f3f4f6', color2: '#9ca3af' },
  ];
  languages: { code: string; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'Français', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'English', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'Deutsch', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  setAppMode(mode: 'light' | 'dark' | 'oled') {
    this.themeService.setAppMode(mode);
  }

  setColorTheme(themeId: string) {
    this.themeService.setColorTheme(themeId);
    
    const themeName = this.themes.find(t => t.id === themeId)?.name || themeId;
    this.toastService.success(this.t9n.currentLang() === 'en' ? `Theme ${themeName} applied` : `Thème ${themeName} appliqué`);
  }

  setLanguage(lang: string) {
    this.t9n.setLanguage(lang as any);
    this.isLangMenuOpen.set(false);
  }

  onSaveProfile() {
    if (!this.fullName()) {
      this.toastService.error(this.t9n.currentLang() === 'en' ? 'Full name is required.' : 'Le nom complet est obligatoire.');
      return;
    }

    this.isSaving.set(true);
    this.authService.updateProfile(this.fullName(), this.bio(), this.avatarUrl()).subscribe({
      next: (success) => {
        this.isSaving.set(false);
        if (success) {
          this.toastService.success(this.t9n.t('profile.msg_profile_success') || 'Profil mis à jour avec succès.');
        } else {
          this.toastService.error(this.t9n.currentLang() === 'en' ? 'Error updating profile.' : 'Erreur lors de la mise à jour du profil.');
        }
      },
      error: () => {
        this.isSaving.set(false);
        this.toastService.error(this.t9n.currentLang() === 'en' ? 'Server error.' : 'Erreur serveur.');
      }
    });
  }

  onUpdatePassword() {
    if (!this.currentPassword() || !this.newPassword() || !this.confirmPassword()) {
      this.toastService.error(this.t9n.currentLang() === 'en' ? 'Please fill in all password fields.' : 'Veuillez remplir tous les champs de mot de passe.');
      return;
    }

    if (this.newPassword() !== this.confirmPassword()) {
      this.toastService.error(this.t9n.currentLang() === 'en' ? 'New passwords do not match.' : 'Les nouveaux mots de passe ne correspondent pas.');
      return;
    }

    this.isSavingPassword.set(true);
    this.authService.updatePassword(this.currentPassword(), this.newPassword()).subscribe({
      next: (success) => {
        this.isSavingPassword.set(false);
        if (success) {
          this.toastService.success(this.t9n.t('profile.msg_password_success') || 'Mot de passe modifié avec succès.');
          this.currentPassword.set('');
          this.newPassword.set('');
          this.confirmPassword.set('');
        } else {
          this.toastService.error(this.t9n.currentLang() === 'en' ? 'Incorrect current password or error.' : 'Mot de passe actuel incorrect ou erreur.');
        }
      },
      error: () => {
        this.isSavingPassword.set(false);
        this.toastService.error(this.t9n.currentLang() === 'en' ? 'Server error. Incorrect current password?' : 'Erreur serveur. Mot de passe actuel incorrect ?');
      }
    });
  }
}
