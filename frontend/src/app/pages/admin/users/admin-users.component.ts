import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { AdminService, AdminUserDto } from '../../../services/admin.service';
import { AuthService } from '../../../services/auth.service';
import { FormsModule } from '@angular/forms';
import { TranslationService } from '../../../services/translation.service';
import { ToastService } from '../../../services/toast.service';

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
              <th style="width: 60px;">ID</th>
              <th>{{ t9n.t('admin.users.col_user') || 'Utilisateur' }}</th>
              <th>{{ t9n.t('admin.users.col_role') }}</th>
              <th>{{ t9n.t('admin.users.col_plan') }}</th>
              <th>{{ t9n.t('admin.users.col_status') }}</th>
              <th style="text-align: right;">{{ t9n.t('admin.users.col_actions') }}</th>
            </tr>
          </thead>
          <tbody>
            @for (user of users(); track user.id) {
              <tr>
                <td class="id-cell">#{{ user.id }}</td>
                <td>
                  <div class="user-profile-cell">
                    <img [src]="user.avatarUrl || getInitialsAvatar(user.fullName)" alt="avatar" class="user-avatar" />
                    <div class="user-details">
                      <div class="user-name">{{ user.fullName }}</div>
                      <div class="user-email">{{ user.email }}</div>
                    </div>
                  </div>
                </td>
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
                    <button class="icon-action-btn btn-danger-soft" (click)="requestAction(user, 'status', 'BLOCKED')" [disabled]="user.role === 'ROLE_SUPERADMIN'" [title]="t9n.t('admin.users.btn_ban') || 'Bannir'">
                      <span class="material-symbols-outlined">block</span>
                    </button>
                  } @else if (user.status === 'BLOCKED') {
                    <button class="icon-action-btn btn-success-soft" (click)="requestAction(user, 'status', 'ACTIVE')" [title]="t9n.t('admin.users.btn_unban') || 'Débannir'">
                      <span class="material-symbols-outlined">check_circle</span>
                    </button>
                  } @else if (user.status === 'PENDING_APPROVAL') {
                    <button class="icon-action-btn btn-primary-soft" (click)="requestAction(user, 'status', 'ACTIVE')" [title]="t9n.t('admin.users.btn_approve') || 'Approuver'">
                      <span class="material-symbols-outlined">task_alt</span>
                    </button>
                  }
                  
                  @if (isSuperAdmin() && user.role !== 'ROLE_SUPERADMIN') {
                    <button class="icon-action-btn btn-secondary-soft" (click)="requestAction(user, 'role', 'ROLE_ADMIN')" *ngIf="user.role === 'ROLE_USER'" title="Promouvoir Admin">
                      <span class="material-symbols-outlined">shield_person</span>
                    </button>
                    <button class="icon-action-btn btn-secondary-soft" (click)="requestAction(user, 'role', 'ROLE_USER')" *ngIf="user.role === 'ROLE_ADMIN'" title="Rétrograder Utilisateur">
                      <span class="material-symbols-outlined">person</span>
                    </button>
                    <button class="icon-action-btn btn-danger-outline" (click)="requestAction(user, 'delete', '')" [title]="t9n.t('admin.users.btn_delete') || 'Supprimer'">
                      <span class="material-symbols-outlined">delete</span>
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
    .page-title { font-size: 1.5rem; font-weight: 600; color: var(--text-main); margin-bottom: 2rem; }
    .table-wrapper { background: #ffffff; border-radius: 12px; box-shadow: var(--glass-shadow); overflow-x: auto; border: 1px solid var(--border-card); }
    :host-context(body.dark-theme) .table-wrapper { background: #1e293b; }
    :host-context(body.oled-theme) .table-wrapper { background: #0f0f0f; }
    .users-table { width: 100%; border-collapse: collapse; text-align: left; color: var(--text-main); background: transparent; }
    .users-table th, .users-table td { padding: 1.25rem 1rem; border-bottom: 1px solid var(--border-card); vertical-align: middle; }
    .users-table th { background-color: transparent; font-weight: 600; color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; border-bottom: 2px solid var(--border-card); }
    .users-table tbody tr { transition: background-color 0.2s; }
    .users-table tbody tr:hover { background-color: rgba(var(--primary-hsl), 0.05); }
    .id-cell { color: var(--text-muted); font-size: 0.85rem; font-family: monospace; }
    
    .user-profile-cell { display: flex; align-items: center; gap: 0.75rem; }
    .user-avatar { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; border: 2px solid var(--border-card); }
    .user-name { font-weight: 600; color: var(--text-main); font-size: 0.95rem; }
    .user-email { color: var(--text-muted); font-size: 0.8rem; }
    
    .badge { padding: 0.35rem 0.75rem; border-radius: 6px; font-size: 0.75rem; font-weight: 600; display: inline-flex; align-items: center; justify-content: center; letter-spacing: 0.02em; }
    .status-active { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
    .status-blocked { background-color: rgba(239, 68, 68, 0.1); color: #ef4444; }
    .status-pending { background-color: rgba(245, 158, 11, 0.15); color: #f59e0b; }
    
    .role-badge { background-color: rgba(var(--primary-hsl), 0.1); color: var(--text-main); }
    .role-badge.admin { background-color: rgba(249, 115, 22, 0.1); color: #f97316; }
    .role-badge.superadmin { background-color: rgba(192, 38, 211, 0.1); color: #c026d3; }
    
    .actions-cell { display: flex; gap: 0.4rem; justify-content: flex-end; align-items: center; }
    .icon-action-btn { width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center; border: none; cursor: pointer; transition: all 0.2s; font-size: 1.1rem; }
    .icon-action-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .icon-action-btn .material-symbols-outlined { font-size: 1.25rem; }
    
    .btn-primary-soft { background-color: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .btn-primary-soft:hover:not(:disabled) { background-color: rgba(59, 130, 246, 0.2); }
    .btn-success-soft { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
    .btn-success-soft:hover:not(:disabled) { background-color: rgba(16, 185, 129, 0.2); }
    .btn-danger-soft { background-color: rgba(239, 68, 68, 0.1); color: #ef4444; }
    .btn-danger-soft:hover:not(:disabled) { background-color: rgba(239, 68, 68, 0.2); }
    .btn-secondary-soft { background-color: rgba(100, 116, 139, 0.1); color: var(--text-muted); }
    .btn-secondary-soft:hover:not(:disabled) { background-color: rgba(100, 116, 139, 0.2); color: var(--text-main); }
    .btn-danger-outline { background-color: transparent; border: 1px solid rgba(239, 68, 68, 0.3); color: #ef4444; }
    .btn-danger-outline:hover:not(:disabled) { background-color: rgba(239, 68, 68, 0.1); border-color: transparent; }
    
    .form-select { padding: 0.4rem 0.75rem; border-radius: 6px; border: 1px solid var(--border-card); outline: none; background-color: var(--bg-card); color: var(--text-main); font-size: 0.85rem; font-weight: 500; cursor: pointer; transition: border-color 0.2s; }
    .form-select:hover:not(:disabled) { border-color: rgba(var(--primary-hsl), 0.5); }
    .form-select:disabled { opacity: 0.6; cursor: not-allowed; }
    .empty-state { text-align: center; padding: 3rem; color: #6b7280; }

    /* Modal Styles */
    .tm-modal-overlay {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000;
    }
    .confirm-modal-content {
      background: var(--bg-card); border-radius: 12px; width: 100%; max-width: 400px; overflow: hidden;
      box-shadow: var(--glass-shadow); backdrop-filter: blur(var(--glass-blur)); border: 1px solid var(--border-card);
      color: var(--text-main);
    }
    .confirm-modal-header {
      padding: 1rem 1.5rem; border-bottom: 1px solid var(--border-card);
      display: flex; justify-content: space-between; align-items: center;
    }
    .confirm-modal-header h3 { margin: 0; font-size: 1.1rem; color: var(--text-main); }
    .icon-btn { background: none; border: none; cursor: pointer; color: var(--text-muted); display: flex; }
    .confirm-modal-body {
      padding: 1.5rem; color: var(--text-muted); font-size: 0.95rem; line-height: 1.5;
    }
    .confirm-user-preview { margin-top: 1rem; padding: 0.75rem; background: rgba(var(--primary-hsl), 0.05); border-radius: 8px; font-size: 0.9rem; }
    .confirm-modal-actions {
      padding: 1rem 1.5rem; background: transparent; display: flex; justify-content: flex-end; gap: 0.5rem; border-top: 1px solid var(--border-card);
    }
  `]
})
export class AdminUsersComponent implements OnInit {
  private adminService = inject(AdminService);
  private authService = inject(AuthService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
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
          error: (err) => { this.toastService.error(err.error?.message || 'Erreur'); this.closeModal(); }
        });
        break;

      case 'plan':
        this.adminService.updateUserPlan(user.id, state.actionValue).subscribe({
          next: () => {
            this.users.update(list => list.map(u => u.id === user.id ? { ...u, plan: state.actionValue } : u));
            // Don't revert select, just close
            this.modalState.set({ isOpen: false, user: null, actionType: null, actionValue: '' });
          },
          error: (err) => { this.toastService.error('Erreur lors de la modification du forfait'); this.closeModal(); }
        });
        break;

      case 'role':
        this.adminService.updateUserRole(user.id, state.actionValue).subscribe({
          next: () => {
            this.users.update(list => list.map(u => u.id === user.id ? { ...u, role: state.actionValue } : u));
            this.closeModal();
          },
          error: (err) => { this.toastService.error('Erreur lors de la modification du rôle'); this.closeModal(); }
        });
        break;

      case 'delete':
        this.adminService.deleteUser(user.id).subscribe({
          next: () => {
            this.users.update(list => list.filter(u => u.id !== user.id));
            this.closeModal();
          },
          error: (err) => { this.toastService.error('Erreur lors de la suppression'); this.closeModal(); }
        });
        break;
    }
  }

  getInitialsAvatar(name: string): string {
    let hash = 0;
    if (name) {
      for (let i = 0; i < name.length; i++) {
        hash = name.charCodeAt(i) + ((hash << 5) - hash);
      }
    }
    const color = Math.floor(Math.abs((Math.sin(hash) * 10000) % 1 * 16777215)).toString(16).padStart(6, '0');
    const nameParam = name ? encodeURIComponent(name) : 'U';
    return `https://ui-avatars.com/api/?name=${nameParam}&background=${color}&color=fff&rounded=true&bold=true`;
  }
}
