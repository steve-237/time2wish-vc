import { Component, inject, ViewEncapsulation } from '@angular/core';
import { RouterOutlet } from '@angular/router';
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
export class App {
  private readonly themeService = inject(ThemeService); // Initializes the theme listeners
}
