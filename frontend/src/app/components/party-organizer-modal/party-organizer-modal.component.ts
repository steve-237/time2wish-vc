import { Component, Input, Output, EventEmitter, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { BirthdayService } from '../../services/birthday.service';
import { Birthday, PartyTask } from '../../models/birthday.model';
import { ToastService } from '../../services/toast.service';
import { TranslationService } from '../../services/translation.service';
import { MessagingService } from '../../services/messaging.service';
import { ContactService } from '../../services/contact.service';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-party-organizer-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './party-organizer-modal.component.html',
  styleUrls: ['./party-organizer-modal.component.scss']
})
export class PartyOrganizerModalComponent implements OnInit {
  @Input() birthday!: Birthday;
  @Output() close = new EventEmitter<void>();
  
  birthdayService = inject(BirthdayService);
  toastService = inject(ToastService);
  t9n = inject(TranslationService);
  messagingService = inject(MessagingService);
  contactService = inject(ContactService);
  router = inject(Router);

  activeTab = signal<'details' | 'tasks' | 'share' | 'friends'>('details');

  // Party Details
  partyDate = signal<string>('');
  partyTime = signal<string>('');
  partyLocation = signal<string>('');
  partyDescription = signal<string>('');

  // Tasks
  newTaskDescription = '';
  isAddingTask = false;

  // Group Organization
  selectedContactIds: number[] = [];

  ngOnInit() {
    this.partyDate.set(this.birthday.partyDate || '');
    this.partyTime.set(this.birthday.partyTime || '');
    this.partyLocation.set(this.birthday.partyLocation || '');
    this.partyDescription.set(this.birthday.partyDescription || '');
    
    // Refresh contacts if empty
    if (this.contactService.contacts().length === 0) {
      this.contactService.getContacts().subscribe();
    }

    if (!this.birthday.shareToken && this.birthday.id) {
      this.birthdayService.generateShareToken(this.birthday.id).subscribe({
        next: (res) => {
          this.birthday.shareToken = res.token;
        }
      });
    }
  }

  saveDetails() {
    const id = this.birthday.id;
    if (id) {
      this.birthdayService.updateBirthday(
        id,
        this.birthday.name,
        this.birthday.birthdate,
        this.birthday.category,
        this.birthday.notes || '',
        this.birthday.reminderDays,
        this.birthday.photoUrl || '',
        this.birthday.showAge !== false,
        this.birthday.email || '',
        this.birthday.whatsapp || '',
        this.birthday.gender,
        this.birthday.interests || [],
        this.birthday.isFavorite || false,
        this.partyDate(),
        this.partyTime(),
        this.partyLocation(),
        this.partyDescription()
      );
      this.toastService.success('Détails de la fête sauvegardés.');
    }
  }

  // --- Tasks Management ---
  addPartyTask() {
    const id = this.birthday.id;
    if (!id || !this.newTaskDescription.trim()) return;
    
    this.isAddingTask = true;
    this.birthdayService.addPartyTask(id, this.newTaskDescription).subscribe({
      next: (task) => {
        this.toastService.success('Tâche ajoutée');
        this.newTaskDescription = '';
        this.isAddingTask = false;
        
        // Update local object immediately for smooth UI
        if (!this.birthday.partyTasks) this.birthday.partyTasks = [];
        this.birthday.partyTasks.push(task);
      },
      error: () => {
        this.toastService.error("Erreur lors de l'ajout");
        this.isAddingTask = false;
      }
    });
  }

  deletePartyTask(taskId: number) {
    const bId = this.birthday.id;
    if (!bId) return;
    
    this.birthdayService.deletePartyTask(bId, taskId).subscribe({
      next: () => {
        this.toastService.success('Tâche supprimée');
        if (this.birthday.partyTasks) {
          this.birthday.partyTasks = this.birthday.partyTasks.filter(t => t.id !== taskId);
        }
      },
      error: () => this.toastService.error('Erreur lors de la suppression')
    });
  }

  toggleTaskCompletion(task: PartyTask) {
    const bId = this.birthday.id;
    if (!bId) return;
    
    this.birthdayService.togglePartyTask(bId, task.id).subscribe({
      next: (updatedTask: PartyTask) => {
        task.isCompleted = updatedTask.isCompleted;
      },
      error: () => this.toastService.error('Erreur de mise à jour')
    });
  }

  // --- Sharing Links ---
  getShareLink(): string {
    if (!this.birthday.shareToken) return 'Génération du lien...';
    const baseUrl = window.location.origin;
    return `${baseUrl}/shared/${this.birthday.shareToken}`;
  }

  copyShareLink() {
    if (!this.birthday.shareToken) {
      this.toastService.error('Veuillez patienter, le lien est en cours de création.');
      return;
    }
    navigator.clipboard.writeText(this.getShareLink()).then(() => {
      this.toastService.success('Lien copié dans le presse-papier');
    }).catch(err => {
      console.error('Could not copy text: ', err);
      this.toastService.error('Erreur lors de la copie du lien.');
    });
  }

  // --- Group Friends ---
  toggleContactSelection(contactId: number) {
    const idx = this.selectedContactIds.indexOf(contactId);
    if (idx > -1) {
      this.selectedContactIds.splice(idx, 1);
    } else {
      this.selectedContactIds.push(contactId);
    }
  }

  createBirthdayGroup() {
    const b = this.birthday;
    if (!b || !b.id || this.selectedContactIds.length === 0) return;
    
    this.messagingService.createBirthdayGroup(b.id, this.selectedContactIds).subscribe({
      next: (conv) => {
        this.toastService.success('Groupe créé avec succès');
        this.close.emit();
        this.router.navigate(['/dashboard/messaging'], { queryParams: { startChatWith: conv.id } });
      },
      error: (err) => this.toastService.error(err.error?.message || 'Erreur')
    });
  }

  onClose() {
    this.close.emit();
  }
}
