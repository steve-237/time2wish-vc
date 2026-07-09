import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FeedbackService, Feedback } from '../../../services/feedback.service';

@Component({
  selector: 'app-admin-feedbacks',
  standalone: true,
  imports: [CommonModule, DatePipe],
  template: `
    <div class="admin-container">
      <div class="header-container flex-between">
        <div>
          <h2 class="page-title">Avis Utilisateurs ⭐</h2>
          <p class="page-subtitle">Consultez les retours d'expérience sur l'application</p>
        </div>
        <div class="global-rating" *ngIf="feedbacks().length > 0">
          <div class="rating-value">{{ averageRating() | number:'1.1-1' }}</div>
          <div class="stars">
            @for (star of [1,2,3,4,5]; track star) {
              <span class="material-symbols-outlined" [class.active]="star <= Math.round(averageRating())">star</span>
            }
          </div>
          <div class="rating-count">{{ feedbacks().length }} avis</div>
        </div>
      </div>

      <div class="filters mb-4">
        <button class="filter-btn" [class.active]="filter() === 0" (click)="filter.set(0)">Tous</button>
        <button class="filter-btn" [class.active]="filter() === 5" (click)="filter.set(5)">5 étoiles</button>
        <button class="filter-btn" [class.active]="filter() === 4" (click)="filter.set(4)">4 étoiles</button>
        <button class="filter-btn" [class.active]="filter() === 3" (click)="filter.set(3)">3 étoiles</button>
        <button class="filter-btn" [class.active]="filter() === 2" (click)="filter.set(2)">2 étoiles</button>
        <button class="filter-btn" [class.active]="filter() === 1" (click)="filter.set(1)">1 étoile</button>
      </div>

      <div class="feedbacks-grid">
        @for (fb of filteredFeedbacks(); track fb.id) {
          <div class="feedback-card">
            <div class="card-header">
              <img [src]="fb.user?.avatarUrl || getInitialsAvatar(fb.user?.fullName)" class="user-avatar" alt="Avatar">
              <div class="user-info">
                <strong>{{ fb.user?.fullName || 'Utilisateur inconnu' }}</strong>
                <span>{{ fb.createdAt | date:'short' }}</span>
              </div>
            </div>
            
            <div class="stars-display mb-3">
              @for (star of [1,2,3,4,5]; track star) {
                <span class="material-symbols-outlined" [class.active]="star <= fb.rating">star</span>
              }
            </div>

            <div class="comment-text">
              <span *ngIf="fb.comment">{{ fb.comment }}</span>
              <span *ngIf="!fb.comment" class="no-comment">Aucun commentaire fourni.</span>
            </div>
          </div>
        } @empty {
          <div class="empty-state">
            <span class="material-symbols-outlined">sentiment_dissatisfied</span>
            <p>Aucun avis trouvé pour ce filtre.</p>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .admin-container { padding: 1rem; }
    .header-container { margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: flex-end; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .global-rating { display: flex; flex-direction: column; align-items: flex-end; }
    .rating-value { font-size: 2.5rem; font-weight: 800; color: var(--text-main); line-height: 1; margin-bottom: 4px; }
    .stars { display: flex; gap: 2px; }
    .stars .material-symbols-outlined { font-size: 1.2rem; color: var(--border-card); font-variation-settings: 'FILL' 1; }
    .stars .material-symbols-outlined.active { color: #f59e0b; }
    .rating-count { font-size: 0.85rem; color: var(--text-muted); margin-top: 4px; }

    .mb-4 { margin-bottom: 1.5rem; }
    .mb-3 { margin-bottom: 1rem; }

    .filters { display: flex; gap: 8px; flex-wrap: wrap; }
    .filter-btn { padding: 6px 16px; border-radius: 20px; border: 1px solid var(--border-card); background: transparent; color: var(--text-muted); cursor: pointer; font-size: 0.85rem; font-weight: 500; transition: all 0.2s; }
    .filter-btn:hover { border-color: var(--primary); color: var(--primary); }
    .filter-btn.active { background: var(--primary); color: white; border-color: var(--primary); }

    .feedbacks-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; }
    
    .feedback-card { background: var(--bg-card); border: 1px solid var(--border-card); border-radius: 16px; padding: 1.5rem; box-shadow: var(--glass-shadow); }
    .card-header { display: flex; gap: 12px; margin-bottom: 1rem; align-items: center; }
    .user-avatar { width: 44px; height: 44px; border-radius: 50%; object-fit: cover; }
    .user-info { display: flex; flex-direction: column; }
    .user-info strong { color: var(--text-main); font-size: 0.95rem; }
    .user-info span { color: var(--text-muted); font-size: 0.8rem; }
    
    .stars-display { display: flex; gap: 2px; }
    .stars-display .material-symbols-outlined { font-size: 1.1rem; color: var(--border-card); font-variation-settings: 'FILL' 1; }
    .stars-display .material-symbols-outlined.active { color: #f59e0b; }

    .comment-text { color: var(--text-main); font-size: 0.95rem; line-height: 1.5; white-space: pre-wrap; }
    .no-comment { color: var(--text-muted); font-style: italic; }

    .empty-state { grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 4rem; color: var(--text-muted); text-align: center; }
    .empty-state .material-symbols-outlined { font-size: 4rem; margin-bottom: 1rem; opacity: 0.5; }
  `]
})
export class AdminFeedbacksComponent implements OnInit {
  private feedbackService = inject(FeedbackService);
  
  feedbacks = signal<Feedback[]>([]);
  filter = signal<number>(0);
  Math = Math;

  filteredFeedbacks = computed(() => {
    const r = this.filter();
    if (r === 0) return this.feedbacks();
    return this.feedbacks().filter(f => f.rating === r);
  });

  averageRating = computed(() => {
    const list = this.feedbacks();
    if (list.length === 0) return 0;
    const sum = list.reduce((acc, f) => acc + f.rating, 0);
    return sum / list.length;
  });

  ngOnInit() {
    this.feedbackService.getAllFeedbacks().subscribe({
      next: (data) => this.feedbacks.set(data)
    });
  }

  getInitialsAvatar(name?: string): string {
    if (!name) return 'https://ui-avatars.com/api/?name=U&background=random';
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    const color = Math.floor(Math.abs((Math.sin(hash) * 10000) % 1 * 16777215)).toString(16).padStart(6, '0');
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=${color}&color=fff&rounded=true&bold=true`;
  }
}
