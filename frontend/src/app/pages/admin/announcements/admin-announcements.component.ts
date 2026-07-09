import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AnnouncementService, Announcement } from '../../../services/announcement.service';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-announcements',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  template: `
    <div class="admin-container">
      <div class="header-container flex-between">
        <div>
          <h2 class="page-title">Annonces Globales</h2>
          <p class="page-subtitle">Publiez des messages importants pour tous les utilisateurs</p>
        </div>
        <button class="btn-PRO" (click)="isModalOpen.set(true)" *ngIf="!isModalOpen()">
          <span class="material-symbols-outlined">campaign</span>
          Nouvelle Annonce
        </button>
      </div>

      <!-- New Announcement Form -->
      @if (isModalOpen()) {
        <div class="glass-card mb-4">
          <h3>Rédiger une annonce</h3>
          <div class="form-group mt-3">
            <label class="form-label">Titre</label>
            <input type="text" class="form-control" [(ngModel)]="newAnnouncement.title" placeholder="Ex: Maintenance prévue, Nouvelle fonctionnalité...">
          </div>
          <div class="form-group mt-3">
            <label class="form-label">Message</label>
            <textarea class="form-control" rows="3" [(ngModel)]="newAnnouncement.message" placeholder="Détails de l'annonce..."></textarea>
          </div>
          <div class="form-group mt-3">
            <label class="form-label">Type d'affichage</label>
            <select class="form-control" [(ngModel)]="newAnnouncement.type">
              <option value="INFO">Information (Bleu)</option>
              <option value="SUCCESS">Succès (Vert)</option>
              <option value="WARNING">Avertissement (Orange)</option>
            </select>
          </div>
          
          <label class="toggle-switch mt-4" style="display: flex; align-items: center; gap: 12px; cursor: pointer; width: fit-content;">
            <input type="checkbox" [(ngModel)]="newAnnouncement.isActive">
            <span class="slider"></span>
            <span style="color: var(--text-main); font-weight: 500;">Activer immédiatement</span>
          </label>

          <div class="mt-4 flex-gap">
            <button class="btn btn-secondary" (click)="closeModal()">Annuler</button>
            <button class="btn-PRO" (click)="submitAnnouncement()" [disabled]="!newAnnouncement.title || !newAnnouncement.message || isSubmitting()">
              {{ isSubmitting() ? 'Création...' : 'Créer l\'annonce' }}
            </button>
          </div>
        </div>
      }

      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>Statut</th>
              <th>Type</th>
              <th>Titre & Message</th>
              <th>Date de création</th>
              <th style="text-align: right;">Action</th>
            </tr>
          </thead>
          <tbody>
            @for (ann of announcements(); track ann.id) {
              <tr [class.is-active]="ann.isActive">
                <td>
                  <span class="badge" [ngClass]="ann.isActive ? 'badge-success' : 'badge-neutral'">
                    {{ ann.isActive ? 'Publiée' : 'Brouillon' }}
                  </span>
                </td>
                <td>
                  <span class="badge" [ngClass]="'badge-' + ann.type.toLowerCase()">{{ ann.type }}</span>
                </td>
                <td>
                  <strong>{{ ann.title }}</strong>
                  <p style="margin: 4px 0 0; font-size: 0.85rem; color: var(--text-muted);">{{ ann.message }}</p>
                </td>
                <td style="color: var(--text-muted); font-size: 0.85rem;">{{ ann.createdAt | date:'short' }}</td>
                <td style="text-align: right;">
                  <button class="btn btn-sm" [ngClass]="ann.isActive ? 'btn-secondary text-error' : 'btn-PRO'" (click)="toggle(ann.id)">
                    <span class="material-symbols-outlined">{{ ann.isActive ? 'visibility_off' : 'visibility' }}</span>
                    {{ ann.isActive ? 'Masquer' : 'Publier' }}
                  </button>
                </td>
              </tr>
            } @empty {
              <tr><td colspan="5" style="text-align: center; padding: 2rem; color: var(--text-muted);">Aucune annonce.</td></tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .admin-container { padding: 1rem; }
    .header-container { margin-bottom: 2rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin: 0 0 0.5rem 0; }
    .page-subtitle { color: var(--text-muted); margin: 0; font-size: 0.95rem; }
    
    .mb-4 { margin-bottom: 1.5rem; }
    .mt-3 { margin-top: 1rem; }
    .mt-4 { margin-top: 1.5rem; }
    .flex-between { display: flex; justify-content: space-between; align-items: center; }
    .flex-gap { display: flex; gap: 1rem; }
    
    .table-wrapper { background: var(--bg-card); border-radius: 12px; box-shadow: var(--glass-shadow); overflow: hidden; border: 1px solid var(--border-card); }
    .data-table { width: 100%; border-collapse: collapse; text-align: left; color: var(--text-main); }
    .data-table th, .data-table td { padding: 1rem; border-bottom: 1px solid var(--border-card); vertical-align: middle; }
    .data-table th { font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; background: rgba(0,0,0,0.02); }
    .data-table tr.is-active { background: rgba(16, 185, 129, 0.05); }
    
    .badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }
    .badge-success { background: rgba(16, 185, 129, 0.1); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.2); }
    .badge-info { background: rgba(59, 130, 246, 0.1); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.2); }
    .badge-warning { background: rgba(245, 158, 11, 0.1); color: #f59e0b; border: 1px solid rgba(245, 158, 11, 0.2); }
    .badge-neutral { background: rgba(100, 116, 139, 0.1); color: #64748b; border: 1px solid rgba(100, 116, 139, 0.2); }
    
    .btn-sm { padding: 0.35rem 0.75rem; font-size: 0.85rem; display: inline-flex; align-items: center; gap: 0.35rem; }
    .btn-sm .material-symbols-outlined { font-size: 1.1rem; }
    .text-error { color: #ef4444 !important; border-color: #ef4444 !important; }

    /* Toggle Switch */
    .toggle-switch { position: relative; width: auto; height: 24px; }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .slider { position: relative; display: inline-block; width: 44px; height: 24px; background-color: #cbd5e1; border-radius: 24px; transition: .4s; }
    .slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; border-radius: 50%; transition: .4s; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
    input:checked + .slider { background-color: var(--primary); }
    input:checked + .slider:before { transform: translateX(20px); }
  `]
})
export class AdminAnnouncementsComponent implements OnInit {
  private announcementService = inject(AnnouncementService);
  private toast = inject(ToastService);

  announcements = signal<Announcement[]>([]);
  isModalOpen = signal(false);
  isSubmitting = signal(false);

  newAnnouncement: Partial<Announcement> = {
    title: '',
    message: '',
    type: 'INFO',
    isActive: false
  };

  ngOnInit() {
    this.load();
  }

  load() {
    this.announcementService.getAllAnnouncements().subscribe({
      next: (data) => this.announcements.set(data)
    });
  }

  closeModal() {
    this.isModalOpen.set(false);
    this.newAnnouncement = { title: '', message: '', type: 'INFO', isActive: false };
  }

  submitAnnouncement() {
    this.isSubmitting.set(true);
    this.announcementService.createAnnouncement(this.newAnnouncement).subscribe({
      next: (ann) => {
        this.announcements.update(arr => [ann, ...arr]);
        this.toast.success('Annonce créée');
        this.closeModal();
        this.isSubmitting.set(false);
      },
      error: () => {
        this.toast.error('Erreur lors de la création');
        this.isSubmitting.set(false);
      }
    });
  }

  toggle(id: number) {
    this.announcementService.toggleAnnouncement(id).subscribe({
      next: (updated) => {
        this.announcements.update(arr => arr.map(a => a.id === updated.id ? updated : a));
      }
    });
  }
}
