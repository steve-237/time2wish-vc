import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { AdminService, AdminUserDto } from '../../../services/admin.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, DatePipe, FormsModule],
  template: `
    <div class="users-container">
      <h2 class="page-title">User Management</h2>
      
      <div class="table-wrapper">
        <table class="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Full Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status</th>
              <th>Created At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (user of users(); track user.id) {
              <tr>
                <td>#{{ user.id }}</td>
                <td class="font-medium">{{ user.fullName }}</td>
                <td>{{ user.email }}</td>
                <td><span class="badge role-badge">{{ user.role }}</span></td>
                <td><span class="badge" [class.status-active]="user.status === 'ACTIVE'">{{ user.status }}</span></td>
                <td>{{ user.createdAt | date:'shortDate' }}</td>
                <td class="actions-cell">
                  <button class="btn btn-warning" (click)="openPasswordModal(user)">Reset Password</button>
                  <button class="btn btn-danger" (click)="deleteUser(user)">Delete</button>
                </td>
              </tr>
            } @empty {
              <tr>
                <td colspan="7" class="empty-state">No users found.</td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      @if (selectedUser()) {
        <div class="modal-backdrop">
          <div class="modal-content">
            <h3>Reset Password for {{ selectedUser()?.fullName }}</h3>
            <div class="form-group">
              <label>New Password:</label>
              <input type="password" [(ngModel)]="newPassword" class="form-input" placeholder="Enter new password">
            </div>
            <div class="modal-actions">
              <button class="btn btn-secondary" (click)="closeModal()">Cancel</button>
              <button class="btn btn-primary" (click)="submitPassword()" [disabled]="!newPassword">Update</button>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .users-container {
      padding: 1rem;
    }
    .page-title {
      font-size: 1.5rem;
      font-weight: 600;
      color: #111827;
      margin-bottom: 2rem;
    }
    .table-wrapper {
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      overflow-x: auto;
    }
    .users-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    .users-table th, .users-table td {
      padding: 1rem 1.5rem;
      border-bottom: 1px solid #e5e7eb;
    }
    .users-table th {
      background-color: #f9fafb;
      font-weight: 600;
      color: #374151;
      text-transform: uppercase;
      font-size: 0.75rem;
      letter-spacing: 0.05em;
    }
    .font-medium {
      font-weight: 500;
      color: #111827;
    }
    .badge {
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background-color: #f3f4f6;
      color: #374151;
    }
    .status-active {
      background-color: #d1fae5;
      color: #065f46;
    }
    .role-badge {
      background-color: #e0e7ff;
      color: #3730a3;
    }
    .actions-cell {
      display: flex;
      gap: 0.5rem;
    }
    .btn {
      padding: 0.375rem 0.75rem;
      border-radius: 6px;
      font-size: 0.875rem;
      font-weight: 500;
      border: none;
      cursor: pointer;
      transition: background-color 0.2s;
    }
    .btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
    .btn-primary { background-color: #3b82f6; color: white; }
    .btn-primary:hover:not(:disabled) { background-color: #2563eb; }
    .btn-warning { background-color: #f59e0b; color: white; }
    .btn-warning:hover { background-color: #d97706; }
    .btn-danger { background-color: #ef4444; color: white; }
    .btn-danger:hover { background-color: #dc2626; }
    .btn-secondary { background-color: #9ca3af; color: white; }
    .btn-secondary:hover { background-color: #6b7280; }
    
    .empty-state {
      text-align: center;
      padding: 3rem;
      color: #6b7280;
    }

    .modal-backdrop {
      position: fixed;
      top: 0; left: 0; width: 100%; height: 100%;
      background-color: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 50;
    }
    .modal-content {
      background: white;
      padding: 2rem;
      border-radius: 12px;
      width: 100%;
      max-width: 400px;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }
    .modal-content h3 {
      margin-top: 0;
      margin-bottom: 1.5rem;
      color: #111827;
    }
    .form-group {
      margin-bottom: 1.5rem;
    }
    .form-group label {
      display: block;
      margin-bottom: 0.5rem;
      font-size: 0.875rem;
      color: #374151;
      font-weight: 500;
    }
    .form-input {
      width: 100%;
      padding: 0.5rem 0.75rem;
      border: 1px solid #d1d5db;
      border-radius: 6px;
      outline: none;
    }
    .form-input:focus {
      border-color: #3b82f6;
      box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    }
    .modal-actions {
      display: flex;
      justify-content: flex-end;
      gap: 1rem;
    }
  `]
})
export class AdminUsersComponent implements OnInit {
  private adminService = inject(AdminService);
  users = signal<AdminUserDto[]>([]);
  
  selectedUser = signal<AdminUserDto | null>(null);
  newPassword = '';

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.adminService.getAllUsers().subscribe({
      next: (data) => this.users.set(data),
      error: (err) => console.error('Error fetching users', err)
    });
  }

  deleteUser(user: AdminUserDto) {
    if (confirm(`Are you sure you want to completely delete user ${user.fullName} and all their data?`)) {
      this.adminService.deleteUser(user.id).subscribe({
        next: () => {
          this.users.set(this.users().filter(u => u.id !== user.id));
        },
        error: (err) => console.error('Error deleting user', err)
      });
    }
  }

  openPasswordModal(user: AdminUserDto) {
    this.selectedUser.set(user);
    this.newPassword = '';
  }

  closeModal() {
    this.selectedUser.set(null);
    this.newPassword = '';
  }

  submitPassword() {
    const user = this.selectedUser();
    if (user && this.newPassword) {
      this.adminService.updateUserPassword(user.id, this.newPassword).subscribe({
        next: () => {
          alert('Password updated successfully!');
          this.closeModal();
        },
        error: (err) => {
          console.error('Error updating password', err);
          alert('Failed to update password');
        }
      });
    }
  }
}
