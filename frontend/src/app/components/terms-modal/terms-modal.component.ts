import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-terms-modal',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (!isAccepted() && t9n.isLoaded()) {
      <div class="terms-overlay">
        <div class="terms-modal glass-panel">
          @if (!isRefused()) {
            <div class="terms-header">
              <h2>{{ t9n.t('terms.title') || 'Conditions d\\'Utilisation' }}</h2>
            </div>
            
            <div class="terms-content">
              <p>{{ t9n.t('terms.content') || 'En utilisant Time2Wish, vous acceptez nos conditions d\\'utilisation. Nous nous engageons à protéger vos données personnelles et à ne les utiliser que pour le bon fonctionnement de l\\'application.' }}</p>
              
              <div class="terms-scroll-area">
                <p><strong>{{ t9n.t('terms.sec1_title') }}</strong><br>
                {{ t9n.t('terms.sec1_text') }}</p>
                
                <p><strong>{{ t9n.t('terms.sec2_title') }}</strong><br>
                {{ t9n.t('terms.sec2_text') }}</p>
                <ul>
                  <li>{{ t9n.t('terms.sec2_li1') }}</li>
                  <li>{{ t9n.t('terms.sec2_li2') }}</li>
                  <li>{{ t9n.t('terms.sec2_li3') }}</li>
                </ul>

                <p><strong>{{ t9n.t('terms.sec3_title') }}</strong><br>
                {{ t9n.t('terms.sec3_text') }}</p>

                <p><strong>{{ t9n.t('terms.sec4_title') }}</strong><br>
                {{ t9n.t('terms.sec4_text') }}</p>

                <p><strong>{{ t9n.t('terms.sec5_title') }}</strong><br>
                {{ t9n.t('terms.sec5_text') }}</p>
              </div>
            </div>

            <div class="terms-actions">
              <button class="btn btn-secondary" (click)="refuse()">{{ t9n.t('terms.refuse') || 'Refuser' }}</button>
              <button class="btn btn-primary" (click)="accept()">{{ t9n.t('terms.accept') || 'Accepter et Continuer' }}</button>
            </div>
          } @else {
            <div class="terms-content text-center">
              <span class="material-symbols-outlined blocked-icon">block</span>
              <h2>{{ t9n.t('terms.blocked_title') || 'Accès Refusé' }}</h2>
              <p>{{ t9n.t('terms.blocked_content') || 'Vous devez accepter les conditions d\\'utilisation pour pouvoir utiliser Time2Wish.' }}</p>
            </div>
            <div class="terms-actions flex-center">
              <button class="btn btn-primary" (click)="isRefused.set(false)">{{ t9n.t('terms.rethink') || 'Relire les conditions' }}</button>
            </div>
          }
        </div>
      </div>
    }
  `,
  styles: [`
    .terms-overlay {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background-color: rgba(15, 23, 42, 0.8);
      backdrop-filter: blur(8px);
      z-index: 99999;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1rem;
    }
    .terms-modal {
      background: white;
      border-radius: 16px;
      width: 100%;
      max-width: 600px;
      max-height: 90vh;
      display: flex;
      flex-direction: column;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      overflow: hidden;
      animation: modalSlideUp 0.3s ease-out forwards;
    }
    .terms-header {
      padding: 1.5rem;
      border-bottom: 1px solid #e2e8f0;
      background: #f8fafc;
    }
    .terms-header h2 {
      margin: 0;
      font-size: 1.5rem;
      color: #0f172a;
      font-weight: 600;
    }
    .terms-content {
      padding: 1.5rem;
      overflow-y: auto;
      flex: 1;
      color: #334155;
      line-height: 1.6;
    }
    .terms-scroll-area {
      margin-top: 1.5rem;
      padding: 1rem;
      background: #f1f5f9;
      border-radius: 8px;
      font-size: 0.9rem;
      max-height: 200px;
      overflow-y: auto;
      border: 1px solid #e2e8f0;
    }
    .terms-scroll-area p {
      margin-bottom: 1rem;
    }
    .terms-scroll-area p:last-child {
      margin-bottom: 0;
    }
    .terms-scroll-area ul {
      margin-top: -0.5rem;
      margin-bottom: 1rem;
      padding-left: 1.5rem;
    }
    .terms-scroll-area li {
      margin-bottom: 0.25rem;
    }
    .terms-actions {
      padding: 1.5rem;
      border-top: 1px solid #e2e8f0;
      display: flex;
      justify-content: flex-end;
      gap: 1rem;
      background: #f8fafc;
    }
    .btn {
      padding: 0.75rem 1.5rem;
      border-radius: 8px;
      font-weight: 500;
      cursor: pointer;
      border: none;
      transition: all 0.2s;
    }
    .btn-primary {
      background: #3b82f6;
      color: white;
    }
    .btn-primary:hover {
      background: #2563eb;
    }
    .btn-secondary {
      background: transparent;
      color: #64748b;
    }
    .btn-secondary:hover {
      background: #e2e8f0;
      color: #0f172a;
    }
    .blocked-icon {
      font-size: 4rem;
      color: #ef4444;
      margin-bottom: 1rem;
    }
    .text-center {
      text-align: center;
    }
    .flex-center {
      justify-content: center;
    }

    /* Dark Mode Support */
    :host-context(.dark-theme) .terms-modal {
      background: #1e293b;
      border: 1px solid #334155;
    }
    :host-context(.dark-theme) .terms-header,
    :host-context(.dark-theme) .terms-actions {
      background: #0f172a;
      border-color: #334155;
    }
    :host-context(.dark-theme) .terms-header h2 {
      color: #f8fafc;
    }
    :host-context(.dark-theme) .terms-content {
      color: #cbd5e1;
    }
    :host-context(.dark-theme) .terms-scroll-area {
      background: #0f172a;
      border-color: #334155;
      color: #cbd5e1;
    }
    :host-context(.dark-theme) .btn-secondary {
      color: #94a3b8;
    }
    :host-context(.dark-theme) .btn-secondary:hover {
      background: #334155;
      color: #f8fafc;
    }

    @keyframes modalSlideUp {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
  `]
})
export class TermsModalComponent implements OnInit {
  t9n = inject(TranslationService);
  
  isAccepted = signal<boolean>(true);
  isRefused = signal<boolean>(false);

  ngOnInit() {
    const accepted = localStorage.getItem('t2w_terms_accepted') === 'true';
    this.isAccepted.set(accepted);
  }

  accept() {
    localStorage.setItem('t2w_terms_accepted', 'true');
    this.isAccepted.set(true);
  }

  refuse() {
    this.isRefused.set(true);
  }
}
