import { ApplicationConfig, provideBrowserGlobalErrorListeners, isDevMode, APP_INITIALIZER } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './interceptors/auth.interceptor';
import { MatPaginatorIntl } from '@angular/material/paginator';
import { CustomMatPaginatorIntl } from './services/custom-paginator-intl';
import { provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { provideServiceWorker } from '@angular/service-worker';
import { AuthService } from './services/auth.service';
import { ToastService } from './services/toast.service';

export function initializeAuth(authService: AuthService, toastService: ToastService) {
  return () => {
    let serverWakingToastId: number | null = null;
    let isCompleted = false;

    // Si le serveur met plus de 2.5 secondes à répondre (Render Free Tier Cold Start)
    const timeout = setTimeout(() => {
      if (!isCompleted) {
        serverWakingToastId = toastService.info('⏳ Le serveur sort de veille, synchronisation en cours... (1-2 min)', 120000);
      }
    }, 2500);

    // Launch the refresh in the background but resolve immediately
    // so the frontend doesn't wait (white screen) if the backend is waking up.
    authService.refreshSession().subscribe(() => {
      isCompleted = true;
      clearTimeout(timeout);
      if (serverWakingToastId !== null) {
        toastService.remove(serverWakingToastId);
        toastService.success('Serveur synchronisé et prêt !', 3000);
      }
    });
    
    return Promise.resolve(true);
  };
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),
    { provide: MatPaginatorIntl, useClass: CustomMatPaginatorIntl },
    { provide: APP_INITIALIZER, useFactory: initializeAuth, deps: [AuthService, ToastService], multi: true },
    provideCharts(withDefaultRegisterables()),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000'
    })
  ]
};
