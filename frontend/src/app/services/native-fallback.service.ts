import { Injectable } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { Share } from '@capacitor/share';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { LocalNotifications } from '@capacitor/local-notifications';

@Injectable({
  providedIn: 'root'
})
export class NativeFallbackService {

  get isNative(): boolean {
    return Capacitor.isNativePlatform();
  }

  get platform(): string {
    return Capacitor.getPlatform();
  }

  /**
   * Trigger soft haptic feedback on button clicks / interactions
   */
  async hapticImpact(style: ImpactStyle = ImpactStyle.Light): Promise<void> {
    if (this.isNative) {
      try {
        await Haptics.impact({ style });
      } catch (err) {
        console.warn('[Haptics] Native error:', err);
      }
    } else {
      // Browser fallback using Web Vibration API
      if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
        navigator.vibrate(15);
      }
    }
  }

  /**
   * Native Share sheet with fallback to Clipboard / Web Share API
   */
  async shareUrl(title: string, text: string, url: string): Promise<boolean> {
    if (this.isNative) {
      try {
        await Share.share({ title, text, url, dialogTitle: title });
        return true;
      } catch (err) {
        console.warn('[Share] Native share cancelled or failed:', err);
        return false;
      }
    } else if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({ title, text, url });
        return true;
      } catch (err) {
        return this.copyToClipboard(url);
      }
    } else {
      return this.copyToClipboard(url);
    }
  }

  private async copyToClipboard(text: string): Promise<boolean> {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Capture or Pick Image using Camera API with Web fallback
   */
  async pickImage(): Promise<string | null> {
    if (this.isNative) {
      try {
        const photo = await Camera.getPhoto({
          quality: 85,
          allowEditing: false,
          resultType: CameraResultType.DataUrl,
          source: CameraSource.Prompt
        });
        return photo.dataUrl || null;
      } catch (err) {
        console.warn('[Camera] Native camera cancelled or failed:', err);
        return null;
      }
    } else {
      // Web Browser Fallback: Open File Dialog
      return new Promise((resolve) => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.onchange = (e: any) => {
          const file = e.target?.files?.[0];
          if (!file) {
            resolve(null);
            return;
          }
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = () => resolve(null);
          reader.readAsDataURL(file);
        };
        input.click();
      });
    }
  }

  /**
   * Schedule Local Notification with Web Notification Fallback
   */
  async scheduleNotification(id: number, title: string, body: string, delaySeconds: number = 2): Promise<void> {
    if (this.isNative) {
      try {
        const perm = await LocalNotifications.requestPermissions();
        if (perm.display === 'granted') {
          await LocalNotifications.schedule({
            notifications: [
              {
                id,
                title,
                body,
                schedule: { at: new Date(Date.now() + delaySeconds * 1000) }
              }
            ]
          });
        }
      } catch (err) {
        console.warn('[LocalNotifications] Error scheduling native notification:', err);
      }
    } else {
      // Web Notification API Fallback
      if (typeof window !== 'undefined' && 'Notification' in window) {
        if (Notification.permission === 'granted') {
          setTimeout(() => new Notification(title, { body }), delaySeconds * 1000);
        } else if (Notification.permission !== 'denied') {
          const result = await Notification.requestPermission();
          if (result === 'granted') {
            setTimeout(() => new Notification(title, { body }), delaySeconds * 1000);
          }
        }
      }
    }
  }
}
