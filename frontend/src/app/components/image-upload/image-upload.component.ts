import { Component, Input, Output, EventEmitter, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-image-upload',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './image-upload.component.html',
  styleUrls: ['./image-upload.component.scss']
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
    if (!file.type.startsWith('image/')) {
      this.errorMessage.set(this.t9n.t('upload.err_type'));
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      this.errorMessage.set(this.t9n.t('upload.err_size'));
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
        this.errorMessage.set(this.t9n.t('upload.err_fail'));
      }
    });
  }

  removeImage(event: Event) {
    event.stopPropagation();
    this.currentImageUrl = '';
    this.imageUrlChange.emit('');
  }
}
