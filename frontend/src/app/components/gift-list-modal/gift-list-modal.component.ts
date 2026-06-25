import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Birthday, Gift } from '../../models/birthday.model';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-gift-list-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './gift-list-modal.component.html',
  styleUrl: './gift-list-modal.component.scss'
})
export class GiftListModalComponent {
  @Input({ required: true }) birthday!: Birthday;
  @Input({ required: true }) gifts: Gift[] = [];
  
  @Output() close = new EventEmitter<void>();
  @Output() deleteGift = new EventEmitter<number>();
  @Output() generateShare = new EventEmitter<void>();

  toastService = inject(ToastService);

  onDelete(giftId: number) {
    this.deleteGift.emit(giftId);
  }

  onGenerateShare() {
    this.generateShare.emit();
  }

  copyShareLink() {
    if (!this.birthday.shareToken) return;
    const url = `${window.location.origin}/shared/${this.birthday.shareToken}`;
    navigator.clipboard.writeText(url).then(() => {
      this.toastService.success('Lien de partage copié dans le presse-papier !');
    }).catch(err => {
      console.error('Could not copy text: ', err);
      this.toastService.error('Erreur lors de la copie du lien.');
    });
  }
}
