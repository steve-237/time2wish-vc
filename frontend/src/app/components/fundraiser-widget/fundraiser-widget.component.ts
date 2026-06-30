import { Component, Input, Output, EventEmitter, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FundraiserService, Fundraiser, Pledge } from '../../services/fundraiser.service';

@Component({
  selector: 'app-fundraiser-widget',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="fundraiser-container glass-card">
      @if (loading()) {
        <div class="loading-state">Chargement de la cagnotte...</div>
      } @else if (fundraiser()) {
        <div class="fundraiser-header">
          <h3>💰 Cagnotte Collaborative</h3>
          <span class="status-badge" [class.active]="fundraiser()?.active">
            {{ fundraiser()?.active ? 'En cours' : 'Clôturée' }}
          </span>
        </div>

        <div class="progress-section">
          <div class="progress-bar">
            <div class="progress-fill" [style.width.%]="progressPercentage()"></div>
          </div>
          <div class="progress-stats">
            <span class="current">{{ fundraiser()?.currentAmount }} {{ fundraiser()?.currency }}</span>
            <span class="target">sur {{ fundraiser()?.targetAmount }} {{ fundraiser()?.currency }}</span>
          </div>
        </div>

        @if (fundraiser()?.active) {
          <div class="pledge-form">
            <h4>Participer à ce cadeau</h4>
            <div class="input-group">
              <input type="text" [ngModel]="guestName()" (ngModelChange)="guestName.set($event)" placeholder="Votre nom (facultatif)" class="form-input">
            </div>
            <div class="input-group">
              <input type="number" [ngModel]="pledgeAmount()" (ngModelChange)="pledgeAmount.set($event)" placeholder="Montant" class="form-input" min="1">
              <span class="currency-symbol">{{ fundraiser()?.currency }}</span>
            </div>
            <div class="input-group">
              <input type="text" [ngModel]="pledgeMessage()" (ngModelChange)="pledgeMessage.set($event)" placeholder="Un petit mot ?" class="form-input">
            </div>
            <button class="btn-PRO" [disabled]="!pledgeAmount() || pledgeAmount() <= 0" (click)="submitPledge()">
              Promettre {{ pledgeAmount() || 0 }} {{ fundraiser()?.currency }}
            </button>
          </div>
        }

        <div class="pledges-list">
          <h4>Participants ({{ fundraiser()?.pledges?.length || 0 }})</h4>
          @for (p of fundraiser()?.pledges; track p.id) {
            <div class="pledge-item">
              <div class="pledge-info">
                <strong>{{ p.contributorName || 'Anonyme' }}</strong>
                <span class="pledge-amount">{{ p.amount }} {{ fundraiser()?.currency }}</span>
              </div>
              @if (p.message) {
                <p class="pledge-message">"{{ p.message }}"</p>
              }
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .fundraiser-container {
      padding: 20px;
      margin-top: 15px;
      border-radius: 12px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--border-color);

      .fundraiser-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;

        h3 { margin: 0; font-size: 1.1rem; color: var(--text-main); }
        .status-badge {
          padding: 4px 8px;
          border-radius: 12px;
          font-size: 0.75rem;
          background: rgba(255,255,255,0.1);
          &.active { background: #10b981; color: white; }
        }
      }

      .progress-section {
        margin-bottom: 20px;
        .progress-bar {
          height: 12px;
          background: rgba(255,255,255,0.1);
          border-radius: 6px;
          overflow: hidden;
          margin-bottom: 8px;
          .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--accent-color), #fcd34d);
            transition: width 0.5s ease-out;
          }
        }
        .progress-stats {
          display: flex;
          justify-content: space-between;
          font-size: 0.85rem;
          .current { font-weight: bold; color: var(--accent-color); }
          .target { color: var(--text-muted); }
        }
      }

      .pledge-form {
        background: rgba(0,0,0,0.1);
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 20px;
        
        h4 { margin: 0 0 10px 0; font-size: 0.95rem; }
        .input-group {
          position: relative;
          margin-bottom: 10px;
          .form-input {
            width: 100%;
            padding: 10px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background: rgba(255,255,255,0.05);
            color: var(--text-main);
          }
          .currency-symbol {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
          }
        }
        .btn-PRO { width: 100%; padding: 10px; border-radius: 6px; }
      }

      .pledges-list {
        h4 { margin: 0 0 10px 0; font-size: 0.9rem; color: var(--text-muted); }
        .pledge-item {
          padding: 10px;
          border-bottom: 1px solid rgba(255,255,255,0.05);
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
            color: var(--text-muted);
            font-style: italic;
          }
        }
      }
    }
  `]
})
export class FundraiserWidgetComponent implements OnInit {
  @Input() giftId!: number;
  @Input() estimatedPrice?: number;

  public fundraiserService = inject(FundraiserService);
  public fundraiser = signal<Fundraiser | null>(null);
  public loading = signal<boolean>(true);

  // Form fields
  public guestName = signal<string>('');
  public pledgeAmount = signal<number>(0);
  public pledgeMessage = signal<string>('');

  ngOnInit() {
    this.loadFundraiser();
  }

  loadFundraiser() {
    this.loading.set(true);
    this.fundraiserService.getFundraiser(this.giftId, this.estimatedPrice).subscribe({
      next: (data) => {
        this.fundraiser.set(data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  progressPercentage(): number {
    const f = this.fundraiser();
    if (!f || f.targetAmount <= 0) return 0;
    return Math.min(100, (f.currentAmount / f.targetAmount) * 100);
  }

  submitPledge() {
    const f = this.fundraiser();
    if (!f || this.pledgeAmount() <= 0) return;

    this.loading.set(true);
    this.fundraiserService.addPledge(f.id, {
      guestName: this.guestName(),
      amount: this.pledgeAmount(),
      message: this.pledgeMessage()
    }).subscribe({
      next: (updated) => {
        this.fundraiser.set(updated);
        this.pledgeAmount.set(0);
        this.pledgeMessage.set('');
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }
}
