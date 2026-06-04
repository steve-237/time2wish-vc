import { Component, Input, Output, EventEmitter, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-image-upload',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './image-upload.component.html',
  styleUrls: ['./image-upload.component.css']
})
export class ImageUploadComponent {
  private readonly http = inject(HttpClient);
  t9n = inject(TranslationService);

  @Input() currentImageUrl: string = '';
  @Output() imageUrlChange = new EventEmitter<string>();

  isDragOver = signal<boolean>(false);
  isUploading = signal<boolean>(false);
  errorMessage = signal<string>('');

  onDragOver(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver.set(true);
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver.set(false);
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver.set(false);

    if (event.dataTransfer?.files && event.dataTransfer.files.length > 0) {
      const file = event.dataTransfer.files[0];
      this.uploadFile(file);
    }
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.uploadFile(file);
    }
  }

  private uploadFile(file: File) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      this.errorMessage.set(this.t9n.currentLang() === 'en' ? 'Only image files are allowed.' : 'Seuls les fichiers image sont autorisés.');
      return;
    }

    // Validate size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.errorMessage.set(this.t9n.currentLang() === 'en' ? 'Image size must be less than 5MB.' : 'La taille de l\'image doit être inférieure à 5 Mo.');
      return;
    }

    this.isUploading.set(true);
    this.errorMessage.set('');

    const formData = new FormData();
    formData.append('file', file);

    this.http.post<{ url: string; filename: string }>('http://localhost:8081/api/upload', formData).subscribe({
      next: (response) => {
        this.isUploading.set(false);
        this.currentImageUrl = response.url;
        this.imageUrlChange.emit(response.url);
      },
      error: (err) => {
        this.isUploading.set(false);
        console.error('File upload error:', err);
        this.errorMessage.set(this.t9n.currentLang() === 'en' ? 'Failed to upload image. Please try again.' : 'Échec du téléversement de l\'image. Veuillez réessayer.');
      }
    });
  }

  removeImage(event: Event) {
    event.stopPropagation();
    this.currentImageUrl = '';
    this.imageUrlChange.emit('');
  }
}
