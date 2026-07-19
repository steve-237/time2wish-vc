import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { SharedBirthday } from '../../models/birthday.model';
import { VirtualEnvelope } from '../../components/virtual-envelope/virtual-envelope';

@Component({
  selector: 'app-surprise',
  standalone: true,
  imports: [CommonModule, VirtualEnvelope],
  templateUrl: './surprise.html',
  styleUrl: './surprise.scss'
})
export class SurpriseComponent implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  route = inject(ActivatedRoute);

  birthday = signal<SharedBirthday | null>(null);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);
  showEnvelope = signal<boolean>(false);

  ngOnInit() {
    const tokenParam = this.route.snapshot.paramMap.get('token');
    if (tokenParam) {
      this.loadSharedList(tokenParam);
    } else {
      this.error.set("Lien surprise invalide.");
      this.isLoading.set(false);
    }
  }

  loadSharedList(token: string) {
    this.birthdayService.getSharedList(token).subscribe({
      next: (b) => {
        this.birthday.set(b);
        this.isLoading.set(false);
        // Toujours afficher l'enveloppe sur la page surprise au premier chargement de session
        if (b && !sessionStorage.getItem(`surprise_opened_${b.id}`)) {
          this.showEnvelope.set(true);
        }
      },
      error: (err) => {
        console.error('Failed to load shared list', err);
        this.error.set("Ce lien surprise est invalide ou a expiré.");
        this.isLoading.set(false);
      }
    });
  }

  onEnvelopeOpened() {
    const b = this.birthday();
    if (b) {
      sessionStorage.setItem(`surprise_opened_${b.id}`, 'true');
    }
    this.showEnvelope.set(false);
  }
}
