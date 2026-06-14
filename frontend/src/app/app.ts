import { Component, OnInit, OnDestroy, inject, ViewEncapsulation, HostListener, NgZone } from '@angular/core';
import { RouterOutlet, Router } from '@angular/router';
import { AuthService } from './services/auth.service';
import { ThemeService } from './services/theme.service';
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
  private readonly themeService = inject(ThemeService); // Initializes the theme listeners
  
  
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
    // Initialize the idle timer
    this.resetIdleTimer();
  }

  ngOnDestroy() {
    clearTimeout(this.idleTimeout);
  }
}
