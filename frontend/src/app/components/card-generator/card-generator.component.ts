import { Component, Output, EventEmitter, inject, signal, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { environment } from '../../../environments/environment';
import { Birthday } from '../../models/birthday.model';

@Component({
  selector: 'app-card-generator',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="tm-overlay" (click)="close.emit()">
      <div class="tm-card cg-card" (click)="$event.stopPropagation()">
        
        <div class="tm-header">
          <h2><span class="material-symbols-outlined tm-header-icon">image</span> {{ t9n.t('card_gen.title') || 'Générateur de Carte IA' }}</h2>
          <button class="tm-close-btn" (click)="close.emit()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>

        <div class="tm-body cg-body">
          <div class="cg-prompt-section">
            <p class="cg-desc">{{ t9n.t('card_gen.desc') || 'Décrivez la carte d\'anniversaire parfaite pour ' + birthday?.name }}</p>
            
            <div class="floating-group">
              <textarea 
                class="floating-input cg-textarea" 
                rows="3" 
                [ngModel]="prompt()" 
                (ngModelChange)="prompt.set($event)"
                placeholder=" "></textarea>
              <label class="floating-label">{{ t9n.t('card_gen.prompt_label') || 'Ex: Un gâteau au chocolat sur une plage au coucher du soleil...' }}</label>
            </div>

            <button 
              class="btn-premium cg-generate-btn" 
              (click)="generateCard()" 
              [disabled]="isLoading() || !prompt().trim()">
              <span class="material-symbols-outlined">{{ isLoading() ? 'sync' : 'magic_button' }}</span>
              {{ isLoading() ? (t9n.t('card_gen.loading') || 'Génération en cours...') : (t9n.t('card_gen.btn_generate') || 'Générer la carte') }}
            </button>
          </div>

          <div class="cg-preview-section">
            @if (isLoading()) {
              <div class="cg-placeholder loader-placeholder">
                <div class="tm-spinner"></div>
              </div>
            } @else if (imageUrl()) {
              <div class="cg-result">
                <img [src]="imageUrl()" alt="Generated card" class="cg-image">
                <a [href]="imageUrl()" [download]="'carte_' + birthday?.name + '.jpg'" class="btn-secondary cg-download-btn">
                  <span class="material-symbols-outlined">download</span>
                  {{ t9n.t('card_gen.btn_download') || 'Télécharger' }}
                </a>
              </div>
            } @else if (errorMsg()) {
              <div class="cg-placeholder error-placeholder">
                <span class="material-symbols-outlined">broken_image</span>
                <p>{{ errorMsg() }}</p>
              </div>
            } @else {
              <div class="cg-placeholder">
                <span class="material-symbols-outlined">image_search</span>
                <p>{{ t9n.t('card_gen.preview_empty') || 'L\'image générée apparaîtra ici.' }}</p>
              </div>
            }
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .cg-card {
      max-width: 800px;
      width: 90%;
    }
    .cg-body {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 24px;
    }
    @media (max-width: 768px) {
      .cg-body { grid-template-columns: 1fr; }
    }
    .cg-prompt-section {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .cg-desc {
      color: var(--text-muted);
      margin-bottom: 8px;
    }
    .cg-textarea {
      resize: none;
    }
    .cg-generate-btn {
      margin-top: auto;
    }
    .cg-preview-section {
      background: rgba(0,0,0,0.03);
      border-radius: 12px;
      border: 2px dashed var(--border-card);
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 300px;
      overflow: hidden;
      position: relative;
    }
    body.dark-theme .cg-preview-section {
      background: rgba(255,255,255,0.02);
    }
    .cg-placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      color: var(--text-muted);
      text-align: center;
      padding: 20px;
    }
    .cg-placeholder .material-symbols-outlined {
      font-size: 3rem;
      opacity: 0.5;
    }
    .error-placeholder {
      color: #ef4444;
    }
    .cg-result {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      position: relative;
    }
    .cg-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .cg-download-btn {
      position: absolute;
      bottom: 16px;
      right: 16px;
      background: rgba(255,255,255,0.9);
      backdrop-filter: blur(4px);
      color: #111;
      border: none;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
    .cg-download-btn:hover {
      background: white;
      transform: translateY(-2px);
    }
  `]
})
export class CardGeneratorComponent {
  t9n = inject(TranslationService);
  toast = inject(ToastService);
  http = inject(HttpClient);

  @Input() birthday?: Birthday;
  @Output() close = new EventEmitter<void>();

  prompt = signal<string>('');
  isLoading = signal<boolean>(false);
  imageUrl = signal<string | null>(null);
  errorMsg = signal<string | null>(null);

  generateCard() {
    if (!this.prompt().trim()) return;
    
    this.isLoading.set(true);
    this.errorMsg.set(null);
    this.imageUrl.set(null);

    this.http.post(
      environment.apiUrl + '/ai/card',
      { prompt: this.prompt() },
      { responseType: 'blob', withCredentials: true }
    ).subscribe({
      next: (blob) => {
        const url = URL.createObjectURL(blob);
        this.imageUrl.set(url);
        this.isLoading.set(false);
      },
      error: (err) => {
        this.isLoading.set(false);
        if (err.status === 503) {
          // Special fallback message
          const reader = new FileReader();
          reader.onload = () => {
            try {
              const res = JSON.parse(reader.result as string);
              this.errorMsg.set(res.message);
            } catch {
              this.errorMsg.set(this.t9n.currentLang() === 'en' ? 'Image generation API is not configured yet.' : 'L\'API de génération d\'images n\'est pas encore configurée.');
            }
          };
          reader.readAsText(err.error);
        } else {
          this.errorMsg.set(this.t9n.currentLang() === 'en' ? 'An error occurred during generation.' : 'Une erreur est survenue lors de la génération.');
        }
      }
    });
  }
}
