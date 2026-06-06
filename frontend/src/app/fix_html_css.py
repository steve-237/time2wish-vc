import os
import re

def process_login():
    html_path = r"d:\formations_personnelles\time2wish-ai\frontend\src\app\pages\login\login.html"
    scss_path = r"d:\formations_personnelles\time2wish-ai\frontend\src\app\pages\login\login.scss"
    
    with open(html_path, 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<div style="position: absolute; top: 16px; right: 16px; z-index: 10;">', '<div class="login-lang-container">')
    html = html.replace('<div class="custom-lang-menu-container" style="position: relative;">', '<div class="custom-lang-menu-container login-lang-menu">')
    html = html.replace('class="custom-lang-btn icon-btn" (click)="isLangMenuOpen.set(!isLangMenuOpen())" style="display: flex; align-items: center; gap: 4px; border-radius: 20px; padding: 4px 12px; font-size: 1.2rem; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); backdrop-filter: blur(10px);"', 'class="custom-lang-btn icon-btn login-lang-btn" (click)="isLangMenuOpen.set(!isLangMenuOpen())"')
    html = html.replace('class="flag-icon" style="border-radius: 2px;"', 'class="flag-icon login-flag"')
    html = html.replace('style="font-size: 1.2rem; transition: transform 0.2s;"', 'class="login-chevron"')
    
    html = html.replace('<div class="custom-lang-dropdown" *ngIf="isLangMenuOpen()" style="min-width: 130px;">', '@if (isLangMenuOpen()) {\n        <div class="custom-lang-dropdown login-dropdown">')
    html = html.replace('<div class="lang-option" *ngFor="let lang of languages" (click)="setLanguage(lang.code)" [class.active]="t9n.currentLang() === lang.code">', '@for (lang of languages; track lang.code) {\n          <div class="lang-option" (click)="setLanguage(lang.code)" [class.active]="t9n.currentLang() === lang.code">')
    html = html.replace('</div>\n        </div>', '</div>\n          }\n        </div>\n        }')
    html = html.replace('<div *ngIf="isLangMenuOpen()" (click)="isLangMenuOpen.set(false)" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 5;"></div>', '@if (isLangMenuOpen()) {\n    <div (click)="isLangMenuOpen.set(false)" class="login-backdrop"></div>\n    }')
    
    html = html.replace('<div *ngIf="errorMessage()" class="alert-box">', '@if (errorMessage()) {\n    <div class="alert-box">')
    html = html.replace('<span class="alert-text">{{ errorMessage() }}</span>\n    </div>', '<span class="alert-text">{{ errorMessage() }}</span>\n    </div>\n    }')
    
    html = html.replace('<div class="form-group" *ngIf="!isLoginTab()">', '@if (!isLoginTab()) {\n      <div class="form-group">')
    html = html.replace('placeholder="Ex: Jean Dupont" \n          required>\n      </div>', 'placeholder="Ex: Jean Dupont" \n          required>\n      </div>\n      }')
    
    html = html.replace('<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">', '<div class="login-password-header">')
    html = html.replace('<label class="form-label" for="login-password" style="margin-bottom: 0;">', '<label class="form-label mb-0" for="login-password">')
    html = html.replace('<a *ngIf="isLoginTab()" href="javascript:void(0)" (click)="openForgotPassword()" style="font-size: 0.8rem; color: #60a5fa; text-decoration: none; font-weight: 500;">', '@if (isLoginTab()) {\n          <a href="javascript:void(0)" (click)="openForgotPassword()" class="login-forgot-link">')
    html = html.replace('</a>\n        </div>', '</a>\n          }\n        </div>')
    
    html = html.replace('style="width: 100%; margin-top: 10px;"', 'class="btn-premium login-submit-btn"')
    html = html.replace('<span *ngIf="!isLoading()" class="material-symbols-outlined">', '@if (!isLoading()) { <span class="material-symbols-outlined">')
    html = html.replace('{{ isLoginTab() ? \'login\' : \'person_add\' }}</span>', '{{ isLoginTab() ? \'login\' : \'person_add\' }}</span> }')
    html = html.replace('<span *ngIf="isLoading()" class="btn-spinner"></span>', '@if (isLoading()) { <span class="btn-spinner"></span> }')
    
    html = html.replace('<div class="demo-account-hint" *ngIf="isLoginTab()">', '@if (isLoginTab()) {\n    <div class="demo-account-hint">')
    html = html.replace('</div>\n\n  </div>', '</div>\n    }\n\n  </div>')
    
    html = html.replace('<div class="tm-modal-overlay" *ngIf="isForgotModalOpen()" style="z-index: 3000;">', '@if (isForgotModalOpen()) {\n<div class="tm-modal-overlay z-modal">')
    html = html.replace('style="padding: 24px; max-width: 400px;"', 'class="forgot-modal-content"')
    html = html.replace('<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">', '<div class="forgot-modal-header">')
    html = html.replace('<h2 style="margin: 0; font-size: 1.4rem;">', '<h2>')
    html = html.replace('style="background: none; border: none; cursor: pointer; color: var(--text-muted);"', 'class="forgot-close-btn"')
    
    html = html.replace('<div style="text-align: center; padding: 10px 0;">', '<div class="forgot-modal-body">')
    html = html.replace('<ng-container *ngIf="!isForgotEmailSent()">', '@if (!isForgotEmailSent()) {')
    html = html.replace('style="font-size: 2.5rem; color: #60a5fa; margin-bottom: 12px;"', 'class="forgot-icon-send"')
    html = html.replace('style="font-size: 0.95rem; color: var(--text-main); margin-bottom: 16px;"', 'class="forgot-desc-send"')
    html = html.replace('style="margin-bottom: 16px;"', 'class="mb-16"')
    html = html.replace('style="width: 100%;"', 'class="w-100"')
    html = html.replace('</ng-container>', '}')
    
    html = html.replace('<ng-container *ngIf="isForgotEmailSent()">', '@if (isForgotEmailSent()) {')
    html = html.replace('style="font-size: 3rem; color: #10b981; margin-bottom: 16px;"', 'class="forgot-icon-success"')
    html = html.replace('<h3 style="margin-bottom: 8px; color: var(--text-main);">', '<h3 class="forgot-title-success">')
    html = html.replace('style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 24px;"', 'class="forgot-desc-success"')
    
    html = html.replace('</div>\n</div>\n', '</div>\n</div>\n}\n')
    
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)
        
    with open(scss_path, 'a', encoding='utf-8') as f:
        f.write('''
/* --- Inline Style Replacements --- */
.login-lang-container { position: absolute; top: 16px; right: 16px; z-index: 10; }
.login-lang-menu { position: relative; }
.login-lang-btn {
  display: flex; align-items: center; gap: 4px; border-radius: 20px; padding: 4px 12px; font-size: 1.2rem;
  background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); backdrop-filter: blur(10px);
}
.login-flag { border-radius: 2px; }
.login-chevron { font-size: 1.2rem; transition: transform 0.2s; }
.login-dropdown { min-width: 130px; }
.login-backdrop { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 5; }
.login-password-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.mb-0 { margin-bottom: 0; }
.login-forgot-link { font-size: 0.8rem; color: #60a5fa; text-decoration: none; font-weight: 500; }
.login-submit-btn { width: 100%; margin-top: 10px; }
.z-modal { z-index: 3000; }
.forgot-modal-content { padding: 24px; max-width: 400px; }
.forgot-modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.forgot-modal-header h2 { margin: 0; font-size: 1.4rem; }
.forgot-close-btn { background: none; border: none; cursor: pointer; color: var(--text-muted); }
.forgot-modal-body { text-align: center; padding: 10px 0; }
.forgot-icon-send { font-size: 2.5rem; color: #60a5fa; margin-bottom: 12px; }
.forgot-desc-send { font-size: 0.95rem; color: var(--text-main); margin-bottom: 16px; }
.mb-16 { margin-bottom: 16px; }
.w-100 { width: 100%; }
.forgot-icon-success { font-size: 3rem; color: #10b981; margin-bottom: 16px; }
.forgot-title-success { margin-bottom: 8px; color: var(--text-main); }
.forgot-desc-success { font-size: 0.9rem; color: var(--text-muted); margin-bottom: 24px; }
''')

