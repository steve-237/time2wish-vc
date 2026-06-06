import { Component, inject, signal, ChangeDetectionStrategy, HostListener, ViewChild, ElementRef, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NotificationService } from '../../services/notification.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-notification-panel',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './notification-panel.component.html',
  styleUrls: ['./notification-panel.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class NotificationPanelComponent {
  public notifService = inject(NotificationService);
  public t9n = inject(TranslationService);
  
  @ViewChild('notifWrapper') notifWrapper!: ElementRef;

  public isOpen = signal(false);
  public isRinging = signal(false);

  private lastCount = 0;

  constructor() {
    effect(() => {
      const count = this.notifService.unreadCount();
      // Trigger ringing animation if the count increases
      if (count > this.lastCount) {
        this.isRinging.set(true);
        setTimeout(() => this.isRinging.set(false), 1000);
      }
      this.lastCount = count;
    });
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    if (this.isOpen() && this.notifWrapper && !this.notifWrapper.nativeElement.contains(event.target)) {
      this.closePanel();
    }
  }

  togglePanel() {
    this.isOpen.set(!this.isOpen());
    if (this.isOpen()) {
      // Optional: auto-mark as read when opening? 
      // We will let the user do it manually or via a button
    }
  }

  closePanel() {
    this.isOpen.set(false);
  }

  getIconForType(type: string): string {
    switch(type) {
      case 'ADD': return 'add_circle';
      case 'UPDATE': return 'edit';
      case 'DELETE': return 'delete';
      case 'REMINDER': return 'notifications_active';
      default: return 'info';
    }
  }
}
