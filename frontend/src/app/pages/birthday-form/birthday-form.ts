import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { BirthdayCategory } from '../../models/birthday.model';
import { AudioService } from '../../services/audio.service';
import { NotificationService } from '../../services/notification.service';
import { ImageUploadComponent } from '../../components/image-upload/image-upload.component';
import { AuthService } from '../../services/auth.service';
import { UiService } from '../../services/ui.service';

@Component({
  selector: 'app-birthday-form',
  standalone: true,
  imports: [CommonModule, FormsModule, ImageUploadComponent],
  templateUrl: './birthday-form.html',
  styleUrl: './birthday-form.scss'
})
export class BirthdayForm implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  router = inject(Router);
  route = inject(ActivatedRoute);
  private audioService = inject(AudioService);
  private notifService = inject(NotificationService);
  private authService = inject(AuthService);
  uiService = inject(UiService);

  get userPlan() {
    return this.authService.currentUser()?.plan || 'BASIC';
  }

  isEditMode = signal<boolean>(false);
  birthdayId = signal<number | null>(null);

  // Form Fields
  name = signal<string>('');
  birthdate = signal<string>('');
  category = signal<BirthdayCategory>('Friend');
  notes = signal<string>('');
  reminderDays = signal<number>(7);
  photoUrl = signal<string>('');
  showAge = signal<boolean>(true);
  email = signal<string>('');
  whatsapp = signal<string>('');
  gender = signal<'Masculin' | 'Féminin' | 'Autre' | undefined>(undefined);
  errorMessage = signal<string>('');

  // Party Details
  partyDate = signal<string>('');
  partyTime = signal<string>('');
  partyLocation = signal<string>('');
  partyDescription = signal<string>('');

  // Dropdown categories list
  readonly categories: BirthdayCategory[] = ['Family', 'Friend', 'Work', 'Other'];

  getIconForCategory(cat: BirthdayCategory): string {
    switch(cat) {
      case 'Family': return 'diversity_3';
      case 'Friend': return 'handshake';
      case 'Work': return 'business_center';
      case 'Other': return 'star';
      default: return 'help';
    }
  }

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
        this.showAge.set(b.showAge !== false);
        if (b.email) this.email.set(b.email);
        if (b.whatsapp) this.whatsapp.set(b.whatsapp);
        if (b.gender) this.gender.set(b.gender);
        if (b.partyDate) this.partyDate.set(b.partyDate);
        if (b.partyTime) this.partyTime.set(b.partyTime);
        if (b.partyLocation) this.partyLocation.set(b.partyLocation);
        if (b.partyDescription) this.partyDescription.set(b.partyDescription);
      } else {
        this.router.navigate(['/dashboard']);
      }
    }
  }

  onCancel() {
    this.router.navigate(['/dashboard']);
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
      const b = id ? this.birthdayService.getBirthday(id) : null;
      if (id !== null) {
        this.birthdayService.updateBirthday(
          id,
          this.name(),
          this.birthdate(),
          this.category(),
          this.notes(),
          this.reminderDays(),
          this.photoUrl(),
          this.showAge(),
          this.email(),
          this.whatsapp(),
          this.gender(),
          b?.interests || [],
          b?.isFavorite || false,
          b?.partyDate, 
          b?.partyTime, 
          b?.partyLocation, 
          b?.partyDescription
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
        this.photoUrl(),
        this.showAge(),
        this.email(),
        this.whatsapp(),
        this.gender()
      );
      this.audioService.playSuccessSound();
      this.notifService.logAction('ADD', `L'anniversaire de ${this.name()} a été ajouté.`);
    }

    this.router.navigate(['/dashboard']);
  }
}
