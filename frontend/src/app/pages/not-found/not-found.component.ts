import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-not-found',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <div class="not-found-container">
      <div class="glass-card not-found-card">
        <div class="icon-container">
          <span class="material-symbols-outlined error-icon">sentiment_dissatisfied</span>
        </div>
        <h1 class="gradient-text">404</h1>
        <h2>{{ t9n.t('not_found.title') || 'Page introuvable' }}</h2>
        <p>{{ t9n.t('not_found.desc') || 'Oups ! La page que vous recherchez n\\'existe pas ou a été déplacée.' }}</p>
        
        <a routerLink="/" class="btn-premium">
          <span class="material-symbols-outlined">home</span>
          {{ t9n.t('not_found.btn_home') || 'Retour à l\\'accueil' }}
        </a>
      </div>
    </div>
  `,
  styles: [`
    .not-found-container {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 1rem;
      background: var(--bg-main);
    }
    .not-found-card {
      max-width: 500px;
      width: 100%;
      text-align: center;
      padding: 3rem 2rem;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 1.5rem;
    }
    .icon-container {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: rgba(239, 68, 68, 0.1);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: -0.5rem;
    }
    .error-icon {
      font-size: 3rem;
      color: #ef4444;
    }
    h1 {
      font-size: 5rem;
      font-weight: 800;
      line-height: 1;
      margin: 0;
    }
    h2 {
      font-size: 1.5rem;
      color: var(--text-main);
      margin: 0;
    }
    p {
      color: var(--text-muted);
      margin-bottom: 1rem;
      line-height: 1.6;
    }
    .btn-premium {
      display: inline-flex;
      text-decoration: none;
    }
  `]
})
export class NotFoundComponent {
  t9n = inject(TranslationService);
}
