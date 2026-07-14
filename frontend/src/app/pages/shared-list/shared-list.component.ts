import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { SharedBirthday, Gift } from '../../models/birthday.model';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-shared-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './shared-list.component.html',
  styleUrl: './shared-list.component.scss'
})
export class SharedListComponent implements OnInit {
  birthdayService = inject(BirthdayService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  route = inject(ActivatedRoute);
  router = inject(Router);

  birthday = signal<SharedBirthday | null>(null);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);

  isReserveModalOpen = signal<boolean>(false);
  selectedGift = signal<Gift | null>(null);
  guestName = signal<string>('');
  token = signal<string>('');
  
  // Party Planner
  isTaskModalOpen = signal<boolean>(false);
  selectedTaskId = signal<number | null>(null);
  taskGuestName = signal<string>('');
  activeTab = signal<'gifts' | 'party' | 'memories' | 'card'>('gifts');

  // Memory Lane
  memoryName = signal<string>('');
  memoryMessage = signal<string>('');
  memoryFile = signal<File | null>(null);
  memoryFilePreview = signal<string | null>(null);
  isMemorySubmitting = signal<boolean>(false);

  // E-Card
  signatureName = signal<string>('');
  signatureMessage = signal<string>('');
  signatureColor = signal<string>('#ffeb3b');
  signatureFont = signal<string>('Caveat');

  AVAILABLE_FONTS = ['Caveat', 'Dancing Script', 'Indie Flower', 'Pacifico'];
  AVAILABLE_COLORS = ['#ffeb3b', '#8bc34a', '#03a9f4', '#ff9800', '#e91e63', '#9c27b0'];

  ngOnInit() {
    const tokenParam = this.route.snapshot.paramMap.get('token');
    if (tokenParam) {
      this.token.set(tokenParam);
      this.loadSharedList(tokenParam);
    } else {
      this.error.set("Lien de partage invalide.");
      this.isLoading.set(false);
    }
  }

  loadSharedList(token: string) {
    this.birthdayService.getSharedList(token).subscribe({
      next: (b) => {
        this.birthday.set(b);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load shared list', err);
        this.error.set("Ce lien de partage est invalide ou a expiré.");
        this.isLoading.set(false);
      }
    });
  }

  openReserveModal(gift: Gift) {
    if (gift.isReserved) return;
    this.selectedGift.set(gift);
    this.guestName.set('');
    this.isReserveModalOpen.set(true);
  }

  closeReserveModal() {
    this.isReserveModalOpen.set(false);
    this.selectedGift.set(null);
  }

  confirmReservation() {
    const gift = this.selectedGift();
    const name = this.guestName().trim();
    if (!gift || !name) return;

    this.birthdayService.reserveGift(this.token(), gift.id, name).subscribe({
      next: (updatedGift) => {
        this.birthday.update(b => {
          if (!b) return b;
          return {
            ...b,
            gifts: b.gifts.map(g => g.id === gift.id ? updatedGift : g)
          };
        });
        this.toastService.success(`Merci ${name} ! Le cadeau est réservé.`);
        this.closeReserveModal();
      },
      error: (err) => {
        console.error('Failed to reserve gift', err);
        this.toastService.error("Erreur lors de la réservation du cadeau.");
      }
    });
  }

  // --- Voting System ---
  vote(gift: Gift, type: 'UP' | 'DOWN' | '') {
    if (gift.userVote === type) {
      type = ''; // undo vote
    }
    const fakeGuestName = this.guestName() || 'Guest';
    this.birthdayService.voteGift(this.token(), gift.id, fakeGuestName, type).subscribe({
      next: (updatedGift) => {
        this.birthday.update(b => {
          if (!b) return b;
          return {
            ...b,
            gifts: b.gifts.map(g => g.id === gift.id ? updatedGift : g)
          };
        });
      },
      error: (err) => {
        console.error('Failed to vote', err);
        this.toastService.error("Erreur lors du vote.");
      }
    });
  }

  // --- Party Planner ---
  openTaskModal(taskId: number) {
    this.selectedTaskId.set(taskId);
    this.taskGuestName.set('');
    this.isTaskModalOpen.set(true);
  }

  closeTaskModal() {
    this.isTaskModalOpen.set(false);
    this.selectedTaskId.set(null);
  }

