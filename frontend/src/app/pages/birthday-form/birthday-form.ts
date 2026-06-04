import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { BirthdayCategory } from '../../models/birthday.model';
import { AudioService } from '../../services/audio.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-birthday-form',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './birthday-form.html',
  styleUrl: './birthday-form.css'
})
export class BirthdayForm implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  router = inject(Router);
  route = inject(ActivatedRoute);
  private audioService = inject(AudioService);
  private notifService = inject(NotificationService);

  isEditMode = signal<boolean>(false);
  birthdayId = signal<number | null>(null);

  // Form Fields
  name = signal<string>('');
  birthdate = signal<string>('');
  category = signal<BirthdayCategory>('Friend');
  notes = signal<string>('');
  reminderDays = signal<number>(7);
  photoUrl = signal<string>('');
  errorMessage = signal<string>('');

  // Dropdown categories list
  readonly categories: BirthdayCategory[] = ['Family', 'Friend', 'Work', 'Other'];

  ngOnInit() {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      const id = +idParam;
      const b = this.birthdayService.getBirthday(id);
      if (b) {
        this.isEditMode.set(true);
        this.birthdayId.set(id);
        
        // Fill form fields
        this.name.set(b.name);
        this.birthdate.set(b.birthdate);
        this.category.set(b.category);
        this.notes.set(b.notes || '');
        this.reminderDays.set(b.reminderDays);
        this.photoUrl.set(b.photoUrl || '');
      } else {
        this.router.navigate(['/dashboard']);
      }
    }
  }

  onSubmit() {
    this.errorMessage.set('');

    if (!this.name() || !this.birthdate()) {
      this.errorMessage.set(this.t9n.t('form.name') + ' et ' + this.t9n.t('form.birthdate') + ' sont obligatoires.');
      return;
    }

    // Basic date validation
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(this.birthdate())) {
      this.errorMessage.set('La date de naissance doit être au format AAAA-MM-JJ.');
      return;
    }

    if (this.isEditMode()) {
      const id = this.birthdayId();
      if (id !== null) {
        this.birthdayService.updateBirthday(
          id,
          this.name(),
          this.birthdate(),
          this.category(),
          this.notes(),
          this.reminderDays(),
          this.photoUrl()
        );
        this.audioService.playSuccessSound();
        this.notifService.logAction('UPDATE', `L'anniversaire de ${this.name()} a été mis à jour.`);
      }
    } else {
      this.birthdayService.addBirthday(
        this.name(),
        this.birthdate(),
        this.category(),
        this.notes(),
        this.reminderDays(),
        this.photoUrl()
      );
      this.audioService.playSuccessSound();
      this.notifService.logAction('ADD', `L'anniversaire de ${this.name()} a été ajouté.`);
    }

    this.router.navigate(['/dashboard']);
  }
}
