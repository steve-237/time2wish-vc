import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { AdminService, AdminUserDto } from '../../../services/admin.service';
import { AuthService } from '../../../services/auth.service';
import { FormsModule } from '@angular/forms';
import { TranslationService } from '../../../services/translation.service';

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, DatePipe, FormsModule],
  template: `
    <div class="users-container">
      <h2 class="page-title">{{ t9n.t('admin.users.title') }}</h2>
      
      <div class="table-wrapper">
        <table class="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>{{ t9n.t('admin.users.col_user') }}</th>
              <th>Email</th>
              <th>{{ t9n.t('admin.users.col_role') }}</th>
              <th>{{ t9n.t('admin.users.col_plan') }}</th>
              <th>{{ t9n.t('admin.users.col_status') }}</th>
              <th>{{ t9n.t('admin.users.col_actions') }}</th>
            </tr>
          </thead>
          <tbody>
            @for (user of users(); track user.id) {
              <tr>
                <td>#{{ user.id }}</td>
                <td class="font-medium">{{ user.fullName }}</td>
                <td>{{ user.email }}</td>
                <td>
                  <span class="badge role-badge" 
                        [class.admin]="user.role === 'ROLE_ADMIN'"
                        [class.superadmin]="user.role === 'ROLE_SUPERADMIN'">
                    {{ user.role === 'ROLE_USER' ? t9n.t('admin.users.role_user') : (user.role === 'ROLE_ADMIN' ? t9n.t('admin.users.role_admin') : 'Super Admin') }}
                  </span>
                </td>
                <td>
                  <select [value]="user.plan" (change)="onPlanChange($event, user)" class="form-select" [disabled]="user.role === 'ROLE_SUPERADMIN'">
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
                    {{ user.status === 'ACTIVE' ? t9n.t('admin.users.status_active') : (user.status === 'BLOCKED' ? t9n.t('admin.users.status_banned') : t9n.t('admin.users.status_pending')) }}
                  </span>
                </td>
                <td class="actions-cell">
                  @if (user.status === 'ACTIVE') {
                    <button class="btn btn-danger" (click)="requestAction(user, 'status', 'BLOCKED')" [disabled]="user.role === 'ROLE_SUPERADMIN'">{{ t9n.t('admin.users.btn_ban') }}</button>
                  } @else if (user.status === 'BLOCKED') {
                    <button class="btn btn-success" (click)="requestAction(user, 'status', 'ACTIVE')">{{ t9n.t('admin.users.btn_unban') }}</button>
                  } @else if (user.status === 'PENDING_APPROVAL') {
                    <button class="btn btn-primary" (click)="requestAction(user, 'status', 'ACTIVE')">{{ t9n.t('admin.users.btn_approve') }}</button>
                  }
                  
                  @if (isSuperAdmin() && user.role !== 'ROLE_SUPERADMIN') {
                    <button class="btn btn-secondary" (click)="requestAction(user, 'role', 'ROLE_ADMIN')" *ngIf="user.role === 'ROLE_USER'">Admin</button>
                    <button class="btn btn-secondary" (click)="requestAction(user, 'role', 'ROLE_USER')" *ngIf="user.role === 'ROLE_ADMIN'">User</button>
                    <button class="btn btn-danger btn-outline" (click)="requestAction(user, 'delete', '')" [title]="t9n.t('admin.users.btn_delete')">
                      <span class="material-symbols-outlined" style="font-size: 1.1rem; vertical-align: middle;">delete</span>
                    </button>
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

    <!-- Confirmation Modal Overlay -->
    @if (modalState().isOpen) {
    <div class="tm-modal-overlay">
      <div class="tm-modal-content confirm-modal-content">
        <div class="confirm-modal-header">
          <h3>Confirmation</h3>
          <button class="icon-btn" (click)="closeModal()">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>
        <div class="confirm-modal-body">
          <p>{{ getModalMessage() }}</p>
          <div class="confirm-user-preview">
            <strong>{{ modalState().user?.fullName }}</strong> ({{ modalState().user?.email }})
          </div>
        </div>
        <div class="confirm-modal-actions">
          <button class="btn btn-secondary" (click)="closeModal()">{{ t9n.t('form.btn_cancel') }}</button>
          <button class="btn" 
                  [class.btn-primary]="modalState().actionType !== 'delete' && modalState().actionValue !== 'BLOCKED'"
                  [class.btn-danger]="modalState().actionType === 'delete' || modalState().actionValue === 'BLOCKED'"
                  (click)="confirmAction()">
            Confirmer
          </button>
        </div>
      </div>
    </div>
    }
  `,
  styles: [`
    .users-container { padding: 1rem; }
    .page-title { font-size: 1.5rem; font-weight: 600; color: #111827; margin-bottom: 2rem; }
    .table-wrapper { background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); overflow-x: auto; }
    .users-table { width: 100%; border-collapse: collapse; text-align: left; }
    .users-table th, .users-table td { padding: 1rem 1.5rem; border-bottom: 1px solid #e5e7eb; vertical-align: middle; }
    .users-table th { background-color: #f9fafb; font-weight: 600; color: #374151; text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; }
    .font-medium { font-weight: 500; color: #111827; }
    
    .badge { padding: 0.3rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; display: inline-block; }
    .status-active { background-color: #d1fae5; color: #065f46; }
    .status-blocked { background-color: #fee2e2; color: #991b1b; }
    .status-pending { background-color: #fef3c7; color: #92400e; }
    
    .role-badge { background-color: #e2e8f0; color: #334155; } /* ROLE_USER (Gris clair / Bleu) */
    .role-badge.admin { background-color: #ffedd5; color: #c2410c; } /* ROLE_ADMIN (Orange) */
    .role-badge.superadmin { background-color: #fce7f3; color: #be185d; } /* ROLE_SUPERADMIN (Rose) */
    
    .actions-cell { display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: center; }
    .btn { padding: 0.375rem 0.75rem; border-radius: 6px; font-size: 0.85rem; font-weight: 500; border: none; cursor: pointer; transition: background-color 0.2s; }
    .btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-primary { background-color: #3b82f6; color: white; }
    .btn-primary:hover:not(:disabled) { background-color: #2563eb; }
    .btn-success { background-color: #10b981; color: white; }
    .btn-success:hover { background-color: #059669; }
    .btn-danger { background-color: #ef4444; color: white; }
    .btn-danger:hover { background-color: #dc2626; }
    .btn-secondary { background-color: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
    .btn-secondary:hover { background-color: #e2e8f0; }
    .btn-outline { background-color: transparent; border: 1px solid #ef4444; color: #ef4444; }
    .btn-outline:hover { background-color: #fef2f2; }
    
    .form-select { padding: 0.25rem 0.5rem; border-radius: 4px; border: 1px solid #d1d5db; outline: none; }
    .empty-state { text-align: center; padding: 3rem; color: #6b7280; }

    /* Modal Styles */
    .tm-modal-overlay {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000;
    }
    .confirm-modal-content {
      background: white; border-radius: 12px; width: 100%; max-width: 400px; overflow: hidden;
      box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1);
    }
    .confirm-modal-header {
      padding: 1rem 1.5rem; border-bottom: 1px solid #e5e7eb;
      display: flex; justify-content: space-between; align-items: center;
    }
    .confirm-modal-header h3 { margin: 0; font-size: 1.1rem; color: #111827; }
    .icon-btn { background: none; border: none; cursor: pointer; color: #6b7280; display: flex; }
    .confirm-modal-body { padding: 1.5rem; color: #374151; }
    .confirm-user-preview { margin-top: 1rem; padding: 0.75rem; background: #f9fafb; border-radius: 8px; font-size: 0.9rem; }
    .confirm-modal-actions {
      padding: 1rem 1.5rem; background: #f9fafb; display: flex; justify-content: flex-end; gap: 0.5rem; border-top: 1px solid #e5e7eb;
    }
  `]
})
export class AdminUsersComponent implements OnInit {
  private adminService = inject(AdminService);
  private authService = inject(AuthService);
  t9n = inject(TranslationService);
  users = signal<AdminUserDto[]>([]);

