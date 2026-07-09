import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface Feedback {
  id?: number;
  user?: any;
  rating: number;
  comment: string;
  createdAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class FeedbackService {
  private http = inject(HttpClient);
  private apiUrl = environment.apiUrl;

  submitFeedback(feedback: Partial<Feedback>): Observable<Feedback> {
    return this.http.post<Feedback>(`${this.apiUrl}/feedbacks`, feedback);
  }

  getAllFeedbacks(): Observable<Feedback[]> {
    return this.http.get<Feedback[]>(`${this.apiUrl}/admin/feedbacks`);
  }
}
