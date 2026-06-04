export type NotificationType = 'ADD' | 'UPDATE' | 'DELETE' | 'REMINDER';

export interface AppNotification {
  id: string;
  type: NotificationType;
  message: string;
  timestamp: Date;
  isRead: boolean;
  link?: string; // Optional link to the birthday
}
