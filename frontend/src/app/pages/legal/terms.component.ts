import { Component, inject } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-terms',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="tm-modal-overlay" (click)="onClose()">
      <div class="tm-modal-content form-modal-content" (click)="$event.stopPropagation()">
        <div class="form-modal-header">
          <h1 class="form-title">{{ t9n.t('terms.title') }}</h1>
          <button class="icon-btn form-close-btn" (click)="onClose()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>
        
        <div class="legal-content">
          <p><strong>{{ t9n.t('terms.last_update') }}</strong></p>
          
          <h2>{{ t9n.t('terms.sec1_title') }}</h2>
          <p>{{ t9n.t('terms.sec1_text') }}</p>
          
          <h2>{{ t9n.t('terms.sec2_title') }}</h2>
          <p>{{ t9n.t('terms.sec2_text') }}</p>
          <ul>
            <li>{{ t9n.t('terms.sec2_li1') }}</li>
            <li>{{ t9n.t('terms.sec2_li2') }}</li>
            <li>{{ t9n.t('terms.sec2_li3') }}</li>
          </ul>

          <h2>{{ t9n.t('terms.sec3_title') }}</h2>
          <p>{{ t9n.t('terms.sec3_text') }}</p>

          <h2>{{ t9n.t('terms.sec4_title') }}</h2>
          <p>{{ t9n.t('terms.sec4_text') }}</p>

          <h2>{{ t9n.t('terms.sec5_title') }}</h2>
          <p>{{ t9n.t('terms.sec5_text') }}</p>
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
    .legal-content h2 {
      margin-top: 24px;
      margin-bottom: 12px;
      font-size: 1.25rem;
      color: var(--text-main);
      font-family: var(--font-title);
    }
    .legal-content p, .legal-content li {
      color: var(--text-muted);
      line-height: 1.7;
      margin-bottom: 16px;
      font-size: 1rem;
    }
    .legal-content ul {
      margin-bottom: 24px;
      padding-left: 20px;
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
export class TermsComponent {
  t9n = inject(TranslationService);
  private location = inject(Location);

  onClose() {
    this.location.back();
  }
}
