import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';

export const routes: Routes = [
  {
    path: 'admin/login',
    loadComponent: () => import('./pages/admin/auth/admin-login.component').then(m => m.AdminLoginComponent)
  },
  {
    path: 'admin/register',
    loadComponent: () => import('./pages/admin/auth/admin-register.component').then(m => m.AdminRegisterComponent)
  },
  {
    path: 'admin',
    loadComponent: () => import('./layouts/admin-layout/admin-layout.component').then(m => m.AdminLayoutComponent),
    canActivate: [authGuard, adminGuard],
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
      },
      {
        path: 'dashboard',
        loadComponent: () => import('./pages/admin/dashboard/admin-dashboard.component').then(m => m.AdminDashboardComponent)
      },
      {
        path: 'users',
        loadComponent: () => import('./pages/admin/users/admin-users.component').then(m => m.AdminUsersComponent)
      }
    ]
  },
  {
    path: '',
    loadComponent: () => import('./layouts/main-layout/main-layout.component').then(m => m.MainLayoutComponent),
    children: [
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
        path: 'dashboard/messaging',
        loadComponent: () => import('./pages/messaging/messaging').then(m => m.MessagingPage),
        canActivate: [authGuard]
      },
      {
        path: 'dashboard/contacts',
        loadComponent: () => import('./pages/contacts/contacts').then(m => m.ContactsPage),
        canActivate: [authGuard]
      },
      {
        path: 'privacy',
        loadComponent: () => import('./pages/legal/privacy.component').then(m => m.PrivacyComponent)
      },
      {
        path: 'terms',
        loadComponent: () => import('./pages/legal/terms.component').then(m => m.TermsComponent)
      },
      {
        path: 'support',
        loadComponent: () => import('./pages/legal/support.component').then(m => m.SupportComponent)
      },
      {
        path: 'shared/:token',
        loadComponent: () => import('./pages/shared-list/shared-list.component').then(m => m.SharedListComponent)
      },
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: '404',
    loadComponent: () => import('./pages/not-found/not-found.component').then(m => m.NotFoundComponent)
  },
  {
    path: '**',
    redirectTo: '404'
  }
];
