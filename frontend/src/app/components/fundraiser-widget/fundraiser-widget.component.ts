import { Component, Input, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FundraiserService, Fundraiser, Pledge } from '../../services/fundraiser.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-fundraiser-widget',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="fundraiser-container glass-card">
      @if (loading()) {
        <div class="loading-state">
          <span class="material-symbols-outlined rotating">sync</span>
          {{ t9n.t('fundraiser.loading') }}
        </div>
      } @else if (fundraiser()) {
        <div class="fundraiser-header">
          <h3>{{ t9n.t('fundraiser.title') }}</h3>
          <span class="status-badge" [class.active]="fundraiser()?.active && !isFullyFunded()" [class.completed]="isFullyFunded()">
            @if (isFullyFunded()) {
              🎉 {{ t9n.t('fundraiser.status_completed') }}
            } @else {
              {{ fundraiser()?.active ? t9n.t('fundraiser.status_active') : t9n.t('fundraiser.status_closed') }}
            }
          </span>
        </div>

        <div class="progress-section">
          <div class="progress-header">
            <span class="progress-label">
              @if (isFullyFunded()) {
                {{ t9n.t('fundraiser.status_completed') }}
              } @else {
                {{ progressPercentage() }}% financé
              }
            </span>
            <span class="progress-percent" [class.completed]="isFullyFunded()">{{ progressPercentage() }}%</span>
          </div>

          <div class="progress-bar">
            <div 
              class="progress-fill" 
              [class.completed]="isFullyFunded()"
              [style.width]="progressPercentage() + '%'">
            </div>
          </div>

          <div class="progress-stats">
            <div class="stat-group">
              <span class="stat-label">Collecté :</span>
              <span class="current">{{ fundraiser()?.currentAmount || 0 }} {{ fundraiser()?.currency }}</span>
            </div>
            @if (!isFullyFunded()) {
              <div class="stat-group">
                <span class="stat-label">{{ t9n.t('fundraiser.remaining') }}</span>
                <span class="remaining">{{ remainingAmount() }} {{ fundraiser()?.currency }}</span>
              </div>
            }
            <div class="stat-group">
              <span class="stat-label">{{ t9n.t('fundraiser.target_of') }}</span>
              <span class="target">{{ fundraiser()?.targetAmount }} {{ fundraiser()?.currency }}</span>
              @if (!isEditingTarget()) {
                <button type="button" class="btn-edit-target" (click)="startEditTarget()" [title]="t9n.t('fundraiser.edit_target')">
                  <span class="material-symbols-outlined">edit</span>
                </button>
              }
            </div>
          </div>

          @if (isEditingTarget()) {
            <div class="edit-target-box">
              <input type="number" [ngModel]="newTargetAmount()" (ngModelChange)="newTargetAmount.set($event)" min="1" class="form-input-sm">
              <button class="btn-sm btn-primary" (click)="saveNewTarget()">{{ t9n.t('fundraiser.save_target') }}</button>
              <button class="btn-sm btn-secondary" (click)="isEditingTarget.set(false)">✕</button>
            </div>
          }
        </div>

        @if (isFullyFunded()) {
          <div class="completed-card">
            <span class="material-symbols-outlined completed-icon">verified</span>
            <div class="completed-text">
              <h4>{{ t9n.t('fundraiser.status_completed') }}</h4>
              <p>{{ t9n.t('fundraiser.completed_message') }}</p>
            </div>
          </div>
        } @else if (fundraiser()?.active) {
          <div class="pledge-form">
            <div class="form-header">
              <h4>{{ t9n.t('fundraiser.participate_title') }}</h4>
              @if (remainingAmount() > 0) {
                <button type="button" class="btn-quick-fill" (click)="fillRemaining()">
                  <span class="material-symbols-outlined">bolt</span>
                  Financer le reste ({{ remainingAmount() }} {{ fundraiser()?.currency }})
                </button>
              }
            </div>

            <div class="input-group">
              <input type="text" [ngModel]="guestName()" (ngModelChange)="guestName.set($event)" [placeholder]="t9n.t('fundraiser.name_placeholder')" class="form-input">
            </div>

            <div class="input-group">
              <input 
                type="number" 
                [ngModel]="pledgeAmount()" 
                (ngModelChange)="onAmountChange($event)" 
                [placeholder]="t9n.t('fundraiser.amount_placeholder')" 
                class="form-input" 
                min="1" 
                [max]="remainingAmount()">
              <span class="currency-symbol">{{ fundraiser()?.currency }}</span>
            </div>

            @if (isExceeding()) {
              <div class="limit-warning">
                <span class="material-symbols-outlined">warning</span>
                <span>{{ t9n.t('fundraiser.limit_exceeded_error', remainingAmount(), fundraiser()?.currency || 'EUR') }}</span>
              </div>
            }

            <div class="input-group">
              <input type="text" [ngModel]="pledgeMessage()" (ngModelChange)="pledgeMessage.set($event)" [placeholder]="t9n.t('fundraiser.message_placeholder')" class="form-input">
            </div>

            <button 
              class="btn-PRO" 
              [disabled]="loading() || !pledgeAmount() || pledgeAmount() <= 0 || isExceeding()" 
              (click)="submitPledge()">
              {{ t9n.t('fundraiser.btn_pledge', pledgeAmount() || 0, fundraiser()?.currency || 'EUR') }}
            </button>
          </div>
        }

        <div class="pledges-list">
          <h4>{{ t9n.t('fundraiser.participants_title', fundraiser()?.pledges?.length || 0) }}</h4>
          @for (p of fundraiser()?.pledges; track p.id) {
            <div class="pledge-item">
              <div class="pledge-info">
                <strong>{{ p.contributorName || t9n.t('fundraiser.anonymous') }}</strong>
                <span class="pledge-amount">+{{ p.amount }} {{ fundraiser()?.currency }}</span>
              </div>
              @if (p.message) {
                <p class="pledge-message">"{{ p.message }}"</p>
              }
            </div>
          } @empty {
            <p class="empty-pledges">Aucune participation pour l'instant. Soyez le premier !</p>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .fundraiser-container {
      padding: 18px;
      margin-top: 15px;
      border-radius: 12px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--border-card, rgba(0, 0, 0, 0.1));

      .loading-state {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        padding: 24px;
        color: var(--text-muted, #64748b);
        .rotating { animation: spin 1s linear infinite; }
      }

      .fundraiser-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;

        h3 { margin: 0; font-size: 1.05rem; color: var(--text-main, #0f172a); font-weight: 600; }
        .status-badge {
          padding: 4px 10px;
          border-radius: 12px;
          font-size: 0.75rem;
          font-weight: 600;
          background: rgba(100, 116, 139, 0.15);
          color: var(--text-muted, #64748b);
          &.active { background: #3b82f6; color: white; }
          &.completed { background: #10b981; color: white; box-shadow: 0 0 8px rgba(16, 185, 129, 0.4); }
        }
      }

      .progress-section {
        margin-bottom: 20px;

        .progress-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 6px;

          .progress-label {
            font-size: 0.85rem;
            color: var(--text-muted, #64748b);
            font-weight: 500;
          }
          .progress-percent {
            font-size: 0.95rem;
            font-weight: 700;
            color: #3b82f6;
            &.completed { color: #10b981; }
          }
        }

        .progress-bar {
          height: 14px;
          background: #e2e8f0;
          border: 1px solid #cbd5e1;
          border-radius: 8px;
          overflow: hidden;
          margin-bottom: 10px;
          position: relative;
          box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.06);

          .progress-fill {
            height: 100%;
            min-width: 0;
            background: linear-gradient(90deg, #3b82f6 0%, #10b981 100%);
            border-radius: 8px;
            transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 0 8px rgba(16, 185, 129, 0.3);

            &.completed {
              background: linear-gradient(90deg, #10b981 0%, #059669 100%);
              box-shadow: 0 0 12px rgba(16, 185, 129, 0.6);
            }
          }
        }

        .progress-stats {
          display: flex;
          justify-content: space-between;
          align-items: center;
          flex-wrap: wrap;
          gap: 8px;
          font-size: 0.85rem;

          .stat-group {
            display: flex;
            align-items: center;
            gap: 4px;
          }
          .stat-label {
            color: var(--text-muted, #64748b);
          }
          .current { font-weight: 700; color: #10b981; }
          .remaining { font-weight: 700; color: #f59e0b; }
          .target { font-weight: 600; color: var(--text-main, #0f172a); }
          .btn-edit-target {
            background: none;
            border: none;
            cursor: pointer;
            color: var(--text-muted, #64748b);
            padding: 2px;
            display: inline-flex;
            align-items: center;
            border-radius: 4px;
            &:hover { color: #3b82f6; background: rgba(59, 130, 246, 0.1); }
            span { font-size: 15px; }
          }
        }

        .edit-target-box {
          display: flex;
          gap: 6px;
          align-items: center;
          margin-top: 10px;
          padding: 8px;
          background: rgba(0, 0, 0, 0.04);
          border-radius: 6px;

          .form-input-sm {
            flex: 1;
            padding: 6px 8px;
            font-size: 0.85rem;
            border-radius: 4px;
            border: 1px solid var(--border-card, #cbd5e1);
            background: white;
            color: var(--text-main, #0f172a);
          }
          .btn-sm {
            padding: 6px 10px;
            font-size: 0.8rem;
            border-radius: 4px;
            border: none;
            cursor: pointer;
            &.btn-primary { background: #3b82f6; color: white; }
            &.btn-secondary { background: #94a3b8; color: white; }
          }
        }
      }

      .completed-card {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 14px 16px;
        border-radius: 8px;
        background: rgba(16, 185, 129, 0.12);
        border: 1px solid rgba(16, 185, 129, 0.3);
        margin-bottom: 20px;

        .completed-icon {
          font-size: 32px;
          color: #10b981;
        }
        .completed-text {
          h4 { margin: 0 0 2px 0; font-size: 0.95rem; color: #10b981; font-weight: 700; }
          p { margin: 0; font-size: 0.85rem; color: var(--text-main, #0f172a); }
        }
      }

      .pledge-form {
        background: rgba(0, 0, 0, 0.03);
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 20px;
        border: 1px solid var(--border-card, rgba(0, 0, 0, 0.05));

        .form-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 12px;

          h4 { margin: 0; font-size: 0.95rem; font-weight: 600; }
          .btn-quick-fill {
            background: rgba(245, 158, 11, 0.15);
            color: #d97706;
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 6px;
            padding: 4px 8px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            cursor: pointer;
            transition: all 0.2s ease;
            &:hover { background: #f59e0b; color: white; }
            span { font-size: 14px; }
          }
        }

        .input-group {
          position: relative;
          margin-bottom: 10px;

          .form-input {
            width: 100%;
            padding: 10px;
            border-radius: 6px;
            border: 1px solid var(--border-card, #cbd5e1);
            background: rgba(255, 255, 255, 0.7);
            color: var(--text-main, #0f172a);
            font-size: 0.9rem;
            box-sizing: border-box;

            &:focus {
              outline: none;
              border-color: #3b82f6;
            }
          }

          .currency-symbol {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted, #64748b);
            font-weight: 600;
          }
        }

        .limit-warning {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 10px;
          border-radius: 6px;
          background: rgba(239, 68, 68, 0.1);
          border: 1px solid rgba(239, 68, 68, 0.25);
          color: #dc2626;
          font-size: 0.8rem;
          margin-bottom: 10px;

          span.material-symbols-outlined { font-size: 16px; }
        }

        .btn-PRO {
          width: 100%;
          padding: 10px;
          border-radius: 6px;
          font-size: 0.9rem;
          cursor: pointer;
          &:disabled { opacity: 0.5; cursor: not-allowed; }
        }
      }

      .pledges-list {
        h4 { margin: 0 0 10px 0; font-size: 0.9rem; color: var(--text-muted, #64748b); }
        .empty-pledges { font-size: 0.85rem; color: var(--text-muted, #64748b); font-style: italic; margin: 0; }
        .pledge-item {
          padding: 10px;
          border-bottom: 1px solid rgba(0, 0, 0, 0.05);
          &:last-child { border-bottom: none; }
          .pledge-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
            font-size: 0.9rem;
            .pledge-amount { font-weight: bold; color: #10b981; }
          }
          .pledge-message {
            margin: 0;
            font-size: 0.8rem;
            color: var(--text-muted, #64748b);
            font-style: italic;
          }
        }
      }
    }

    /* Dark and OLED theme overrides */
    :host-context(body.dark-theme),
    :host-context(body.oled-theme) {
      .progress-bar {
        background: rgba(255, 255, 255, 0.12) !important;
        border-color: rgba(255, 255, 255, 0.1) !important;
        box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.3) !important;
      }
      .progress-stats .target {
        color: #f8fafc !important;
      }
      .pledge-form {
        background: rgba(255, 255, 255, 0.04) !important;
        .form-input {
          background: rgba(255, 255, 255, 0.06) !important;
          border-color: rgba(255, 255, 255, 0.12) !important;
          color: #f8fafc !important;
        }
      }
      .edit-target-box {
        background: rgba(255, 255, 255, 0.05) !important;
        .form-input-sm {
          background: rgba(255, 255, 255, 0.08) !important;
          border-color: rgba(255, 255, 255, 0.15) !important;
          color: #f8fafc !important;
        }
      }
      .completed-card .completed-text p {
        color: #e2e8f0 !important;
      }
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  `]
})
export class FundraiserWidgetComponent implements OnInit {
  @Input() giftId!: number;
  @Input() estimatedPrice?: number;

  public t9n = inject(TranslationService);
  public fundraiserService = inject(FundraiserService);
  private toastService = inject(ToastService);

  public fundraiser = signal<Fundraiser | null>(null);
  public loading = signal<boolean>(true);

  // Form fields
  public guestName = signal<string>('');
  public pledgeAmount = signal<number>(0);
  public pledgeMessage = signal<string>('');

  // Edit target
  public isEditingTarget = signal<boolean>(false);
  public newTargetAmount = signal<number>(0);

  public progressPercentage = computed<number>(() => {
    const f = this.fundraiser();
    if (!f || !f.targetAmount || Number(f.targetAmount) <= 0) return 0;
    const current = Number(f.currentAmount) || 0;
    const target = Number(f.targetAmount);
    return Math.min(100, Math.max(0, Math.round((current / target) * 100)));
  });

  public remainingAmount = computed<number>(() => {
    const f = this.fundraiser();
    if (!f || !f.targetAmount) return 0;
    const target = Number(f.targetAmount);
    const current = Number(f.currentAmount) || 0;
    const rem = target - current;
    return rem > 0 ? Math.round(rem * 100) / 100 : 0;
  });

  public isFullyFunded = computed<boolean>(() => {
    const f = this.fundraiser();
    if (!f) return false;
    if (f.isCompleted) return true;
    const target = Number(f.targetAmount) || 0;
    const current = Number(f.currentAmount) || 0;
    return target > 0 && current >= target;
  });

  public isExceeding = computed<boolean>(() => {
    const amount = Number(this.pledgeAmount()) || 0;
    return amount > this.remainingAmount();
  });

  ngOnInit() {
    this.loadFundraiser();
  }

  loadFundraiser() {
    this.loading.set(true);
    this.fundraiserService.getFundraiser(this.giftId, this.estimatedPrice).subscribe({
      next: (data) => {
        this.fundraiser.set(data);
        this.newTargetAmount.set(data.targetAmount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  onAmountChange(val: any) {
    const num = Number(val);
    this.pledgeAmount.set(isNaN(num) ? 0 : num);
  }

  fillRemaining() {
    const rem = this.remainingAmount();
    if (rem > 0) {
      this.pledgeAmount.set(rem);
    }
  }

  startEditTarget() {
    const f = this.fundraiser();
    if (f) {
      this.newTargetAmount.set(f.targetAmount);
      this.isEditingTarget.set(true);
    }
  }

  saveNewTarget() {
    const f = this.fundraiser();
    const newTarget = Number(this.newTargetAmount());
    if (!f || !newTarget || newTarget <= 0) return;

    if (newTarget < (Number(f.currentAmount) || 0)) {
      this.toastService.error(`Le montant cible ne peut pas être inférieur aux promesses déjà enregistrées (${f.currentAmount} ${f.currency})`);
      return;
    }

    this.loading.set(true);
    this.fundraiserService.updateTarget(f.id, newTarget).subscribe({
      next: (updated) => {
        this.fundraiser.set(updated);
        this.isEditingTarget.set(false);
        this.loading.set(false);
        this.toastService.success("Objectif de la cagnotte mis à jour !");
      },
      error: (err) => {
        this.loading.set(false);
        const msg = err.error?.message || err.message || "Erreur lors de la modification de l'objectif";
        this.toastService.error(msg);
      }
    });
  }

  submitPledge() {
    const f = this.fundraiser();
    const amount = Number(this.pledgeAmount());
    if (!f || amount <= 0) return;

    const rem = this.remainingAmount();
    if (amount > rem) {
      this.toastService.error(`Le montant dépasse la somme restante (${rem} ${f.currency})`);
      return;
    }

    this.loading.set(true);
    this.fundraiserService.addPledge(f.id, {
      guestName: this.guestName()?.trim() || undefined,
      amount: amount,
      message: this.pledgeMessage()?.trim() || undefined
    }).subscribe({
      next: (updated) => {
        this.fundraiser.set(updated);
        this.pledgeAmount.set(0);
        this.pledgeMessage.set('');
        this.guestName.set('');
        this.loading.set(false);
        this.toastService.success(this.t9n.t('fundraiser.pledge_success') || "Votre promesse de don a bien été enregistrée !");
      },
      error: (err) => {
        this.loading.set(false);
        const msg = err.error?.message || err.message || (this.t9n.t('fundraiser.pledge_error') || "Erreur lors de l'enregistrement de la promesse");
        this.toastService.error(msg);
      }
    });
  }
}

