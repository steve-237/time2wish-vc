import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface SupportTicket {
  id: number;
  user?: { id: number; fullName: string; email: string };
  subject: string;
  message: string;
  status: string;
  adminReply?: string;
  createdAt: string;
  updatedAt?: string;
  repliedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class SupportService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  // --- USER API ---
  getMyTickets(): Observable<SupportTicket[]> {
    return this.http.get<SupportTicket[]>(`${this.apiUrl}/support`);
  }

  createTicket(subject: string, message: string): Observable<SupportTicket> {
    return this.http.post<SupportTicket>(`${this.apiUrl}/support`, { subject, message });
  }

  // --- ADMIN API ---
  getAllTickets(): Observable<SupportTicket[]> {
    return this.http.get<SupportTicket[]>(`${this.apiUrl}/admin/support`);
  }

  replyToTicket(ticketId: number, replyMessage: string): Observable<SupportTicket> {
    return this.http.put<SupportTicket>(`${this.apiUrl}/admin/support/${ticketId}/reply`, { replyMessage });
  }

  updateTicketStatus(ticketId: number, status: string): Observable<SupportTicket> {
    return this.http.put<SupportTicket>(`${this.apiUrl}/admin/support/${ticketId}/status`, { status });
  }
}
