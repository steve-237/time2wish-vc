import { Component, OnInit, OnDestroy, inject, ViewEncapsulation, HostListener, NgZone } from '@angular/core';
import { RouterOutlet, Router } from '@angular/router';
import { AuthService } from './services/auth.service';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';
import { TermsModalComponent } from './components/terms-modal/terms-modal.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, ToastContainerComponent, TermsModalComponent],
  templateUrl: './app.html',
  encapsulation: ViewEncapsulation.None
})
export class App implements OnInit, OnDestroy {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly ngZone = inject(NgZone);
  
  private idleTimeout: any;
  private readonly IDLE_TIME = 3 * 60 * 1000; // 3 minutes of inactivity

  @HostListener('window:mousemove')
  @HostListener('window:keydown')
  @HostListener('window:click')
  @HostListener('window:scroll')
  @HostListener('window:touchstart')
  resetIdleTimer() {
    if (this.authService.isAuthenticated()) {
      clearTimeout(this.idleTimeout);
      this.ngZone.runOutsideAngular(() => {
        this.idleTimeout = setTimeout(() => {
          this.ngZone.run(() => this.handleInactivity());
        }, this.IDLE_TIME);
      });
    }
  }

  private handleInactivity() {
    if (this.authService.isAuthenticated()) {
      this.authService.logout().subscribe(() => {
        this.router.navigate(['/login'], { queryParams: { reason: 'timeout' } });
      });
    }
  }
  
  ngOnInit() {
    // Load app mode preference
    const storedMode = localStorage.getItem('t2w_app_mode');
    const legacyDark = localStorage.getItem('t2w_dark_mode') === 'true';
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    let modeToApply: 'light' | 'dark' | 'oled' = 'light';
    
    if (storedMode === 'dark' || storedMode === 'oled') {
      modeToApply = storedMode;
    } else if (legacyDark || (!storedMode && prefersDark)) {
      modeToApply = 'dark';
    }

    if (modeToApply === 'dark') document.body.classList.add('dark-theme');
    if (modeToApply === 'oled') document.body.classList.add('oled-theme');

    // Load color theme
    const storedColorTheme = localStorage.getItem('t2w_color_theme');
    if (storedColorTheme) {
      document.body.classList.add(storedColorTheme);
    } else {
      document.body.classList.add('theme-ocean');
    }

    // Initialize the idle timer
    this.resetIdleTimer();
  }

  ngOnDestroy() {
    clearTimeout(this.idleTimeout);
  }
}
