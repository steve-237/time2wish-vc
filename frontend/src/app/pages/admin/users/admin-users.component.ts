import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { AdminService, AdminUserDto } from '../../../services/admin.service';
import { AuthService } from '../../../services/auth.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, DatePipe, FormsModule],
  template: `
    <div class="users-container">
      <h2 class="page-title">Gestion des Utilisateurs</h2>
      
      <div class="table-wrapper">
        <table class="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Nom Complet</th>
              <th>Email</th>
              <th>Rôle</th>
              <th>Forfait</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (user of users(); track user.id) {
              <tr>
                <td>#{{ user.id }}</td>
                <td class="font-medium">{{ user.fullName }}</td>
                <td>{{ user.email }}</td>
                <td>
                  <span class="badge role-badge" [class.superadmin]="user.role === 'ROLE_SUPERADMIN'">{{ user.role.replace('ROLE_', '') }}</span>
                </td>
                <td>
                  <select [ngModel]="user.plan" (ngModelChange)="changePlan(user, $event)" class="form-select" [disabled]="user.role === 'ROLE_SUPERADMIN'">
                    <option value="BASIC">BASIC</option>
                    <option value="PLUS">PLUS</option>
                    <option value="PRO">PRO</option>
                  </select>
                </td>
                <td>
                  <span class="badge" 
                    [class.status-active]="user.status === 'ACTIVE'"
                    [class.status-blocked]="user.status === 'BLOCKED'"
                    [class.status-pending]="user.status === 'PENDING_APPROVAL'">
                    {{ user.status }}
                  </span>
                </td>
                <td class="actions-cell">
                  @if (user.status === 'ACTIVE') {
                    <button class="btn btn-danger" (click)="changeStatus(user, 'BLOCKED')" [disabled]="user.role === 'ROLE_SUPERADMIN'">Bloquer</button>
                  } @else if (user.status === 'BLOCKED') {
                    <button class="btn btn-success" (click)="changeStatus(user, 'ACTIVE')">Débloquer</button>
                  } @else if (user.status === 'PENDING_APPROVAL') {
                    <button class="btn btn-primary" (click)="changeStatus(user, 'ACTIVE')">Approuver</button>
                  }
                  
                  @if (isSuperAdmin() && user.role !== 'ROLE_SUPERADMIN') {
                    <button class="btn btn-secondary" (click)="promoteToAdmin(user)" *ngIf="user.role === 'ROLE_USER'">Promouvoir Admin</button>
                    <button class="btn btn-secondary" (click)="demoteToUser(user)" *ngIf="user.role === 'ROLE_ADMIN'">Rétrograder User</button>
                  }
                </td>
              </tr>
            } @empty {
              <tr>
                <td colspan="7" class="empty-state">Aucun utilisateur trouvé.</td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .users-container { padding: 1rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: #111827; margin-bottom: 2rem; }
    .table-wrapper { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); overflow-x: auto; }
    .users-table { width: 100%; border-collapse: collapse; text-align: left; }
    .users-table th, .users-table td { padding: 1rem 1.5rem; border-bottom: 1px solid #e5e7eb; vertical-align: middle; }
    .users-table th { background-color: #f9fafb; font-weight: 600; color: #374151; text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; }
    .font-medium { font-weight: 500; color: #111827; }
    .badge { padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; }
    .status-active { background-color: #d1fae5; color: #065f46; }
    .status-blocked { background-color: #fee2e2; color: #991b1b; }
    .status-pending { background-color: #fef3c7; color: #92400e; }
    .role-badge { background-color: #e0e7ff; color: #3730a3; }
    .role-badge.superadmin { background-color: #fce7f3; color: #9d174d; }
    .actions-cell { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .btn { padding: 0.375rem 0.75rem; border-radius: 6px; font-size: 0.875rem; font-weight: 500; border: none; cursor: pointer; transition: background-color 0.2s; }
    .btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-primary { background-color: #3b82f6; color: white; }
    .btn-primary:hover:not(:disabled) { background-color: #2563eb; }
    .btn-success { background-color: #10b981; color: white; }
    .btn-success:hover { background-color: #059669; }
    .btn-danger { background-color: #ef4444; color: white; }
    .btn-danger:hover { background-color: #dc2626; }
    .btn-secondary { background-color: #6b7280; color: white; }
    .btn-secondary:hover { background-color: #4b5563; }
    .form-select { padding: 0.25rem 0.5rem; border-radius: 4px; border: 1px solid #d1d5db; outline: none; }
    .empty-state { text-align: center; padding: 3rem; color: #6b7280; }
  `]
})
export class AdminUsersComponent implements OnInit {
  private adminService = inject(AdminService);
  private authService = inject(AuthService);
  users = signal<AdminUserDto[]>([]);

  ngOnInit() {
    this.loadUsers();
  }

  isSuperAdmin(): boolean {
    const user = this.authService.currentUser();
    return user?.roles?.includes('ROLE_SUPERADMIN') ?? false;
  }

  loadUsers() {
    this.adminService.getAllUsers().subscribe({
      next: (data) => this.users.set(data),
      error: (err) => console.error('Error fetching users', err)
    });
  }

  changeStatus(user: AdminUserDto, newStatus: string) {
    if (confirm(`Êtes-vous sûr de vouloir passer ce compte en ${newStatus} ?`)) {
      this.adminService.updateUserStatus(user.id, newStatus).subscribe({
        next: () => {
          this.users.update(list => list.map(u => u.id === user.id ? { ...u, status: newStatus } : u));
        },
        error: (err) => alert(err.error?.message || 'Erreur lors de la modification')
      });
    }
  }

  changePlan(user: AdminUserDto, newPlan: string) {
    this.adminService.updateUserPlan(user.id, newPlan).subscribe({
      next: () => {
        this.users.update(list => list.map(u => u.id === user.id ? { ...u, plan: newPlan } : u));
      },
      error: (err) => alert('Erreur lors de la modification du forfait')
    });
  }

  promoteToAdmin(user: AdminUserDto) {
    this.adminService.updateUserRole(user.id, 'ROLE_ADMIN').subscribe({
      next: () => {
        this.users.update(list => list.map(u => u.id === user.id ? { ...u, role: 'ROLE_ADMIN' } : u));
      },
      error: (err) => alert('Erreur lors de la promotion')
    });
  }

  demoteToUser(user: AdminUserDto) {
    this.adminService.updateUserRole(user.id, 'ROLE_USER').subscribe({
      next: () => {
        this.users.update(list => list.map(u => u.id === user.id ? { ...u, role: 'ROLE_USER' } : u));
      },
      error: (err) => alert('Erreur lors de la rétrogradation')
    });
  }
}
