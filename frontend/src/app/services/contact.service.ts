import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../environments/environment';

export interface UserSearchDto { id: number; fullName: string; email: string; avatarUrl?: string; }
export interface ContactDto { id: number; userId: number; fullName: string; email: string; avatarUrl?: string; status: string; createdAt: string; }

@Injectable({
  providedIn: 'root'
})
export class ContactService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/contacts`;

  contacts = signal<ContactDto[]>([]);
  pendingRequests = signal<ContactDto[]>([]);
  searchResults = signal<UserSearchDto[]>([]);

  searchUsers(query: string): Observable<UserSearchDto[]> {
    return this.http.get<UserSearchDto[]>(`${this.apiUrl}/search?q=${query}`).pipe(
      tap(results => this.searchResults.set(results))
    );
  }

  getContacts(): Observable<ContactDto[]> {
    return this.http.get<ContactDto[]>(this.apiUrl).pipe(
      tap(contacts => this.contacts.set(contacts))
    );
  }

  getPendingRequests(): Observable<ContactDto[]> {
    return this.http.get<ContactDto[]>(`${this.apiUrl}/pending`).pipe(
      tap(requests => this.pendingRequests.set(requests))
    );
  }

  sendRequest(userId: number): Observable<ContactDto> {
    return this.http.post<ContactDto>(`${this.apiUrl}/request/${userId}`, {});
  }

  acceptRequest(id: number): Observable<ContactDto> {
    return this.http.put<ContactDto>(`${this.apiUrl}/${id}/accept`, {}).pipe(
      tap(() => {
        this.getContacts().subscribe();
        this.getPendingRequests().subscribe();
      })
    );
  }

  rejectRequest(id: number): Observable<ContactDto> {
    return this.http.put<ContactDto>(`${this.apiUrl}/${id}/reject`, {}).pipe(
      tap(() => {
        this.getPendingRequests().subscribe();
      })
    );
  }

  removeContact(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`).pipe(
      tap(() => {
        this.getContacts().subscribe();
      })
    );
  }
}
