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
          <a routerLink="/admin/settings" routerLinkActive="active" class="nav-item">Settings</a>
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
      background-color: #f3f4f6;
    }
    .admin-sidebar {
      width: 250px;
      background-color: #1f2937;
      color: white;
      display: flex;
      flex-direction: column;
    }
    .sidebar-header {
      padding: 20px;
      font-size: 1.2rem;
      font-weight: bold;
      border-bottom: 1px solid #374151;
    }
    .sidebar-nav {
      display: flex;
      flex-direction: column;
      padding: 10px 0;
    }
    .nav-item {
      padding: 15px 20px;
      color: #d1d5db;
      text-decoration: none;
      transition: background-color 0.2s;
    }
    .nav-item:hover, .nav-item.active {
      background-color: #374151;
      color: white;
    }
    .back-link {
      margin-top: auto;
      border-top: 1px solid #374151;
      color: #9ca3af;
    }
    .admin-main {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    .admin-header {
      height: 70px;
      background: var(--header-bg);
      backdrop-filter: blur(var(--glass-blur));
      -webkit-backdrop-filter: blur(var(--glass-blur));
      border-bottom: 1px solid var(--border-card);
      box-shadow: 0 1px 10px rgba(0, 0, 0, 0.02);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 30px;
      z-index: 100;
    }
    .header-title {
      font-family: var(--font-title);
      font-weight: 700;
      font-size: 1.25rem;
      display: inline-block;
      background: linear-gradient(135deg, hsl(var(--primary-hsl)) 0%, hsl(var(--accent-hsl)) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .header-actions {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .admin-user {
      font-family: var(--font-body);
      font-size: 0.95rem;
      font-weight: 500;
      color: var(--text-main);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .logout-btn {
      padding: 8px 16px;
      background: rgba(239, 68, 68, 0.1);
      color: #ef4444;
      border: 1px solid rgba(239, 68, 68, 0.2);
      border-radius: 8px;
      font-family: var(--font-title);
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .logout-btn:hover {
      background: #ef4444;
      color: white;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(239, 68, 68, 0.2);
    }
    .admin-content {
      flex: 1;
      padding: 20px;
      overflow-y: auto;
    }
  `]
})
export class AdminLayoutComponent {
  authService = inject(AuthService);
  router = inject(Router);

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/login']);
    });
  }
}
