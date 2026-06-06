import { Injectable, inject } from '@angular/core';
import { Birthday } from '../models/birthday.model';
import { BirthdayService } from './birthday.service';
import { ToastService } from './toast.service';
import { TranslationService } from './translation.service';

@Injectable({
  providedIn: 'root'
})
export class ExportService {
  private birthdayService = inject(BirthdayService);
  private toastService = inject(ToastService);
  private t9n = inject(TranslationService);

  // --- CSV Import/Export ---
  exportToCSV(birthdays: Birthday[]) {
    let csvContent = 'name,birthdate,category,notes,reminderDays,photoUrl\n';
    birthdays.forEach(b => {
      const notes = b.notes ? `"${b.notes.replace(/"/g, '""')}"` : '';
      const row = `"${b.name.replace(/"/g, '""')}",${b.birthdate},${b.category},${notes},${b.reminderDays ?? 7},"${(b.photoUrl ?? '').replace(/"/g, '""')}"`;
      csvContent += row + '\n';
    });
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    this.downloadBlob(blob, `time2wish_birthdays_${new Date().toISOString().split('T')[0]}.csv`);
  }

  parseAndImportCSV(text: string) {
    try {
      const lines = text.split('\n');
      if (lines.length <= 1) {
        this.toastService.warning(this.t9n.t('toasts.import_error'));
        return;
      }
      
      const headers = lines[0].toLowerCase().trim().split(',');
      let importCount = 0;
      
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        
        // Simple CSV parsing (handling quotes)
        const cols = [];
        let insideQuotes = false;
        let current = '';
        for (let charIndex = 0; charIndex < line.length; charIndex++) {
          const char = line[charIndex];
          if (char === '"') {
            insideQuotes = !insideQuotes;
          } else if (char === ',' && !insideQuotes) {
            cols.push(current.trim());
            current = '';
          } else {
            current += char;
          }
        }
        cols.push(current.trim());
        
        // Extract values
        const nameIdx = headers.indexOf('name');
        const dateIdx = headers.indexOf('birthdate');
        const catIdx = headers.indexOf('category');
        const notesIdx = headers.indexOf('notes');
        const reminderIdx = headers.indexOf('reminderdays');
        const photoIdx = headers.indexOf('photourl');
        
        const name = nameIdx !== -1 ? cols[nameIdx] : '';
        const date = dateIdx !== -1 ? cols[dateIdx] : '';
        
        if (!name || !date) continue;
        
        // Validate date format (YYYY-MM-DD)
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(date)) continue;
        
        let category: any = 'Other';
        const catValue = catIdx !== -1 ? cols[catIdx] : 'Other';
        if (['Family', 'Friend', 'Work', 'Other'].includes(catValue)) {
          category = catValue;
        }
        
        const notes = notesIdx !== -1 ? cols[notesIdx] : '';
        const reminderDays = reminderIdx !== -1 ? parseInt(cols[reminderIdx], 10) || 7 : 7;
        const photoUrl = photoIdx !== -1 ? cols[photoIdx] : '';
        
        this.birthdayService.addBirthday(name, date, category, notes, reminderDays, photoUrl);
        importCount++;
      }
      
      if (importCount > 0) {
        this.toastService.success(this.t9n.t('toasts.import_success', importCount));
      } else {
        this.toastService.warning(this.t9n.t('toasts.import_error'));
      }
    } catch (err) {
      console.error(err);
      this.toastService.error(this.t9n.t('toasts.import_error'));
    }
  }

  // --- iCal Import/Export ---
  exportListToICal(birthdays: Birthday[]) {
    let icsContent = 'BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Time2Wish//NONSGML Birthday Calendar//EN\nCALSCALE:GREGORIAN\n';
    
    birthdays.forEach(b => {
      const cleanDate = b.birthdate.replace(/-/g, ''); // 19900515
      const bDate = new Date(b.birthdate);
      bDate.setDate(bDate.getDate() + 1);
      const cleanEndDate = bDate.toISOString().split('T')[0].replace(/-/g, '');
      
      icsContent += 'BEGIN:VEVENT\n';
      icsContent += `SUMMARY:🎂 Anniversaire de ${b.name}\n`;
      icsContent += `DTSTART;VALUE=DATE:${cleanDate}\n`;
      icsContent += `DTEND;VALUE=DATE:${cleanEndDate}\n`;
      icsContent += 'RRULE:FREQ=YEARLY\n';
      icsContent += `DESCRIPTION:${b.notes ? b.notes.replace(/\n/g, '\\n') : 'Time2Wish Birthday reminder'}\n`;
      icsContent += 'END:VEVENT\n';
    });
    
    icsContent += 'END:VCALENDAR';
    
    const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8;' });
    this.downloadBlob(blob, `time2wish_birthdays_${new Date().toISOString().split('T')[0]}.ics`);
  }

  downloadSingleIcs(birthday: Birthday): void {
    const bdate = new Date(birthday.birthdate);
    const year = new Date().getFullYear();
    const nextOccurrence = new Date(year, bdate.getMonth(), bdate.getDate());
    
    // If the birthday already passed this year, schedule for next year
    if (nextOccurrence.getTime() < new Date().setHours(0,0,0,0)) {
      nextOccurrence.setFullYear(year + 1);
    }

    const startStr = nextOccurrence.toISOString().replace(/[-:]/g, '').split('T')[0];
    const endOccurrence = new Date(nextOccurrence);
    endOccurrence.setDate(endOccurrence.getDate() + 1);
    const endStr = endOccurrence.toISOString().replace(/[-:]/g, '').split('T')[0];

    const icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Time2Wish//FR',
      'BEGIN:VEVENT',
      `DTSTART;VALUE=DATE:${startStr}`,
      `DTEND;VALUE=DATE:${endStr}`,
      `SUMMARY:Anniversaire de ${birthday.name}`,
      `DESCRIPTION:N'oubliez pas de souhaiter un joyeux anniversaire à ${birthday.name} !`,
      'RRULE:FREQ=YEARLY',
      'END:VEVENT',
      'END:VCALENDAR'
    ].join('\r\n');

    const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8' });
    this.downloadBlob(blob, `anniversaire_${birthday.name.replace(/\s+/g, '_').toLowerCase()}.ics`);
  }

  private downloadBlob(blob: Blob, filename: string) {
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}
