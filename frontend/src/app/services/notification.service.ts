import { Injectable, signal, computed, inject, effect } from '@angular/core';
import { AppNotification, NotificationType } from '../models/notification.model';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private authService = inject(AuthService);
  private notificationsSignal = signal<AppNotification[]>([]);

  // Computed signals
  public readonly notifications = this.notificationsSignal.asReadonly();
  public readonly unreadCount = computed(() => 
    this.notificationsSignal().filter(n => !n.isRead).length
  );

  constructor() {
    // Automatically load/clear notifications when user changes
    effect(() => {
      const user = this.authService.currentUser();
      if (user) {
        this.loadFromStorage(user.id);
      } else {
        this.notificationsSignal.set([]);
      }
    });
  }

  logAction(type: NotificationType, message: string, link?: string) {
    const user = this.authService.currentUser();
    if (!user) return;

    const newNotif: AppNotification = {
      id: crypto.randomUUID(),
      type,
      message,
      timestamp: new Date(),
      isRead: false,
      link
    };
    
    this.notificationsSignal.update(current => [newNotif, ...current].slice(0, 50)); // Keep last 50
    this.saveToStorage(user.id);
  }

  markAllAsRead() {
    const user = this.authService.currentUser();
    if (!user) return;

    this.notificationsSignal.update(current => 
      current.map(n => ({ ...n, isRead: true }))
    );
    this.saveToStorage(user.id);
  }

  markAsRead(id: string) {
    const user = this.authService.currentUser();
    if (!user) return;

    this.notificationsSignal.update(current => 
      current.map(n => n.id === id ? { ...n, isRead: true } : n)
    );
    this.saveToStorage(user.id);
  }

  clearAll() {
    const user = this.authService.currentUser();
    if (!user) return;

    this.notificationsSignal.set([]);
    this.saveToStorage(user.id);
  }

  private saveToStorage(userId: number) {
    localStorage.setItem(`time2wish_notifications_${userId}`, JSON.stringify(this.notificationsSignal()));
  }

  private loadFromStorage(userId: number) {
    const stored = localStorage.getItem(`time2wish_notifications_${userId}`);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        // Convert string dates back to Date objects
        const withDates = parsed.map((n: any) => ({
          ...n,
          timestamp: new Date(n.timestamp)
        }));
        this.notificationsSignal.set(withDates);
      } catch (e) {
        console.error('Failed to load notifications from storage', e);
        this.notificationsSignal.set([]);
      }
    } else {
      this.notificationsSignal.set([]);
    }
  }
}
