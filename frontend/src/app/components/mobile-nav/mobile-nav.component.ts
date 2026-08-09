import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslationService } from '../../services/translation.service';
import { MessagingService } from '../../services/messaging.service';
import { NativeFallbackService } from '../../services/native-fallback.service';

@Component({
  selector: 'app-mobile-nav',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  template: `
    <nav class="mobile-nav-container">
      <div class="mobile-nav-bar">
        
        <!-- Birthdays / Home Tab -->
        <a routerLink="/dashboard" 
           routerLinkActive="active" 
           [routerLinkActiveOptions]="{exact: true}" 
           class="nav-item"
           (click)="onTabClick()">
          <span class="material-symbols-outlined nav-icon">cake</span>
          <span class="nav-label">{{ t9n.t('nav.birthdays') || 'Anniversaires' }}</span>
        </a>

        <!-- Contacts Tab -->
        <a routerLink="/dashboard/contacts" 
           routerLinkActive="active" 
           class="nav-item"
           (click)="onTabClick()">
          <span class="material-symbols-outlined nav-icon">group</span>
          <span class="nav-label">{{ t9n.t('nav.contacts') || 'Contacts' }}</span>
        </a>

        <!-- Add Birthday Center FAB Button -->
        <a routerLink="/dashboard/birthday/add" 
           class="nav-fab-item"
           (click)="onTabClick()"
           [title]="t9n.t('birthday.add') || 'Ajouter'">
          <div class="fab-circle">
            <span class="material-symbols-outlined fab-icon">add</span>
          </div>
        </a>

        <!-- Messaging Tab -->
        <a routerLink="/dashboard/messaging" 
           routerLinkActive="active" 
           class="nav-item"
           (click)="onTabClick()">
          <div class="icon-wrapper">
            <span class="material-symbols-outlined nav-icon">chat</span>
            @if (messagingService.unreadCount() > 0) {
              <span class="unread-badge">{{ messagingService.unreadCount() }}</span>
            }
          </div>
          <span class="nav-label">{{ t9n.t('nav.messaging') || 'Messages' }}</span>
        </a>

        <!-- Profile Tab -->
        <a routerLink="/dashboard/profile" 
           routerLinkActive="active" 
           class="nav-item"
           (click)="onTabClick()">
          <span class="material-symbols-outlined nav-icon">person</span>
          <span class="nav-label">{{ t9n.t('nav.profile') || 'Profil' }}</span>
        </a>

      </div>
    </nav>
  `,
  styles: [`
    .mobile-nav-container {
      display: none; /* Shown on screens <= 768px */
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      z-index: 999;
      padding-bottom: max(env(safe-area-inset-bottom, 0px), 8px);
      background: rgba(15, 23, 42, 0.85);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border-top: 1px solid rgba(255, 255, 255, 0.12);
      box-shadow: 0 -4px 30px rgba(0, 0, 0, 0.4);
    }

    @media (max-width: 768px) {
      .mobile-nav-container {
        display: block;
      }
    }

    .mobile-nav-bar {
      display: flex;
      align-items: center;
      justify-content: space-around;
      height: 62px;
      padding: 0 8px;
    }

    .nav-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: rgba(255, 255, 255, 0.6);
      text-decoration: none;
      font-size: 0.72rem;
      font-weight: 500;
      transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
      flex: 1;
      gap: 2px;
      padding: 6px 0;
      border-radius: 12px;
    }

    .nav-item.active {
      color: #38bdf8;
      font-weight: 700;
    }

    .nav-item.active .nav-icon {
      transform: scale(1.15);
      color: #38bdf8;
      text-shadow: 0 0 12px rgba(56, 189, 248, 0.5);
    }

    .nav-icon {
      font-size: 24px;
      transition: transform 0.25s ease, color 0.25s ease;
    }

    .icon-wrapper {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .unread-badge {
      position: absolute;
      top: -4px;
      right: -8px;
      background: #ef4444;
      color: #ffffff;
      font-size: 0.65rem;
      font-weight: 800;
      height: 16px;
      min-width: 16px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0 4px;
      box-shadow: 0 2px 6px rgba(239, 68, 68, 0.5);
    }

    .nav-fab-item {
      display: flex;
      align-items: center;
      justify-content: center;
      text-decoration: none;
      margin-top: -24px;
    }

    .fab-circle {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: linear-gradient(135deg, #6366f1 0%, #a855f7 50%, #ec4899 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 8px 25px rgba(168, 85, 247, 0.5), 0 0 0 4px rgba(15, 23, 42, 0.9);
      transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
    }

    .fab-circle:active {
      transform: scale(0.9);
    }

    .fab-icon {
      font-size: 28px;
      font-weight: bold;
    }
  `]
})
export class MobileNavComponent {
  t9n = inject(TranslationService);
  messagingService = inject(MessagingService);
  nativeFallback = inject(NativeFallbackService);

  onTabClick(): void {
    this.nativeFallback.hapticImpact();
  }
}
