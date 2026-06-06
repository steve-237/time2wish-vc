import { Component, Output, EventEmitter, inject, signal, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TemplateService } from '../../services/template.service';
import { TranslationService } from '../../services/translation.service';
import { MessageTemplate } from '../../models/template.model';

@Component({
  selector: 'app-template-manager',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './template-manager.component.html',
  styleUrls: ['./template-manager.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class TemplateManagerComponent {
  templateService = inject(TemplateService);
  t9n = inject(TranslationService);

  @Output() close = new EventEmitter<void>();

  // Form fields for adding/editing a template
  isEditing = signal<boolean>(false);
  editingId = signal<number | null>(null);
  
  title = signal<string>('');
  content = signal<string>('');
  category = signal<string>('custom');

  readonly categories = ['friendly', 'funny', 'formal', 'custom'];

  getCategoryLabel(cat: string): string {
    const lang = this.t9n.currentLang();
    if (lang === 'en') {
      switch(cat) {
        case 'friendly': return 'Friendly';
        case 'funny': return 'Funny';
        case 'formal': return 'Formal';
        default: return 'Custom';
      }
    } else {
      switch(cat) {
        case 'friendly': return 'Amical';
        case 'funny': return 'Drôle';
        case 'formal': return 'Formel';
        default: return 'Personnalisé';
      }
    }
  }

  resetForm() {
    this.title.set('');
    this.content.set('');
    this.category.set('custom');
    this.isEditing.set(false);
    this.editingId.set(null);
  }

  startEdit(template: MessageTemplate) {
    this.title.set(template.title);
    this.content.set(template.content);
    this.category.set(template.category);
    this.isEditing.set(true);
    if (template.id !== undefined) {
      this.editingId.set(template.id);
    }
  }

  onSubmit() {
    if (!this.title() || !this.content()) {
      return;
    }

    const payload = {
      title: this.title(),
      content: this.content(),
      category: this.category()
    };

    if (this.isEditing() && this.editingId() !== null) {
      this.templateService.updateTemplate(this.editingId()!, payload).subscribe({
        next: () => this.resetForm()
      });
    } else {
      this.templateService.createTemplate(payload).subscribe({
        next: () => this.resetForm()
      });
    }
  }

  onDelete(id: number) {
    if (confirm(this.t9n.currentLang() === 'en' ? 'Are you sure you want to delete this template?' : 'Êtes-vous sûr de vouloir supprimer ce modèle ?')) {
      this.templateService.deleteTemplate(id).subscribe();
    }
  }
}
