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
    <div class="tm-modal-overlay" style="z-index: 3000;" (click)="close.emit()">
      <div class="glass-card cg-card" (click)="$event.stopPropagation()">
        
        <div class="cg-header flex-between">
          <h2><span class="material-symbols-outlined tm-header-icon">image</span> {{ t9n.t('card_gen.title') || 'Générateur de Carte' }}</h2>
          <button class="icon-btn cg-close-btn" (click)="close.emit()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>

        <div class="tabs-container">
          <button class="tab-btn" [class.active]="mode() === 'ai'" (click)="mode.set('ai')">
            <span class="material-symbols-outlined tab-icon">auto_awesome</span>
            {{ t9n.t('card_gen.tab_ai') || 'Générateur IA' }}
          </button>
          <button class="tab-btn" [class.active]="mode() === 'gallery'" (click)="mode.set('gallery')">
            <span class="material-symbols-outlined tab-icon">photo_library</span>
            {{ t9n.t('card_gen.tab_gallery') || "Galerie d'images" }}
          </button>
        </div>

        @if (mode() === 'ai') {
        <div class="tm-body cg-body animate-fade">
          <div class="cg-prompt-section">
            <p class="cg-desc">{{ t9n.t('card_gen.desc') || "Décrivez la carte d'anniversaire parfaite pour " + birthday?.name }}</p>
            
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
              class="btn-PRO cg-generate-btn" 
              (click)="generateCard()" 
              [disabled]="isLoading() || !prompt().trim()"
              [class.disabled]="isLoading() || !prompt().trim()">
              <span class="material-symbols-outlined">{{ isLoading() ? 'sync' : 'magic_button' }}</span>
              {{ isLoading() ? (t9n.t('card_gen.loading') || 'Génération en cours...') : (t9n.t('card_gen.btn_generate') || 'Générer la carte') }}
            </button>
          </div>

          <div class="cg-preview-section">
            @if (isLoading()) {
              <div class="ai-processing-overlay" style="position: relative; min-height: 250px;">
                <div class="ai-glow-orb purple"></div>
                <div class="ai-glow-orb pink"></div>

                <div class="ai-loader-core">
                  <div class="ai-pulse-ring ring-1"></div>
                  <div class="ai-pulse-ring ring-2"></div>
                  <div class="ai-pulse-ring ring-3"></div>

                  <div class="ai-icon-box">
                    <span class="material-symbols-outlined ai-magic-sparkle">palette</span>
                  </div>
                </div>

                <div class="ai-loading-status">
                  <span class="ai-shimmer-title">{{ t9n.t('card_gen.loading') || "Création de l'illustration par l'IA..." }}</span>
                  <span class="ai-loading-subtitle">Génération d'une carte virtuelle unique</span>
                </div>

                <div class="ai-particle p1">🎨</div>
                <div class="ai-particle p2">✨</div>
                <div class="ai-particle p3">🖼️</div>
              </div>
            } @else if (imageUrl()) {
              <div class="cg-result">
                <img [src]="imageUrl()" alt="Generated card" class="cg-image">
                <a [href]="imageUrl()" [download]="'carte_' + birthday?.name + '.jpg'" target="_blank" class="btn-secondary cg-download-btn">
                  <span class="material-symbols-outlined">download</span>
                  {{ t9n.t('card_gen.btn_download') || 'Télécharger' }}
                </a>
              </div>
            } @else if (errorMsg()) {
              <div class="cg-placeholder error-placeholder">
                <span class="material-symbols-outlined">broken_image</span>
                <p>{{ errorMsg() }}</p>
                <button class="btn-secondary mt-2" (click)="mode.set('gallery')">
                  {{ t9n.t('card_gen.btn_view_gallery') || "Voir la galerie d'images" }}
                </button>
              </div>
            } @else {
              <div class="cg-placeholder">
                <span class="material-symbols-outlined">image_search</span>
                <p>{{ t9n.t('card_gen.preview_empty') || "L'image générée apparaîtra ici." }}</p>
              </div>
            }
          </div>
        </div>
        }

        @if (mode() === 'gallery') {
        <div class="tm-body animate-fade">
          <p class="cg-desc mb-4">{{ t9n.t('card_gen.gallery_desc') || "Choisissez l'une de ces belles images prêtes à être partagées :" }}</p>
          <div class="gallery-grid">
            @for (img of fallbackImages; track img) {
              <div class="gallery-item" (click)="selectFallback(img)" [class.selected]="selectedFallback() === img">
                <img [src]="img" alt="Carte d'anniversaire">
                @if (selectedFallback() === img) {
                  <div class="gallery-item-overlay">
                    <span class="material-symbols-outlined">check_circle</span>
                  </div>
                }
              </div>
            }
          </div>

          <div class="gallery-actions" [class.visible]="selectedFallback()">
            <a [href]="selectedFallback()" target="_blank" class="btn-PRO">
              <span class="material-symbols-outlined">download</span>
              {{ t9n.t('card_gen.btn_download_selected') || "Télécharger l'image sélectionnée" }}
            </a>
          </div>
        </div>
        }

      </div>
    </div>
  `,
  styles: [`
    .cg-card {
      max-width: 800px;
      width: 90%;
      padding-bottom: 24px;
    }
    .cg-header {
      padding: 24px 24px 16px;
      margin-bottom: 16px;
      border-bottom: 1px solid var(--border-card);
    }
    .cg-header h2 {
      margin: 0;
      font-size: 1.3rem;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .cg-close-btn {
      background: rgba(255, 255, 255, 0.05);
      border: none;
      color: var(--text-muted);
      cursor: pointer;
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      transition: all 0.2s;
    }
    .cg-close-btn:hover {
      background: rgba(255, 255, 255, 0.15);
      color: var(--text-main);
    }
    .tabs-container {
      display: flex;
      background: rgba(0, 0, 0, 0.03);
      border: 1px solid var(--border-card);
      border-radius: 10px;
      padding: 4px;
      margin: 0 24px 20px;
    }
    body.dark-theme .tabs-container {
      background: rgba(255, 255, 255, 0.02);
    }
    .tab-btn {
      flex: 1;
      background: transparent;
      border: none;
      border-radius: 8px;
      padding: 8px 12px;
      font-family: var(--font-title);
      font-weight: 600;
      font-size: 0.9rem;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      cursor: pointer;
      color: var(--text-muted);
      transition: all 0.2s ease;
    }
    .tab-btn:hover {
      color: var(--text-main);
    }
    .tab-btn.active {
      background: var(--bg-card);
      color: hsl(var(--primary-hsl));
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
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
    .mb-4 {
      margin-bottom: 16px;
    }
    .mt-2 {
      margin-top: 12px;
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
    
    /* Gallery Styles */
    .gallery-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      gap: 16px;
      max-height: 400px;
      overflow-y: auto;
      padding-right: 8px;
    }
    
    /* Custom Scrollbar for Gallery */
    .gallery-grid::-webkit-scrollbar {
      width: 6px;
    }
    .gallery-grid::-webkit-scrollbar-track {
      background: rgba(0,0,0,0.05);
      border-radius: 4px;
    }
    .gallery-grid::-webkit-scrollbar-thumb {
      background: rgba(0,0,0,0.2);
      border-radius: 4px;
    }
    
    .gallery-item {
      position: relative;
      border-radius: 12px;
      overflow: hidden;
      cursor: pointer;
      aspect-ratio: 4/3;
      border: 2px solid transparent;
      transition: all 0.2s ease;
    }
    .gallery-item:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 16px rgba(0,0,0,0.1);
    }
    .gallery-item.selected {
      border-color: hsl(var(--primary-hsl));
      transform: translateY(-4px);
      box-shadow: 0 8px 20px rgba(236, 72, 153, 0.3);
    }
    .gallery-item img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    .gallery-item-overlay {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(236, 72, 153, 0.2);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .gallery-item-overlay .material-symbols-outlined {
      font-size: 3rem;
      color: white;
      filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
    }
    .gallery-actions {
      display: flex;
      justify-content: flex-end;
      margin-top: 20px;
      opacity: 0;
      pointer-events: none;
      transform: translateY(10px);
      transition: all 0.3s ease;
    }
    .gallery-actions.visible {
      opacity: 1;
      pointer-events: auto;
      transform: translateY(0);
    }
    .animate-fade {
      animation: fadeIn 0.2s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(4px); }
      to { opacity: 1; transform: translateY(0); }
    }
  `]
})
export class CardGeneratorComponent {
  t9n = inject(TranslationService);
  toast = inject(ToastService);
  http = inject(HttpClient);

  @Input() birthday?: Birthday;
  @Output() close = new EventEmitter<void>();

  mode = signal<'ai' | 'gallery'>('ai');
  prompt = signal<string>('');
  isLoading = signal<boolean>(false);
  imageUrl = signal<string | null>(null);
  errorMsg = signal<string | null>(null);
  
  selectedFallback = signal<string | null>(null);

  readonly fallbackImages = [
    '/assets/images/cards/card-1.png',
    '/assets/images/cards/card-2.png',
    '/assets/images/cards/card-3.png',
    '/assets/images/cards/card-4.png',
    '/assets/images/cards/card-5.png',
    '/assets/images/cards/card-6.png'
  ];

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
          const reader = new FileReader();
          reader.onload = () => {
            try {
              const res = JSON.parse(reader.result as string);
              this.errorMsg.set(res.message);
            } catch {
              this.errorMsg.set(this.t9n.currentLang() === 'en' ? 'Image generation API is not configured yet.' : "L'API de génération d'images n'est pas encore configurée.");
            }
          };
          reader.readAsText(err.error);
        } else {
          this.errorMsg.set(this.t9n.currentLang() === 'en' ? 'An error occurred during generation.' : 'Une erreur est survenue lors de la génération.');
        }
      }
    });
  }

  selectFallback(img: string) {
    this.selectedFallback.set(img);
  }
}
