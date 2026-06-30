import { Component, inject } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-support',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="tm-modal-overlay" (click)="onClose()">
      <div class="tm-modal-content form-modal-content" (click)="$event.stopPropagation()">
        <div class="form-modal-header">
          <h1 class="form-title">{{ t9n.t('support.title') }}</h1>
          <button class="icon-btn form-close-btn" (click)="onClose()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>
        
        <div class="legal-content">
          <p class="support-intro">{{ t9n.t('support.intro') }}</p>
          
          <div class="faq-grid">
            <div class="faq-card">
              <span class="material-symbols-outlined faq-icon">notifications_active</span>
              <h3>{{ t9n.t('support.faq1_title') }}</h3>
              <p>{{ t9n.t('support.faq1_text') }}</p>
            </div>
            
            <div class="faq-card">
              <span class="material-symbols-outlined faq-icon">auto_awesome</span>
              <h3>{{ t9n.t('support.faq2_title') }}</h3>
              <p>{{ t9n.t('support.faq2_text') }}</p>
            </div>
            
            <div class="faq-card">
              <span class="material-symbols-outlined faq-icon">cloud_sync</span>
              <h3>{{ t9n.t('support.faq3_title') }}</h3>
              <p>{{ t9n.t('support.faq3_text') }}</p>
            </div>
          </div>

          <div class="contact-section">
            <h2>{{ t9n.t('support.contact_title') }}</h2>
            <p>{{ t9n.t('support.contact_text') }}</p>
            <a href="mailto:support@time2wish.app" class="btn-PRO contact-btn">
              <span class="material-symbols-outlined">mail</span>
              {{ t9n.t('support.contact_btn') }}
            </a>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .form-modal-content {
      max-width: 800px;
      padding: 32px;
      max-height: 90vh;
      overflow-y: auto;
    }
    .form-modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border-card);
    }
    .form-title {
      margin: 0;
      font-size: 1.8rem;
      background: linear-gradient(135deg, hsl(var(--primary-hsl)), hsl(var(--secondary-hsl)));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      font-family: var(--font-title);
    }
    .form-close-btn {
      background: none;
      border: none;
      cursor: pointer;
    }
    
    .support-intro {
      text-align: center;
      font-size: 1.15rem;
      color: var(--text-muted);
      margin-bottom: 48px;
      line-height: 1.6;
    }

    .faq-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 24px;
      margin-bottom: 48px;
    }
    .faq-card {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid var(--border-card);
      border-radius: 16px;
      padding: 24px;
      text-align: center;
      transition: transform 0.2s;
    }
    .faq-card:hover {
      transform: translateY(-4px);
    }
    .faq-icon {
      font-size: 2.5rem;
      color: hsl(var(--primary-hsl));
      margin-bottom: 16px;
    }
    .faq-card h3 {
      font-family: var(--font-title);
      font-size: 1.1rem;
      color: var(--text-main);
      margin-bottom: 12px;
    }
    .faq-card p {
      font-size: 0.95rem;
      color: var(--text-muted);
      line-height: 1.5;
      margin: 0;
    }

    .contact-section {
      text-align: center;
      padding-top: 32px;
      border-top: 1px solid var(--border-card);
    }
    .contact-section h2 {
      font-family: var(--font-title);
      font-size: 1.5rem;
      color: var(--text-main);
      margin-bottom: 12px;
    }
    .contact-section p {
      color: var(--text-muted);
      margin-bottom: 24px;
    }
    .contact-btn {
      display: inline-flex;
      text-decoration: none;
    }

    @media (max-width: 600px) {
      .form-modal-content {
        padding: 20px;
      }
      .form-title {
        font-size: 1.5rem;
      }
    }
  `]
})
export class SupportComponent {
  t9n = inject(TranslationService);
  private location = inject(Location);

  onClose() {
    this.location.back();
  }
}
