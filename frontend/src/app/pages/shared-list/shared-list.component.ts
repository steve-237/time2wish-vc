import { Component, signal, inject, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { SharedBirthday, Gift } from '../../models/birthday.model';
import { FormsModule } from '@angular/forms';
import { VirtualEnvelope } from '../../components/virtual-envelope/virtual-envelope';

@Component({
  selector: 'app-shared-list',
  standalone: true,
  imports: [CommonModule, FormsModule, VirtualEnvelope],
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
  showEnvelope = signal<boolean>(false);

  isReserveModalOpen = signal<boolean>(false);
  selectedGift = signal<Gift | null>(null);
  guestName = signal<string>('');
  token = signal<string>('');
  
  // Party Planner
  isTaskModalOpen = signal<boolean>(false);
  selectedTaskId = signal<number | null>(null);
  taskGuestName = signal<string>('');
  activeTab = signal<'gifts' | 'party' | 'memories' | 'card' | 'capsule'>('gifts');

  // Tinder Mode (Gift Voting)
  tinderMode = signal<boolean>(false);
  currentTinderIndex = signal<number>(0);
  swipeTransform = signal<string>('translate3d(0px, 0px, 0) rotate(0deg)');
  cardTransition = signal<string>('transform 0.3s ease-out');
  unvotedGifts = computed(() => {
    const b = this.birthday();
    if (!b || !b.gifts) return [];
    return b.gifts.filter(g => g.userVote == null);
  });

  private startX = 0;
  private startY = 0;
  private currentX = 0;
  private currentY = 0;
  private isDragging = false;


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

  // Time Capsule
  timeCapsuleGuestName = signal<string>('');
  timeCapsuleFile = signal<File | null>(null);
  isTimeCapsuleSubmitting = signal<boolean>(false);

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
        if (b && !localStorage.getItem(`ecard_opened_${b.id}`)) {
          this.showEnvelope.set(true);
        }
      },
      error: (err) => {
        console.error('Failed to load shared list', err);
        this.error.set("Ce lien de partage est invalide ou a expiré.");
        this.isLoading.set(false);
      }
    });
  }

  onEnvelopeOpened() {
    const b = this.birthday();
    if (b) {
      localStorage.setItem(`ecard_opened_${b.id}`, 'true');
    }
    this.showEnvelope.set(false);
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

  // --- Tinder Mode ---
  startTinderMode() {
    if (this.unvotedGifts().length > 0) {
      this.currentTinderIndex.set(0);
      this.tinderMode.set(true);
      this.resetCardPosition();
    } else {
      this.toastService.success("Vous avez déjà voté pour tous les cadeaux !");
    }
  }

  closeTinderMode() {
    this.tinderMode.set(false);
  }

  handleSwipe(direction: 'left' | 'right') {
    const gift = this.unvotedGifts()[this.currentTinderIndex()];
    if (!gift) return;

    // Animate out
    this.cardTransition.set('transform 0.4s ease-out');
    const screenWidth = window.innerWidth;
    const endX = direction === 'right' ? screenWidth : -screenWidth;
    const rotate = direction === 'right' ? 30 : -30;
    this.swipeTransform.set(`translate3d(${endX}px, 0px, 0) rotate(${rotate}deg)`);

    // Register vote
    const voteType = direction === 'right' ? 'UP' : 'DOWN';
    this.vote(gift, voteType);

    // Wait for animation, then next card
    setTimeout(() => {
      const nextIndex = this.currentTinderIndex() + 1;
      if (nextIndex >= this.unvotedGifts().length) {
        this.closeTinderMode();
      } else {
        this.currentTinderIndex.set(nextIndex);
        this.resetCardPosition();
      }
    }, 300);
  }

  resetCardPosition() {
    this.cardTransition.set('none'); // no transition when resetting to center
    this.swipeTransform.set('translate3d(0px, 0px, 0) rotate(0deg)');
    setTimeout(() => {
      this.cardTransition.set('transform 0.3s ease-out'); // restore transition for manual swiping
    }, 50);
  }

  onCardTouchStart(event: TouchEvent | MouseEvent) {
    this.isDragging = true;
    this.cardTransition.set('none'); // disable transition during drag
    const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
    const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
    this.startX = clientX;
    this.startY = clientY;
    this.currentX = clientX;
    this.currentY = clientY;
  }

  onCardTouchMove(event: TouchEvent | MouseEvent) {
    if (!this.isDragging) return;
    event.preventDefault(); // prevent scrolling
    const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
    const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
    this.currentX = clientX;
    this.currentY = clientY;
    
    const deltaX = this.currentX - this.startX;
    const deltaY = this.currentY - this.startY;
    const rotate = deltaX * 0.05; // slight rotation based on drag distance
    
    this.swipeTransform.set(`translate3d(${deltaX}px, ${deltaY}px, 0) rotate(${rotate}deg)`);
  }

  onCardTouchEnd() {
    if (!this.isDragging) return;
    this.isDragging = false;
    this.cardTransition.set('transform 0.3s ease-out'); // re-enable transition
    
    const deltaX = this.currentX - this.startX;
    const swipeThreshold = 100; // px
    
    if (deltaX > swipeThreshold) {
      this.handleSwipe('right');
    } else if (deltaX < -swipeThreshold) {
      this.handleSwipe('left');
    } else {
      this.resetCardPosition(); // snap back if threshold not met
    }
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

  // --- Time Capsule ---
  onTimeCapsuleFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      if (file.size > 20 * 1024 * 1024) { // 20 MB limit
        this.toastService.error("La vidéo est trop volumineuse (Max 20MB).");
        return;
      }
      this.timeCapsuleFile.set(file);
    }
  }

  submitTimeCapsule() {
    const name = this.timeCapsuleGuestName().trim();
    const file = this.timeCapsuleFile();

    if (!name || !file) {
      this.toastService.error("Veuillez saisir votre nom et sélectionner une vidéo.");
      return;
    }

    this.isTimeCapsuleSubmitting.set(true);

    this.birthdayService.uploadTimeCapsuleVideo(this.token(), name, file).subscribe({
      next: () => {
        this.toastService.success("Vidéo ajoutée à la capsule temporelle !");
        this.timeCapsuleGuestName.set('');
        this.timeCapsuleFile.set(null);
        this.isTimeCapsuleSubmitting.set(false);
      },
      error: (err) => {
        console.error(err);
        this.toastService.error("Erreur lors de l'envoi de la vidéo.");
        this.isTimeCapsuleSubmitting.set(false);
      }
    });
  }
}
