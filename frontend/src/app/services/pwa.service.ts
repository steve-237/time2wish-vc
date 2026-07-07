import { Injectable, signal, inject, isDevMode } from '@angular/core';
import { ToastService } from './toast.service';
import { TranslationService } from './translation.service';
import { SwUpdate } from '@angular/service-worker';

@Injectable({
  providedIn: 'root'
})
export class PwaService {
  private deferredPrompt: any = null;
  public canInstall = signal<boolean>(false);
  public isIos = signal<boolean>(false);
  public showIosPrompt = signal<boolean>(false);
  
  private toastService = inject(ToastService);
  private t9n = inject(TranslationService);

  private swUpdate = inject(SwUpdate);

  constructor() {
    this.initPwaListeners();
  }

  private initPwaListeners() {
    if (this.swUpdate.isEnabled) {
      this.swUpdate.versionUpdates.subscribe((evt: any) => {
        if (evt.type === 'VERSION_READY') {
          const msg = this.t9n.currentLang() === 'en' 
            ? 'A new version is available! Refresh to update.' 
            : 'Une nouvelle version est disponible ! Rafraîchissez pour mettre à jour.';
          this.toastService.info(msg);
          // Optional: setTimeout(() => window.location.reload(), 3000);
        }
      });
    }
    // Check if already installed
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches || (window.navigator as any).standalone === true;
    if (isStandalone) {
      return; // Already installed, no need to do anything
    }

    // Android / Chrome / Edge
    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault();
      // Stash the event so it can be triggered later.
      this.deferredPrompt = e;
      // Update UI notify the user they can install the PWA
      this.canInstall.set(true);
    });

    // Detect installation success
    window.addEventListener('appinstalled', () => {
      // Clear the deferredPrompt so it can be garbage collected
      this.deferredPrompt = null;
      this.canInstall.set(false);
      this.showIosPrompt.set(false);
      this.toastService.success(this.t9n.currentLang() === 'en' ? 'App installed successfully!' : 'Application installée avec succès !');
    });

    // iOS Detection
    const userAgent = window.navigator.userAgent.toLowerCase();
    const isIosDevice = /iphone|ipad|ipod/.test(userAgent);
    if (isIosDevice && !isStandalone) {
      this.isIos.set(true);
      // We can also let the user install it
      this.canInstall.set(true); 
    }

    // Dev Mode Simulation
    if (isDevMode() && !isStandalone && !isIosDevice) {
      setTimeout(() => {
        if (!this.canInstall()) {
          this.canInstall.set(true);
        }
      }, 1000);
    }
  }

  public installApp() {
    if (this.isIos()) {
      // Show iOS instruction toast
      this.showIosPrompt.set(true);
      const msg = this.t9n.currentLang() === 'en' 
        ? 'To install: tap the Share button at the bottom, then "Add to Home Screen".' 
        : 'Pour installer : touchez l\'icône Partager en bas, puis "Sur l\'écran d\'accueil".';
      this.toastService.info(msg);
      return;
    }

    if (!this.deferredPrompt) {
      if (isDevMode()) {
        const msg = this.t9n.currentLang() === 'en'
          ? 'Development simulation: The native install prompt would appear here in production.'
          : 'Simulation dev : L\'invite d\'installation native apparaîtrait ici en production.';
        this.toastService.info(msg);
      }
      return;
    }

    // Show the install prompt
    this.deferredPrompt.prompt();

    // Wait for the user to respond to the prompt
    this.deferredPrompt.userChoice.then((choiceResult: { outcome: string }) => {
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the install prompt');
      } else {
        console.log('User dismissed the install prompt');
      }
      // We no longer need the prompt. Clear it up.
      this.deferredPrompt = null;
      this.canInstall.set(false);
    });
  }
}
