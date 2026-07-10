import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface Announcement {
  id: number;
  title: string;
  message: string;
  type: string;
  active: boolean;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class AnnouncementService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  getActiveAnnouncement(): Observable<Announcement | null> {
    return this.http.get<Announcement | null>(`${this.apiUrl}/announcements/active`);
  }

  getAllAnnouncements(): Observable<Announcement[]> {
    return this.http.get<Announcement[]>(`${this.apiUrl}/admin/announcements`);
  }

  createAnnouncement(announcement: Partial<Announcement>): Observable<Announcement> {
    return this.http.post<Announcement>(`${this.apiUrl}/admin/announcements`, announcement);
  }

  toggleAnnouncement(id: number): Observable<Announcement> {
    return this.http.put<Announcement>(`${this.apiUrl}/admin/announcements/${id}/toggle`, {});
  }
}
