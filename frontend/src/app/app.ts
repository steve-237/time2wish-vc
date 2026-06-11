import { Component, OnInit, inject, ViewEncapsulation } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, ToastContainerComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss',
  encapsulation: ViewEncapsulation.None
})
export class App implements OnInit {
  
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
  }
}