def process_profile():
    html_path = r"d:\formations_personnelles\time2wish-ai\frontend\src\app\pages\profile\profile.html"
    scss_path = r"d:\formations_personnelles\time2wish-ai\frontend\src\app\pages\profile\profile.scss"
    
    with open(html_path, 'r', encoding='utf-8') as f:
        html = f.read()
        
    html = html.replace('style="max-width: 600px; padding: 24px;"', 'class="profile-modal-content"')
    html = html.replace('<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">', '<div class="profile-header">')
    html = html.replace('<h1 style="margin: 0;">', '<h1>')
    html = html.replace('style="background: none; border: none; cursor: pointer;"', 'class="profile-close-btn"')
    html = html.replace('<div style="padding: 24px;">', '<div class="profile-body">')
    html = html.replace('<div style="margin-bottom: 24px;">', '<div class="mb-24">')
    html = html.replace('style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 8px; display: block;"', 'class="profile-avatar-label"')
    html = html.replace('style="opacity: 0.7; cursor: not-allowed;"', 'class="profile-email-input"')
    html = html.replace('<div style="margin-top: 40px;"></div>', '<div class="mt-40"></div>')
    html = html.replace('<div style="display: flex; gap: 16px; margin-bottom: 20px;">', '<div class="profile-prefs-row">')
    html = html.replace('style="flex: 1;"', 'class="flex-1"')
    html = html.replace('style="position: relative; width: 100%;"', 'class="profile-lang-container"')
    html = html.replace('style="top: -10px; font-size: 0.7rem; color: hsl(var(--primary-hsl)); font-weight: 700; z-index: 10;"', 'class="profile-lang-label"')
    html = html.replace('style="display: flex; justify-content: space-between; align-items: center; width: 100%; border-radius: 8px; padding: 12px 16px; background: transparent; border: 1px solid var(--border-card);"', 'class="profile-lang-btn"')
    html = html.replace('<div style="display: flex; align-items: center; gap: 8px;">', '<div class="profile-lang-value">')
    html = html.replace('style="border-radius: 2px;"', 'class="profile-flag"')
    html = html.replace('style="transition: transform 0.2s;"', 'class="profile-chevron"')
    
    html = html.replace('<div class="custom-lang-dropdown" *ngIf="isLangMenuOpen()" style="width: 100%; top: calc(100% + 4px);">', '@if (isLangMenuOpen()) {\n          <div class="custom-lang-dropdown profile-lang-dropdown">')
    html = html.replace('<div class="lang-option" *ngFor="let lang of languages" (click)="setLanguage(lang.code)" [class.active]="t9n.currentLang() === lang.code">', '@for (lang of languages; track lang.code) {\n            <div class="lang-option" (click)="setLanguage(lang.code)" [class.active]="t9n.currentLang() === lang.code">')
    html = html.replace('</div>\n          </div>', '</div>\n            }\n          </div>\n          }')
    
    html = html.replace('<div *ngIf="isLangMenuOpen()" (click)="isLangMenuOpen.set(false)" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 5;"></div>', '@if (isLangMenuOpen()) {\n        <div (click)="isLangMenuOpen.set(false)" class="profile-lang-backdrop"></div>\n        }')
    
    html = html.replace('style="width: 100%;"', 'class="w-100"')
    html = html.replace('style="padding-top: 20px; padding-bottom: 8px;"', 'class="profile-theme-select"')
    html = html.replace('style="top: 4px; font-size: 0.7rem; color: hsl(var(--primary-hsl)); font-weight: 700;"', 'class="profile-theme-label"')
    
    html = html.replace('style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 12px; display: block;"', 'class="profile-color-label"')
    html = html.replace('<div style="display: flex; gap: 12px; flex-wrap: wrap;">', '<div class="profile-colors-row">')
    
    html = html.replace('<button \n          *ngFor="let theme of themes" ', '@for (theme of themes; track theme.id) {\n        <button ')
    html = html.replace('[title]="theme.name">\n          <span *ngIf="colorTheme() === theme.id" class="material-symbols-outlined" style="color: white; font-size: 1.2rem;">check</span>\n        </button>', '[title]="theme.name">\n          @if (colorTheme() === theme.id) { <span class="material-symbols-outlined profile-color-check">check</span> }\n        </button>\n        }')
    
    html = html.replace('style="background: hsl(var(--primary-hsl));"', 'class="profile-update-pass-btn"')
    
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)
        
    with open(scss_path, 'a', encoding='utf-8') as f:
        f.write('''
/* --- Inline Style Replacements --- */
.profile-modal-content { max-width: 600px; padding: 24px; }
.profile-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.profile-header h1 { margin: 0; }
.profile-close-btn { background: none; border: none; cursor: pointer; }
.profile-body { padding: 24px; }
.mb-24 { margin-bottom: 24px; }
.profile-avatar-label { font-size: 0.9rem; color: var(--text-muted); margin-bottom: 8px; display: block; }
.profile-email-input { opacity: 0.7; cursor: not-allowed; }
.mt-40 { margin-top: 40px; }
.profile-prefs-row { display: flex; gap: 16px; margin-bottom: 20px; }
.flex-1 { flex: 1; }
.profile-lang-container { position: relative; width: 100%; }
.profile-lang-label { top: -10px; font-size: 0.7rem; color: hsl(var(--primary-hsl)); font-weight: 700; z-index: 10; }
.profile-lang-btn { display: flex; justify-content: space-between; align-items: center; width: 100%; border-radius: 8px; padding: 12px 16px; background: transparent; border: 1px solid var(--border-card); }
.profile-lang-value { display: flex; align-items: center; gap: 8px; }
.profile-flag { border-radius: 2px; }
.profile-chevron { transition: transform 0.2s; }
.profile-lang-dropdown { width: 100%; top: calc(100% + 4px); }
.profile-lang-backdrop { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 5; }
.w-100 { width: 100%; }
.profile-theme-select { padding-top: 20px; padding-bottom: 8px; }
.profile-theme-label { top: 4px; font-size: 0.7rem; color: hsl(var(--primary-hsl)); font-weight: 700; }
.profile-color-label { font-size: 0.9rem; color: var(--text-muted); margin-bottom: 12px; display: block; }
.profile-colors-row { display: flex; gap: 12px; flex-wrap: wrap; }
.profile-color-check { color: white; font-size: 1.2rem; }
.profile-update-pass-btn { background: hsl(var(--primary-hsl)); }
''')

if __name__ == "__main__":
    process_login()
    process_profile()
