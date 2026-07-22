import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { GoogleSyncService } from '../../services/google-sync.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-google-callback',
  standalone: true,
  template: `<div style="display: flex; justify-content: center; align-items: center; height: 100vh; flex-direction: column; gap: 16px;">
    <div class="loader" style="width: 48px; height: 48px; border: 4px solid var(--border-card); border-top-color: #4285F4; border-radius: 50%; animation: spin 1s linear infinite;"></div>
    <h2 style="font-family: var(--font-title); color: var(--text-main);">Connexion à Google en cours...</h2>
  </div>
  <style>
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  </style>`
})
export class GoogleCallbackComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private googleSyncService = inject(GoogleSyncService);
  private toastService = inject(ToastService);

  ngOnInit() {
    this.route.queryParams.subscribe(params => {
      const code = params['code'];
      const error = params['error'];

      if (error) {
        this.toastService.error('Erreur lors de la connexion à Google: ' + error);
        this.router.navigate(['/dashboard']);
        return;
      }

      if (code) {
        this.googleSyncService.handleCallback(code).subscribe({
          next: () => {
            this.toastService.success('Compte Google connecté avec succès ! Vous pouvez maintenant synchroniser.');
            this.router.navigate(['/dashboard']);
          },
          error: (err) => {
            this.toastService.error('Erreur lors de la validation du code Google.');
            console.error(err);
            this.router.navigate(['/dashboard']);
          }
        });
      } else {
        this.router.navigate(['/dashboard']);
      }
    });
  }
}
