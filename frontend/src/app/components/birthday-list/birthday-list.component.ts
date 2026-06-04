import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy, ViewChild, OnChanges, SimpleChanges, inject, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { Birthday } from '../../models/birthday.model';
import { BirthdayService } from '../../services/birthday.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-birthday-list',
  standalone: true,
  imports: [CommonModule, RouterModule, MatTableModule, MatPaginatorModule, MatSortModule],
  templateUrl: './birthday-list.component.html',
  styleUrls: ['./birthday-list.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BirthdayListComponent implements OnChanges, AfterViewInit {
  @Input({ required: true }) birthdays: Birthday[] = [];
  
  @Output() sendWish = new EventEmitter<{ birthday: Birthday, event: Event }>();
  @Output() delete = new EventEmitter<{ id: number, event: Event }>();

  public birthdayService = inject(BirthdayService);
  public t9n = inject(TranslationService);

  displayedColumns: string[] = ['avatar', 'name', 'birthdate', 'category', 'countdown', 'actions'];
  dataSource: MatTableDataSource<Birthday>;

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  constructor() {
    this.dataSource = new MatTableDataSource<Birthday>([]);
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['birthdays'] && changes['birthdays'].currentValue) {
      this.dataSource.data = this.birthdays;
    }
  }

  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
    // Custom sort for birthdate (need to consider month/day vs absolute date)
    this.dataSource.sortingDataAccessor = (item, property) => {
      switch(property) {
        case 'countdown': return this.birthdayService.getDaysUntil(item.birthdate);
        case 'name': return item.name.toLowerCase();
        default: return (item as any)[property];
      }
    };
  }

  getLabel(rawLabel: string): string {
    if (rawLabel === '__today__') return this.t9n.t('countdown.today');
    if (rawLabel === '__tomorrow__') return this.t9n.t('countdown.tomorrow');
    if (rawLabel.startsWith('__days__:')) {
      const days = rawLabel.split(':')[1];
      return this.t9n.t('countdown.days', days);
    }
    return rawLabel;
  }

  onSendWish(birthday: Birthday, event: Event) {
    this.sendWish.emit({ birthday, event });
  }

  onDelete(id: number, event: Event) {
    this.delete.emit({ id, event });
  }
}
