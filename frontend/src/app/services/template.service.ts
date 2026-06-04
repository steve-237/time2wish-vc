import { Injectable, signal, inject, effect } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MessageTemplate } from '../models/template.model';
import { ToastService } from './toast.service';
import { TranslationService } from './translation.service';
import { AuthService } from './auth.service';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class TemplateService {
  private readonly http = inject(HttpClient);
  private readonly toastService = inject(ToastService);
  private readonly t9n = inject(TranslationService);
  private readonly authService = inject(AuthService);
  private readonly API_URL = 'http://localhost:8081/api/templates';

  // Signal for templates list
  readonly templates = signal<MessageTemplate[]>([]);

  constructor() {
    // Automatically load templates whenever the user logs in
    effect(() => {
      if (this.authService.isAuthenticated()) {
        this.loadTemplates();
      } else {
        this.templates.set([]);
      }
    });
  }

  loadTemplates(): void {
    this.http.get<MessageTemplate[]>(this.API_URL).subscribe({
      next: (list) => {
        this.templates.set(list);
      },
      error: (err) => {
        console.error('Failed to load templates from API', err);
      }
    });
  }

  createTemplate(template: Omit<MessageTemplate, 'id'>): Observable<MessageTemplate> {
    return this.http.post<MessageTemplate>(this.API_URL, template).pipe(
      tap({
        next: (saved) => {
          this.templates.update(list => [...list, saved]);
          this.toastService.success(this.t9n.currentLang() === 'en' ? 'Template created successfully!' : 'Modèle créé avec succès !');
        },
        error: (err) => {
          console.error('Failed to create template', err);
          this.toastService.error(this.t9n.currentLang() === 'en' ? 'Failed to create template.' : 'Échec de création du modèle.');
        }
      })
    );
  }

  updateTemplate(id: number, template: Omit<MessageTemplate, 'id'>): Observable<MessageTemplate> {
    return this.http.put<MessageTemplate>(`${this.API_URL}/${id}`, template).pipe(
      tap({
        next: (updated) => {
          this.templates.update(list => list.map(t => t.id === id ? updated : t));
          this.toastService.success(this.t9n.currentLang() === 'en' ? 'Template updated successfully!' : 'Modèle mis à jour avec succès !');
        },
        error: (err) => {
          console.error('Failed to update template', err);
          this.toastService.error(this.t9n.currentLang() === 'en' ? 'Failed to update template.' : 'Échec de la mise à jour.');
        }
      })
    );
  }

  deleteTemplate(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API_URL}/${id}`).pipe(
      tap({
        next: () => {
          this.templates.update(list => list.filter(t => t.id !== id));
          this.toastService.success(this.t9n.currentLang() === 'en' ? 'Template deleted successfully!' : 'Modèle supprimé avec succès !');
        },
        error: (err) => {
          console.error('Failed to delete template', err);
          this.toastService.error(this.t9n.currentLang() === 'en' ? 'Failed to delete template.' : 'Échec de la suppression.');
        }
      })
    );
  }
}
