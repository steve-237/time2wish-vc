import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./pages/login/login').then(m => m.Login)
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./pages/dashboard/dashboard').then(m => m.Dashboard),
    canActivate: [authGuard],
    children: [
      {
        path: 'profile',
        loadComponent: () => import('./pages/profile/profile').then(m => m.Profile)
      },
      {
        path: 'birthday/add',
        loadComponent: () => import('./pages/birthday-form/birthday-form').then(m => m.BirthdayForm)
      },
      {
        path: 'birthday/edit/:id',
        loadComponent: () => import('./pages/birthday-form/birthday-form').then(m => m.BirthdayForm)
      },
      {
        path: 'birthday/:id',
        loadComponent: () => import('./pages/birthday-detail/birthday-detail').then(m => m.BirthdayDetail)
      },
      {
        path: 'stats',
        loadComponent: () => import('./components/statistics-modal/statistics-modal.component').then(m => m.StatisticsModalComponent)
      }
    ]
  },
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full'
  },
  {
    path: '**',
    redirectTo: 'dashboard'
  }
];
