import { TranslationService } from '../../services/translation.service';
import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Birthday, Gift } from '../../models/birthday.model';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-gift-list-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './gift-list-modal.component.html',
  styleUrl: './gift-list-modal.component.scss'
})
export class GiftListModalComponent {
  t9n = inject(TranslationService);
  @Input({ required: true }) birthday!: Birthday;
  @Input({ required: true }) gifts: Gift[] = [];
  @Input() isGeneratingGifts = false;
  @Input() aiError = false;
  @Input() giftSource = '';
  @Input() giftSuggestions: any[] = [];
  @Output() deleteGift = new EventEmitter<number>();
  @Output() generateShare = new EventEmitter<void>();
  @Output() addGift = new EventEmitter<{name: string, description: string, priceRange: string, url: string}>();
  @Output() updateGift = new EventEmitter<{id: number, data: {name: string, description: string, priceRange: string, url: string}}>();
  @Output() generateGifts = new EventEmitter<void>();

  toastService = inject(ToastService);

  activeTab: 'list' | 'ai' = 'list';
  showManualForm = false;
  editingGiftId: number | null = null;
  newGift = {
    name: '',
    description: '',
    priceRange: '',
    url: ''
  };

  onDelete(giftId: number) {
    this.deleteGift.emit(giftId);
  }

  onGenerateShare() {
    this.generateShare.emit();
  }

  onEditGift(gift: Gift) {
    this.editingGiftId = gift.id;
    this.newGift = {
      name: gift.name,
      description: gift.description,
      priceRange: gift.priceRange,
      url: gift.url
    };
    this.showManualForm = true;
    // Scroll to form (optional, could use window.scrollTo)
  }

  onAddManualGift() {
    if (!this.newGift.name) return;
    
    if (this.editingGiftId) {
      this.updateGift.emit({ id: this.editingGiftId, data: { ...this.newGift } });
    } else {
      this.addGift.emit({ ...this.newGift });
    }
    
    // Reset form
    this.newGift = { name: '', description: '', priceRange: '', url: '' };
    this.editingGiftId = null;
    this.showManualForm = false;
  }

  cancelEdit() {
    this.newGift = { name: '', description: '', priceRange: '', url: '' };
    this.editingGiftId = null;
    this.showManualForm = false;
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
