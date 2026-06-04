import { Injectable, inject, effect } from '@angular/core';
import { MatPaginatorIntl } from '@angular/material/paginator';
import { TranslationService } from './translation.service';

@Injectable({ providedIn: 'root' })
export class CustomMatPaginatorIntl extends MatPaginatorIntl {
  private t9n = inject(TranslationService);

  constructor() {
    super();

    // Dynamically update labels when translation changes
    effect(() => {
      this.itemsPerPageLabel = this.t9n.t('paginator.items_per_page');
      this.nextPageLabel = this.t9n.t('paginator.next_page');
      this.previousPageLabel = this.t9n.t('paginator.previous_page');
      this.firstPageLabel = this.t9n.t('paginator.first_page');
      this.lastPageLabel = this.t9n.t('paginator.last_page');
      this.changes.next(); // Trigger redraw
    });
  }

  override getRangeLabel = (page: number, pageSize: number, length: number) => {
    if (length === 0 || pageSize === 0) {
      return `0 ${this.t9n.t('paginator.of')} ${length}`;
    }
    length = Math.max(length, 0);
    const startIndex = page * pageSize;
    const endIndex = startIndex < length ?
      Math.min(startIndex + pageSize, length) :
      startIndex + pageSize;
    return `${startIndex + 1} – ${endIndex} ${this.t9n.t('paginator.of')} ${length}`;
  };
}