  assignTask() {
    const taskId = this.selectedTaskId();
    const name = this.taskGuestName().trim();
    if (!taskId || !name) return;

    this.birthdayService.assignTask(this.token(), taskId, name).subscribe({
      next: (updatedTask) => {
        this.birthday.update(b => {
          if (!b) return b;
          return {
            ...b,
            partyTasks: (b.partyTasks || []).map(t => t.id === taskId ? updatedTask : t)
          };
        });
        this.toastService.success(`Merci ${name} ! Tâche assignée.`);
        this.closeTaskModal();
      },
      error: (err) => {
        console.error('Failed to assign task', err);
        this.toastService.error("Erreur lors de l'assignation de la tâche.");
      }
    });
  }

  unassignTask(taskId: number) {
    this.birthdayService.unassignTask(this.token(), taskId).subscribe({
      next: (updatedTask) => {
        this.birthday.update(b => {
          if (!b) return b;
          return {
            ...b,
            partyTasks: (b.partyTasks || []).map(t => t.id === taskId ? updatedTask : t)
          };
        });
        this.toastService.success("Tâche désassignée avec succès.");
      },
      error: (err) => {
        console.error('Failed to unassign task', err);
        if (err.status === 403) {
          this.toastService.error("Vous ne pouvez désassigner que vos propres tâches.");
        } else {
          this.toastService.error("Erreur lors de la désassignation de la tâche.");
        }
      }
    });
  }

  // --- Memory Lane ---
  onMemoryFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        this.toastService.error("Le fichier est trop volumineux (Max 5MB).");
        return;
      }
      this.memoryFile.set(file);
      const reader = new FileReader();
      reader.onload = e => this.memoryFilePreview.set(e.target?.result as string);
      reader.readAsDataURL(file);
    }
  }

  submitMemory() {
    const name = this.memoryName().trim();
    const msg = this.memoryMessage().trim();
    const file = this.memoryFile();

    if (!name || (!msg && !file)) {
      this.toastService.error("Veuillez saisir votre nom et un message ou une photo.");
      return;
    }

    this.isMemorySubmitting.set(true);

    if (file) {
      this.birthdayService.uploadMemoryFile(file).subscribe({
        next: (res) => this.finalizeMemorySubmit(name, msg, res.url, file.type),
        error: (err) => {
          console.error(err);
          this.toastService.error("Erreur lors de l'envoi du fichier.");
          this.isMemorySubmitting.set(false);
        }
      });
    } else {
      this.finalizeMemorySubmit(name, msg);
    }
  }

  private finalizeMemorySubmit(name: string, msg: string, mediaUrl?: string, mediaType?: string) {
    this.birthdayService.addMemory(this.token(), name, msg, mediaUrl, mediaType).subscribe({
      next: (newMemory) => {
        this.birthday.update(b => {
          if (!b) return b;
          return { ...b, memories: [newMemory, ...(b.memories || [])] };
        });
        this.toastService.success("Votre souvenir a été ajouté !");
        this.memoryName.set('');
        this.memoryMessage.set('');
        this.memoryFile.set(null);
        this.memoryFilePreview.set(null);
        this.isMemorySubmitting.set(false);
      },
      error: (err) => {
        console.error(err);
        this.toastService.error("Erreur lors de l'ajout du souvenir.");
        this.isMemorySubmitting.set(false);
      }
    });
  }

  // --- E-Card ---
  submitSignature() {
    const name = this.signatureName().trim();
    const msg = this.signatureMessage().trim();
    if (!name || !msg) {
      this.toastService.error("Veuillez saisir votre nom et un message.");
      return;
    }

    this.birthdayService.addSignature(this.token(), name, msg, this.signatureColor(), this.signatureFont()).subscribe({
      next: (newSignature) => {
        this.birthday.update(b => {
          if (!b) return b;
          return { ...b, signatures: [...(b.signatures || []), newSignature] };
        });
        this.toastService.success("Votre signature a été ajoutée à la carte !");
        this.signatureName.set('');
        this.signatureMessage.set('');
      },
      error: (err) => {
        console.error(err);
        this.toastService.error("Erreur lors de l'ajout de la signature.");
      }
    });
  }
}
