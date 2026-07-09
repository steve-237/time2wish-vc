import { Component, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule],
  template: `
    <div class="admin-layout">
      <aside class="admin-sidebar">
        <div class="sidebar-header">
          <h2>Admin Panel</h2>
        </div>
        <nav class="sidebar-nav">
          <a routerLink="/admin/dashboard" routerLinkActive="active" class="nav-item">Dashboard</a>
          <a routerLink="/admin/users" routerLinkActive="active" class="nav-item">Users</a>
          <a routerLink="/admin/payments" routerLinkActive="active" class="nav-item">Paiements 💳</a>
          <a routerLink="/admin/settings" routerLinkActive="active" class="nav-item">Paramètres ⚙️</a>
          <a routerLink="/dashboard" class="nav-item back-link">Back to App</a>
        </nav>
      </aside>

      <main class="admin-main">
        <header class="admin-header">
          <div class="header-title">
            Time2Wish Administration
          </div>
          <div class="header-actions">
            <span class="admin-user">{{ authService.currentUser()?.fullName }} (Admin)</span>
            <button class="logout-btn" (click)="onLogout()">Logout</button>
          </div>
        </header>
        <div class="admin-content">
          <router-outlet></router-outlet>
        </div>
      </main>
    </div>
  `,
  styles: [`
    .admin-layout {
      display: flex;
      height: 100vh;
      background-color: var(--bg-main);
      font-family: 'Inter', sans-serif;
      color: var(--text-main);
    }
    .admin-sidebar {
      width: 250px;
      background-color: var(--bg-card);
      border-right: 1px solid var(--border-card);
      display: flex;
      flex-direction: column;
      z-index: 10;
    }
    .sidebar-header {
      padding: 24px 20px;
      font-size: 1.25rem;
      font-weight: 700;
      border-bottom: 1px solid var(--border-card);
      display: flex;
      align-items: center;
      gap: 10px;
      color: var(--text-main);
    }
    .sidebar-header .material-symbols-outlined {
      color: var(--primary);
    }
    .sidebar-nav {
      display: flex;
      flex-direction: column;
      padding: 16px 0;
    }
    .nav-item {
      padding: 12px 24px;
      color: var(--text-muted);
      text-decoration: none;
      font-weight: 500;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .nav-item:hover, .nav-item.active {
      background-color: var(--bg-main);
      color: var(--primary);
      border-right: 3px solid var(--primary);
    }
    .back-link {
      margin-top: auto;
      border-top: 1px solid var(--border-card);
      color: var(--text-muted);
    }
    .admin-main {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      background-color: var(--bg-main);
    }
    .admin-header {
      height: 70px;
      background: var(--bg-card);
      border-bottom: 1px solid var(--border-card);
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 32px;
      z-index: 5;
    }
    .header-title {
      font-weight: 600;
      font-size: 1.1rem;
      color: var(--text-main);
    }
    .header-actions {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .admin-user {
      font-size: 0.9rem;
      font-weight: 500;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .logout-btn {
      padding: 8px 16px;
      background: transparent;
      color: var(--text-main);
      border: 1px solid var(--border-card);
      border-radius: 6px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
    }
    .logout-btn:hover {
      background: var(--bg-main);
      border-color: var(--primary);
      color: var(--primary);
    }
    .admin-content {
      flex: 1;
      padding: 32px;
      overflow-y: auto;
    }
  `]
})
export class AdminLayoutComponent {
  authService = inject(AuthService);
  router = inject(Router);

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/admin/login']);
    });
  }
}