  modalState = signal<{
    isOpen: boolean;
    user: AdminUserDto | null;
    actionType: 'status' | 'role' | 'delete' | 'plan' | null;
    actionValue: string;
    triggerEvent?: Event;
  }>({ isOpen: false, user: null, actionType: null, actionValue: '' });

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

  onPlanChange(event: Event, user: AdminUserDto) {
    const select = event.target as HTMLSelectElement;
    const newPlan = select.value;
    
    // Store the event so we can revert the select if canceled
    this.modalState.set({
      isOpen: true,
      user,
      actionType: 'plan',
      actionValue: newPlan,
      triggerEvent: event
    });
  }

  // --- Modal Logic ---

  requestAction(user: AdminUserDto, type: 'status' | 'role' | 'delete' | 'plan', value: string) {
    this.modalState.set({
      isOpen: true,
      user,
      actionType: type,
      actionValue: value
    });
  }

  closeModal() {
    const state = this.modalState();
    // Revert the select if it was a plan change that got canceled
    if (state.actionType === 'plan' && state.triggerEvent && state.user) {
      const select = state.triggerEvent.target as HTMLSelectElement;
      select.value = state.user.plan; // revert to original value
    }
    this.modalState.set({ isOpen: false, user: null, actionType: null, actionValue: '' });
  }

