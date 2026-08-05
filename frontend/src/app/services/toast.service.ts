import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'info' | 'warning' | 'error';

export interface Toast {
  id: number;
  message: string;
  type: ToastType;
  duration: number;
}

@Injectable({
  providedIn: 'root'
})
export class ToastService {
  private nextId = 1;
  readonly toasts = signal<Toast[]>([]);

  show(message: string, type: ToastType = 'info', duration = 3000): number {
    const id = this.nextId++;
    const newToast: Toast = { id, message, type, duration };
    
    this.toasts.update(current => [...current, newToast]);

    setTimeout(() => {
      this.remove(id);
    }, duration);
    
    return id;
  }

  success(message: string, duration = 3000): number {
    return this.show(message, 'success', duration);
  }

  error(message: string, duration = 3000): number {
    return this.show(message, 'error', duration);
  }

  info(message: string, duration = 3000): number {
    return this.show(message, 'info', duration);
  }

  warning(message: string, duration = 3000): number {
    return this.show(message, 'warning', duration);
  }

  remove(id: number) {
    this.toasts.update(current => current.filter(t => t.id !== id));
  }
}
