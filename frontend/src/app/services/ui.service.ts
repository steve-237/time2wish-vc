import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class UiService {
  public isPricingModalOpen = signal<boolean>(false);
}
