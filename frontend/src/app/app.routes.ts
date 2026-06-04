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
    canActivate: [authGuard]
  },
  {
    path: 'birthday/add',
    loadComponent: () => import('./pages/birthday-form/birthday-form').then(m => m.BirthdayForm),
    canActivate: [authGuard]
  },
  {
    path: 'birthday/edit/:id',
    loadComponent: () => import('./pages/birthday-form/birthday-form').then(m => m.BirthdayForm),
    canActivate: [authGuard]
  },
  {
    path: 'birthday/:id',
    loadComponent: () => import('./pages/birthday-detail/birthday-detail').then(m => m.BirthdayDetail),
    canActivate: [authGuard]
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