  getModalMessage(): string {
    const state = this.modalState();
    if (!state.user) return '';

    switch (state.actionType) {
      case 'status':
        return `Voulez-vous passer cet utilisateur en statut ${state.actionValue} ?`;
      case 'role':
        const roleName = state.actionValue === 'ROLE_ADMIN' ? 'Administrateur' : 'Utilisateur simple';
        return `Voulez-vous donner le rôle ${roleName} à ce compte ?`;
      case 'plan':
        return `Voulez-vous attribuer le forfait ${state.actionValue} à cet utilisateur ?`;
      case 'delete':
        return `ATTENTION : Voulez-vous supprimer DÉFINITIVEMENT ce compte et toutes ses données associées (anniversaires, etc.) ?`;
      default:
        return 'Confirmer cette action ?';
    }
  }

  confirmAction() {
    const state = this.modalState();
    if (!state.user || !state.actionType) return;

    const user = state.user;

    switch (state.actionType) {
      case 'status':
        this.adminService.updateUserStatus(user.id, state.actionValue).subscribe({
          next: () => {
            this.users.update(list => list.map(u => u.id === user.id ? { ...u, status: state.actionValue } : u));
            this.closeModal();
          },
          error: (err) => { alert(err.error?.message || 'Erreur'); this.closeModal(); }
        });
        break;

      case 'plan':
        this.adminService.updateUserPlan(user.id, state.actionValue).subscribe({
          next: () => {
            this.users.update(list => list.map(u => u.id === user.id ? { ...u, plan: state.actionValue } : u));
            // Don't revert select, just close
            this.modalState.set({ isOpen: false, user: null, actionType: null, actionValue: '' });
          },
          error: (err) => { alert('Erreur lors de la modification du forfait'); this.closeModal(); }
        });
        break;

      case 'role':
        this.adminService.updateUserRole(user.id, state.actionValue).subscribe({
          next: () => {
            this.users.update(list => list.map(u => u.id === user.id ? { ...u, role: state.actionValue } : u));
            this.closeModal();
          },
          error: (err) => { alert('Erreur lors de la modification du rôle'); this.closeModal(); }
        });
        break;

      case 'delete':
        this.adminService.deleteUser(user.id).subscribe({
          next: () => {
            this.users.update(list => list.filter(u => u.id !== user.id));
            this.closeModal();
          },
          error: (err) => { alert('Erreur lors de la suppression'); this.closeModal(); }
        });
        break;
    }
  }
}
