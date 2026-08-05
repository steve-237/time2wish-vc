import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class GoogleSyncService {
  private apiUrl = `${environment.apiUrl}/google`;

  constructor(private http: HttpClient) {}

  getAuthUrl(): Observable<{ url: string }> {
    return this.http.get<{ url: string }>(`${this.apiUrl}/auth-url`);
  }

  handleCallback(code: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/callback`, { code });
  }

  syncContacts(): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${this.apiUrl}/sync-contacts`, {});
  }

  syncCalendar(): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${this.apiUrl}/sync-calendar`, {});
  }
}
